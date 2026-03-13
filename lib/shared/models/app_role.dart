enum AppRole { customer, provider }

extension AppRoleX on AppRole {
  static AppRole fromQuery(String? rawValue) {
    return rawValue == 'provider' ? AppRole.provider : AppRole.customer;
  }

  String get queryValue => switch (this) {
    AppRole.customer => 'customer',
    AppRole.provider => 'provider',
  };

  String get label => switch (this) {
    AppRole.customer => 'Customer',
    AppRole.provider => 'Service provider',
  };

  String get shortLabel => switch (this) {
    AppRole.customer => 'UCR',
    AppRole.provider => 'USO',
  };

  String get description => switch (this) {
    AppRole.customer =>
      'Discover services, request reservations, and manage upcoming visits.',
    AppRole.provider =>
      'Manage brands, services, and reservation requests from one account.',
  };
}
