enum AppRole { customer, provider }

extension AppRoleX on AppRole {
  static AppRole fromQuery(String? rawValue) {
    switch (rawValue?.trim().toUpperCase()) {
      case 'PROVIDER':
      case 'USO':
        return AppRole.provider;
      case 'CUSTOMER':
      case 'UCR':
      default:
        return AppRole.customer;
    }
  }

  String get queryValue => switch (this) {
    AppRole.customer => 'customer',
    AppRole.provider => 'provider',
  };

  String get backendValue => switch (this) {
    AppRole.customer => 'UCR',
    AppRole.provider => 'USO',
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
