import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:reziphay_mobile/shared/models/user_session.dart';

abstract class SessionStore {
  Future<UserSession?> readSession();
  Future<void> writeSession(UserSession session);
  Future<void> clearSession();
}

final sessionStoreProvider = Provider<SessionStore>(
  (ref) => SecureSessionStore(),
);

class SecureSessionStore implements SessionStore {
  SecureSessionStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const _sessionKey = 'reziphay.session';

  final FlutterSecureStorage _storage;

  @override
  Future<void> clearSession() async {
    await _storage.delete(key: _sessionKey);
  }

  @override
  Future<UserSession?> readSession() async {
    final rawJson = await _storage.read(key: _sessionKey);

    if (rawJson == null || rawJson.isEmpty) {
      return null;
    }

    final decoded = jsonDecode(rawJson) as Map<String, dynamic>;
    return UserSession.fromJson(decoded);
  }

  @override
  Future<void> writeSession(UserSession session) async {
    await _storage.write(key: _sessionKey, value: jsonEncode(session.toJson()));
  }
}

class InMemorySessionStore implements SessionStore {
  UserSession? _session;

  @override
  Future<void> clearSession() async {
    _session = null;
  }

  @override
  Future<UserSession?> readSession() async => _session;

  @override
  Future<void> writeSession(UserSession session) async {
    _session = session;
  }
}
