// api_client.dart
// Reziphay
//
// Author: Vugar Safarzada (@vugarsafarzada)

import 'package:dio/dio.dart';
import '../storage/secure_storage.dart';
import 'endpoints.dart';
import 'network_exception.dart';

class ApiClient {
  ApiClient._() {
    _dio = Dio(
      BaseOptions(
        baseUrl: Endpoints.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Only attach auth header — error mapping is done at method level
    _dio.interceptors.add(_AuthHeaderInterceptor(_dio));
  }

  static final ApiClient instance = ApiClient._();
  late final Dio _dio;
  final _storage = SecureStorage.instance;

  // MARK: - Public Methods

  Future<T> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    required T Function(Map<String, dynamic>) fromJson,
  }) => _execute(
        () => _dio.get(path, queryParameters: queryParameters),
        fromJson,
      );

  Future<T> post<T>(
    String path, {
    Object? data,
    required T Function(Map<String, dynamic>) fromJson,
  }) => _execute(
        () => _dio.post(path, data: data),
        fromJson,
      );

  Future<void> postEmpty(String path, {Object? data}) async {
    try {
      await _dio.post(path, data: data);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<T> patch<T>(
    String path, {
    Object? data,
    required T Function(Map<String, dynamic>) fromJson,
  }) => _execute(
        () => _dio.patch(path, data: data),
        fromJson,
      );

  // MARK: - Core Execute (with optional 401 retry)

  Future<T> _execute<T>(
    Future<Response<dynamic>> Function() call,
    T Function(Map<String, dynamic>) fromJson, {
    bool retryOnUnauthorized = true,
  }) async {
    try {
      final response = await call();
      return _unwrap(response, fromJson);
    } on DioException catch (e) {
      // On 401, try token refresh once then retry
      if (e.response?.statusCode == 401 &&
          retryOnUnauthorized &&
          !(e.requestOptions.path.contains(Endpoints.refreshToken))) {
        final refreshed = await _tryRefreshToken();
        if (refreshed) {
          return _execute(call, fromJson, retryOnUnauthorized: false);
        }
        await _storage.clearTokens();
        throw const NetworkException('Session expired. Please log in again.', statusCode: 401);
      }
      throw _mapError(e);
    }
  }

  // MARK: - Helpers

  T _unwrap<T>(Response response, T Function(Map<String, dynamic>) fromJson) {
    final body = response.data;
    if (body is Map<String, dynamic> && body.containsKey('data')) {
      return fromJson(body['data'] as Map<String, dynamic>);
    }
    return fromJson(body as Map<String, dynamic>);
  }

  NetworkException _mapError(DioException e) {
    final statusCode = e.response?.statusCode;

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const NetworkException.timeout();

      case DioExceptionType.connectionError:
        return const NetworkException.noInternet();

      case DioExceptionType.badResponse:
        final message = _extractMessage(e.response);
        if (statusCode == 401) {
          return NetworkException(message ?? 'Unauthorized.', statusCode: 401);
        }
        if (statusCode == 404) {
          return const NetworkException.notFound();
        }
        return NetworkException(
          message ?? 'Something went wrong.',
          statusCode: statusCode,
        );

      default:
        return NetworkException(e.message ?? 'An unexpected error occurred.');
    }
  }

  String? _extractMessage(Response? response) {
    try {
      final data = response?.data;
      if (data is Map<String, dynamic>) {
        final msg = data['message'];
        if (msg is String) return msg;
        if (msg is List && msg.isNotEmpty) return msg.first as String?;
      }
    } catch (_) {}
    return null;
  }

  Future<bool> _tryRefreshToken() async {
    final refresh = await _storage.refreshToken;
    if (refresh == null) return false;

    try {
      final response = await _dio.post(
        Endpoints.refreshToken,
        data: {'refreshToken': refresh},
      );
      final body = response.data;
      final data = (body is Map && body.containsKey('data'))
          ? body['data'] as Map<String, dynamic>
          : body as Map<String, dynamic>;

      final accessToken  = data['accessToken']  as String?;
      final refreshToken = data['refreshToken'] as String?;

      if (accessToken != null && refreshToken != null) {
        await _storage.saveTokens(
          accessToken: accessToken,
          refreshToken: refreshToken,
        );
        return true;
      }
    } catch (_) {}
    return false;
  }
}

// MARK: - Auth Header Interceptor (only injects Bearer token)

class _AuthHeaderInterceptor extends Interceptor {
  _AuthHeaderInterceptor(Dio dio);
  final _storage = SecureStorage.instance;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _storage.accessToken;
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}
