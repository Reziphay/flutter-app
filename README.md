# Reziphay Mobile

The current mobile app covers:

- app bootstrap and environment config
- token-based light theme and shared UI primitives
- role-aware routing with guarded customer/provider shells
- live OTP auth/session integration with the backend
- backend-backed discovery, reservations, QR completion, reviews, notifications, media upload, and settings flows
- app-side push lifecycle wiring with optional Firebase Messaging enablement
- custom-scheme deep-link lifecycle handling, including backend-verified email magic links
- iOS and Android native targets with shared push setup baseline

## Requirements

- Flutter `>= 3.35.0`
- Dart `^3.9.0`

These minimums are driven by the current package constraints in `pubspec.yaml`.

## Run

```bash
flutter pub get
flutter run \
  --dart-define=APP_ENV=development \
  --dart-define=API_BASE_URL=http://localhost:3000/api/v1 \
  --dart-define=ENABLE_FIREBASE_MESSAGING=false
```

On Android emulators, the default development API base URL is `http://10.0.2.2:3000/api/v1` when `API_BASE_URL` is not explicitly provided.

For staging or production-like builds:

```bash
flutter run \
  --dart-define=APP_ENV=staging \
  --dart-define=API_BASE_URL=https://staging-api.reziphay.com/api/v1 \
  --dart-define=ENABLE_FIREBASE_MESSAGING=false
```

To enable real Firebase Cloud Messaging in app builds:

```bash
flutter run \
  --dart-define=APP_ENV=development \
  --dart-define=API_BASE_URL=http://localhost:3000/api/v1 \
  --dart-define=ENABLE_FIREBASE_MESSAGING=true
```

Real FCM requires native Firebase setup in this app before the flag is usable:

- `ios/Runner/GoogleService-Info.plist`
- `android/app/google-services.json`
- matching Firebase project configuration for the Reziphay bundle/package IDs

The Android Gradle build is wired to apply Google Services only when `android/app/google-services.json` exists, so local builds continue to work before the real Firebase file is added.

Canonical app identifiers:

- iOS bundle ID: `com.reziphay.mobile`
- Android application ID / namespace: `com.reziphay.mobile`

## Deep Links

The app currently supports custom-scheme deep links with the `reziphay://` scheme. Useful test examples:

```bash
reziphay://auth/email-link-result?status=success
reziphay://auth/verify-email-magic-link?token=abc123
reziphay://services/svc_1001
reziphay://brands/brand_2001
reziphay://providers/prov_3001
reziphay://categories/cat_4001
reziphay://notifications
```

Email magic-link verification is resolved against the backend and then routed into the existing email-link result screen.

The native projects are also configured for HTTPS universal/app links on:

- `https://reziphay.com`
- `https://staging.reziphay.com`

Checked-in deployment assets live here:

- `deployment/app-links/.well-known/apple-app-site-association`
- `deployment/app-links/.well-known/assetlinks.json`

Sync or refresh those files with:

```bash
dart run tool/sync_app_links_files.dart \
  --android-sha256=AA:BB:CC:DD
```

Run a local release readiness check with:

```bash
dart run tool/release_preflight.dart
```

What is still missing for production-grade link handling:

- publishing the `.well-known` files on the live domains
- replacing the Android asset-links placeholder with the real release SHA-256 certificate fingerprint
- optional expansion if you later want additional hosts such as `www.reziphay.com`

## Test

```bash
flutter test
flutter analyze
```

## Structure

```txt
lib/
  app/        app bootstrap, router, theme, config
  core/       session, storage, network, shared widgets
  features/   auth, customer, provider, common screens, role switch
  shared/     core mobile models
```

## Current integration note

The app is backend-backed across auth, discovery, provider management, reservations, QR, reviews, notifications, media upload, and reminder settings. The main remaining integration gap is native Firebase project configuration for real FCM delivery.
