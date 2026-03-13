import 'dart:convert';
import 'dart:io';

import 'package:reziphay_mobile/app/config/deep_link_config.dart';
import 'package:reziphay_mobile/devops/app_links_manifest_builder.dart';
import 'package:reziphay_mobile/devops/firebase_config_inspector.dart';

Future<void> main() async {
  final checks = <_CheckResult>[
    await _checkIosFirebaseConfig(),
    await _checkAndroidFirebaseConfig(),
    await _checkAppleAssociationFile(),
    await _checkAndroidAssetLinksFile(),
  ];

  stdout.writeln('Reziphay mobile release preflight');
  for (final check in checks) {
    stdout.writeln('${check.level.label} ${check.title}: ${check.message}');
  }

  stdout.writeln(
    'MANUAL Publish the .well-known files to https://reziphay.com and '
    'https://staging.reziphay.com before enabling production HTTPS app links.',
  );

  if (checks.any((check) => check.level == _CheckLevel.fail)) {
    exitCode = 1;
  }
}

Future<_CheckResult> _checkIosFirebaseConfig() async {
  final file = File('ios/Runner/GoogleService-Info.plist');
  if (!await file.exists()) {
    return _CheckResult.fail(
      'iOS Firebase config',
      'Missing ${file.path}. Add the real Firebase plist for '
          '$iOSBundleId with tool/install_firebase_configs.dart.',
    );
  }

  final content = await file.readAsString();
  final bundleId = extractIosFirebaseBundleId(content);
  if (bundleId != iOSBundleId) {
    return _CheckResult.fail(
      'iOS Firebase config',
      'Expected bundle ID $iOSBundleId but found ${bundleId ?? 'none'}.',
    );
  }

  return _CheckResult.pass(
    'iOS Firebase config',
    'Found ${file.path} with bundle ID $bundleId.',
  );
}

Future<_CheckResult> _checkAndroidFirebaseConfig() async {
  final file = File('android/app/google-services.json');
  if (!await file.exists()) {
    return _CheckResult.fail(
      'Android Firebase config',
      'Missing ${file.path}. Add the real Firebase config for '
          '$androidApplicationId with tool/install_firebase_configs.dart.',
    );
  }

  final content = await file.readAsString();
  final packageNames = extractAndroidFirebasePackageNames(content);

  if (!packageNames.contains(androidApplicationId)) {
    final found = packageNames.isEmpty ? 'none' : packageNames.join(', ');
    return _CheckResult.fail(
      'Android Firebase config',
      'Expected package $androidApplicationId but found $found.',
    );
  }

  return _CheckResult.pass(
    'Android Firebase config',
    'Found ${file.path} with package $androidApplicationId.',
  );
}

Future<_CheckResult> _checkAppleAssociationFile() async {
  final file = File(
    'deployment/app-links/.well-known/apple-app-site-association',
  );
  if (!await file.exists()) {
    return _CheckResult.fail('Apple association file', 'Missing ${file.path}.');
  }

  final content = await file.readAsString();
  final parsed = jsonDecode(content);
  if (parsed is! Map<String, dynamic>) {
    return _CheckResult.fail(
      'Apple association file',
      '${file.path} is not a valid JSON object.',
    );
  }

  final details =
      ((parsed['applinks'] as Map<String, dynamic>?)?['details']
                  as List<dynamic>? ??
              const <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .toList(growable: false);

  final appIds = details
      .map((detail) => detail['appID'] as String?)
      .whereType<String>()
      .toSet();

  if (!appIds.contains(iOSAssociatedAppId)) {
    return _CheckResult.fail(
      'Apple association file',
      'Expected app ID $iOSAssociatedAppId in ${file.path}.',
    );
  }

  return _CheckResult.pass(
    'Apple association file',
    'Found ${file.path} with app ID $iOSAssociatedAppId.',
  );
}

Future<_CheckResult> _checkAndroidAssetLinksFile() async {
  final file = File('deployment/app-links/.well-known/assetlinks.json');
  if (!await file.exists()) {
    return _CheckResult.fail('Android asset links', 'Missing ${file.path}.');
  }

  final content = await file.readAsString();
  final parsed = jsonDecode(content);
  if (parsed is! List<dynamic>) {
    return _CheckResult.fail(
      'Android asset links',
      '${file.path} is not a valid JSON array.',
    );
  }

  final packageNames = parsed
      .whereType<Map<String, dynamic>>()
      .map(
        (entry) =>
            (entry['target'] as Map<String, dynamic>?)?['package_name']
                as String?,
      )
      .whereType<String>()
      .toSet();

  if (!packageNames.contains(androidApplicationId)) {
    return _CheckResult.fail(
      'Android asset links',
      'Expected package $androidApplicationId in ${file.path}.',
    );
  }

  if (containsPlaceholderFingerprint(content)) {
    return _CheckResult.fail(
      'Android asset links',
      'Replace the placeholder fingerprint in ${file.path} before release.',
    );
  }

  return _CheckResult.pass(
    'Android asset links',
    'Found ${file.path} with package $androidApplicationId.',
  );
}

enum _CheckLevel {
  pass('PASS'),
  fail('FAIL');

  const _CheckLevel(this.label);

  final String label;
}

class _CheckResult {
  const _CheckResult(this.level, this.title, this.message);

  const _CheckResult.pass(this.title, this.message) : level = _CheckLevel.pass;

  const _CheckResult.fail(this.title, this.message) : level = _CheckLevel.fail;

  final _CheckLevel level;
  final String title;
  final String message;
}
