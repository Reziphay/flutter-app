import 'package:reziphay_mobile/shared/models/pending_auth_context.dart';
import 'package:reziphay_mobile/shared/models/user_session.dart';

enum BootstrapStatus { idle, loading, ready }

class SessionState {
  const SessionState({
    required this.bootstrapStatus,
    required this.isBusy,
    required this.errorMessage,
    required this.session,
    required this.pendingAuth,
  });

  factory SessionState.initial() {
    return const SessionState(
      bootstrapStatus: BootstrapStatus.idle,
      isBusy: false,
      errorMessage: null,
      session: null,
      pendingAuth: null,
    );
  }

  final BootstrapStatus bootstrapStatus;
  final bool isBusy;
  final String? errorMessage;
  final UserSession? session;
  final PendingAuthContext? pendingAuth;

  bool get isAuthenticated => session != null;

  SessionState copyWith({
    BootstrapStatus? bootstrapStatus,
    bool? isBusy,
    String? errorMessage,
    bool clearError = false,
    UserSession? session,
    bool clearSession = false,
    PendingAuthContext? pendingAuth,
    bool clearPendingAuth = false,
  }) {
    return SessionState(
      bootstrapStatus: bootstrapStatus ?? this.bootstrapStatus,
      isBusy: isBusy ?? this.isBusy,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      session: clearSession ? null : session ?? this.session,
      pendingAuth: clearPendingAuth ? null : pendingAuth ?? this.pendingAuth,
    );
  }
}
