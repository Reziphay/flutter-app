enum ReminderLeadTime { twoHours, sixHours, oneDay }

extension ReminderLeadTimeX on ReminderLeadTime {
  String get label => switch (this) {
    ReminderLeadTime.twoHours => '2 hours before',
    ReminderLeadTime.sixHours => '6 hours before',
    ReminderLeadTime.oneDay => '1 day before',
  };

  String get description => switch (this) {
    ReminderLeadTime.twoHours => 'Best for same-day service reminders.',
    ReminderLeadTime.sixHours => 'Balanced notice for most reservations.',
    ReminderLeadTime.oneDay => 'Early heads-up for planning ahead.',
  };
}

enum PushPermissionStatus { notRequested, granted, denied }

extension PushPermissionStatusX on PushPermissionStatus {
  String get label => switch (this) {
    PushPermissionStatus.notRequested => 'Not enabled',
    PushPermissionStatus.granted => 'Ready',
    PushPermissionStatus.denied => 'Denied',
  };

  String get description => switch (this) {
    PushPermissionStatus.notRequested =>
      'Enable push delivery so reservation changes can arrive even when the app is backgrounded.',
    PushPermissionStatus.granted =>
      'This device is ready to receive push updates for reservations and reminders.',
    PushPermissionStatus.denied =>
      'Push delivery is blocked on this device until permission is granted again.',
  };
}

class AppSettings {
  const AppSettings({
    required this.pushNotificationsEnabled,
    required this.reservationUpdatesEnabled,
    required this.upcomingRemindersEnabled,
    required this.reminderLeadTime,
    required this.languageCode,
    required this.themePreference,
  });

  factory AppSettings.initial() {
    return const AppSettings(
      pushNotificationsEnabled: true,
      reservationUpdatesEnabled: true,
      upcomingRemindersEnabled: true,
      reminderLeadTime: ReminderLeadTime.sixHours,
      languageCode: 'en',
      themePreference: 'light',
    );
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      pushNotificationsEnabled:
          json['pushNotificationsEnabled'] as bool? ?? true,
      reservationUpdatesEnabled:
          json['reservationUpdatesEnabled'] as bool? ?? true,
      upcomingRemindersEnabled:
          json['upcomingRemindersEnabled'] as bool? ?? true,
      reminderLeadTime: ReminderLeadTime.values.firstWhere(
        (value) => value.name == json['reminderLeadTime'],
        orElse: () => ReminderLeadTime.sixHours,
      ),
      languageCode: json['languageCode'] as String? ?? 'en',
      themePreference: json['themePreference'] as String? ?? 'light',
    );
  }

  final bool pushNotificationsEnabled;
  final bool reservationUpdatesEnabled;
  final bool upcomingRemindersEnabled;
  final ReminderLeadTime reminderLeadTime;
  final String languageCode;
  final String themePreference;

  Map<String, dynamic> toJson() {
    return {
      'pushNotificationsEnabled': pushNotificationsEnabled,
      'reservationUpdatesEnabled': reservationUpdatesEnabled,
      'upcomingRemindersEnabled': upcomingRemindersEnabled,
      'reminderLeadTime': reminderLeadTime.name,
      'languageCode': languageCode,
      'themePreference': themePreference,
    };
  }

  AppSettings copyWith({
    bool? pushNotificationsEnabled,
    bool? reservationUpdatesEnabled,
    bool? upcomingRemindersEnabled,
    ReminderLeadTime? reminderLeadTime,
    String? languageCode,
    String? themePreference,
  }) {
    return AppSettings(
      pushNotificationsEnabled:
          pushNotificationsEnabled ?? this.pushNotificationsEnabled,
      reservationUpdatesEnabled:
          reservationUpdatesEnabled ?? this.reservationUpdatesEnabled,
      upcomingRemindersEnabled:
          upcomingRemindersEnabled ?? this.upcomingRemindersEnabled,
      reminderLeadTime: reminderLeadTime ?? this.reminderLeadTime,
      languageCode: languageCode ?? this.languageCode,
      themePreference: themePreference ?? this.themePreference,
    );
  }
}

class PushRegistrationState {
  const PushRegistrationState({
    required this.permissionStatus,
    this.deviceToken,
    this.lastSyncedAt,
  });

  factory PushRegistrationState.initial() {
    return const PushRegistrationState(
      permissionStatus: PushPermissionStatus.notRequested,
    );
  }

  factory PushRegistrationState.fromJson(Map<String, dynamic> json) {
    final rawSyncedAt = json['lastSyncedAt'] as String?;
    return PushRegistrationState(
      permissionStatus: PushPermissionStatus.values.firstWhere(
        (value) => value.name == json['permissionStatus'],
        orElse: () => PushPermissionStatus.notRequested,
      ),
      deviceToken: json['deviceToken'] as String?,
      lastSyncedAt: rawSyncedAt == null ? null : DateTime.parse(rawSyncedAt),
    );
  }

  final PushPermissionStatus permissionStatus;
  final String? deviceToken;
  final DateTime? lastSyncedAt;

  bool get canSync => permissionStatus == PushPermissionStatus.granted;

  String get tokenPreview {
    if (deviceToken == null || deviceToken!.isEmpty) {
      return 'No token registered yet';
    }

    final token = deviceToken!;
    if (token.length <= 12) {
      return token;
    }

    return '${token.substring(0, 6)}...${token.substring(token.length - 4)}';
  }

  Map<String, dynamic> toJson() {
    return {
      'permissionStatus': permissionStatus.name,
      'deviceToken': deviceToken,
      'lastSyncedAt': lastSyncedAt?.toIso8601String(),
    };
  }

  PushRegistrationState copyWith({
    PushPermissionStatus? permissionStatus,
    String? deviceToken,
    DateTime? lastSyncedAt,
    bool clearDeviceToken = false,
    bool clearLastSyncedAt = false,
  }) {
    return PushRegistrationState(
      permissionStatus: permissionStatus ?? this.permissionStatus,
      deviceToken: clearDeviceToken ? null : deviceToken ?? this.deviceToken,
      lastSyncedAt: clearLastSyncedAt
          ? null
          : lastSyncedAt ?? this.lastSyncedAt,
    );
  }
}
