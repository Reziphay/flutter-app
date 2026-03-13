import 'package:flutter_test/flutter_test.dart';
import 'package:reziphay_mobile/core/network/app_exception.dart';
import 'package:reziphay_mobile/features/maps/data/maps_repository.dart';
import 'package:reziphay_mobile/features/maps/models/map_destination.dart';

void main() {
  group('ExternalMapsRepository', () {
    test('buildPreviewUri encodes the destination query', () {
      final repository = ExternalMapsRepository(launcher: _FakeMapsLauncher());

      final uri = repository.buildPreviewUri(
        const MapDestination(
          title: 'Studio North',
          subtitle: 'Rauf Mammadov',
          addressLine: '28 Nizami St, Baku',
        ),
      );

      expect(uri.host, 'www.google.com');
      expect(uri.path, '/maps/search/');
      expect(uri.queryParameters['api'], '1');
      expect(
        uri.queryParameters['query'],
        'Studio North, Rauf Mammadov, 28 Nizami St, Baku',
      );
    });

    test('openDirections launches a directions URI', () async {
      final launcher = _FakeMapsLauncher();
      final repository = ExternalMapsRepository(launcher: launcher);
      const destination = MapDestination(
        title: 'Classic haircut',
        subtitle: 'Studio North',
        addressLine: '28 Nizami St, Baku',
      );

      await repository.openDirections(destination);

      expect(launcher.launchedUris, hasLength(1));
      expect(launcher.launchedUris.single.path, '/maps/dir/');
      expect(
        launcher.launchedUris.single.queryParameters['destination'],
        'Classic haircut, Studio North, 28 Nizami St, Baku',
      );
    });

    test('openPreview throws when the launcher fails', () async {
      final repository = ExternalMapsRepository(
        launcher: _FakeMapsLauncher(result: false),
      );

      expect(
        () => repository.openPreview(
          const MapDestination(
            title: 'Luna Dental',
            addressLine: '7 Fountain Sq, Baku',
          ),
        ),
        throwsA(isA<AppException>()),
      );
    });
  });
}

class _FakeMapsLauncher implements MapsLauncher {
  _FakeMapsLauncher({this.result = true});

  final bool result;
  final List<Uri> launchedUris = [];

  @override
  Future<bool> launchExternal(Uri uri) async {
    launchedUris.add(uri);
    return result;
  }
}
