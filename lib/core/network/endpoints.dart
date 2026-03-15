// endpoints.dart
// Reziphay
//
// Author: Vugar Safarzada (@vugarsafarzada)

enum OtpPurpose {
  authenticate('AUTHENTICATE'),
  login('LOGIN'),
  register('REGISTER');

  const OtpPurpose(this.value);
  final String value;
}

abstract final class Endpoints {
  static const String _base = 'http://localhost:3000/api/v1';
  static String get baseUrl => _base;

  // Auth
  static const String requestPhoneOtp      = '/auth/request-phone-otp';
  static const String verifyPhoneOtp       = '/auth/verify-phone-otp';
  static const String completeRegistration = '/auth/complete-registration';
  static const String refreshToken         = '/auth/refresh';
  static const String logout               = '/auth/logout';
  static const String authMe               = '/auth/me';

  // User
  static const String userMe       = '/users/me';
  static const String activateUso  = '/users/activate-uso';
  static const String getRoles     = '/users/roles';
  static const String switchRole   = '/users/switch-role';

  // Discovery & Search
  static const String search         = '/search';
  static const String nearbyServices = '/services/nearby';
  static const String serviceOwners  = '/service-owners';
  static const String services       = '/services';
  static const String brands         = '/brands';
  static const String categories     = '/categories';

  static String serviceById(String id) => '/services/$id';
  static String brandById(String id)   => '/brands/$id';

  // Reservations
  static const String reservations          = '/reservations';
  static const String myReservations        = '/reservations/my';
  static String reservationById(String id)  => '/reservations/$id';
  static String cancelReservation(String id)=> '/reservations/$id/cancel-by-customer';
}
