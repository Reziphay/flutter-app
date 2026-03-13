import 'package:flutter_test/flutter_test.dart';
import 'package:reziphay_mobile/devops/firebase_config_inspector.dart';

void main() {
  group('firebase config inspector', () {
    test('extractIosFirebaseBundleId reads the bundle id from plist XML', () {
      const plist = '''
<?xml version="1.0" encoding="UTF-8"?>
<plist version="1.0">
<dict>
  <key>BUNDLE_ID</key>
  <string>com.reziphay.mobile</string>
</dict>
</plist>
''';

      expect(extractIosFirebaseBundleId(plist), 'com.reziphay.mobile');
    });

    test('extractAndroidFirebasePackageNames reads client package names', () {
      const json = '''
{
  "client": [
    {
      "client_info": {
        "android_client_info": {
          "package_name": "com.reziphay.mobile"
        }
      }
    },
    {
      "client_info": {
        "android_client_info": {
          "package_name": "com.reziphay.mobile.debug"
        }
      }
    }
  ]
}
''';

      expect(
        extractAndroidFirebasePackageNames(json),
        containsAll(<String>[
          'com.reziphay.mobile',
          'com.reziphay.mobile.debug',
        ]),
      );
    });
  });
}
