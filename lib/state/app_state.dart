// app_state.dart
// Reziphay
//
// Author: Vugar Safarzada (@vugarsafarzada)

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

// MARK: - Auth Status

enum AuthStatus { unknown, authenticated, unauthenticated }

// MARK: - App State Model

class AppStateData {
  const AppStateData({
    this.authStatus  = AuthStatus.unknown,
    this.currentUser,
    this.selectedRole,
  });

  final AuthStatus authStatus;
  final User? currentUser;
  final UserRole? selectedRole;

  bool get isAuthenticated    => authStatus == AuthStatus.authenticated;
  bool get isUnauthenticated  => authStatus == AuthStatus.unauthenticated;
  bool get isUnknown          => authStatus == AuthStatus.unknown;

  AppStateData copyWith({
    AuthStatus? authStatus,
    User? currentUser,
    UserRole? selectedRole,
    bool clearUser = false,
  }) {
    return AppStateData(
      authStatus:   authStatus  ?? this.authStatus,
      currentUser:  clearUser   ? null : (currentUser ?? this.currentUser),
      selectedRole: selectedRole ?? this.selectedRole,
    );
  }
}

// MARK: - App State Notifier

class AppStateNotifier extends StateNotifier<AppStateData> {
  AppStateNotifier() : super(const AppStateData());

  final _authService = AuthService.instance;

  /// Called on app launch — checks for existing valid session
  Future<void> bootstrap() async {
    final user = await _authService.validateSession();
    if (user != null) {
      state = state.copyWith(
        authStatus:  AuthStatus.authenticated,
        currentUser: user,
      );
    } else {
      state = state.copyWith(authStatus: AuthStatus.unauthenticated);
    }
  }

  /// Called after successful OTP verification
  void onSessionCreated({required User user}) {
    state = state.copyWith(
      authStatus:  AuthStatus.authenticated,
      currentUser: user,
    );
  }

  /// Called when user selects a role on the onboarding screen
  void selectRole(UserRole role) {
    state = state.copyWith(selectedRole: role);
  }

  /// Update the current user (e.g. after profile edit)
  void updateUser(User user) {
    state = state.copyWith(currentUser: user);
  }

  /// Logout
  Future<void> logout() async {
    await _authService.logout();
    state = const AppStateData(authStatus: AuthStatus.unauthenticated);
  }
}

// MARK: - Provider

final appStateProvider =
    StateNotifierProvider<AppStateNotifier, AppStateData>((ref) {
  return AppStateNotifier();
});
