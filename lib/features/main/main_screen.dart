// main_screen.dart
// Reziphay
//
// Author: Vugar Safarzada (@vugarsafarzada)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../state/app_state.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  int _selectedIndex = 0;

  static const _tabs = [
    _TabItem(label: 'Explore',       icon: Icons.search_rounded,          route: '/home/explore'),
    _TabItem(label: 'Reservations',  icon: Icons.calendar_month_rounded,  route: '/home/reservations'),
    _TabItem(label: 'Notifications', icon: Icons.notifications_rounded,   route: '/home/notifications'),
    _TabItem(label: 'Profile',       icon: Icons.person_rounded,          route: '/home/profile'),
  ];

  void _onTabTapped(int index) {
    if (index == _selectedIndex) return;
    setState(() => _selectedIndex = index);
    context.go(_tabs[index].route);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onTabTapped,
        backgroundColor: AppColors.background,
        indicatorColor: AppColors.primary.withValues(alpha: 0.12),
        destinations: _tabs.map((tab) => NavigationDestination(
          icon: Icon(tab.icon, color: AppColors.textSecondary),
          selectedIcon: Icon(tab.icon, color: AppColors.primary),
          label: tab.label,
        )).toList(),
      ),
    );
  }
}

class _TabItem {
  const _TabItem({
    required this.label,
    required this.icon,
    required this.route,
  });

  final String label;
  final IconData icon;
  final String route;
}

// MARK: - Placeholder screens (Phase 2+)

class ExplorePlaceholderScreen extends ConsumerWidget {
  const ExplorePlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(appStateProvider).currentUser;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Explore'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () async {
                await ref.read(appStateProvider.notifier).logout();
              },
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.search_rounded,
              size: 64,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: 16),
            Text(
              'Welcome, ${user?.fullName ?? 'there'}!',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Discovery coming in Phase 2',
              style: TextStyle(fontSize: 15, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class ReservationsPlaceholderScreen extends StatelessWidget {
  const ReservationsPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) => const _PlaceholderView(
    icon: Icons.calendar_month_rounded,
    title: 'Reservations',
    subtitle: 'Booking management coming in Phase 3',
  );
}

class NotificationsPlaceholderScreen extends StatelessWidget {
  const NotificationsPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) => const _PlaceholderView(
    icon: Icons.notifications_rounded,
    title: 'Notifications',
    subtitle: 'Notifications coming in Phase 6',
  );
}

class ProfilePlaceholderScreen extends StatelessWidget {
  const ProfilePlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) => const _PlaceholderView(
    icon: Icons.person_rounded,
    title: 'Profile',
    subtitle: 'Profile management coming in Phase 7',
  );
}

class _PlaceholderView extends StatelessWidget {
  const _PlaceholderView({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: AppColors.textTertiary),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 15,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
