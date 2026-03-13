import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:reziphay_mobile/app/config/deep_link_config.dart';
import 'package:reziphay_mobile/devops/app_links_manifest_builder.dart';

void main() {
  group('app links manifest builder', () {
    test('buildAppleAppSiteAssociation uses the shared app id and paths', () {
      final content = buildAppleAppSiteAssociation();
      final parsed = jsonDecode(content) as Map<String, dynamic>;
      final details =
          (parsed['applinks'] as Map<String, dynamic>)['details']
              as List<dynamic>;
      final firstDetail = details.first as Map<String, dynamic>;

      expect(firstDetail['appID'], iOSAssociatedAppId);
      expect(firstDetail['paths'], appLinkPathPatterns);
    });

    test('buildAssetLinks writes the package and supplied fingerprints', () {
      const fingerprint =
          '12:34:56:78:90:AB:CD:EF:12:34:56:78:90:AB:CD:EF:12:34:56:78:90:AB:CD:EF:12:34:56:78:90:AB:CD:EF';
      final content = buildAssetLinks(sha256Fingerprints: [fingerprint]);
      final parsed = jsonDecode(content) as List<dynamic>;
      final target =
          (parsed.first as Map<String, dynamic>)['target']
              as Map<String, dynamic>;

      expect(target['package_name'], androidApplicationId);
      expect(target['sha256_cert_fingerprints'], [fingerprint]);
    });

    test('containsPlaceholderFingerprint detects unfinished asset links', () {
      final content = buildAssetLinks(
        sha256Fingerprints: [androidAssetLinksFingerprintPlaceholder],
      );

      expect(containsPlaceholderFingerprint(content), isTrue);
    });
  });
}
