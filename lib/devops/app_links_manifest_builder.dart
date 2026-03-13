import 'dart:convert';

import 'package:reziphay_mobile/app/config/deep_link_config.dart';

String buildAppleAppSiteAssociation({
  String? appId,
  List<String> paths = appLinkPathPatterns,
}) {
  return const JsonEncoder.withIndent('  ').convert({
    'applinks': {
      'apps': <String>[],
      'details': <Map<String, Object>>[
        {'appID': appId ?? iOSAssociatedAppId, 'paths': paths},
      ],
    },
  });
}

String buildAssetLinks({
  String packageName = androidApplicationId,
  required Iterable<String> sha256Fingerprints,
}) {
  return const JsonEncoder.withIndent('  ').convert([
    {
      'relation': <String>['delegate_permission/common.handle_all_urls'],
      'target': {
        'namespace': 'android_app',
        'package_name': packageName,
        'sha256_cert_fingerprints': sha256Fingerprints.toList(growable: false),
      },
    },
  ]);
}

bool containsPlaceholderFingerprint(String content) {
  return content.contains(androidAssetLinksFingerprintPlaceholder);
}
