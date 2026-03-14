// app.dart
// Reziphay
//
// Author: Vugar Safarzada (@vugarsafarzada)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/network/endpoints.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/otp_screen.dart';
import 'features/auth/phone_entry_screen.dart';
import 'features/auth/register_screen.dart';
import 'features/main/main_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/splash/splash_screen.dart';
import 'state/app_state.dart';

// MARK: - Router

final _routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final authStatus = ref.read(appStateProvider).authStatus;
      final location   = state.matchedLocation;

      // Still loading
      if (authStatus == AuthStatus.unknown) return null;

      final isAuthRoute = location.startsWith('/auth') ||
          location == '/onboarding' ||
          location == '/';

      if (authStatus == AuthStatus.authenticated && isAuthRoute) {
        return '/home/explore';
      }
      if (authStatus == AuthStatus.unauthenticated && !isAuthRoute) {
        return '/onboarding';
      }
      return null;
    },
    routes: [
      // Splash
      GoRoute(
        path: '/',
        builder: (_, __) => const SplashScreen(),
      ),

      // Onboarding
      GoRoute(
        path: '/onboarding',
        builder: (_, __) => const OnboardingScreen(),
      ),

      // Auth
      GoRoute(
        path: '/auth/phone',
        builder: (_, __) => const PhoneEntryScreen(),
      ),
      GoRoute(
        path: '/auth/otp',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return OtpScreen(
            phone:   extra?['phone']   as String? ?? '',
            purpose: extra?['purpose'] as OtpPurpose? ?? OtpPurpose.login,
          );
        },
      ),
      GoRoute(
        path: '/auth/register',
        builder: (_, __) => const RegisterScreen(),
      ),

      // Main App (Shell Route for TabBar)
      ShellRoute(
        builder: (context, state, child) => MainScreen(child: child),
        routes: [
          GoRoute(
            path: '/home/explore',
            builder: (_, __) => const ExplorePlaceholderScreen(),
          ),
          GoRoute(
            path: '/home/reservations',
            builder: (_, __) => const ReservationsPlaceholderScreen(),
          ),
          GoRoute(
            path: '/home/notifications',
            builder: (_, __) => const NotificationsPlaceholderScreen(),
          ),
          GoRoute(
            path: '/home/profile',
            builder: (_, __) => const ProfilePlaceholderScreen(),
          ),
        ],
      ),

      // Convenience redirect
      GoRoute(
        path: '/home',
        redirect: (_, __) => '/home/explore',
      ),
    ],
  );
});

// MARK: - App Widget

class ReziphayApp extends ConsumerWidget {
  const ReziphayApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(_routerProvider);

    return MaterialApp.router(
      title: 'Reziphay',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: router,
    );
  }
}
