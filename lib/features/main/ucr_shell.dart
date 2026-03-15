// ucr_shell.dart
// Reziphay — Customer (UCR) navigation shell
//
// Author: Vugar Safarzada (@vugarsafarzada)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/app_palette.dart';
import '../../state/app_state.dart';

class UcrShell extends ConsumerStatefulWidget {
  const UcrShell({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<UcrShell> createState() => _UcrShellState();
}

class _UcrShellState extends ConsumerState<UcrShell> {
  static const _tabs = [
    _TabItem(label: 'Explore',       icon: Iconsax.search_normal, route: '/ucr/explore'),
    _TabItem(label: 'Reservations',  icon: Iconsax.calendar,      route: '/ucr/reservations'),
    _TabItem(label: 'Notifications', icon: Iconsax.notification,  route: '/ucr/notifications'),
    _TabItem(label: 'Profile',       icon: Iconsax.user,          route: '/ucr/profile'),
  ];

  int _selectedIndex = 0;

  void _onTabTapped(int index) {
    if (index == _selectedIndex) return;
    setState(() => _selectedIndex = index);
    context.go(_tabs[index].route);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncIndex();
  }

  void _syncIndex() {
    final loc = GoRouterState.of(context).matchedLocation;
    final idx = _tabs.indexWhere((t) => loc.startsWith(t.route));
    if (idx != -1 && idx != _selectedIndex) {
      setState(() => _selectedIndex = idx);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = context.palette.primary;

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: NavigationBar(
        height: 60,
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onTabTapped,
        backgroundColor: AppColors.background,
        indicatorColor: Colors.transparent,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
        destinations: _tabs.map((tab) => NavigationDestination(
          icon:         Icon(tab.icon, color: AppColors.textSecondary),
          selectedIcon: Icon(tab.icon, color: primary),
          label:        tab.label,
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

// ── Placeholder screens ────────────────────────────────────────────────────

class UcrNotificationsPlaceholder extends StatelessWidget {
  const UcrNotificationsPlaceholder({super.key});

  @override
  Widget build(BuildContext context) => const Scaffold(
    body: Center(
      child: _PlaceholderView(
        icon: Iconsax.notification,
        title: 'Notifications',
        subtitle: 'Coming in Phase 7',
      ),
    ),
  );
}

class UcrProfilePlaceholder extends ConsumerWidget {
  const UcrProfilePlaceholder({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(appStateProvider).currentUser;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Iconsax.logout),
            tooltip: 'Logout',
            onPressed: () => ref.read(appStateProvider.notifier).logout(),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _PlaceholderView(
              icon: Iconsax.user,
              title: 'Profile',
              subtitle: 'Coming in Phase 7',
            ),
            if (user?.fullName != null) ...[
              const SizedBox(height: 8),
              Text(user!.fullName!, style: const TextStyle(color: AppColors.textSecondary)),
            ],
          ],
        ),
      ),
    );
  }
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 64, color: AppColors.textTertiary),
        const SizedBox(height: 16),
        Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(subtitle, style: const TextStyle(fontSize: 15, color: AppColors.textSecondary)),
      ],
    );
  }
}
