import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AppFlavor { development, staging, production }

AppFlavor parseAppFlavor(String rawValue) {
  switch (rawValue.toLowerCase()) {
    case 'production':
    case 'prod':
      return AppFlavor.production;
    case 'staging':
      return AppFlavor.staging;
    default:
      return AppFlavor.development;
  }
}

class AppEnvironment {
  const AppEnvironment({
    required this.flavor,
    required this.apiBaseUrl,
    required this.appName,
    required this.enableFirebaseMessaging,
  });

  factory AppEnvironment.fromDefines() {
    final flavor = parseAppFlavor(
      const String.fromEnvironment('APP_ENV', defaultValue: 'development'),
    );

    const baseUrlOverride = String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: '',
    );

    final apiBaseUrl = switch (flavor) {
      AppFlavor.development =>
        baseUrlOverride.isEmpty
            ? _defaultDevelopmentApiBaseUrl()
            : baseUrlOverride,
      AppFlavor.staging =>
        baseUrlOverride.isEmpty
            ? 'https://staging-api.reziphay.com/api/v1'
            : baseUrlOverride,
      AppFlavor.production =>
        baseUrlOverride.isEmpty
            ? 'https://api.reziphay.com/api/v1'
            : baseUrlOverride,
    };

    final suffix = switch (flavor) {
      AppFlavor.development => ' Dev',
      AppFlavor.staging => ' Staging',
      AppFlavor.production => '',
    };

    const enableFirebaseMessaging = bool.fromEnvironment(
      'ENABLE_FIREBASE_MESSAGING',
      defaultValue: false,
    );

    return AppEnvironment(
      flavor: flavor,
      apiBaseUrl: apiBaseUrl,
      appName: 'Reziphay$suffix',
      enableFirebaseMessaging: enableFirebaseMessaging,
    );
  }

  final AppFlavor flavor;
  final String apiBaseUrl;
  final String appName;
  final bool enableFirebaseMessaging;

  bool get isProduction => flavor == AppFlavor.production;

  String get environmentLabel => switch (flavor) {
    AppFlavor.development => 'Development',
    AppFlavor.staging => 'Staging',
    AppFlavor.production => 'Production',
  };
}

final appEnvironmentProvider = Provider<AppEnvironment>(
  (ref) => throw UnimplementedError('AppEnvironment must be overridden.'),
);

String _defaultDevelopmentApiBaseUrl() {
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    return 'http://10.0.2.2:3000/api/v1';
  }

  return 'http://localhost:3000/api/v1';
}
