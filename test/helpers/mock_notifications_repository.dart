// Extracted from lib/features/notifications/data/notifications_repository.dart
// This file is a test-only helper.

import 'package:reziphay_mobile/features/notifications/data/notifications_repository.dart';
import 'package:reziphay_mobile/features/notifications/models/app_notification_models.dart';
import 'package:reziphay_mobile/shared/models/app_role.dart';

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
