import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reziphay_mobile/core/network/api_client.dart';
import 'package:reziphay_mobile/core/network/app_exception.dart';
import 'package:reziphay_mobile/features/media/data/media_upload_repository.dart';
import 'package:reziphay_mobile/features/media/models/app_media_asset.dart';

void main() {
  group('BackendMediaUploadRepository', () {
    test(
      'uploadImages uploads picked assets and preserves generated ones',
      () async {
        Object? capturedData;
        final repository = BackendMediaUploadRepository(
          apiClient: _FakeMediaApiClient(
            onPost: ({required path, data, queryParameters}) {
              capturedData = data;
              return {
                'media': {
                  'id': 'media_uploaded_1',
                  'label': 'Premium Chair',
                  'url': 'https://cdn.reziphay.test/premium-chair.jpg',
                },
              };
            },
          ),
        );

        final uploaded = await repository.uploadImages([
          AppMediaAsset(
            id: 'picked_1',
            label: 'Premium Chair',
            source: AppMediaSource.pickedImage,
            bytes: Uint8List.fromList(const [1, 2, 3]),
          ),
          const AppMediaAsset.generated(
            id: 'existing_1',
            label: 'Existing visual',
          ),
        ], purpose: 'service_gallery');

        expect(capturedData, isA<FormData>());
        expect(uploaded.first.source, AppMediaSource.uploaded);
        expect(
          uploaded.first.remoteUrl,
          'https://cdn.reziphay.test/premium-chair.jpg',
        );
        expect(uploaded.first.bytes, isNull);
        expect(uploaded.last.id, 'existing_1');
      },
    );

    test('uploadOptionalImage tries fallback upload endpoints', () async {
      var attemptCount = 0;
      final repository = BackendMediaUploadRepository(
        apiClient: _FakeMediaApiClient(
          onPost: ({required path, data, queryParameters}) {
            attemptCount += 1;
            if (attemptCount == 1) {
              throw const AppException(
                'Not found',
                type: AppExceptionType.unknown,
                statusCode: 404,
              );
            }
            return {
              'file': {
                'id': 'logo_uploaded_1',
                'fileName': 'North Atelier',
                'publicUrl': 'https://cdn.reziphay.test/north-atelier.png',
              },
            };
          },
        ),
      );

      final uploaded = await repository.uploadOptionalImage(
        AppMediaAsset(
          id: 'logo_1',
          label: 'North Atelier',
          source: AppMediaSource.pickedImage,
          bytes: Uint8List.fromList(const [4, 5, 6]),
        ),
        purpose: 'brand_logo',
      );

      expect(attemptCount, 2);
      expect(uploaded, isNotNull);
      expect(uploaded!.source, AppMediaSource.uploaded);
      expect(uploaded.remoteUrl, 'https://cdn.reziphay.test/north-atelier.png');
    });
  });
}

class _FakeMediaApiClient extends ApiClient {
  _FakeMediaApiClient({this.onPost}) : super(Dio());

  final dynamic Function({
    required String path,
    Object? data,
    Map<String, dynamic>? queryParameters,
  })?
  onPost;

  @override
  Future<T> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? extra,
    required T Function(dynamic data) mapper,
  }) async {
    return mapper(
      onPost?.call(path: path, data: data, queryParameters: queryParameters) ??
          <String, dynamic>{},
    );
  }
}
