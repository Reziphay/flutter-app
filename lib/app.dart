// app.dart
// Reziphay
//
// Author: Vugar Safarzada (@vugarsafarzada)

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/theme/app_theme.dart';
import 'features/auth/otp_screen.dart';
import 'features/auth/phone_entry_screen.dart';
import 'features/auth/register_screen.dart';
import 'features/brand_detail/brand_detail_screen.dart';
import 'features/explore/explore_screen.dart';
import 'features/main/ucr_shell.dart';
import 'features/main/uso_shell.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/profile/profile_edit_screen.dart';
import 'features/profile/ucr_profile_screen.dart';
import 'features/profile/uso_profile_screen.dart';
import 'features/provider_profile/provider_profile_screen.dart';
import 'features/reservations/reservation_detail_screen.dart';
import 'features/reservations/reservations_screen.dart';
import 'features/search/search_screen.dart';
import 'features/service_detail/service_detail_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/splash/splash_screen.dart';
import 'features/ucr/favorites/favorites_screen.dart';
import 'features/uso/incoming_reservations/incoming_reservations_screen.dart';
import 'features/uso/my_services/create_edit_service_screen.dart';
import 'features/uso/my_services/my_services_screen.dart';
import 'core/l10n/app_localizations.dart';
import 'state/app_state.dart';
import 'state/settings_provider.dart';
import 'state/theme_provider.dart';

// MARK: - Router Notifier

/// Bridges Riverpod auth/role state → GoRouter refresh.
class _RouterNotifier extends ChangeNotifier {
  _RouterNotifier(Ref ref) {
    ref.listen(
      appStateProvider.select(
        (s) => (s.authStatus, s.currentUser?.activeRole),
      ),
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
      final appState = ref.read(appStateProvider);
      final location = state.matchedLocation;

      // Still bootstrapping
      if (appState.isUnknown) return null;

      final isAuthRoute = location.startsWith('/auth') ||
          location == '/onboarding' ||
          location == '/';

      if (appState.isAuthenticated) {
        // Redirect from auth/onboarding → correct home based on role
        if (isAuthRoute || location.startsWith('/home')) {
          return appState.isUso ? '/uso/incoming' : '/ucr/explore';
        }
        // Prevent UCR from accessing USO routes and vice versa
        if (appState.isUso && location.startsWith('/ucr')) {
          return '/uso/incoming';
        }
        if (appState.isUcr && location.startsWith('/uso')) {
          return '/ucr/explore';
        }
      }

      if (appState.isUnauthenticated && !isAuthRoute) {
        return '/onboarding';
      }

      return null;
    },
    routes: [
      // Splash
      GoRoute(path: '/', builder: (_, __) => const SplashScreen()),

      // Onboarding
      GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingScreen()),

      // Auth
      GoRoute(path: '/auth/phone', builder: (_, __) => const PhoneEntryScreen()),
      GoRoute(
        path: '/auth/otp',
        builder: (_, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return OtpScreen(
            phone:     extra?['phone']     as String? ?? '',
            debugCode: extra?['debugCode'] as String?,
          );
        },
      ),
      GoRoute(
        path: '/auth/register',
        builder: (_, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return RegisterScreen(
            registrationToken: extra?['registrationToken'] as String? ?? '',
            phone:             extra?['phone']             as String? ?? '',
          );
        },
      ),

      // ── UCR Shell ──────────────────────────────────────────────────────
      ShellRoute(
        builder: (_, __, child) => UcrShell(child: child),
        routes: [
          GoRoute(
            path: '/ucr/explore',
            builder: (_, __) => const ExploreScreen(),
          ),
          GoRoute(
            path: '/ucr/reservations',
            builder: (_, __) => const ReservationsScreen(),
          ),
          GoRoute(
            path: '/ucr/notifications',
            builder: (_, __) => const UcrNotificationsPlaceholder(),
          ),
          GoRoute(
            path: '/ucr/profile',
            builder: (_, __) => const UcrProfileScreen(),
          ),
        ],
      ),

      // ── USO Shell ──────────────────────────────────────────────────────
      ShellRoute(
        builder: (_, __, child) => UsoShell(child: child),
        routes: [
          GoRoute(
            path: '/uso/incoming',
            builder: (_, __) => const IncomingReservationsScreen(),
          ),
          GoRoute(
            path: '/uso/services',
            builder: (_, __) => const MyServicesScreen(),
          ),
          GoRoute(
            path: '/uso/notifications',
            builder: (_, __) => const UsoNotificationsPlaceholder(),
          ),
          GoRoute(
            path: '/uso/profile',
            builder: (_, __) => const UsoProfileScreen(),
          ),
        ],
      ),

      // ── USO Service CRUD ───────────────────────────────────────────────
      GoRoute(
        path: '/uso/services/new',
        builder: (_, __) => const CreateEditServiceScreen(),
      ),
      GoRoute(
        path: '/uso/services/:id/edit',
        builder: (_, state) =>
            CreateEditServiceScreen(serviceId: state.pathParameters['id']),
      ),

      // ── Settings (shared — UCR & USO) ──────────────────────────────────
      GoRoute(
        path: '/settings',
        builder: (_, __) => const SettingsScreen(),
      ),

      // ── Profile Edit (shared — UCR & USO) ──────────────────────────────
      GoRoute(
        path: '/profile/edit',
        builder: (_, __) => const ProfileEditScreen(),
      ),

      // ── UCR Favorites ──────────────────────────────────────────────────
      GoRoute(
        path: '/ucr/favorites',
        builder: (_, __) => const FavoritesScreen(),
      ),

      // ── Shared full-screen routes ───────────────────────────────────────
      GoRoute(
        path: '/search',
        builder: (_, state) {
          final tab = state.uri.queryParameters['tab'];
          return SearchScreen(initialTab: tab);
        },
      ),
      GoRoute(
        path: '/service/:id',
        builder: (_, state) =>
            ServiceDetailScreen(serviceId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/brand/:id',
        builder: (_, state) =>
            BrandDetailScreen(brandId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/provider/:id',
        builder: (_, state) =>
            ProviderProfileScreen(providerId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/reservation/:id',
        builder: (_, state) =>
            ReservationDetailScreen(reservationId: state.pathParameters['id']!),
      ),

      // Legacy redirect
      GoRoute(path: '/home', redirect: (_, __) => '/ucr/explore'),
      GoRoute(path: '/home/explore',       redirect: (_, __) => '/ucr/explore'),
      GoRoute(path: '/home/reservations',  redirect: (_, __) => '/ucr/reservations'),
      GoRoute(path: '/home/notifications', redirect: (_, __) => '/ucr/notifications'),
      GoRoute(path: '/home/profile',       redirect: (_, __) => '/ucr/profile'),
    ],
  );
});

// MARK: - App Widget

class ReziphayApp extends ConsumerWidget {
  const ReziphayApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router   = ref.watch(_routerProvider);
    final palette  = ref.watch(appPaletteProvider);
    final settings = ref.watch(settingsProvider);

    return MaterialApp.router(
      title:                     'Reziphay',
      debugShowCheckedModeBanner: false,
      // Light theme (existing appearance)
      theme:     AppTheme.build(palette),
      // Dark theme — same role palette, dark brightness
      darkTheme: AppTheme.buildDark(palette),
      // Follows system / user preference from settings
      themeMode: settings.flutterThemeMode,
      // Locale from language setting
      locale:           settings.locale,
      supportedLocales: const [
        Locale('az'),
        Locale('en'),
        Locale('ru'),
        Locale('tr'),
      ],
      localizationsDelegates: const [
        AppLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: router,
    );
  }
}
