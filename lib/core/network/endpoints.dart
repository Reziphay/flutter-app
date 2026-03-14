// endpoints.dart
// Reziphay
//
// Author: Vugar Safarzada (@vugarsafarzada)

enum OtpPurpose {
  login('LOGIN'),
  register('REGISTER');

  const OtpPurpose(this.value);
  final String value;
}

abstract final class Endpoints {
  static const String _base = 'http://localhost:3000/api/v1';
  static String get baseUrl => _base;

  // Auth
  static const String requestPhoneOtp  = '/auth/request-phone-otp';
  static const String verifyPhoneOtp   = '/auth/verify-phone-otp';
  static const String refreshToken     = '/auth/refresh';
  static const String logout           = '/auth/logout';
  static const String authMe           = '/auth/me';

  // User
  static const String userMe       = '/users/me';
  static const String activateUso  = '/users/activate-uso';
  static const String getRoles     = '/users/roles';
  static const String switchRole   = '/users/switch-role';
}
