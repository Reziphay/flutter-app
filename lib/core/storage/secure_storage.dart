// secure_storage.dart
// Reziphay
//
// Author: Vugar Safarzada (@vugarsafarzada)

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  SecureStorage._();
  static final SecureStorage instance = SecureStorage._();

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const _keyAccess  = 'reziphay_access_token';
  static const _keyRefresh = 'reziphay_refresh_token';

  Future<String?> get accessToken  => _storage.read(key: _keyAccess);
  Future<String?> get refreshToken => _storage.read(key: _keyRefresh);

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await Future.wait([
      _storage.write(key: _keyAccess,  value: accessToken),
      _storage.write(key: _keyRefresh, value: refreshToken),
    ]);
  }

  Future<void> clearTokens() async {
    await Future.wait([
      _storage.delete(key: _keyAccess),
      _storage.delete(key: _keyRefresh),
    ]);
  }

  Future<bool> get hasTokens async {
    final token = await accessToken;
    return token != null && token.isNotEmpty;
  }
}
