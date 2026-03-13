# Firebase Native Config

The real native Firebase files are intentionally not committed.

Expected targets:

- `ios/Runner/GoogleService-Info.plist`
- `android/app/google-services.json`

Install them from local secure storage with:

```bash
dart run tool/install_firebase_configs.dart \
  --ios-plist=/absolute/path/to/GoogleService-Info.plist \
  --android-json=/absolute/path/to/google-services.json
```

Then verify the mobile package with:

```bash
dart run tool/release_preflight.dart
flutter analyze
flutter test
```

The installer refuses to copy files if the bundle/package IDs do not match:

- iOS bundle ID: `com.reziphay.mobile`
- Android package name: `com.reziphay.mobile`
