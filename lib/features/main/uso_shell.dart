// uso_shell.dart
// Reziphay — Service Provider (USO) navigation shell
//
// Author: Vugar Safarzada (@vugarsafarzada)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_dynamic_colors.dart';
import '../../core/theme/app_palette.dart';

class UsoShell extends ConsumerStatefulWidget {
  const UsoShell({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<UsoShell> createState() => _UsoShellState();
}

class _UsoShellState extends ConsumerState<UsoShell> {
  static const _tabRoutes = [
    '/uso/incoming',
    '/uso/services',
    '/uso/brands',
    '/uso/notifications',
    '/uso/profile',
  ];
  static const _tabIcons = [
    Iconsax.calendar_tick,
    Iconsax.briefcase,
    Iconsax.shop,
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
    final l10n    = context.l10n;
    final primary = context.palette.primary;
    final dc = context.dc;

    final tabLabels = [
      l10n.navIncoming,
      l10n.navMyServices,
      l10n.navMyBrands,
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

class UsoNotificationsPlaceholder extends StatelessWidget {
  const UsoNotificationsPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final dc = context.dc;
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Iconsax.notification, size: 64, color: dc.textTertiary),
            const SizedBox(height: 16),
            Text(l10n.navNotifications, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: dc.textPrimary)),
            const SizedBox(height: 8),
            Text(l10n.notificationsComingSoon, style: TextStyle(fontSize: 15, color: dc.textSecondary)),
          ],
        ),
      ),
    );
  }
}

