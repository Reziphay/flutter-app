// ucr_profile_screen.dart
// Reziphay — Customer (UCR) profile
//
// Author: Vugar Safarzada (@vugarsafarzada)

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';

import '../../core/constants/app_colors.dart';
import '../../core/network/network_exception.dart';
import '../../core/theme/app_dynamic_colors.dart';
import '../../core/theme/app_palette.dart';
import '../../models/user.dart';
import '../../services/auth_service.dart';
import '../../state/app_state.dart';

class UcrProfileScreen extends ConsumerStatefulWidget {
  const UcrProfileScreen({super.key});

  @override
  ConsumerState<UcrProfileScreen> createState() => _UcrProfileScreenState();
}

class _UcrProfileScreenState extends ConsumerState<UcrProfileScreen> {
  bool _activatingUso = false;

  Future<void> _activateUso() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Become a Service Provider'),
        content: const Text(
          'This will activate the Service Provider role on your account. '
          'You can switch between Customer and Provider modes at any time.',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Activate'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _activatingUso = true);
    try {
      final session = await AuthService.instance.activateUso();
      if (!mounted) return;
      ref.read(appStateProvider.notifier).onSessionCreated(user: session.user);
    } on NetworkException catch (e) {
      if (!mounted) return;
      _showError(e.message);
    } catch (_) {
      if (!mounted) return;
      _showError('Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _activatingUso = false);
    }
  }

  Future<void> _switchToUso() async {
    setState(() => _activatingUso = true);
    try {
      final session = await AuthService.instance.switchRole(UserRole.uso);
      if (!mounted) return;
      ref.read(appStateProvider.notifier).onSessionCreated(user: session.user);
    } on NetworkException catch (e) {
      if (!mounted) return;
      _showError(e.message);
    } catch (_) {
      if (!mounted) return;
      _showError('Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _activatingUso = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user    = ref.watch(appStateProvider).currentUser;
    final primary = context.palette.primary;
    final dc      = context.dc;
    final topPad  = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: dc.secondaryBackground,
      body: ListView(
        children: [
          // ── Header ────────────────────────────────────────────────────────
          Container(
            color: dc.background,
            padding: EdgeInsets.fromLTRB(20, topPad + 16, 20, 24),
            child: Column(
              children: [
                _ProfileAvatar(
                  user:    user,
                  primary: primary,
                  size:    80,
                ),
                const SizedBox(height: 12),
                Text(
                  user?.fullName ?? '—',
                  style: TextStyle(
                    fontSize:   20,
                    fontWeight: FontWeight.w700,
                    color:      dc.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user?.phone ?? '—',
                  style: TextStyle(fontSize: 14, color: dc.textSecondary),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Edit Profile ──────────────────────────────────────────────────
          _SectionCard(dc: dc, children: [
            _ActionRow(
              icon:  Iconsax.edit,
              label: 'Edit Profile',
              color: dc.textPrimary,
              dc:    dc,
              onTap: () => context.push('/profile/edit'),
            ),
          ]),

          const SizedBox(height: 16),

          // ── Account info ──────────────────────────────────────────────────
          _SectionCard(dc: dc, children: [
            _InfoRow(icon: Iconsax.user, label: 'Full Name', value: user?.fullName ?? '—', dc: dc),
            _Divider(dc: dc),
            _InfoRow(icon: Iconsax.sms,  label: 'Email',    value: user?.email ?? '—',    dc: dc),
            _Divider(dc: dc),
            _InfoRow(icon: Iconsax.call, label: 'Phone',    value: user?.phone ?? '—',    dc: dc),
          ]),

          const SizedBox(height: 16),

          // ── Favorites (UCR-only) ──────────────────────────────────────────
          _SectionCard(dc: dc, children: [
            _ActionRow(
              icon:  Iconsax.heart,
              label: 'My Favorites',
              color: AppColors.error,
              dc:    dc,
              onTap: () => context.push('/ucr/favorites'),
            ),
          ]),

          const SizedBox(height: 16),

          // ── Role & Switching ──────────────────────────────────────────────
          _SectionCard(dc: dc, children: [
            if (user?.hasUsoRole == true) ...[
              _ActionRow(
                icon:    Iconsax.briefcase,
                label:   'Switch to Service Provider',
                color:   const Color(0xFF0466C8),
                loading: _activatingUso,
                dc:      dc,
                onTap:   _switchToUso,
              ),
            ] else ...[
              _ActionRow(
                icon:    Iconsax.briefcase,
                label:   'Become a Service Provider',
                color:   const Color(0xFF0466C8),
                loading: _activatingUso,
                dc:      dc,
                onTap:   _activateUso,
              ),
            ],
          ]),

          const SizedBox(height: 16),

          // ── Settings ──────────────────────────────────────────────────────
          _SectionCard(dc: dc, children: [
            _ActionRow(
              icon:  Iconsax.setting,
              label: 'Settings',
              color: dc.textPrimary,
              dc:    dc,
              onTap: () => context.push('/settings'),
            ),
          ]),

          const SizedBox(height: 16),

          // ── Logout ────────────────────────────────────────────────────────
          _SectionCard(dc: dc, children: [
            _ActionRow(
              icon:  Iconsax.logout,
              label: 'Log out',
              color: AppColors.error,
              dc:    dc,
              onTap: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Log out'),
                    content: const Text(
                      'Are you sure you want to log out?',
                      style: TextStyle(fontSize: 14),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(true),
                        child: const Text(
                          'Log out',
                          style: TextStyle(color: AppColors.error),
                        ),
                      ),
                    ],
                  ),
                );
                if (confirmed == true) {
                  ref.read(appStateProvider.notifier).logout();
                }
              },
            ),
          ]),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

}

// ── Profile Avatar (shows photo if set, else initials) ────────────────────────

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({
    required this.user,
    required this.primary,
    required this.size,
  });

  final dynamic user;
  final Color  primary;
  final double size;

  String _initials(String? name) {
    if (name == null || name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final avatarUrl = user?.avatarUrl as String?;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      clipBehavior: Clip.antiAlias,
      child: avatarUrl != null && avatarUrl.isNotEmpty
          ? CachedNetworkImage(
              imageUrl: avatarUrl,
              fit: BoxFit.cover,
              placeholder: (_, __) => const SizedBox.shrink(),
              errorWidget: (_, __, ___) => Center(
                child: Text(
                  _initials(user?.fullName as String?),
                  style: TextStyle(
                    fontSize:   size * 0.35,
                    fontWeight: FontWeight.w700,
                    color:      primary,
                  ),
                ),
              ),
            )
          : Center(
              child: Text(
                _initials(user?.fullName as String?),
                style: TextStyle(
                  fontSize:   size * 0.35,
                  fontWeight: FontWeight.w700,
                  color:      primary,
                ),
              ),
            ),
    );
  }
}

// ── Shared widgets ────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.children, required this.dc});
  final List<Widget>     children;
  final AppDynamicColors dc;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: dc.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color:     Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset:    const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider({required this.dc});
  final AppDynamicColors dc;

  @override
  Widget build(BuildContext context) => Divider(
        height:    1,
        indent:    52,
        endIndent: 0,
        color:     dc.divider,
      );
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.dc,
  });

  final IconData         icon;
  final String           label;
  final String           value;
  final AppDynamicColors dc;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 20, color: dc.textTertiary),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize:   11,
                    color:      dc.textTertiary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize:   15,
                    color:      dc.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    required this.dc,
    this.loading = false,
  });

  final IconData         icon;
  final String           label;
  final Color            color;
  final VoidCallback     onTap;
  final AppDynamicColors dc;
  final bool             loading;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: loading ? null : onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize:   15,
                  color:      color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (loading)
              SizedBox(
                width:  18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: color),
              )
            else
              Icon(Icons.chevron_right_rounded,
                  size: 20, color: color.withValues(alpha: 0.5)),
          ],
        ),
      ),
    );
  }
}
