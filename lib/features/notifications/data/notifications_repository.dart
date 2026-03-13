import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reziphay_mobile/core/auth/session_controller.dart';
import 'package:reziphay_mobile/features/notifications/models/app_notification_models.dart';
import 'package:reziphay_mobile/shared/models/app_role.dart';

abstract class NotificationsRepository {
  Future<List<AppNotification>> getNotifications(List<AppRole> availableRoles);

  Future<void> markNotificationRead(String notificationId);

  Future<void> markAllRead(List<AppRole> availableRoles);
}

final notificationsRepositoryProvider = Provider<NotificationsRepository>(
  (ref) => MockNotificationsRepository(),
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

    final session = ref.read(sessionControllerProvider).session;
    final targetRole = notification.destination.role;
    if (session != null &&
        session.availableRoles.contains(targetRole) &&
        session.activeRole != targetRole) {
      await ref.read(sessionControllerProvider.notifier).switchRole(targetRole);
    }

    return notification.destination;
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
