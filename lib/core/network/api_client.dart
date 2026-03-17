// api_client.dart
// Reziphay
//
// Author: Vugar Safarzada (@vugarsafarzada)

import 'dart:io';

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

  Future<void> deleteVoid(String path) async {
    try {
      await _dio.delete(path);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  /// Uploads a file as multipart/form-data. Returns the parsed response body.
  Future<Map<String, dynamic>> postMultipart(
    String path, {
    required File file,
    String fieldName = 'file',
  }) async {
    final formData = FormData.fromMap({
      fieldName: await MultipartFile.fromFile(
        file.path,
        filename: file.path.split('/').last,
      ),
    });
    try {
      final response = await _dio.post(path, data: formData);
      return _unwrap(response, (j) => j);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

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
      final status = e.response?.statusCode;
      final isRefreshPath =
          e.requestOptions.path.contains(Endpoints.refreshToken);

      // On 401 or 403 (some backends return 403 for expired/missing tokens),
      // attempt a single token refresh then retry.
      if ((status == 401 || status == 403) &&
          retryOnUnauthorized &&
          !isRefreshPath) {
        final refreshed = await _tryRefreshToken();
        if (refreshed) {
          return _execute(call, fromJson, retryOnUnauthorized: false);
        }
        // Refresh failed — session is dead
        await _storage.clearTokens();
        throw const NetworkException(
          'Session expired. Please log in again.',
          statusCode: 401,
        );
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
        if (statusCode == 403) {
          return NetworkException(
            message ?? 'Access denied.',
            statusCode: 403,
          );
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
      final raw = response?.data;
      // Direct JSON body: { "message": "...", ... }
      if (raw is Map<String, dynamic>) {
        final msg = raw['message'];
        if (msg is String && msg.isNotEmpty) return msg;
        if (msg is List && msg.isNotEmpty) return msg.first as String?;
        // Some backends wrap in { "error": { "message": "..." } }
        final err = raw['error'];
        if (err is Map) {
          final m = err['message'];
          if (m is String && m.isNotEmpty) return m;
        }
        if (err is String && err.isNotEmpty) return err;
      }
      // Body is a plain string (rare but possible)
      if (raw is String && raw.isNotEmpty && raw.length < 200) return raw;
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
      // Unwrap top-level { data: { ... } } envelope if present
      final payload = (body is Map<String, dynamic> && body.containsKey('data'))
          ? body['data'] as Map<String, dynamic>
          : body as Map<String, dynamic>;

      // Tokens are nested under 'tokens' key: { tokens: { accessToken, refreshToken } }
      final tokensMap = payload['tokens'] as Map<String, dynamic>?;
      final accessToken  = tokensMap?['accessToken']  as String?;
      final refreshToken = tokensMap?['refreshToken'] as String?;

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
