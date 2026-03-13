import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:reziphay_mobile/app/config/app_environment.dart';
import 'package:reziphay_mobile/features/notifications/models/app_notification_models.dart';
import 'package:reziphay_mobile/features/settings/models/settings_models.dart';
import 'package:reziphay_mobile/shared/models/app_role.dart';

final pushMessagingServiceProvider = Provider<PushMessagingService>((ref) {
  final environment = ref.watch(appEnvironmentProvider);
  final service = environment.enableFirebaseMessaging
      ? FirebasePushMessagingService()
      : LocalPushMessagingService();
  ref.onDispose(() {
    unawaited(service.dispose());
  });
  return service;
});

enum PushInboundEventSource { foreground, openedApp, initialLaunch }

class PushInboundEvent {
  const PushInboundEvent({
    required this.destination,
    required this.title,
    required this.body,
    required this.source,
  });

  final NotificationDestination destination;
  final String title;
  final String body;
  final PushInboundEventSource source;
}

abstract class PushMessagingService {
  Future<void> initialize();

  Future<PushPermissionStatus> requestPermission();

  Future<String?> getDeviceToken();

  Stream<String> get tokenRefreshes;

  Stream<PushInboundEvent> get inboundEvents;

  Future<PushInboundEvent?> takeInitialEvent();

  Future<void> dispose();
}

class LocalPushMessagingService implements PushMessagingService {
  LocalPushMessagingService();

  String? _token;

  @override
  Stream<PushInboundEvent> get inboundEvents => const Stream.empty();

  @override
  Stream<String> get tokenRefreshes => const Stream.empty();

  @override
  Future<String?> getDeviceToken() async {
    _token ??=
        'local_push_${DateFormat('yyyyMMddHHmmss').format(DateTime.now())}';
    return _token;
  }

  @override
  Future<void> initialize() async {}

  @override
  Future<PushPermissionStatus> requestPermission() async {
    return PushPermissionStatus.granted;
  }

  @override
  Future<PushInboundEvent?> takeInitialEvent() async => null;

  @override
  Future<void> dispose() async {}
}

class FirebasePushMessagingService implements PushMessagingService {
  FirebasePushMessagingService({FirebaseMessaging? messaging})
    : _messaging = messaging ?? FirebaseMessaging.instance;

  final FirebaseMessaging _messaging;
  final StreamController<PushInboundEvent> _inboundController =
      StreamController<PushInboundEvent>.broadcast();
  final StreamController<String> _tokenRefreshController =
      StreamController<String>.broadcast();

  StreamSubscription<RemoteMessage>? _foregroundSubscription;
  StreamSubscription<RemoteMessage>? _openedAppSubscription;
  StreamSubscription<String>? _tokenRefreshSubscription;

  bool _initialized = false;
  bool _firebaseReady = false;
  PushInboundEvent? _initialEvent;

  @override
  Stream<PushInboundEvent> get inboundEvents => _inboundController.stream;

  @override
  Stream<String> get tokenRefreshes => _tokenRefreshController.stream;

  @override
  Future<String?> getDeviceToken() async {
    await initialize();
    if (!_firebaseReady) {
      return null;
    }

    return _messaging.getToken();
  }

  @override
  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    _initialized = true;

    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
      _firebaseReady = true;
    } catch (_) {
      _firebaseReady = false;
      return;
    }

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _initialEvent = _eventFromRemoteMessage(
        initialMessage,
        PushInboundEventSource.initialLaunch,
      );
    }

    _foregroundSubscription = FirebaseMessaging.onMessage.listen((message) {
      final event = _eventFromRemoteMessage(
        message,
        PushInboundEventSource.foreground,
      );
      if (event != null) {
        _inboundController.add(event);
      }
    });

    _openedAppSubscription = FirebaseMessaging.onMessageOpenedApp.listen((
      message,
    ) {
      final event = _eventFromRemoteMessage(
        message,
        PushInboundEventSource.openedApp,
      );
      if (event != null) {
        _inboundController.add(event);
      }
    });

    _tokenRefreshSubscription = _messaging.onTokenRefresh.listen((token) {
      if (token.isNotEmpty) {
        _tokenRefreshController.add(token);
      }
    });
  }

  @override
  Future<PushPermissionStatus> requestPermission() async {
    await initialize();
    if (!_firebaseReady) {
      return PushPermissionStatus.notRequested;
    }

    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
      announcement: false,
      carPlay: false,
      criticalAlert: false,
    );

    return switch (settings.authorizationStatus) {
      AuthorizationStatus.authorized => PushPermissionStatus.granted,
      AuthorizationStatus.provisional => PushPermissionStatus.granted,
      AuthorizationStatus.denied => PushPermissionStatus.denied,
      AuthorizationStatus.notDetermined => PushPermissionStatus.notRequested,
    };
  }

  @override
  Future<PushInboundEvent?> takeInitialEvent() async {
    await initialize();
    final event = _initialEvent;
    _initialEvent = null;
    return event;
  }

  @override
  Future<void> dispose() async {
    await _foregroundSubscription?.cancel();
    await _openedAppSubscription?.cancel();
    await _tokenRefreshSubscription?.cancel();
    _foregroundSubscription = null;
    _openedAppSubscription = null;
    _tokenRefreshSubscription = null;
    if (!_inboundController.isClosed) {
      await _inboundController.close();
    }
    if (!_tokenRefreshController.isClosed) {
      await _tokenRefreshController.close();
    }
  }

  PushInboundEvent? _eventFromRemoteMessage(
    RemoteMessage message,
    PushInboundEventSource source,
  ) {
    final destination = _parseDestination(message.data);
    if (destination == null) {
      return null;
    }

    return PushInboundEvent(
      destination: destination,
      title:
          message.notification?.title ??
          _readString(message.data, ['title', 'subject']) ??
          'New update',
      body:
          message.notification?.body ??
          _readString(message.data, ['body', 'message', 'description']) ??
          'Open the notification to see the latest update.',
      source: source,
    );
  }

  NotificationDestination? _parseDestination(Map<String, dynamic> data) {
    final role =
        _parseRole(_readString(data, ['role', 'targetRole', 'roleScope'])) ??
        _defaultRoleForType(
          AppNotificationTypeX.parse(
            _readString(data, ['notificationType', 'type', 'eventType']),
          ),
        );

    final destinationType = NotificationDestinationTypeX.parse(
      _readString(data, ['destinationType', 'targetType', 'entityType']),
    );
    final entityId = _readString(data, [
      'entityId',
      'targetId',
      'reservationId',
      'serviceId',
      'providerId',
      'brandId',
    ]);

    if (destinationType != null && entityId != null && entityId.isNotEmpty) {
      return NotificationDestination(
        type: _normalizeDestinationType(destinationType, role),
        entityId: entityId,
        role: role,
      );
    }

    final reservationId = _readString(data, ['reservationId', 'bookingId']);
    if (reservationId != null && reservationId.isNotEmpty) {
      final type = AppNotificationTypeX.parse(
        _readString(data, ['notificationType', 'type', 'eventType']),
      );
      return NotificationDestination(
        type: type == AppNotificationType.reviewReminder
            ? NotificationDestinationType.reviewCreate
            : role == AppRole.provider
            ? NotificationDestinationType.providerReservation
            : NotificationDestinationType.customerReservation,
        entityId: reservationId,
        role: role,
      );
    }

    final serviceId = _readString(data, ['serviceId']);
    if (serviceId != null && serviceId.isNotEmpty) {
      return NotificationDestination(
        type: NotificationDestinationType.service,
        entityId: serviceId,
        role: role,
      );
    }

    final providerId = _readString(data, [
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

    final brandId = _readString(data, ['brandId']);
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
      return role == AppRole.provider
          ? NotificationDestinationType.providerReservation
          : NotificationDestinationType.customerReservation;
    }

    return type;
  }

  AppRole _defaultRoleForType(AppNotificationType? type) {
    return switch (type) {
      AppNotificationType.reservationReceived => AppRole.provider,
      AppNotificationType.changeRequested => AppRole.provider,
      _ => AppRole.customer,
    };
  }

  AppRole? _parseRole(String? rawValue) {
    if (rawValue == null || rawValue.isEmpty) {
      return null;
    }

    return AppRoleX.fromQuery(rawValue);
  }

  String? _readString(Map<String, dynamic> source, List<String> keys) {
    for (final key in keys) {
      final value = _readPath(source, key);
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
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

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }
  } catch (_) {}
}
