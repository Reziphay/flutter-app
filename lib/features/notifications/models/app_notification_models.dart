import 'package:intl/intl.dart';
import 'package:reziphay_mobile/shared/models/app_role.dart';

enum AppNotificationType {
  reservationReceived,
  reservationConfirmed,
  reservationRejected,
  reservationCancelled,
  changeRequested,
  upcomingAppointment,
  delayStatus,
  reviewReminder,
}

extension AppNotificationTypeX on AppNotificationType {
  String get label => switch (this) {
    AppNotificationType.reservationReceived => 'Reservation received',
    AppNotificationType.reservationConfirmed => 'Reservation confirmed',
    AppNotificationType.reservationRejected => 'Reservation rejected',
    AppNotificationType.reservationCancelled => 'Reservation cancelled',
    AppNotificationType.changeRequested => 'Change requested',
    AppNotificationType.upcomingAppointment => 'Upcoming appointment',
    AppNotificationType.delayStatus => 'Delay status',
    AppNotificationType.reviewReminder => 'Leave a review',
  };
}

enum NotificationDestinationType {
  customerReservation,
  providerReservation,
  service,
  provider,
  brand,
  reviewCreate,
}

class NotificationDestination {
  const NotificationDestination({
    required this.type,
    required this.entityId,
    required this.role,
  });

  final NotificationDestinationType type;
  final String entityId;
  final AppRole role;
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.createdAt,
    required this.isRead,
    required this.destination,
    this.roleScope,
  });

  final String id;
  final String title;
  final String body;
  final AppNotificationType type;
  final DateTime createdAt;
  final bool isRead;
  final NotificationDestination destination;
  final AppRole? roleScope;

  bool get isUnread => !isRead;

  String get relativeTimeLabel {
    final difference = DateTime.now().difference(createdAt);
    if (difference.inMinutes <= 0) {
      return 'Just now';
    }
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    }
    if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    }
    if (difference.inDays == 1) {
      return 'Yesterday';
    }
    if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    }
    return DateFormat('MMM d').format(createdAt);
  }

  String get dayGroupLabel {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final itemDay = DateTime(createdAt.year, createdAt.month, createdAt.day);
    final difference = today.difference(itemDay).inDays;

    if (difference == 0) {
      return 'Today';
    }
    if (difference == 1) {
      return 'Yesterday';
    }
    if (difference < 7) {
      return 'Earlier this week';
    }
    return DateFormat('MMMM d').format(createdAt);
  }

  AppNotification copyWith({
    String? id,
    String? title,
    String? body,
    AppNotificationType? type,
    DateTime? createdAt,
    bool? isRead,
    NotificationDestination? destination,
    AppRole? roleScope,
    bool clearRoleScope = false,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      destination: destination ?? this.destination,
      roleScope: clearRoleScope ? null : roleScope ?? this.roleScope,
    );
  }
}
