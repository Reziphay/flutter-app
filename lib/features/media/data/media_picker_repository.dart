import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:reziphay_mobile/features/media/models/app_media_asset.dart';

final mediaPickerRepositoryProvider = Provider<MediaPickerRepository>(
  (ref) => ImagePickerMediaRepository(),
);

abstract class MediaPickerRepository {
  Future<AppMediaAsset?> pickSingleImage();

  Future<List<AppMediaAsset>> pickMultipleImages({int limit = 6});
}

class ImagePickerMediaRepository implements MediaPickerRepository {
  ImagePickerMediaRepository({ImagePicker? picker})
    : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  static int _seed = 0;

  @override
  Future<List<AppMediaAsset>> pickMultipleImages({int limit = 6}) async {
    final images = await _picker.pickMultiImage(imageQuality: 88);
    if (images.isEmpty) {
      return const [];
    }

    return Future.wait(images.take(limit).map(_assetFromFile));
  }

  @override
  Future<AppMediaAsset?> pickSingleImage() async {
    final image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 88,
    );
    if (image == null) {
      return null;
    }

    return _assetFromFile(image);
  }

  Future<AppMediaAsset> _assetFromFile(XFile file) async {
    final bytes = await file.readAsBytes();
    return AppMediaAsset(
      id: 'media_${DateTime.now().microsecondsSinceEpoch}_${_seed++}',
      label: _labelFromName(file.name),
      source: AppMediaSource.pickedImage,
      bytes: bytes,
    );
  }

  String _labelFromName(String name) {
    final withoutExtension = name.replaceFirst(RegExp(r'\.[^.]+$'), '');
    final normalized = withoutExtension
        .replaceAll(RegExp(r'[_-]+'), ' ')
        .trim();
    if (normalized.isEmpty) {
      return 'Picked image';
    }

    return normalized
        .split(RegExp(r'\s+'))
        .map((part) {
          if (part.isEmpty) {
            return part;
          }
          return '${part[0].toUpperCase()}${part.substring(1)}';
        })
        .join(' ');
  }
}
