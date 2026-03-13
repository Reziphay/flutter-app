import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reziphay_mobile/core/auth/auth_repository.dart';
import 'package:reziphay_mobile/core/auth/session_state.dart';
import 'package:reziphay_mobile/core/network/app_exception.dart';
import 'package:reziphay_mobile/core/storage/session_store.dart';
import 'package:reziphay_mobile/shared/models/app_role.dart';
import 'package:reziphay_mobile/shared/models/pending_auth_context.dart';
import 'package:reziphay_mobile/shared/models/user_session.dart';

final sessionControllerProvider =
    NotifierProvider<SessionController, SessionState>(SessionController.new);

class SessionController extends Notifier<SessionState> {
  @override
  SessionState build() => SessionState.initial();

  Future<void> activateProviderRole() async {
    final currentSession = state.session;
    if (currentSession == null) {
      return;
    }

    state = state.copyWith(isBusy: true, clearError: true);

    try {
      final updatedSession = await ref
          .read(authRepositoryProvider)
          .activateProviderRole(currentSession);

      await _persistSession(updatedSession);

      state = state.copyWith(
        isBusy: false,
        session: updatedSession,
        clearError: true,
      );
    } catch (error) {
      state = state.copyWith(isBusy: false, errorMessage: _mapError(error));
    }
  }

  Future<void> bootstrap() async {
    if (state.bootstrapStatus == BootstrapStatus.loading ||
        state.bootstrapStatus == BootstrapStatus.ready) {
      return;
    }

    state = state.copyWith(
      bootstrapStatus: BootstrapStatus.loading,
      clearError: true,
    );

    final restoredSession = await ref.read(sessionStoreProvider).readSession();

    if (restoredSession == null) {
      state = state.copyWith(
        bootstrapStatus: BootstrapStatus.ready,
        clearSession: true,
      );
      return;
    }

    try {
      final refreshedSession =
          restoredSession.tokens.isAccessTokenExpired ||
              restoredSession.tokens.shouldRefreshSoon
          ? await ref
                .read(authRepositoryProvider)
                .refreshSession(restoredSession)
          : restoredSession;

      await _persistSession(refreshedSession);

      state = state.copyWith(
        bootstrapStatus: BootstrapStatus.ready,
        session: refreshedSession,
        clearError: true,
      );
    } catch (error) {
      await ref.read(sessionStoreProvider).clearSession();

      state = state.copyWith(
        bootstrapStatus: BootstrapStatus.ready,
        clearSession: true,
        errorMessage: _mapError(error),
      );
    }
  }

  void clearError() {
    if (state.errorMessage == null) {
      return;
    }

    state = state.copyWith(clearError: true);
  }

  Future<void> logout() async {
    state = state.copyWith(isBusy: true, clearError: true);

    try {
      await ref.read(authRepositoryProvider).logout(state.session);
    } finally {
      await ref.read(sessionStoreProvider).clearSession();
      state = SessionState.initial().copyWith(
        bootstrapStatus: BootstrapStatus.ready,
      );
    }
  }

  Future<bool> requestOtpForLogin(String phoneNumber) {
    return _requestOtp(
      PendingAuthContext(
        phoneNumber: phoneNumber,
        mode: AuthFlowMode.login,
        intendedRole: AppRole.customer,
      ),
    );
  }

  Future<bool> requestOtpForRegistration({
    required String fullName,
    required String email,
    required String phoneNumber,
    required AppRole intendedRole,
  }) {
    return _requestOtp(
      PendingAuthContext(
        phoneNumber: phoneNumber,
        mode: AuthFlowMode.register,
        intendedRole: intendedRole,
        fullName: fullName,
        email: email,
      ),
    );
  }

  Future<void> switchRole(AppRole role) async {
    final currentSession = state.session;
    if (currentSession == null ||
        !currentSession.availableRoles.contains(role) ||
        currentSession.activeRole == role) {
      return;
    }

    final updatedSession = currentSession.copyWith(activeRole: role);
    await _persistSession(updatedSession);
    state = state.copyWith(session: updatedSession);
  }

  Future<bool> verifyOtp(String otpCode) async {
    final pendingAuth = state.pendingAuth;
    if (pendingAuth == null) {
      state = state.copyWith(
        errorMessage: 'Your verification session expired. Request a new OTP.',
      );
      return false;
    }

    state = state.copyWith(isBusy: true, clearError: true);

    try {
      final session = await ref
          .read(authRepositoryProvider)
          .verifyOtp(otpCode: otpCode, context: pendingAuth);

      await _persistSession(session);

      state = state.copyWith(
        bootstrapStatus: BootstrapStatus.ready,
        isBusy: false,
        session: session,
        clearPendingAuth: true,
        clearError: true,
      );

      return true;
    } catch (error) {
      state = state.copyWith(isBusy: false, errorMessage: _mapError(error));
      return false;
    }
  }

  String _mapError(Object error) {
    if (error is AppException) {
      return error.message;
    }

    return 'Something went wrong. Please try again.';
  }

  Future<void> _persistSession(UserSession session) {
    return ref.read(sessionStoreProvider).writeSession(session);
  }

  Future<bool> _requestOtp(PendingAuthContext context) async {
    state = state.copyWith(isBusy: true, clearError: true);

    try {
      await ref.read(authRepositoryProvider).requestOtp(context);

      state = state.copyWith(
        isBusy: false,
        pendingAuth: context,
        clearError: true,
      );

      return true;
    } catch (error) {
      state = state.copyWith(isBusy: false, errorMessage: _mapError(error));
      return false;
    }
  }
}
