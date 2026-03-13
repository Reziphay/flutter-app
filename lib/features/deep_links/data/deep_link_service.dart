import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final deepLinkServiceProvider = Provider<DeepLinkService>((ref) {
  final service = AppLinksDeepLinkService();
  ref.onDispose(() {
    unawaited(service.dispose());
  });
  return service;
});

abstract class DeepLinkService {
  Future<void> initialize();

  Future<Uri?> getInitialUri();

  Stream<Uri> get uriStream;

  Future<void> dispose();
}

class AppLinksDeepLinkService implements DeepLinkService {
  AppLinksDeepLinkService({AppLinks? appLinks})
    : _appLinks = appLinks ?? AppLinks();

  final AppLinks _appLinks;

  @override
  Stream<Uri> get uriStream => _appLinks.uriLinkStream;

  @override
  Future<Uri?> getInitialUri() => _appLinks.getInitialLink();

  @override
  Future<void> initialize() async {}

  @override
  Future<void> dispose() async {}
}
