import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reziphay_mobile/core/auth/auth_repository.dart';
import 'package:reziphay_mobile/core/auth/session_controller.dart';
import 'package:reziphay_mobile/core/storage/session_store.dart';
import 'package:reziphay_mobile/shared/models/app_role.dart';
import 'package:reziphay_mobile/shared/models/auth_tokens.dart';
import 'package:reziphay_mobile/shared/models/session_user.dart';
import 'package:reziphay_mobile/shared/models/user_session.dart';
import 'package:reziphay_mobile/shared/models/user_status.dart';
import 'helpers/fake_auth_repository.dart';

void main() {
  group('SessionController', () {
    late InMemorySessionStore sessionStore;
    late FakeAuthRepository authRepository;
    late ProviderContainer container;

    setUp(() {
      sessionStore = InMemorySessionStore();
      authRepository = FakeAuthRepository();
      container = ProviderContainer(
        overrides: [
          sessionStoreProvider.overrideWithValue(sessionStore),
          authRepositoryProvider.overrideWithValue(authRepository),
        ],
      );
      addTearDown(container.dispose);
    });

    test('bootstrap restores the persisted session', () async {
      await sessionStore.writeSession(_buildSession());

      await container.read(sessionControllerProvider.notifier).bootstrap();

      final state = container.read(sessionControllerProvider);
      expect(state.session?.user.fullName, 'Test User');
      expect(state.session?.activeRole, AppRole.customer);
    });

    test(
      'activateProviderRole adds provider access and switches context',
      () async {
        await sessionStore.writeSession(_buildSession());
        await container.read(sessionControllerProvider.notifier).bootstrap();

        await container
            .read(sessionControllerProvider.notifier)
            .activateProviderRole();

        final updatedSession = container
            .read(sessionControllerProvider)
            .session;
        expect(updatedSession?.availableRoles, contains(AppRole.provider));
        expect(updatedSession?.activeRole, AppRole.provider);
      },
    );

    test(
      'requestOtp stores the pending auth context with dev metadata',
      () async {
        final ok = await container
            .read(sessionControllerProvider.notifier)
            .requestOtpForLogin('+994500000000');

        final state = container.read(sessionControllerProvider);
        expect(ok, isTrue);
        expect(state.pendingAuth?.phoneNumber, '+994500000000');
        expect(state.pendingAuth?.debugOtpCode, '123456');
        expect(state.pendingAuth?.otpExpiresAt, isNotNull);
      },
    );

    test('switchRole reissues the session through the repository', () async {
      await sessionStore.writeSession(_buildSession());
      await container.read(sessionControllerProvider.notifier).bootstrap();
      await container
          .read(sessionControllerProvider.notifier)
          .activateProviderRole();

      await container
          .read(sessionControllerProvider.notifier)
          .switchRole(AppRole.customer);

      final updatedSession = container.read(sessionControllerProvider).session;
      expect(updatedSession?.activeRole, AppRole.customer);
      expect(updatedSession?.tokens.accessToken, isNot('access'));
    });
  });
}

UserSession _buildSession() {
  return UserSession(
    user: const SessionUser(
      id: 'usr_test',
      fullName: 'Test User',
      email: 'test@reziphay.com',
      phoneNumber: '+994500000000',
      roles: [AppRole.customer],
      status: UserStatus.active,
    ),
    activeRole: AppRole.customer,
    tokens: AuthTokens(
      accessToken: 'access',
      refreshToken: 'refresh',
      accessTokenExpiresAt: DateTime.now().add(const Duration(minutes: 30)),
    ),
  );
}
