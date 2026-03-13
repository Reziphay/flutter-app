import 'package:dio/dio.dart';
import 'package:reziphay_mobile/shared/models/user_session.dart';

class AuthInterceptor extends QueuedInterceptor {
  AuthInterceptor({
    required this.readSession,
    required this.ensureFreshSession,
  });

  final UserSession? Function() readSession;
  final Future<UserSession?> Function() ensureFreshSession;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (_shouldSkipAuth(options)) {
      handler.next(options);
      return;
    }

    var session = readSession();

    if (session != null && session.tokens.shouldRefreshSoon) {
      try {
        session = await ensureFreshSession();
      } catch (_) {
        session = readSession();
      }
    }

    final accessToken = session?.tokens.accessToken;

    if (accessToken != null && accessToken.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $accessToken';
    }

    handler.next(options);
  }

  bool _shouldSkipAuth(RequestOptions options) {
    if (options.extra['skipAuth'] == true) {
      return true;
    }

    final path = options.path;
    return path.contains('/auth/request-phone-otp') ||
        path.contains('/auth/verify-phone-otp') ||
        path.contains('/auth/refresh') ||
        path.contains('/auth/verify-email-magic-link');
  }
}
