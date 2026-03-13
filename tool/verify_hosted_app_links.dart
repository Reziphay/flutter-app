import 'dart:convert';
import 'dart:io';

import 'package:reziphay_mobile/app/config/deep_link_config.dart';

Future<void> main() async {
  final localAppleFile = File(
    'deployment/app-links/.well-known/apple-app-site-association',
  );
  final localAssetLinksFile = File(
    'deployment/app-links/.well-known/assetlinks.json',
  );

  final localApple = jsonDecode(await localAppleFile.readAsString());
  final localAssetLinks = jsonDecode(await localAssetLinksFile.readAsString());

  final client = HttpClient();
  var hasFailure = false;

  try {
    for (final host in appLinkHosts) {
      final appleResult = await _fetchAndCompare(
        client: client,
        uri: Uri.https(host, '/.well-known/apple-app-site-association'),
        expected: localApple,
      );
      stdout.writeln(appleResult.message);
      hasFailure = hasFailure || !appleResult.ok;

      final assetLinksResult = await _fetchAndCompare(
        client: client,
        uri: Uri.https(host, '/.well-known/assetlinks.json'),
        expected: localAssetLinks,
      );
      stdout.writeln(assetLinksResult.message);
      hasFailure = hasFailure || !assetLinksResult.ok;
    }
  } finally {
    client.close(force: true);
  }

  if (hasFailure) {
    exitCode = 1;
  }
}

Future<_RemoteCheckResult> _fetchAndCompare({
  required HttpClient client,
  required Uri uri,
  required Object? expected,
}) async {
  try {
    final request = await client.getUrl(uri);
    request.headers.set(HttpHeaders.acceptHeader, 'application/json');
    final response = await request.close();
    final body = await utf8.decodeStream(response);

    if (response.statusCode != HttpStatus.ok) {
      return _RemoteCheckResult(
        ok: false,
        message: 'FAIL ${uri.toString()} returned HTTP ${response.statusCode}.',
      );
    }

    final remote = jsonDecode(body);
    if (!_jsonEquals(expected, remote)) {
      return _RemoteCheckResult(
        ok: false,
        message:
            'FAIL ${uri.toString()} does not match the local deployment manifest.',
      );
    }

    return _RemoteCheckResult(
      ok: true,
      message: 'PASS ${uri.toString()} matches the local deployment manifest.',
    );
  } catch (error) {
    return _RemoteCheckResult(
      ok: false,
      message: 'FAIL ${uri.toString()} could not be verified: $error',
    );
  }
}

bool _jsonEquals(Object? left, Object? right) {
  if (left.runtimeType != right.runtimeType) {
    return false;
  }

  if (left is Map && right is Map) {
    if (left.length != right.length) {
      return false;
    }

    for (final key in left.keys) {
      if (!right.containsKey(key) || !_jsonEquals(left[key], right[key])) {
        return false;
      }
    }
    return true;
  }

  if (left is List && right is List) {
    if (left.length != right.length) {
      return false;
    }

    for (var index = 0; index < left.length; index += 1) {
      if (!_jsonEquals(left[index], right[index])) {
        return false;
      }
    }
    return true;
  }

  return left == right;
}

class _RemoteCheckResult {
  const _RemoteCheckResult({required this.ok, required this.message});

  final bool ok;
  final String message;
}
