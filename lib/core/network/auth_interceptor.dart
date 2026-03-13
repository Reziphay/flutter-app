import 'package:dio/dio.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor({required this.readAccessToken});

  final String? Function() readAccessToken;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final accessToken = readAccessToken();

    if (accessToken != null && accessToken.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $accessToken';
    }

    handler.next(options);
  }
}
