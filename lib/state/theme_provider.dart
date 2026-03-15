// theme_provider.dart
// Reziphay
//
// Author: Vugar Safarzada (@vugarsafarzada)

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_palette.dart';
import '../models/user.dart';
import 'app_state.dart';

/// Selects [AppPalette.ucr], [AppPalette.uso], or [AppPalette.neutral].
///
/// Authenticated  → based on session activeRole
/// Unauthenticated + selectedRole set → based on onboarding selection
/// Otherwise → [AppPalette.neutral]
final appPaletteProvider = Provider<AppPalette>((ref) {
  final appState = ref.watch(appStateProvider);

  if (appState.authStatus == AuthStatus.authenticated) {
    final user = appState.currentUser;
    final active = user?.activeRole?.toUpperCase();
    if (active == 'USO') return AppPalette.uso;
    if (active == 'UCR') return AppPalette.ucr;
    if (user?.hasUsoRole == true && user?.hasUcrRole == false) return AppPalette.uso;
    return AppPalette.ucr;
  }

  // Auth flow: use the role the user selected on onboarding
  if (appState.selectedRole == UserRole.uso) return AppPalette.uso;
  if (appState.selectedRole == UserRole.ucr) return AppPalette.ucr;

  return AppPalette.neutral;
});
