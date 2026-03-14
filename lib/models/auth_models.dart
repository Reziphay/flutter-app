// auth_models.dart
// Reziphay
//
// Author: Vugar Safarzada (@vugarsafarzada)

import 'user.dart';

class OtpRequestResponse {
  const OtpRequestResponse({this.message, this.phone});

  final String? message;
  final String? phone;

  factory OtpRequestResponse.fromJson(Map<String, dynamic> json) {
    return OtpRequestResponse(
      message: json['message'] as String?,
      phone:   json['phone']   as String?,
    );
  }
}

class OtpVerifyResponse {
  const OtpVerifyResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  final String accessToken;
  final String refreshToken;
  final User user;

  factory OtpVerifyResponse.fromJson(Map<String, dynamic> json) {
    return OtpVerifyResponse(
      accessToken:  json['accessToken']  as String,
      refreshToken: json['refreshToken'] as String,
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
