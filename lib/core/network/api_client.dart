import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reziphay_mobile/app/config/app_environment.dart';
import 'package:reziphay_mobile/core/auth/session_controller.dart';
import 'package:reziphay_mobile/core/network/auth_interceptor.dart';

final dioProvider = Provider<Dio>((ref) {
  final environment = ref.watch(appEnvironmentProvider);

  final dio = Dio(
    BaseOptions(
      baseUrl: environment.apiBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
      sendTimeout: const Duration(seconds: 20),
      headers: const {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ),
  );

  dio.interceptors.add(
    AuthInterceptor(
      readAccessToken: () =>
          ref.read(sessionControllerProvider).session?.tokens.accessToken,
    ),
  );

  return dio;
});
