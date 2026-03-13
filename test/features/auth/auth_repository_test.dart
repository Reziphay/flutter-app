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
          onGet: ({required path, queryParameters}) {
            expect(path, '/auth/verify-email-magic-link');
            expect(queryParameters?['token'], 'abc123');
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
          onGet: ({required path, queryParameters}) {
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
  _FakeAuthApiClient({this.onGet}) : super(Dio());

  final dynamic Function({
    required String path,
    Map<String, dynamic>? queryParameters,
  })?
  onGet;

  @override
  Future<T> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? extra,
    required T Function(dynamic data) mapper,
  }) async {
    return mapper(
      onGet?.call(path: path, queryParameters: queryParameters) ??
          <String, dynamic>{},
    );
  }
}
