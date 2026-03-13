const Set<String> appLinkHosts = <String>{
  'reziphay.com',
  'staging.reziphay.com',
};

const List<String> appLinkPathPatterns = <String>[
  '/auth/verify-email-magic-link*',
  '/auth/email-link-result*',
  '/auth/login*',
  '/auth/register*',
  '/welcome*',
  '/notifications*',
  '/services/*',
  '/brands/*',
  '/providers/*',
  '/categories/*',
];

const String iOSAssociatedDomainsTeamId = '297PWJKRJP';
const String iOSBundleId = 'com.reziphay.mobile';
const String androidApplicationId = 'com.reziphay.mobile';
const String androidAssetLinksFingerprintPlaceholder =
    'REPLACE_WITH_RELEASE_SHA256_CERT_FINGERPRINT';

String get iOSAssociatedAppId => '$iOSAssociatedDomainsTeamId.$iOSBundleId';
