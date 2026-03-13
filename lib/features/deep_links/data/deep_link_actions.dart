import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reziphay_mobile/app/config/deep_link_config.dart';
import 'package:reziphay_mobile/core/auth/auth_repository.dart';
import 'package:reziphay_mobile/features/auth/models/email_link_result_status.dart';
import 'package:reziphay_mobile/features/auth/presentation/pages/email_link_result_page.dart';
import 'package:reziphay_mobile/features/auth/presentation/pages/login_page.dart';
import 'package:reziphay_mobile/features/auth/presentation/pages/register_page.dart';
import 'package:reziphay_mobile/features/auth/presentation/pages/welcome_page.dart';
import 'package:reziphay_mobile/features/common/presentation/pages/notifications_page.dart';
import 'package:reziphay_mobile/features/discovery/presentation/pages/brand_detail_page.dart';
import 'package:reziphay_mobile/features/discovery/presentation/pages/category_detail_page.dart';
import 'package:reziphay_mobile/features/discovery/presentation/pages/provider_detail_page.dart';
import 'package:reziphay_mobile/features/discovery/presentation/pages/service_detail_page.dart';
import 'package:reziphay_mobile/shared/models/app_role.dart';

final deepLinkActionsProvider = Provider<DeepLinkActions>(
  (ref) => DeepLinkActions(ref),
);

enum AppDeepLinkType {
  emailVerification,
  emailResult,
  service,
  brand,
  provider,
  category,
  login,
  register,
  welcome,
  notifications,
}

class AppDeepLink {
  const AppDeepLink({
    required this.type,
    required this.uri,
    this.entityId,
    this.emailStatus,
    this.role,
  });

  final AppDeepLinkType type;
  final Uri uri;
  final String? entityId;
  final EmailLinkResultStatus? emailStatus;
  final AppRole? role;
}

class DeepLinkActions {
  DeepLinkActions(this.ref);

  final Ref ref;

  AppDeepLink? parse(Uri uri) {
    if (!_isSupportedUri(uri)) {
      return null;
    }

    final segments = _normalizedSegments(uri);

    if (_matchesPath(segments, ['auth', 'verify-email-magic-link']) ||
        segments.singleOrNull == 'verify-email-magic-link') {
      return AppDeepLink(type: AppDeepLinkType.emailVerification, uri: uri);
    }

    if (_matchesPath(segments, ['auth', 'email-link-result'])) {
      return AppDeepLink(
        type: AppDeepLinkType.emailResult,
        uri: uri,
        emailStatus: EmailLinkResultStatusX.fromQuery(
          uri.queryParameters['status'],
        ),
      );
    }

    if (_matchesEntityPath(segments, ['services', 'service'])) {
      return AppDeepLink(
        type: AppDeepLinkType.service,
        uri: uri,
        entityId: _entityIdFor(uri, segments),
      );
    }

    if (_matchesEntityPath(segments, ['brands', 'brand'])) {
      return AppDeepLink(
        type: AppDeepLinkType.brand,
        uri: uri,
        entityId: _entityIdFor(uri, segments),
      );
    }

    if (_matchesEntityPath(segments, ['providers', 'provider'])) {
      return AppDeepLink(
        type: AppDeepLinkType.provider,
        uri: uri,
        entityId: _entityIdFor(uri, segments),
      );
    }

    if (_matchesEntityPath(segments, ['categories', 'category'])) {
      return AppDeepLink(
        type: AppDeepLinkType.category,
        uri: uri,
        entityId: _entityIdFor(uri, segments),
      );
    }

    if (_matchesPath(segments, ['auth', 'login']) ||
        segments.singleOrNull == 'login') {
      return AppDeepLink(type: AppDeepLinkType.login, uri: uri);
    }

    if (_matchesPath(segments, ['auth', 'register']) ||
        segments.singleOrNull == 'register') {
      return AppDeepLink(
        type: AppDeepLinkType.register,
        uri: uri,
        role: AppRoleX.fromQuery(uri.queryParameters['role']),
      );
    }

    if (segments.singleOrNull == 'welcome') {
      return AppDeepLink(type: AppDeepLinkType.welcome, uri: uri);
    }

    if (segments.singleOrNull == 'notifications') {
      return AppDeepLink(type: AppDeepLinkType.notifications, uri: uri);
    }

    if (uri.queryParameters['serviceId'] case final serviceId?) {
      return AppDeepLink(
        type: AppDeepLinkType.service,
        uri: uri,
        entityId: serviceId,
      );
    }
    if (uri.queryParameters['brandId'] case final brandId?) {
      return AppDeepLink(
        type: AppDeepLinkType.brand,
        uri: uri,
        entityId: brandId,
      );
    }
    if (uri.queryParameters['providerId'] case final providerId?) {
      return AppDeepLink(
        type: AppDeepLinkType.provider,
        uri: uri,
        entityId: providerId,
      );
    }
    if (uri.queryParameters['categoryId'] case final categoryId?) {
      return AppDeepLink(
        type: AppDeepLinkType.category,
        uri: uri,
        entityId: categoryId,
      );
    }

    return null;
  }

  Future<String?> locationForUri(Uri uri) async {
    final link = parse(uri);
    if (link == null) {
      return null;
    }

    return switch (link.type) {
      AppDeepLinkType.emailVerification => EmailLinkResultPage.location(
        await ref.read(authRepositoryProvider).verifyEmailMagicLink(link.uri),
      ),
      AppDeepLinkType.emailResult => EmailLinkResultPage.location(
        link.emailStatus ?? EmailLinkResultStatus.success,
      ),
      AppDeepLinkType.service when link.entityId != null =>
        ServiceDetailPage.location(link.entityId!),
      AppDeepLinkType.brand when link.entityId != null =>
        BrandDetailPage.location(link.entityId!),
      AppDeepLinkType.provider when link.entityId != null =>
        ProviderDetailPage.location(link.entityId!),
      AppDeepLinkType.category when link.entityId != null =>
        CategoryDetailPage.location(link.entityId!),
      AppDeepLinkType.login => LoginPage.path,
      AppDeepLinkType.register => _registerLocation(link.role),
      AppDeepLinkType.welcome => WelcomePage.path,
      AppDeepLinkType.notifications => NotificationsPage.path,
      _ => null,
    };
  }

  String _registerLocation(AppRole? role) {
    if (role == null) {
      return RegisterPage.path;
    }

    return '${RegisterPage.path}?role=${role.queryValue}';
  }

  String? _entityIdFor(Uri uri, List<String> segments) {
    if (segments.length >= 2) {
      return segments[1];
    }
    return uri.queryParameters['id'];
  }

  bool _matchesPath(List<String> segments, List<String> expected) {
    if (segments.length < expected.length) {
      return false;
    }

    for (var index = 0; index < expected.length; index += 1) {
      if (segments[index] != expected[index]) {
        return false;
      }
    }
    return true;
  }

  bool _matchesEntityPath(List<String> segments, List<String> prefixes) {
    return segments.length >= 2 && prefixes.contains(segments.first);
  }

  bool _isSupportedUri(Uri uri) {
    final scheme = uri.scheme.toLowerCase();
    if (scheme == 'http' || scheme == 'https') {
      return appLinkHosts.contains(uri.host.toLowerCase());
    }

    return scheme.isEmpty || scheme == 'reziphay';
  }

  List<String> _normalizedSegments(Uri uri) {
    final segments = <String>[];
    if (uri.scheme.isNotEmpty &&
        uri.scheme != 'http' &&
        uri.scheme != 'https' &&
        uri.host.isNotEmpty) {
      segments.add(uri.host.toLowerCase());
    }

    segments.addAll(
      uri.pathSegments
          .where((segment) => segment.trim().isNotEmpty)
          .map((segment) => segment.trim().toLowerCase()),
    );

    return segments;
  }
}
