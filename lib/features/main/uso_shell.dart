// uso_shell.dart
// Reziphay — Service Provider (USO) navigation shell
//
// Author: Vugar Safarzada (@vugarsafarzada)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/app_dynamic_colors.dart';
import '../../core/theme/app_palette.dart';

class UsoShell extends ConsumerStatefulWidget {
  const UsoShell({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<UsoShell> createState() => _UsoShellState();
}

class _UsoShellState extends ConsumerState<UsoShell> {
  static const _tabs = [
    _TabItem(label: 'Incoming',      icon: Iconsax.calendar_tick,   route: '/uso/incoming'),
    _TabItem(label: 'My Services',   icon: Iconsax.briefcase,       route: '/uso/services'),
    _TabItem(label: 'Notifications', icon: Iconsax.notification,    route: '/uso/notifications'),
    _TabItem(label: 'Profile',       icon: Iconsax.user,            route: '/uso/profile'),
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

    final dc = context.dc;

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: NavigationBar(
        height: 60,
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onTabTapped,
        backgroundColor: dc.background,
        indicatorColor: Colors.transparent,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
        destinations: _tabs.map((tab) => NavigationDestination(
          icon:         Icon(tab.icon, color: dc.textSecondary),
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

class UsoNotificationsPlaceholder extends StatelessWidget {
  const UsoNotificationsPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    final dc = context.dc;
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Iconsax.notification, size: 64, color: dc.textTertiary),
            const SizedBox(height: 16),
            Text('Notifications', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: dc.textPrimary)),
            const SizedBox(height: 8),
            Text('Coming in Phase 7', style: TextStyle(fontSize: 15, color: dc.textSecondary)),
          ],
        ),
      ),
    );
  }
}

