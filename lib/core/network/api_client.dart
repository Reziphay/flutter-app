import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reziphay_mobile/app/config/app_environment.dart';
import 'package:reziphay_mobile/core/auth/session_controller.dart';
import 'package:reziphay_mobile/core/network/app_exception.dart';
import 'package:reziphay_mobile/core/network/auth_interceptor.dart';

typedef JsonMap = Map<String, dynamic>;

final publicDioProvider = Provider<Dio>((ref) {
  return _buildDio(ref.watch(appEnvironmentProvider));
});

final dioProvider = Provider<Dio>((ref) {
  final dio = _buildDio(ref.watch(appEnvironmentProvider));

  dio.interceptors.add(
    AuthInterceptor(
      readSession: () => ref.read(sessionControllerProvider).session,
      ensureFreshSession: () =>
          ref.read(sessionControllerProvider.notifier).ensureFreshSession(),
    ),
  );

  return dio;
});

final publicApiClientProvider = Provider<ApiClient>(
  (ref) => ApiClient(ref.watch(publicDioProvider)),
);

final apiClientProvider = Provider<ApiClient>(
  (ref) => ApiClient(ref.watch(dioProvider)),
);

class ApiClient {
  const ApiClient(this._dio);

  final Dio _dio;

  Future<T> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? extra,
    required T Function(dynamic data) mapper,
  }) {
    return _send(
      method: 'GET',
      path: path,
      queryParameters: queryParameters,
      headers: headers,
      extra: extra,
      mapper: mapper,
    );
  }

  Future<T> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? extra,
    required T Function(dynamic data) mapper,
  }) {
    return _send(
      method: 'POST',
      path: path,
      data: data,
      queryParameters: queryParameters,
      headers: headers,
      extra: extra,
      mapper: mapper,
    );
  }

  Future<T> patch<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? extra,
    required T Function(dynamic data) mapper,
  }) {
    return _send(
      method: 'PATCH',
      path: path,
      data: data,
      queryParameters: queryParameters,
      headers: headers,
      extra: extra,
      mapper: mapper,
    );
  }

  Future<T> put<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? extra,
    required T Function(dynamic data) mapper,
  }) {
    return _send(
      method: 'PUT',
      path: path,
      data: data,
      queryParameters: queryParameters,
      headers: headers,
      extra: extra,
      mapper: mapper,
    );
  }

  Future<T> delete<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? extra,
    required T Function(dynamic data) mapper,
  }) {
    return _send(
      method: 'DELETE',
      path: path,
      data: data,
      queryParameters: queryParameters,
      headers: headers,
      extra: extra,
      mapper: mapper,
    );
  }

  Future<T> _send<T>({
    required String method,
    required String path,
    Object? data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? extra,
    required T Function(dynamic data) mapper,
  }) async {
    try {
      final response = await _dio.request<dynamic>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: Options(method: method, headers: headers, extra: extra),
      );

      final envelope = unwrapResponseEnvelope(response.data);
      return mapper(envelope);
    } on DioException catch (error) {
      throw mapDioException(error);
    }
  }
}

Dio _buildDio(AppEnvironment environment) {
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

  if (!environment.isProduction && kDebugMode) {
    dio.interceptors.add(
      LogInterceptor(requestBody: true, responseBody: false),
    );
  }

  return dio;
}

dynamic unwrapResponseEnvelope(dynamic rawBody) {
  if (rawBody is Map<String, dynamic> &&
      rawBody['success'] == true &&
      rawBody.containsKey('data')) {
    return rawBody['data'];
  }

  return rawBody;
}

JsonMap asJsonMap(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return value.map((key, item) => MapEntry(key.toString(), item));
  }

  throw const AppException(
    'Unexpected response payload from the server.',
    type: AppExceptionType.server,
  );
}

List<JsonMap> asJsonMapList(dynamic value) {
  if (value is! List) {
    throw const AppException(
      'Unexpected response list from the server.',
      type: AppExceptionType.server,
    );
  }

  return value.map(asJsonMap).toList(growable: false);
}

AppException mapDioException(DioException error) {
  if (error.error is AppException) {
    return error.error! as AppException;
  }

  switch (error.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
      return const AppException(
        'The server took too long to respond.',
        type: AppExceptionType.timeout,
      );
    case DioExceptionType.connectionError:
      return const AppException(
        'Network connection is unavailable right now.',
        type: AppExceptionType.network,
      );
    case DioExceptionType.badCertificate:
      return const AppException(
        'A secure connection could not be established.',
        type: AppExceptionType.network,
      );
    case DioExceptionType.cancel:
      return const AppException(
        'The request was cancelled.',
        type: AppExceptionType.unknown,
      );
    case DioExceptionType.badResponse:
      return _mapBadResponse(error);
    case DioExceptionType.unknown:
      if (error.error is SocketException) {
        return const AppException(
          'Network connection is unavailable right now.',
          type: AppExceptionType.network,
        );
      }

      return const AppException('Something went wrong. Please try again.');
  }
}

AppException _mapBadResponse(DioException error) {
  final response = error.response;
  final statusCode = response?.statusCode;
  final body = response?.data;
  final responseMap = body is Map<String, dynamic>
      ? body
      : body is Map
      ? body.map((key, value) => MapEntry(key.toString(), value))
      : <String, dynamic>{};
  final errorMap = responseMap['error'] is Map
      ? asJsonMap(responseMap['error'])
      : <String, dynamic>{};
  final message =
      errorMap['message'] as String? ??
      'The server could not complete the request.';
  final requestId = responseMap['requestId'] as String?;
  final code = errorMap['code'] as String?;
  final details = errorMap['details'];

  return AppException(
    message,
    type: _mapStatusCodeToType(statusCode),
    code: code,
    statusCode: statusCode,
    details: details,
    requestId: requestId,
  );
}

AppExceptionType _mapStatusCodeToType(int? statusCode) {
  switch (statusCode) {
    case 400:
    case 422:
      return AppExceptionType.validation;
    case 401:
      return AppExceptionType.unauthorized;
    case 403:
      return AppExceptionType.forbidden;
    case 409:
      return AppExceptionType.conflict;
    case 500:
    case 502:
    case 503:
    case 504:
      return AppExceptionType.server;
    default:
      return AppExceptionType.unknown;
  }
}
