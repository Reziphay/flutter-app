# Reziphay Mobile

Phase 1 foundation for the Reziphay Flutter app lives here. The current scaffold covers:

- app bootstrap and environment config
- token-based light theme and shared UI primitives
- role-aware routing with guarded customer/provider shells
- session persistence and OTP-oriented auth flow foundation
- placeholder customer/provider surfaces aligned to the PRD and design docs

## Requirements

- Flutter `>= 3.35.0`
- Dart `^3.9.0`

These minimums are driven by the current package constraints in `pubspec.yaml`.

## Run

```bash
flutter pub get
flutter run \
  --dart-define=APP_ENV=development \
  --dart-define=API_BASE_URL=http://localhost:3000/api/v1
```

For staging or production-like builds:

```bash
flutter run \
  --dart-define=APP_ENV=staging \
  --dart-define=API_BASE_URL=https://staging-api.reziphay.com/api/v1
```

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

The app currently uses a local `FakeAuthRepository` so the navigation and session lifecycle can be exercised before the live backend client is wired. The `Dio` client, environment config, and auth header interceptor are already in place for the real REST integration pass.
