// app.dart
// Reziphay
//
// Author: Vugar Safarzada (@vugarsafarzada)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/theme/app_theme.dart';
import 'features/auth/otp_screen.dart';
import 'features/auth/phone_entry_screen.dart';
import 'features/auth/register_screen.dart';
import 'features/brand_detail/brand_detail_screen.dart';
import 'features/explore/explore_screen.dart';
import 'features/main/main_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/provider_profile/provider_profile_screen.dart';
import 'features/reservations/reservation_detail_screen.dart';
import 'features/reservations/reservations_screen.dart';
import 'features/search/search_screen.dart';
import 'features/service_detail/service_detail_screen.dart';
import 'features/splash/splash_screen.dart';
import 'state/app_state.dart';

// MARK: - Router Notifier

/// Bridges Riverpod auth state → GoRouter refresh.
/// Whenever [AuthStatus] changes, GoRouter re-evaluates redirect.
class _RouterNotifier extends ChangeNotifier {
  _RouterNotifier(Ref ref) {
    ref.listen(
      appStateProvider.select((s) => s.authStatus),
      (_, __) => notifyListeners(),
    );
  }
}

// MARK: - Router

final _routerProvider = Provider<GoRouter>((ref) {
  final notifier = _RouterNotifier(ref);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: notifier,
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
            phone:     extra?['phone']     as String? ?? '',
            debugCode: extra?['debugCode'] as String?,
          );
        },
      ),
      GoRoute(
        path: '/auth/register',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return RegisterScreen(
            registrationToken: extra?['registrationToken'] as String? ?? '',
            phone:             extra?['phone']             as String? ?? '',
          );
        },
      ),

      // Main App (Shell Route for TabBar)
      ShellRoute(
        builder: (context, state, child) => MainScreen(child: child),
        routes: [
          GoRoute(
            path: '/home/explore',
            builder: (_, __) => const ExploreScreen(),
          ),
          GoRoute(
            path: '/home/reservations',
            builder: (_, __) => const ReservationsScreen(),
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

      // Discovery routes (outside shell — full-screen)
      GoRoute(
        path: '/search',
        builder: (context, state) {
          final tab = state.uri.queryParameters['tab'];
          return SearchScreen(initialTab: tab);
        },
      ),
      GoRoute(
        path: '/service/:id',
        builder: (context, state) =>
            ServiceDetailScreen(serviceId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/brand/:id',
        builder: (context, state) =>
            BrandDetailScreen(brandId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/provider/:id',
        builder: (context, state) =>
            ProviderProfileScreen(providerId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/reservation/:id',
        builder: (context, state) =>
            ReservationDetailScreen(reservationId: state.pathParameters['id']!),
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
