import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:reziphay_mobile/app/theme/app_colors.dart';
import 'package:reziphay_mobile/features/common/presentation/pages/notifications_page.dart';
import 'package:reziphay_mobile/features/common/presentation/pages/profile_page.dart';
import 'package:reziphay_mobile/features/common/presentation/pages/settings_page.dart';
import 'package:reziphay_mobile/features/customer/presentation/pages/customer_home_page.dart';
import 'package:reziphay_mobile/features/customer/presentation/pages/search_page.dart';
import 'package:reziphay_mobile/features/provider/presentation/pages/provider_dashboard_page.dart';
import 'package:reziphay_mobile/features/role_switch/presentation/pages/role_switch_page.dart';
import 'package:reziphay_mobile/shared/models/app_role.dart';
import 'package:reziphay_mobile/core/auth/session_controller.dart';

const _customerReservationsPath = '/customer/reservations';
const _providerReservationsPath = '/provider/reservations';
const _providerServicesPath = '/provider/services';
const _providerBrandsPath = '/provider/brands';

class AppShell extends ConsumerWidget {
  const AppShell({required this.location, required this.child, super.key});

  final String location;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeRole = ref.watch(
      sessionControllerProvider.select(
        (state) => state.session?.activeRole ?? AppRole.customer,
      ),
    );

    final items = activeRole == AppRole.provider
        ? _providerItems
        : _customerItems;

    final navigationLocation = switch (location) {
      SettingsPage.path => ProfilePage.path,
      RoleSwitchPage.path => ProfilePage.path,
      _ when location.startsWith('/customer/reservations') =>
        _customerReservationsPath,
      _ when location.startsWith('/reviews/') => _customerReservationsPath,
      _ when location.startsWith('/provider/reservations') =>
        _providerReservationsPath,
      _ when location.startsWith('/provider/qr') => ProviderDashboardPage.path,
      _
          when location.startsWith('/customer/search') ||
              location.startsWith('/customer/category/') ||
              location.startsWith('/customer/service/') ||
              location.startsWith('/customer/brand/') ||
              location.startsWith('/customer/provider/') =>
        SearchPage.path,
      _ => location,
    };

    final selectedIndex = items.indexWhere(
      (item) =>
          navigationLocation == item.path ||
          navigationLocation.startsWith('${item.path}/'),
    );

    final currentIndex = selectedIndex < 0 ? 0 : selectedIndex;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        destinations: items
            .map(
              (item) => NavigationDestination(
                icon: Icon(item.icon),
                selectedIcon: Icon(item.selectedIcon),
                label: item.label,
              ),
            )
            .toList(),
        onDestinationSelected: (index) => context.go(items[index].path),
      ),
    );
  }
}

class _ShellItem {
  const _ShellItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.path,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final String path;
}

const _customerItems = [
  _ShellItem(
    label: 'Home',
    icon: Icons.home_outlined,
    selectedIcon: Icons.home_rounded,
    path: CustomerHomePage.path,
  ),
  _ShellItem(
    label: 'Search',
    icon: Icons.search_outlined,
    selectedIcon: Icons.search_rounded,
    path: SearchPage.path,
  ),
  _ShellItem(
    label: 'Reservations',
    icon: Icons.calendar_month_outlined,
    selectedIcon: Icons.calendar_month,
    path: _customerReservationsPath,
  ),
  _ShellItem(
    label: 'Notifications',
    icon: Icons.notifications_outlined,
    selectedIcon: Icons.notifications,
    path: NotificationsPage.path,
  ),
  _ShellItem(
    label: 'Profile',
    icon: Icons.person_outline,
    selectedIcon: Icons.person,
    path: ProfilePage.path,
  ),
];

const _providerItems = [
  _ShellItem(
    label: 'Dashboard',
    icon: Icons.grid_view_outlined,
    selectedIcon: Icons.grid_view_rounded,
    path: ProviderDashboardPage.path,
  ),
  _ShellItem(
    label: 'Reservations',
    icon: Icons.calendar_today_outlined,
    selectedIcon: Icons.calendar_today,
    path: _providerReservationsPath,
  ),
  _ShellItem(
    label: 'Services',
    icon: Icons.design_services_outlined,
    selectedIcon: Icons.design_services,
    path: _providerServicesPath,
  ),
  _ShellItem(
    label: 'Brands',
    icon: Icons.storefront_outlined,
    selectedIcon: Icons.storefront,
    path: _providerBrandsPath,
  ),
  _ShellItem(
    label: 'Profile',
    icon: Icons.person_outline,
    selectedIcon: Icons.person,
    path: ProfilePage.path,
  ),
];
