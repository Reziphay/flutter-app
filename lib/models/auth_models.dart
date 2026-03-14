// auth_models.dart
// Reziphay
//
// Author: Vugar Safarzada (@vugarsafarzada)

import 'user.dart';

class OtpRequestResponse {
  const OtpRequestResponse({this.message, this.phone, this.debugCode});

  final String? message;
  final String? phone;
  final String? debugCode;

  factory OtpRequestResponse.fromJson(Map<String, dynamic> json) {
    return OtpRequestResponse(
      message:   json['message']   as String?,
      phone:     json['phone']     as String?,
      debugCode: json['debugCode'] as String?,
    );
  }
}

/// Result of verifyPhoneOtp with AUTHENTICATE purpose.
/// Either the user is fully authenticated OR registration is required.
class OtpVerifyResult {
  const OtpVerifyResult._({
    this.session,
    this.registrationPending,
  });

  factory OtpVerifyResult.authenticated(AuthSession session) =>
      OtpVerifyResult._(session: session);

  factory OtpVerifyResult.registrationRequired(RegistrationPending pending) =>
      OtpVerifyResult._(registrationPending: pending);

  final AuthSession? session;
  final RegistrationPending? registrationPending;

  bool get isAuthenticated => session != null;
  bool get requiresRegistration => registrationPending != null;

  factory OtpVerifyResult.fromJson(Map<String, dynamic> json) {
    if (json['requiresRegistration'] == true) {
      return OtpVerifyResult.registrationRequired(
        RegistrationPending.fromJson(json),
      );
    }
    return OtpVerifyResult.authenticated(AuthSession.fromJson(json));
  }
}

class RegistrationPending {
  const RegistrationPending({required this.phone, required this.registrationToken});

  final String phone;
  final String registrationToken;

  factory RegistrationPending.fromJson(Map<String, dynamic> json) {
    return RegistrationPending(
      phone:             json['phone']             as String,
      registrationToken: json['registrationToken'] as String,
    );
  }
}

class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  final String accessToken;
  final String refreshToken;
  final User user;

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    final tokens = json['tokens'] as Map<String, dynamic>;
    return AuthSession(
      accessToken:  tokens['accessToken']  as String,
      refreshToken: tokens['refreshToken'] as String,
      user:         User.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}

class AuthTokens {
  const AuthTokens({required this.accessToken, required this.refreshToken});

  final String accessToken;
  final String refreshToken;

  factory AuthTokens.fromJson(Map<String, dynamic> json) {
    return AuthTokens(
      accessToken:  json['accessToken']  as String,
      refreshToken: json['refreshToken'] as String,
    );
  }
}
