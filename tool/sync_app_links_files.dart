import 'dart:io';

import 'package:reziphay_mobile/app/config/deep_link_config.dart';
import 'package:reziphay_mobile/devops/app_links_manifest_builder.dart';

Future<void> main(List<String> args) async {
  final outputDirectory =
      _readArg(args, '--output-dir') ?? 'deployment/app-links/.well-known';
  final fingerprintArgument = _readArg(args, '--android-sha256');
  final fingerprints =
      fingerprintArgument == null || fingerprintArgument.isEmpty
      ? <String>[androidAssetLinksFingerprintPlaceholder]
      : fingerprintArgument
            .split(',')
            .map((value) => value.trim())
            .where((value) => value.isNotEmpty)
            .toList(growable: false);

  final directory = Directory(outputDirectory);
  await directory.create(recursive: true);

  final appleFile = File('${directory.path}/apple-app-site-association');
  await appleFile.writeAsString('${buildAppleAppSiteAssociation()}\n');

  final assetLinksFile = File('${directory.path}/assetlinks.json');
  await assetLinksFile.writeAsString(
    '${buildAssetLinks(sha256Fingerprints: fingerprints)}\n',
  );

  stdout.writeln('Wrote ${appleFile.path}');
  stdout.writeln('Wrote ${assetLinksFile.path}');
  if (fingerprints.contains(androidAssetLinksFingerprintPlaceholder)) {
    stdout.writeln(
      'Android fingerprint is still using the placeholder value. '
      'Pass --android-sha256=<SHA256[:...]> before production deploy.',
    );
  }
}

String? _readArg(List<String> args, String name) {
  for (final argument in args) {
    if (argument.startsWith('$name=')) {
      return argument.substring(name.length + 1);
    }
  }
  return null;
}
