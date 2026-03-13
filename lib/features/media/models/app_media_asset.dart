import 'dart:typed_data';

enum AppMediaSource { generated, pickedImage, uploaded }

class AppMediaAsset {
  const AppMediaAsset({
    required this.id,
    required this.label,
    required this.source,
    this.bytes,
    this.remoteUrl,
  });

  const AppMediaAsset.generated({
    required this.id,
    required this.label,
    this.remoteUrl,
  }) : source = AppMediaSource.generated,
       bytes = null;

  const AppMediaAsset.uploaded({
    required this.id,
    required this.label,
    required this.remoteUrl,
  }) : source = AppMediaSource.uploaded,
       bytes = null;

  final String id;
  final String label;
  final AppMediaSource source;
  final Uint8List? bytes;
  final String? remoteUrl;

  bool get hasBytes => bytes != null && bytes!.isNotEmpty;
  bool get hasRemoteUrl => remoteUrl != null && remoteUrl!.isNotEmpty;

  AppMediaAsset copyWith({
    String? id,
    String? label,
    AppMediaSource? source,
    Object? bytes = _sentinel,
    Object? remoteUrl = _sentinel,
  }) {
    return AppMediaAsset(
      id: id ?? this.id,
      label: label ?? this.label,
      source: source ?? this.source,
      bytes: identical(bytes, _sentinel) ? this.bytes : bytes as Uint8List?,
      remoteUrl: identical(remoteUrl, _sentinel)
          ? this.remoteUrl
          : remoteUrl as String?,
    );
  }
}

const _sentinel = Object();
