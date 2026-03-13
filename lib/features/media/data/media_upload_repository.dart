import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reziphay_mobile/core/network/api_client.dart';
import 'package:reziphay_mobile/core/network/app_exception.dart';
import 'package:reziphay_mobile/features/media/models/app_media_asset.dart';

final mediaUploadRepositoryProvider = Provider<MediaUploadRepository>(
  (ref) =>
      BackendMediaUploadRepository(apiClient: ref.watch(apiClientProvider)),
);

abstract class MediaUploadRepository {
  Future<AppMediaAsset?> uploadOptionalImage(
    AppMediaAsset? asset, {
    required String purpose,
  });

  Future<List<AppMediaAsset>> uploadImages(
    List<AppMediaAsset> assets, {
    required String purpose,
  });
}

class BackendMediaUploadRepository implements MediaUploadRepository {
  BackendMediaUploadRepository({required ApiClient apiClient})
    : _apiClient = apiClient;

  final ApiClient _apiClient;

  static const _endpointCandidates = [
    '/uploads/media',
    '/uploads/images',
    '/media/upload',
    '/files/upload',
  ];

  @override
  Future<AppMediaAsset?> uploadOptionalImage(
    AppMediaAsset? asset, {
    required String purpose,
  }) async {
    if (asset == null) {
      return null;
    }

    return _uploadAsset(asset, purpose: purpose);
  }

  @override
  Future<List<AppMediaAsset>> uploadImages(
    List<AppMediaAsset> assets, {
    required String purpose,
  }) {
    return Future.wait(
      assets.map((asset) => _uploadAsset(asset, purpose: purpose)),
    );
  }

  Future<AppMediaAsset> _uploadAsset(
    AppMediaAsset asset, {
    required String purpose,
  }) async {
    if (!asset.hasBytes) {
      return asset;
    }

    final errors = <AppException>[];
    for (final endpoint in _endpointCandidates) {
      try {
        final payload = await _apiClient.post<dynamic>(
          endpoint,
          data: FormData.fromMap({
            'file': MultipartFile.fromBytes(
              asset.bytes!,
              filename: _filenameFor(asset),
            ),
            'purpose': purpose,
            'category': purpose,
            'label': asset.label,
            'contentType': 'image',
          }),
          headers: const {'Content-Type': 'multipart/form-data'},
          mapper: (data) => data,
        );
        return _parseUploadedAsset(payload, fallbackLabel: asset.label);
      } on AppException catch (error) {
        if (_shouldTryNextEndpoint(error)) {
          errors.add(error);
          continue;
        }
        rethrow;
      }
    }

    final lastError = errors.isEmpty ? null : errors.last;
    throw AppException(
      'Media upload is unavailable right now.',
      type: AppExceptionType.server,
      statusCode: lastError?.statusCode,
      code: lastError?.code,
      details: lastError?.details,
      requestId: lastError?.requestId,
    );
  }

  AppMediaAsset _parseUploadedAsset(
    dynamic payload, {
    required String fallbackLabel,
  }) {
    final entity = _extractEntity(payload, ['media', 'file', 'item', 'upload']);
    final id =
        _readString(entity, ['id', 'fileId', 'mediaId', 'key']) ??
        _readString(entity, ['url', 'publicUrl', 'downloadUrl', 'cdnUrl']);
    if (id == null || id.isEmpty) {
      throw const AppException(
        'The upload finished, but the server response was incomplete.',
        type: AppExceptionType.server,
      );
    }

    final label =
        _readString(entity, ['label', 'name', 'fileName']) ?? fallbackLabel;
    final remoteUrl = _readString(entity, [
      'url',
      'publicUrl',
      'downloadUrl',
      'cdnUrl',
    ]);

    if (remoteUrl != null && remoteUrl.isNotEmpty) {
      return AppMediaAsset.uploaded(id: id, label: label, remoteUrl: remoteUrl);
    }

    return AppMediaAsset.generated(id: id, label: label);
  }

  bool _shouldTryNextEndpoint(AppException error) {
    return switch (error.statusCode) {
      404 || 405 || 415 || 501 => true,
      _ => false,
    };
  }

  JsonMap _extractEntity(dynamic payload, List<String> keys) {
    if (payload is Map) {
      final map = asJsonMap(payload);
      for (final key in keys) {
        final value = _readPath(map, key);
        if (value is Map) {
          return asJsonMap(value);
        }
      }
      return map;
    }

    throw const AppException(
      'Unexpected upload payload returned by the server.',
      type: AppExceptionType.server,
    );
  }

  String? _readString(JsonMap source, List<String> keys) {
    for (final key in keys) {
      final value = _readPath(source, key);
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return null;
  }

  dynamic _readPath(dynamic source, String path) {
    final segments = path.split('.');
    dynamic current = source;
    for (final segment in segments) {
      if (current is Map) {
        current = current[segment];
      } else {
        return null;
      }
    }
    return current;
  }

  String _filenameFor(AppMediaAsset asset) {
    final base = asset.label
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    if (base.isEmpty) {
      return 'upload.jpg';
    }
    return '$base.jpg';
  }
}
