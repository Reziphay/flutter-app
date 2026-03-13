import 'dart:io';

import 'package:reziphay_mobile/app/config/deep_link_config.dart';
import 'package:reziphay_mobile/devops/android_signing_inspector.dart';
import 'package:reziphay_mobile/devops/app_links_manifest_builder.dart';

Future<void> main(List<String> args) async {
  final outputDirectory =
      _readArg(args, '--output-dir') ?? 'deployment/app-links/.well-known';
  final fingerprints = await _resolveFingerprints(args);

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

Future<List<String>> _resolveFingerprints(List<String> args) async {
  final fingerprintArgument = _readArg(args, '--android-sha256');
  if (fingerprintArgument != null && fingerprintArgument.isNotEmpty) {
    return fingerprintArgument
        .split(',')
        .map((value) => value.trim().toUpperCase())
        .where((value) => value.isNotEmpty)
        .toList(growable: false);
  }

  final keystorePath = _readArg(args, '--android-keystore');
  if (keystorePath != null && keystorePath.isNotEmpty) {
    final alias = _readArg(args, '--android-alias');
    if (alias == null || alias.isEmpty) {
      stderr.writeln(
        'Pass --android-alias when using --android-keystore to derive '
        'the asset-links fingerprint.',
      );
      exitCode = 64;
      exit(64);
    }

    final fingerprints = await _fingerprintsFromKeytool(
      keystorePath: keystorePath,
      alias: alias,
      storePassword: _readArg(args, '--android-storepass'),
      keyPassword: _readArg(args, '--android-keypass'),
      keytoolPath: _readArg(args, '--keytool') ?? 'keytool',
    );

    if (fingerprints.isEmpty) {
      stderr.writeln(
        'Could not extract an SHA-256 fingerprint from the provided keystore.',
      );
      exitCode = 1;
      exit(1);
    }

    return fingerprints.toList(growable: false);
  }

  return <String>[androidAssetLinksFingerprintPlaceholder];
}

Future<Set<String>> _fingerprintsFromKeytool({
  required String keystorePath,
  required String alias,
  String? storePassword,
  String? keyPassword,
  required String keytoolPath,
}) async {
  final arguments = <String>[
    '-list',
    '-v',
    '-keystore',
    keystorePath,
    '-alias',
    alias,
  ];

  if (storePassword != null && storePassword.isNotEmpty) {
    arguments.addAll(<String>['-storepass', storePassword]);
  }
  if (keyPassword != null && keyPassword.isNotEmpty) {
    arguments.addAll(<String>['-keypass', keyPassword]);
  }

  final result = await Process.run(keytoolPath, arguments);
  if (result.exitCode != 0) {
    stderr.writeln(result.stderr.toString().trim());
    exitCode = result.exitCode;
    exit(result.exitCode);
  }

  return extractSha256Fingerprints(result.stdout.toString());
}

String? _readArg(List<String> args, String name) {
  for (final argument in args) {
    if (argument.startsWith('$name=')) {
      return argument.substring(name.length + 1);
    }
  }
  return null;
}
