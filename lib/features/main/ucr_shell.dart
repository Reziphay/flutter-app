// ucr_shell.dart
// Reziphay — Customer (UCR) navigation shell
//
// Author: Vugar Safarzada (@vugarsafarzada)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_dynamic_colors.dart';
import '../../core/theme/app_palette.dart';

class UcrShell extends ConsumerStatefulWidget {
  const UcrShell({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<UcrShell> createState() => _UcrShellState();
}

class _UcrShellState extends ConsumerState<UcrShell> {
  static const _tabRoutes = [
    '/ucr/explore',
    '/ucr/reservations',
    '/ucr/notifications',
    '/ucr/profile',
  ];
  static const _tabIcons = [
    Iconsax.search_normal,
    Iconsax.calendar,
    Iconsax.notification,
    Iconsax.user,
  ];

  int _selectedIndex = 0;

  void _onTabTapped(int index) {
    if (index == _selectedIndex) return;
    setState(() => _selectedIndex = index);
    context.go(_tabRoutes[index]);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncIndex();
  }

  void _syncIndex() {
    final loc = GoRouterState.of(context).matchedLocation;
    final idx = _tabRoutes.indexWhere((r) => loc.startsWith(r));
    if (idx != -1 && idx != _selectedIndex) {
      setState(() => _selectedIndex = idx);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n   = context.l10n;
    final primary = context.palette.primary;
    final dc = context.dc;

    final tabLabels = [
      l10n.navExplore,
      l10n.navReservations,
      l10n.navNotifications,
      l10n.navProfile,
    ];

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: NavigationBar(
        height: 60,
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onTabTapped,
        backgroundColor: dc.background,
        indicatorColor: Colors.transparent,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
        destinations: List.generate(_tabRoutes.length, (i) => NavigationDestination(
          icon:         Icon(_tabIcons[i], color: dc.textSecondary),
          selectedIcon: Icon(_tabIcons[i], color: primary),
          label:        tabLabels[i],
        )),
      ),
    );
  }
}

// ── Placeholder screens ────────────────────────────────────────────────────

class UcrNotificationsPlaceholder extends StatelessWidget {
  const UcrNotificationsPlaceholder({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: _PlaceholderView(
        icon: Iconsax.notification,
        title: context.l10n.navNotifications,
        subtitle: context.l10n.notificationsComingSoon,
      ),
    ),
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
    final dc = context.dc;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 64, color: dc.textTertiary),
        const SizedBox(height: 16),
        Text(title, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: dc.textPrimary)),
        const SizedBox(height: 8),
        Text(subtitle, style: TextStyle(fontSize: 15, color: dc.textSecondary)),
      ],
    );
  }
}
