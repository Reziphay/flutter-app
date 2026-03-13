import 'dart:typed_data';

enum AppMediaSource { generated, pickedImage }

class AppMediaAsset {
  const AppMediaAsset({
    required this.id,
    required this.label,
    required this.source,
    this.bytes,
  });

  const AppMediaAsset.generated({required this.id, required this.label})
    : source = AppMediaSource.generated,
      bytes = null;

  final String id;
  final String label;
  final AppMediaSource source;
  final Uint8List? bytes;

  bool get hasBytes => bytes != null && bytes!.isNotEmpty;

  AppMediaAsset copyWith({
    String? id,
    String? label,
    AppMediaSource? source,
    Object? bytes = _sentinel,
  }) {
    return AppMediaAsset(
      id: id ?? this.id,
      label: label ?? this.label,
      source: source ?? this.source,
      bytes: identical(bytes, _sentinel) ? this.bytes : bytes as Uint8List?,
    );
  }
}

const _sentinel = Object();
