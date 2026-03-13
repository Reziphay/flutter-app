import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reziphay_mobile/core/network/app_exception.dart';
import 'package:reziphay_mobile/features/maps/models/map_destination.dart';
import 'package:url_launcher/url_launcher.dart';

final mapsRepositoryProvider = Provider<MapsRepository>(
  (ref) => ExternalMapsRepository(launcher: const UrlLauncherMapsLauncher()),
);

abstract class MapsRepository {
  Uri buildPreviewUri(MapDestination destination);

  Uri buildDirectionsUri(MapDestination destination);

  Future<void> openPreview(MapDestination destination);

  Future<void> openDirections(MapDestination destination);
}

abstract class MapsLauncher {
  Future<bool> launchExternal(Uri uri);
}

class UrlLauncherMapsLauncher implements MapsLauncher {
  const UrlLauncherMapsLauncher();

  @override
  Future<bool> launchExternal(Uri uri) {
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

class ExternalMapsRepository implements MapsRepository {
  ExternalMapsRepository({required MapsLauncher launcher})
    : _launcher = launcher;

  final MapsLauncher _launcher;

  @override
  Uri buildDirectionsUri(MapDestination destination) {
    return Uri.https('www.google.com', '/maps/dir/', {
      'api': '1',
      'destination': destination.searchQuery,
    });
  }

  @override
  Uri buildPreviewUri(MapDestination destination) {
    return Uri.https('www.google.com', '/maps/search/', {
      'api': '1',
      'query': destination.searchQuery,
    });
  }

  @override
  Future<void> openDirections(MapDestination destination) async {
    await _open(buildDirectionsUri(destination));
  }

  @override
  Future<void> openPreview(MapDestination destination) async {
    await _open(buildPreviewUri(destination));
  }

  Future<void> _open(Uri uri) async {
    final opened = await _launcher.launchExternal(uri);
    if (!opened) {
      throw const AppException('Could not open maps right now.');
    }
  }
}
