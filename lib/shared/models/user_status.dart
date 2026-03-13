enum UserStatus { active, suspended, closed }

extension UserStatusX on UserStatus {
  String get label => switch (this) {
    UserStatus.active => 'Active',
    UserStatus.suspended => 'Suspended',
    UserStatus.closed => 'Closed',
  };

  String get description => switch (this) {
    UserStatus.active =>
      'Your account is available for reservations and role switching.',
    UserStatus.suspended =>
      'Penalty rules temporarily restrict reservations for this account.',
    UserStatus.closed =>
      'This account is closed indefinitely according to the penalty policy.',
  };
}
