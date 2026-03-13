enum AppExceptionType {
  network,
  timeout,
  unauthorized,
  validation,
  forbidden,
  conflict,
  server,
  unknown,
}

class AppException implements Exception {
  const AppException(
    this.message, {
    this.type = AppExceptionType.unknown,
    this.code,
    this.statusCode,
    this.details,
    this.requestId,
  });

  final String message;
  final AppExceptionType type;
  final String? code;
  final int? statusCode;
  final Object? details;
  final String? requestId;

  bool get isUnauthorized => type == AppExceptionType.unauthorized;

  @override
  String toString() => 'AppException: $message';
}
