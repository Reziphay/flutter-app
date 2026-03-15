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
  }) {
    return _client.post(
      Endpoints.requestPhoneOtp,
      data: {'phone': phone, 'purpose': purpose.value},
      fromJson: OtpRequestResponse.fromJson,
    );
  }

  /// Verifies OTP (AUTHENTICATE purpose).
  /// Returns [OtpVerifyResult] — either fully authenticated or registration required.
  Future<OtpVerifyResult> verifyOtp({
    required String phone,
    required String code,
  }) async {
    final result = await _client.post(
      Endpoints.verifyPhoneOtp,
      data: {
        'phone':   phone,
        'code':    code,
        'purpose': OtpPurpose.authenticate.value,
      },
      fromJson: OtpVerifyResult.fromJson,
    );

    if (result.isAuthenticated) {
      final session = result.session!;
      await _storage.saveTokens(
        accessToken:  session.accessToken,
        refreshToken: session.refreshToken,
      );
    }

    return result;
  }

  /// Called after [verifyOtp] returns [OtpVerifyResult.requiresRegistration].
  Future<AuthSession> completeRegistration({
    required String registrationToken,
    required String fullName,
    required String email,
    String? role,
  }) async {
    final session = await _client.post(
      Endpoints.completeRegistration,
      data: {
        'registrationToken': registrationToken,
        'fullName':          fullName,
        'email':             email,
        if (role != null) 'initialRole': role,
      },
      fromJson: AuthSession.fromJson,
    );

    await _storage.saveTokens(
      accessToken:  session.accessToken,
      refreshToken: session.refreshToken,
    );

    return session;
  }

  // MARK: - Session

  Future<void> logout() async {
    try {
      await _client.postEmpty(Endpoints.logout);
    } catch (_) {
      // Session may already be revoked on the server — that's fine
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
        fromJson: (json) => User.fromJson(json['user'] as Map<String, dynamic>),
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

  Future<AuthSession> activateUso() async {
    final session = await _client.post(
      Endpoints.activateUso,
      fromJson: AuthSession.fromJson,
    );
    await _storage.saveTokens(
      accessToken:  session.accessToken,
      refreshToken: session.refreshToken,
    );
    return session;
  }

  Future<AuthSession> switchRole(UserRole role) async {
    final session = await _client.post(
      Endpoints.switchRole,
      data: {'role': role.value},
      fromJson: AuthSession.fromJson,
    );
    await _storage.saveTokens(
      accessToken:  session.accessToken,
      refreshToken: session.refreshToken,
    );
    return session;
  }
}
