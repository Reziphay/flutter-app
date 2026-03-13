import 'package:flutter_test/flutter_test.dart';
import 'package:reziphay_mobile/devops/android_signing_inspector.dart';

void main() {
  group('android signing inspector', () {
    test('extractSha256Fingerprints normalizes SHA-256 lines from keytool', () {
      const output = '''
Alias name: reziphay-release
Certificate fingerprints:
         SHA1: 11:22:33
         SHA256: aa:bb:cc:dd:ee:ff:00:11:22:33:44:55:66:77:88:99:AA:BB:CC:DD:EE:FF:00:11:22:33:44:55:66:77:88:99
Signature algorithm name: SHA256withRSA
''';

      expect(extractSha256Fingerprints(output), <String>{
        'AA:BB:CC:DD:EE:FF:00:11:22:33:44:55:66:77:88:99:AA:BB:CC:DD:EE:FF:00:11:22:33:44:55:66:77:88:99',
      });
    });
  });
}
