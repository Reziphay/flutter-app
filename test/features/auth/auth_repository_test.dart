import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reziphay_mobile/core/auth/auth_repository.dart';
import 'package:reziphay_mobile/core/network/api_client.dart';
import 'package:reziphay_mobile/core/network/app_exception.dart';
import 'package:reziphay_mobile/features/auth/models/email_link_result_status.dart';

void main() {
  group('BackendAuthRepository', () {
    test('verifyEmailMagicLink maps backend success payload', () async {
      final repository = BackendAuthRepository(
        publicApiClient: _FakeAuthApiClient(
          onPost: ({required path, data}) {
            expect(path, '/auth/verify-email-magic-link');
            expect(data, {'token': 'abc123'});
            return {'status': 'VERIFIED'};
          },
        ),
        apiClient: _FakeAuthApiClient(),
      );

      final status = await repository.verifyEmailMagicLink(
        Uri.parse('reziphay://auth/verify-email-magic-link?token=abc123'),
      );

      expect(status, EmailLinkResultStatus.success);
    });

    test('verifyEmailMagicLink maps backend expiry errors', () async {
      final repository = BackendAuthRepository(
        publicApiClient: _FakeAuthApiClient(
          onPost: ({required path, data}) {
            throw const AppException(
              'Link expired.',
              type: AppExceptionType.server,
              statusCode: 410,
            );
          },
        ),
        apiClient: _FakeAuthApiClient(),
      );

      final status = await repository.verifyEmailMagicLink(
        Uri.parse('reziphay://auth/verify-email-magic-link?token=expired'),
      );

      expect(status, EmailLinkResultStatus.expired);
    });
  });
}

class _FakeAuthApiClient extends ApiClient {
  _FakeAuthApiClient({this.onPost}) : super(Dio());

  final dynamic Function({required String path, Object? data})? onPost;

  @override
  Future<T> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? extra,
    required T Function(dynamic data) mapper,
  }) async {
    return mapper(onPost?.call(path: path, data: data) ?? <String, dynamic>{});
  }
}
