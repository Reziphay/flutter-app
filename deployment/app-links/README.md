# App Links Deployment

Serve the files in this directory from both of these HTTPS hosts:

- `https://reziphay.com/.well-known/`
- `https://staging.reziphay.com/.well-known/`

Files:

- `apple-app-site-association`
- `assetlinks.json`

Before publishing `assetlinks.json`, replace `REPLACE_WITH_RELEASE_SHA256_CERT_FINGERPRINT` with the SHA-256 fingerprint from the Android signing certificate that will ship the app.

These files match the current mobile identifiers:

- iOS team ID: `297PWJKRJP`
- iOS bundle ID: `com.reziphay.mobile`
- Android package name: `com.reziphay.mobile`

The mobile app is configured to accept these HTTPS paths:

- `/auth/*`
- `/welcome*`
- `/notifications*`
- `/services/*`
- `/brands/*`
- `/providers/*`
- `/categories/*`

Refresh the checked-in files from the mobile package root with:

```bash
dart run tool/sync_app_links_files.dart --android-sha256=AA:BB:CC:DD
```

Run the local setup check with:

```bash
dart run tool/release_preflight.dart
```
