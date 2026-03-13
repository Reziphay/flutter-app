import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reziphay_mobile/core/auth/session_controller.dart';
import 'package:reziphay_mobile/core/network/api_client.dart';
import 'package:reziphay_mobile/core/network/app_exception.dart';
import 'package:reziphay_mobile/features/notifications/data/notification_navigation.dart';
import 'package:reziphay_mobile/features/notifications/models/app_notification_models.dart';
import 'package:reziphay_mobile/shared/models/app_role.dart';

abstract class NotificationsRepository {
  Future<List<AppNotification>> getNotifications(List<AppRole> availableRoles);

  Future<void> markNotificationRead(String notificationId);

  Future<void> markAllRead(List<AppRole> availableRoles);
}

final notificationsRepositoryProvider = Provider<NotificationsRepository>(
  (ref) =>
      BackendNotificationsRepository(apiClient: ref.watch(apiClientProvider)),
);

final notificationsProvider = FutureProvider.autoDispose<List<AppNotification>>(
  (ref) {
    final availableRoles = ref.watch(
      sessionControllerProvider.select(
        (state) => state.session?.availableRoles ?? const [AppRole.customer],
      ),
    );

    return ref
        .watch(notificationsRepositoryProvider)
        .getNotifications(availableRoles);
  },
);

final notificationsActionsProvider = Provider<NotificationsActions>(
  (ref) => NotificationsActions(ref),
);

class NotificationsActions {
  NotificationsActions(this.ref);

  final Ref ref;

  Future<void> markAllVisibleRead() async {
    final availableRoles = ref.read(
      sessionControllerProvider.select(
        (state) => state.session?.availableRoles ?? const [AppRole.customer],
      ),
    );

    await ref.read(notificationsRepositoryProvider).markAllRead(availableRoles);
    ref.invalidate(notificationsProvider);
  }

  Future<void> markRead(String notificationId) async {
    await ref
        .read(notificationsRepositoryProvider)
        .markNotificationRead(notificationId);
    ref.invalidate(notificationsProvider);
  }

  Future<NotificationDestination> openNotification(
    AppNotification notification,
  ) async {
    await markRead(notification.id);
    return ref
        .read(notificationNavigationActionsProvider)
        .prepareDestination(notification.destination);
  }
}

class BackendNotificationsRepository implements NotificationsRepository {
  BackendNotificationsRepository({required ApiClient apiClient})
    : _apiClient = apiClient;

  final ApiClient _apiClient;
  final Map<String, bool> _localReadOverrides = <String, bool>{};

  @override
  Future<List<AppNotification>> getNotifications(
    List<AppRole> availableRoles,
  ) async {
    final payload = await _apiClient.get<dynamic>(
      '/notifications',
      mapper: (data) => data,
    );

    final items = _extractItems(payload, ['items', 'notifications']);
    final notifications =
        items
            .map(_parseNotification)
            .whereType<AppNotification>()
            .where(
              (notification) => _matchesRoles(notification, availableRoles),
            )
            .map(
              (notification) => notification.copyWith(
                isRead:
                    _localReadOverrides[notification.id] ?? notification.isRead,
              ),
            )
            .toList(growable: false)
          ..sort((left, right) => right.createdAt.compareTo(left.createdAt));
    return notifications;
  }

  @override
  Future<void> markAllRead(List<AppRole> availableRoles) async {
    try {
      await _apiClient.post<void>(
        '/notifications/mark-all-read',
        data: {
          'roles': availableRoles.map((role) => role.backendValue).toList(),
        },
        mapper: (_) {},
      );
      return;
    } on AppException catch (error) {
      if (!_canFallbackMarkAll(error)) {
        rethrow;
      }
    }

    final notifications = await getNotifications(availableRoles);
    for (final notification in notifications) {
      _localReadOverrides[notification.id] = true;
    }
  }

  @override
  Future<void> markNotificationRead(String notificationId) async {
    try {
      await _apiClient.post<void>(
        '/notifications/$notificationId/read',
        mapper: (_) {},
      );
    } on AppException catch (error) {
      if (!_canFallbackMarkRead(error)) {
        rethrow;
      }
    }

    _localReadOverrides[notificationId] = true;
  }

  AppNotification? _parseNotification(JsonMap item) {
    final type =
        AppNotificationTypeX.parse(
          _readString(item, ['type', 'eventType', 'name', 'code']),
        ) ??
        _inferTypeFromPayload(item);
    if (type == null) {
      return null;
    }

    final destination = _parseDestination(item, type);
    if (destination == null) {
      return null;
    }

    final createdAt =
        _readDateTime(item, ['createdAt', 'sentAt', 'publishedAt']) ??
        DateTime.now();
    final readAt = _readDateTime(item, ['readAt', 'openedAt']);
    final readValue = _readBool(item, ['isRead', 'read']) ?? (readAt != null);

    return AppNotification(
      id: _readString(item, ['id']) ?? '',
      title: _readString(item, ['title', 'subject']) ?? type.label,
      body: _readString(item, ['body', 'message', 'description']) ?? type.label,
      type: type,
      createdAt: createdAt,
      isRead: readValue,
      destination: destination,
      roleScope: _parseRoleScope(item, destination.role),
    );
  }

  AppNotificationType? _inferTypeFromPayload(JsonMap item) {
    final destination = _extractNestedMap(item, [
      'destination',
      'metadata',
      'data',
      'payload',
    ]);
    final destinationType = NotificationDestinationTypeX.parse(
      _readString(destination ?? item, [
        'destinationType',
        'type',
        'targetType',
        'entityType',
      ]),
    );
    if (destinationType == NotificationDestinationType.reviewCreate) {
      return AppNotificationType.reviewReminder;
    }

    final body = _readString(item, ['title', 'body', 'message'])?.toUpperCase();
    if (body == null) {
      return null;
    }
    if (body.contains('CONFIRMED')) {
      return AppNotificationType.reservationConfirmed;
    }
    if (body.contains('REJECTED')) {
      return AppNotificationType.reservationRejected;
    }
    if (body.contains('CANCELLED')) {
      return AppNotificationType.reservationCancelled;
    }
    if (body.contains('CHANGE')) {
      return AppNotificationType.changeRequested;
    }
    if (body.contains('REVIEW')) {
      return AppNotificationType.reviewReminder;
    }
    if (body.contains('UPCOMING') || body.contains('REMINDER')) {
      return AppNotificationType.upcomingAppointment;
    }
    if (body.contains('DELAY')) {
      return AppNotificationType.delayStatus;
    }
    if (body.contains('RECEIVED') || body.contains('REQUEST')) {
      return AppNotificationType.reservationReceived;
    }
    return null;
  }

  NotificationDestination? _parseDestination(
    JsonMap item,
    AppNotificationType type,
  ) {
    final destinationPayload = _extractNestedMap(item, [
      'destination',
      'metadata',
      'data',
      'payload',
    ]);
    final role = _parseRoleScope(item, null) ?? _defaultRoleFor(type);
    final explicitType = NotificationDestinationTypeX.parse(
      _readString(destinationPayload ?? item, [
        'destinationType',
        'type',
        'targetType',
        'entityType',
      ]),
    );
    final entityId = _readString(destinationPayload ?? item, [
      'entityId',
      'targetId',
      'reservationId',
      'reviewReservationId',
      'serviceId',
      'providerId',
      'brandId',
    ]);

    if (explicitType != null && entityId != null && entityId.isNotEmpty) {
      return NotificationDestination(
        type: _normalizeDestinationType(explicitType, role),
        entityId: entityId,
        role: role,
      );
    }

    final reservationId = _readString(destinationPayload ?? item, [
      'reservationId',
      'bookingId',
    ]);
    if (reservationId != null && reservationId.isNotEmpty) {
      return NotificationDestination(
        type: type == AppNotificationType.reviewReminder
            ? NotificationDestinationType.reviewCreate
            : _reservationDestinationTypeFor(role),
        entityId: reservationId,
        role: role,
      );
    }

    final serviceId = _readString(destinationPayload ?? item, ['serviceId']);
    if (serviceId != null && serviceId.isNotEmpty) {
      return NotificationDestination(
        type: NotificationDestinationType.service,
        entityId: serviceId,
        role: role,
      );
    }

    final providerId = _readString(destinationPayload ?? item, [
      'providerId',
      'ownerId',
      'serviceOwnerId',
    ]);
    if (providerId != null && providerId.isNotEmpty) {
      return NotificationDestination(
        type: NotificationDestinationType.provider,
        entityId: providerId,
        role: role,
      );
    }

    final brandId = _readString(destinationPayload ?? item, ['brandId']);
    if (brandId != null && brandId.isNotEmpty) {
      return NotificationDestination(
        type: NotificationDestinationType.brand,
        entityId: brandId,
        role: role,
      );
    }

    return null;
  }

  NotificationDestinationType _normalizeDestinationType(
    NotificationDestinationType type,
    AppRole role,
  ) {
    if (type == NotificationDestinationType.customerReservation ||
        type == NotificationDestinationType.providerReservation) {
      return _reservationDestinationTypeFor(role);
    }
    return type;
  }

  NotificationDestinationType _reservationDestinationTypeFor(AppRole role) {
    return role == AppRole.provider
        ? NotificationDestinationType.providerReservation
        : NotificationDestinationType.customerReservation;
  }

  AppRole _defaultRoleFor(AppNotificationType type) {
    return switch (type) {
      AppNotificationType.reservationReceived => AppRole.provider,
      AppNotificationType.changeRequested => AppRole.provider,
      AppNotificationType.reservationConfirmed => AppRole.customer,
      AppNotificationType.reservationRejected => AppRole.customer,
      AppNotificationType.reservationCancelled => AppRole.customer,
      AppNotificationType.upcomingAppointment => AppRole.customer,
      AppNotificationType.delayStatus => AppRole.customer,
      AppNotificationType.reviewReminder => AppRole.customer,
    };
  }

  AppRole? _parseRoleScope(JsonMap item, AppRole? fallbackRole) {
    final roleValue = _readString(item, [
      'roleScope',
      'scopeRole',
      'recipientRole',
      'role',
    ]);
    if (roleValue != null) {
      return AppRoleX.fromQuery(roleValue);
    }

    final destination = _extractNestedMap(item, [
      'destination',
      'metadata',
      'data',
      'payload',
    ]);
    final destinationRole = _readString(destination ?? item, [
      'role',
      'targetRole',
      'roleScope',
      'recipientRole',
    ]);
    if (destinationRole != null) {
      return AppRoleX.fromQuery(destinationRole);
    }

    return fallbackRole;
  }

  bool _matchesRoles(
    AppNotification notification,
    List<AppRole> availableRoles,
  ) {
    final roleScope = notification.roleScope;
    return roleScope == null || availableRoles.contains(roleScope);
  }

  bool _canFallbackMarkAll(AppException error) {
    return switch (error.statusCode) {
      404 || 405 || 501 => true,
      _ => false,
    };
  }

  bool _canFallbackMarkRead(AppException error) {
    return switch (error.statusCode) {
      404 || 405 || 501 => true,
      _ => false,
    };
  }

  List<JsonMap> _extractItems(dynamic payload, List<String> keys) {
    if (payload is List) {
      return asJsonMapList(payload);
    }
    if (payload is Map) {
      final map = asJsonMap(payload);
      for (final key in keys) {
        final value = _readPath(map, key);
        if (value is List) {
          return asJsonMapList(value);
        }
      }
    }
    return const [];
  }

  JsonMap? _extractNestedMap(JsonMap source, List<String> keys) {
    for (final key in keys) {
      final value = _readPath(source, key);
      if (value is Map) {
        return asJsonMap(value);
      }
    }
    return null;
  }

  String? _readString(JsonMap source, List<String> keys) {
    for (final key in keys) {
      final value = _readPath(source, key);
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return null;
  }

  bool? _readBool(JsonMap source, List<String> keys) {
    for (final key in keys) {
      final value = _readPath(source, key);
      if (value is bool) {
        return value;
      }
      if (value is num) {
        return value != 0;
      }
      if (value is String) {
        final normalized = value.trim().toLowerCase();
        if (normalized == 'true' || normalized == '1') {
          return true;
        }
        if (normalized == 'false' || normalized == '0') {
          return false;
        }
      }
    }
    return null;
  }

  DateTime? _readDateTime(JsonMap source, List<String> keys) {
    for (final key in keys) {
      final value = _readPath(source, key);
      if (value is DateTime) {
        return value;
      }
      if (value is String && value.trim().isNotEmpty) {
        final parsed = DateTime.tryParse(value.trim());
        if (parsed != null) {
          return parsed;
        }
      }
    }
    return null;
  }

  dynamic _readPath(dynamic source, String path) {
    final segments = path.split('.');
    dynamic current = source;
    for (final segment in segments) {
      if (current is Map) {
        current = current[segment];
      } else {
        return null;
      }
    }
    return current;
  }
}

class MockNotificationsRepository implements NotificationsRepository {
  final List<AppNotification> _notifications = [
    AppNotification(
      id: 'notif_1001',
      title: 'Reservation confirmed',
      body: 'Your beard trim for tomorrow at 16:30 is confirmed.',
      type: AppNotificationType.reservationConfirmed,
      createdAt: DateTime.now().subtract(const Duration(minutes: 6)),
      isRead: false,
      roleScope: AppRole.customer,
      destination: const NotificationDestination(
        type: NotificationDestinationType.customerReservation,
        entityId: 'r_1002',
        role: AppRole.customer,
      ),
    ),
    AppNotification(
      id: 'notif_1002',
      title: 'Upcoming appointment',
      body: 'Leave enough travel time for your confirmed slot later today.',
      type: AppNotificationType.upcomingAppointment,
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      isRead: true,
      roleScope: AppRole.customer,
      destination: const NotificationDestination(
        type: NotificationDestinationType.customerReservation,
        entityId: 'r_1002',
        role: AppRole.customer,
      ),
    ),
    AppNotification(
      id: 'notif_1003',
      title: 'Leave a review',
      body: 'Your dental consultation is complete. Share a quick review.',
      type: AppNotificationType.reviewReminder,
      createdAt: DateTime.now().subtract(const Duration(hours: 20)),
      isRead: false,
      roleScope: AppRole.customer,
      destination: const NotificationDestination(
        type: NotificationDestinationType.reviewCreate,
        entityId: 'r_1003',
        role: AppRole.customer,
      ),
    ),
    AppNotification(
      id: 'notif_1004',
      title: 'Reservation received',
      body: 'Amina Hasanli requested a quick cleanup for today at 15:30.',
      type: AppNotificationType.reservationReceived,
      createdAt: DateTime.now().subtract(const Duration(minutes: 3)),
      isRead: false,
      roleScope: AppRole.provider,
      destination: const NotificationDestination(
        type: NotificationDestinationType.providerReservation,
        entityId: 'r_1006',
        role: AppRole.provider,
      ),
    ),
    AppNotification(
      id: 'notif_1005',
      title: 'Customer requested a new time',
      body:
          'Leyla Mammadova proposed a different slot for the haircut booking.',
      type: AppNotificationType.changeRequested,
      createdAt: DateTime.now().subtract(const Duration(hours: 5)),
      isRead: false,
      roleScope: AppRole.provider,
      destination: const NotificationDestination(
        type: NotificationDestinationType.providerReservation,
        entityId: 'r_1008',
        role: AppRole.provider,
      ),
    ),
    AppNotification(
      id: 'notif_1006',
      title: 'Delay status',
      body:
          'The provider flagged a short delay. Check the reservation for updates.',
      type: AppNotificationType.delayStatus,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      isRead: true,
      roleScope: AppRole.customer,
      destination: const NotificationDestination(
        type: NotificationDestinationType.customerReservation,
        entityId: 'r_1001',
        role: AppRole.customer,
      ),
    ),
  ];

  @override
  Future<List<AppNotification>> getNotifications(
    List<AppRole> availableRoles,
  ) async {
    await _delay();
    return _notifications
        .where((notification) => _matchesRoles(notification, availableRoles))
        .toList()
      ..sort((left, right) => right.createdAt.compareTo(left.createdAt));
  }

  @override
  Future<void> markAllRead(List<AppRole> availableRoles) async {
    await _delay();
    for (var index = 0; index < _notifications.length; index += 1) {
      final notification = _notifications[index];
      if (_matchesRoles(notification, availableRoles) && !notification.isRead) {
        _notifications[index] = notification.copyWith(isRead: true);
      }
    }
  }

  @override
  Future<void> markNotificationRead(String notificationId) async {
    await _delay();
    for (var index = 0; index < _notifications.length; index += 1) {
      final notification = _notifications[index];
      if (notification.id == notificationId && !notification.isRead) {
        _notifications[index] = notification.copyWith(isRead: true);
        return;
      }
    }
  }

  bool _matchesRoles(
    AppNotification notification,
    List<AppRole> availableRoles,
  ) {
    final roleScope = notification.roleScope;
    return roleScope == null || availableRoles.contains(roleScope);
  }

  Future<void> _delay() =>
      Future<void>.delayed(const Duration(milliseconds: 120));
}
