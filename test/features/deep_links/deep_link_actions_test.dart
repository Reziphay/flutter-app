import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reziphay_mobile/core/auth/auth_repository.dart';
import 'package:reziphay_mobile/features/auth/models/email_link_result_status.dart';
import 'package:reziphay_mobile/features/auth/presentation/pages/email_link_result_page.dart';
import 'package:reziphay_mobile/features/auth/presentation/pages/register_page.dart';
import 'package:reziphay_mobile/features/deep_links/data/deep_link_actions.dart';
import 'package:reziphay_mobile/features/discovery/presentation/pages/service_detail_page.dart';
import 'package:reziphay_mobile/shared/models/app_role.dart';
import 'package:reziphay_mobile/shared/models/pending_auth_context.dart';
import 'package:reziphay_mobile/shared/models/user_session.dart';

void main() {
  group('DeepLinkActions', () {
    test('service deep links resolve to service detail routes', () async {
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
        ],
      );
      addTearDown(container.dispose);

      final location = await container
          .read(deepLinkActionsProvider)
          .locationForUri(Uri.parse('reziphay://services/svc_1001'));

      expect(location, ServiceDetailPage.location('svc_1001'));
    });

    test('https deep links resolve for supported Reziphay hosts', () async {
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
        ],
      );
      addTearDown(container.dispose);

      final location = await container
          .read(deepLinkActionsProvider)
          .locationForUri(Uri.parse('https://reziphay.com/services/svc_2002'));

      expect(location, ServiceDetailPage.location('svc_2002'));
    });

    test('unsupported https hosts are ignored', () async {
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
        ],
      );
      addTearDown(container.dispose);

      final location = await container
          .read(deepLinkActionsProvider)
          .locationForUri(Uri.parse('https://example.com/services/svc_3003'));

      expect(location, isNull);
    });

    test(
      'email verification deep links resolve through auth verification',
      () async {
        final container = ProviderContainer(
          overrides: [
            authRepositoryProvider.overrideWithValue(
              _FakeAuthRepository(status: EmailLinkResultStatus.alreadyUsed),
            ),
          ],
        );
        addTearDown(container.dispose);

        final location = await container
            .read(deepLinkActionsProvider)
            .locationForUri(
              Uri.parse('reziphay://auth/verify-email-magic-link?token=used'),
            );

        expect(
          location,
          EmailLinkResultPage.location(EmailLinkResultStatus.alreadyUsed),
        );
      },
    );

    test('register deep links preserve requested role', () async {
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
        ],
      );
      addTearDown(container.dispose);

      final location = await container
          .read(deepLinkActionsProvider)
          .locationForUri(Uri.parse('reziphay://auth/register?role=provider'));

      expect(
        location,
        '${RegisterPage.path}?role=${AppRole.provider.queryValue}',
      );
    });
  });
}

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository({this.status = EmailLinkResultStatus.success});

  final EmailLinkResultStatus status;

  @override
  Future<UserSession> activateProviderRole(UserSession session) {
    throw UnimplementedError();
  }

  @override
  Future<void> logout(UserSession? session) async {}

  @override
  Future<UserSession> refreshSession(UserSession currentSession) {
    throw UnimplementedError();
  }

  @override
  Future<OtpRequestResult> requestOtp(PendingAuthContext context) {
    throw UnimplementedError();
  }

  @override
  Future<EmailLinkResultStatus> verifyEmailMagicLink(Uri uri) async => status;

  @override
  Future<UserSession> verifyOtp({
    required String otpCode,
    required PendingAuthContext context,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<UserSession> switchRole(UserSession session, AppRole role) {
    throw UnimplementedError();
  }
}
