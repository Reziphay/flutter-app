import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:reziphay_mobile/core/auth/session_controller.dart';
import 'package:reziphay_mobile/core/auth/session_state.dart';
import 'package:reziphay_mobile/core/widgets/app_shell.dart';
import 'package:reziphay_mobile/features/auth/presentation/pages/email_link_result_page.dart';
import 'package:reziphay_mobile/features/auth/presentation/pages/login_page.dart';
import 'package:reziphay_mobile/features/auth/presentation/pages/otp_verification_page.dart';
import 'package:reziphay_mobile/features/auth/presentation/pages/register_page.dart';
import 'package:reziphay_mobile/features/auth/presentation/pages/splash_page.dart';
import 'package:reziphay_mobile/features/auth/presentation/pages/welcome_page.dart';
import 'package:reziphay_mobile/features/common/presentation/pages/notifications_page.dart';
import 'package:reziphay_mobile/features/common/presentation/pages/profile_page.dart';
import 'package:reziphay_mobile/features/common/presentation/pages/settings_page.dart';
import 'package:reziphay_mobile/features/customer/presentation/pages/customer_home_page.dart';
import 'package:reziphay_mobile/features/customer/presentation/pages/search_page.dart';
import 'package:reziphay_mobile/features/discovery/presentation/pages/brand_detail_page.dart';
import 'package:reziphay_mobile/features/discovery/presentation/pages/category_detail_page.dart';
import 'package:reziphay_mobile/features/discovery/presentation/pages/provider_detail_page.dart';
import 'package:reziphay_mobile/features/discovery/presentation/pages/service_detail_page.dart';
import 'package:reziphay_mobile/features/provider/presentation/pages/provider_dashboard_page.dart';
import 'package:reziphay_mobile/features/provider_management/presentation/pages/provider_brand_detail_page.dart';
import 'package:reziphay_mobile/features/provider_management/presentation/pages/provider_brands_page.dart';
import 'package:reziphay_mobile/features/provider_management/presentation/pages/provider_service_form_page.dart';
import 'package:reziphay_mobile/features/provider_management/presentation/pages/provider_services_page.dart';
import 'package:reziphay_mobile/features/qr_completion/presentation/pages/provider_qr_page.dart';
import 'package:reziphay_mobile/features/qr_completion/presentation/pages/qr_completion_result_page.dart';
import 'package:reziphay_mobile/features/qr_completion/presentation/pages/qr_scan_page.dart';
import 'package:reziphay_mobile/features/reviews/presentation/pages/review_create_page.dart';
import 'package:reziphay_mobile/features/reservations/presentation/pages/customer_reservation_detail_page.dart';
import 'package:reziphay_mobile/features/reservations/presentation/pages/customer_reservations_page.dart';
import 'package:reziphay_mobile/features/reservations/presentation/pages/provider_reservation_detail_page.dart';
import 'package:reziphay_mobile/features/reservations/presentation/pages/provider_reservations_page.dart';
import 'package:reziphay_mobile/features/reservations/presentation/pages/reservation_request_page.dart';
import 'package:reziphay_mobile/features/reservations/presentation/pages/reservation_request_success_page.dart';
import 'package:reziphay_mobile/features/restrictions/presentation/pages/account_closed_page.dart';
import 'package:reziphay_mobile/features/restrictions/presentation/pages/account_suspended_page.dart';
import 'package:reziphay_mobile/features/role_switch/presentation/pages/role_switch_page.dart';
import 'package:reziphay_mobile/shared/models/app_role.dart';
import 'package:reziphay_mobile/shared/models/user_session.dart';
import 'package:reziphay_mobile/shared/models/user_status.dart';

const _customerReservationsPath = '/customer/reservations';
const _providerReservationsPath = '/provider/reservations';
const _providerServicesPath = '/provider/services';
const _providerBrandsPath = '/provider/brands';

final goRouterProvider = Provider<GoRouter>((ref) {
  final sessionState = ref.watch(sessionControllerProvider);

  return GoRouter(
    initialLocation: SplashPage.path,
    routes: [
      GoRoute(
        path: SplashPage.path,
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: WelcomePage.path,
        builder: (context, state) => const WelcomePage(),
      ),
      GoRoute(
        path: LoginPage.path,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: RegisterPage.path,
        builder: (context, state) => RegisterPage(
          initialRole: AppRoleX.fromQuery(state.uri.queryParameters['role']),
        ),
      ),
      GoRoute(
        path: OtpVerificationPage.path,
        builder: (context, state) => const OtpVerificationPage(),
      ),
      GoRoute(
        path: EmailLinkResultPage.path,
        builder: (context, state) => EmailLinkResultPage(
          status: EmailLinkResultStatusX.fromQuery(
            state.uri.queryParameters['status'],
          ),
        ),
      ),
      GoRoute(
        path: AccountSuspendedPage.path,
        builder: (context, state) => const AccountSuspendedPage(),
      ),
      GoRoute(
        path: AccountClosedPage.path,
        builder: (context, state) => const AccountClosedPage(),
      ),
      ShellRoute(
        builder: (context, state, child) =>
            AppShell(location: state.matchedLocation, child: child),
        routes: [
          GoRoute(
            path: CustomerHomePage.path,
            builder: (context, state) => const CustomerHomePage(),
          ),
          GoRoute(
            path: SearchPage.path,
            builder: (context, state) => const SearchPage(),
          ),
          GoRoute(
            path: CategoryDetailPage.path,
            builder: (context, state) => CategoryDetailPage(
              categoryId: state.pathParameters['categoryId']!,
            ),
          ),
          GoRoute(
            path: ServiceDetailPage.path,
            builder: (context, state) => ServiceDetailPage(
              serviceId: state.pathParameters['serviceId']!,
            ),
          ),
          GoRoute(
            path: ReservationRequestPage.path,
            builder: (context, state) => ReservationRequestPage(
              serviceId: state.pathParameters['serviceId']!,
            ),
          ),
          GoRoute(
            path: BrandDetailPage.path,
            builder: (context, state) =>
                BrandDetailPage(brandId: state.pathParameters['brandId']!),
          ),
          GoRoute(
            path: ProviderDetailPage.path,
            builder: (context, state) => ProviderDetailPage(
              providerId: state.pathParameters['providerId']!,
            ),
          ),
          GoRoute(
            path: _customerReservationsPath,
            builder: (context, state) => const CustomerReservationsPage(),
          ),
          GoRoute(
            path: CustomerReservationDetailPage.path,
            builder: (context, state) => CustomerReservationDetailPage(
              reservationId: state.pathParameters['reservationId']!,
            ),
          ),
          GoRoute(
            path: ReservationRequestSuccessPage.path,
            builder: (context, state) => ReservationRequestSuccessPage(
              reservationId: state.pathParameters['reservationId']!,
            ),
          ),
          GoRoute(
            path: QrScanPage.path,
            builder: (context, state) => QrScanPage(
              reservationId: state.pathParameters['reservationId']!,
            ),
          ),
          GoRoute(
            path: QrCompletionResultPage.path,
            builder: (context, state) => QrCompletionResultPage(
              reservationId: state.pathParameters['reservationId']!,
              status: state.pathParameters['status']!,
            ),
          ),
          GoRoute(
            path: ReviewCreatePage.path,
            builder: (context, state) => ReviewCreatePage(
              reservationId: state.pathParameters['reservationId']!,
            ),
          ),
          GoRoute(
            path: ProviderDashboardPage.path,
            builder: (context, state) => const ProviderDashboardPage(),
          ),
          GoRoute(
            path: ProviderQrPage.path,
            builder: (context, state) => const ProviderQrPage(),
          ),
          GoRoute(
            path: _providerReservationsPath,
            builder: (context, state) => const ProviderReservationsPage(),
          ),
          GoRoute(
            path: ProviderReservationDetailPage.path,
            builder: (context, state) => ProviderReservationDetailPage(
              reservationId: state.pathParameters['reservationId']!,
            ),
          ),
          GoRoute(
            path: _providerServicesPath,
            builder: (context, state) => const ProviderServicesPage(),
          ),
          GoRoute(
            path: ProviderServiceFormPage.createPath,
            builder: (context, state) => const ProviderServiceFormPage(),
          ),
          GoRoute(
            path: ProviderServiceFormPage.editPath,
            builder: (context, state) => ProviderServiceFormPage(
              serviceId: state.pathParameters['serviceId']!,
            ),
          ),
          GoRoute(
            path: _providerBrandsPath,
            builder: (context, state) => const ProviderBrandsPage(),
          ),
          GoRoute(
            path: ProviderBrandDetailPage.createPath,
            builder: (context, state) => const ProviderBrandDetailPage(),
          ),
          GoRoute(
            path: ProviderBrandDetailPage.path,
            builder: (context, state) => ProviderBrandDetailPage(
              brandId: state.pathParameters['brandId']!,
            ),
          ),
          GoRoute(
            path: NotificationsPage.path,
            builder: (context, state) => const NotificationsPage(),
          ),
          GoRoute(
            path: ProfilePage.path,
            builder: (context, state) => const ProfilePage(),
          ),
          GoRoute(
            path: SettingsPage.path,
            builder: (context, state) => const SettingsPage(),
          ),
          GoRoute(
            path: RoleSwitchPage.path,
            builder: (context, state) => const RoleSwitchPage(),
          ),
        ],
      ),
    ],
    redirect: (context, state) {
      return _redirectForState(
        location: state.matchedLocation,
        sessionState: sessionState,
      );
    },
  );
});

String? _redirectForState({
  required String location,
  required SessionState sessionState,
}) {
  final isBootstrapping = sessionState.bootstrapStatus != BootstrapStatus.ready;
  final isPublicPath = _isPublicPath(location);

  if (isBootstrapping) {
    return location == SplashPage.path ? null : SplashPage.path;
  }

  final session = sessionState.session;

  if (session == null) {
    if (location == SplashPage.path) {
      return WelcomePage.path;
    }

    return isPublicPath ? null : WelcomePage.path;
  }

  if (session.user.status == UserStatus.closed) {
    return location == AccountClosedPage.path ? null : AccountClosedPage.path;
  }

  if (session.user.status == UserStatus.suspended) {
    return location == AccountSuspendedPage.path
        ? null
        : AccountSuspendedPage.path;
  }

  if (location == SplashPage.path ||
      location == AccountClosedPage.path ||
      location == AccountSuspendedPage.path ||
      isPublicPath) {
    return _homePathForRole(session);
  }

  if (location.startsWith('/provider') &&
      !session.availableRoles.contains(AppRole.provider)) {
    return RoleSwitchPage.path;
  }

  if (session.activeRole == AppRole.customer &&
      location.startsWith('/provider')) {
    return CustomerHomePage.path;
  }

  if (session.activeRole == AppRole.provider &&
      location.startsWith('/customer')) {
    return ProviderDashboardPage.path;
  }

  return null;
}

bool _isPublicPath(String location) {
  return location == WelcomePage.path ||
      location == LoginPage.path ||
      location == RegisterPage.path ||
      location == OtpVerificationPage.path ||
      location == EmailLinkResultPage.path;
}

String _homePathForRole(UserSession session) {
  return session.activeRole == AppRole.provider
      ? ProviderDashboardPage.path
      : CustomerHomePage.path;
}
