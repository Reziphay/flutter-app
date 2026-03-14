// auth_service.dart
// Reziphay
//
// Author: Vugar Safarzada (@vugarsafarzada)

import '../core/network/api_client.dart';
import '../core/network/endpoints.dart';
import '../core/storage/secure_storage.dart';
import '../models/auth_models.dart';
import '../models/user.dart';

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final _client  = ApiClient.instance;
  final _storage = SecureStorage.instance;

  // MARK: - OTP

  Future<OtpRequestResponse> requestOtp({
    required String phone,
    required OtpPurpose purpose,
    String? fullName,
    String? email,
  }) async {
    final body = <String, dynamic>{
      'phone':   phone,
      'purpose': purpose.value,
    };
    if (fullName != null) body['fullName'] = fullName;
    if (email    != null) body['email']    = email;

    return _client.post(
      Endpoints.requestPhoneOtp,
      data: body,
      fromJson: OtpRequestResponse.fromJson,
    );
  }

  Future<OtpVerifyResponse> verifyOtp({
    required String phone,
    required String code,
    required OtpPurpose purpose,
  }) async {
    final response = await _client.post(
      Endpoints.verifyPhoneOtp,
      data: {'phone': phone, 'code': code, 'purpose': purpose.value},
      fromJson: OtpVerifyResponse.fromJson,
    );

    await _storage.saveTokens(
      accessToken:  response.accessToken,
      refreshToken: response.refreshToken,
    );

    return response;
  }

  // MARK: - Session

  Future<void> logout() async {
    try {
      await _client.postEmpty(Endpoints.logout);
    } finally {
      await _storage.clearTokens();
    }
  }

  Future<User?> validateSession() async {
    final hasToken = await _storage.hasTokens;
    if (!hasToken) return null;
    try {
      return await _client.get(
        Endpoints.authMe,
        fromJson: User.fromJson,
      );
    } catch (_) {
      return null;
    }
  }

  // MARK: - User

  Future<User> getMe() => _client.get(Endpoints.userMe, fromJson: User.fromJson);

  Future<User> updateProfile({String? fullName, String? email}) async {
    final body = <String, dynamic>{};
    if (fullName != null) body['fullName'] = fullName;
    if (email    != null) body['email']    = email;
    return _client.patch(Endpoints.userMe, data: body, fromJson: User.fromJson);
  }

  Future<User> activateUso() =>
      _client.post(Endpoints.activateUso, fromJson: User.fromJson);

  Future<User> switchRole(UserRole role) =>
      _client.post(
        Endpoints.switchRole,
        data: {'role': role.value},
        fromJson: User.fromJson,
      );
}
