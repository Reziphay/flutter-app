// network_exception.dart
// Reziphay
//
// Author: Vugar Safarzada (@vugarsafarzada)

class NetworkException implements Exception {
  const NetworkException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  // Named constructors for common cases
  const NetworkException.unauthorized()
      : message = 'Your session has expired. Please log in again.',
        statusCode = 401;

  const NetworkException.notFound()
      : message = 'Resource not found.',
        statusCode = 404;

  const NetworkException.noInternet()
      : message = 'No internet connection. Please check your network settings.',
        statusCode = null;

  const NetworkException.timeout()
      : message = 'Request timed out. Please try again.',
        statusCode = null;

  bool get isUnauthorized  => statusCode == 401;
  bool get isNotFound      => statusCode == 404;
  bool get isServerError   => statusCode != null && statusCode! >= 500;

  @override
  String toString() => message;
}
