// ucr_profile_screen.dart
// Reziphay — Customer (UCR) profile
//
// Author: Vugar Safarzada (@vugarsafarzada)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';

import '../../core/constants/app_colors.dart';
import '../../core/network/network_exception.dart';
import '../../core/theme/app_palette.dart';
import '../../models/auth_models.dart';
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
        backgroundColor: Colors.white,
        title: const Text('Become a Service Provider'),
        content: const Text(
          'This will activate the Service Provider role on your account. '
          'You can switch between Customer and Provider modes at any time.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
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
      // Router will automatically redirect to /uso/incoming
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
      // Router will automatically redirect to /uso/incoming
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
    final user   = ref.watch(appStateProvider).currentUser;
    final primary = context.palette.primary;
    final topPad  = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: AppColors.secondaryBackground,
      body: ListView(
        children: [
          // ── Header ────────────────────────────────────────────────────────
          Container(
            color: AppColors.background,
            padding: EdgeInsets.fromLTRB(20, topPad + 16, 20, 24),
            child: Column(
              children: [
                // Avatar
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      _initials(user?.fullName),
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  user?.fullName ?? '—',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user?.phone ?? '—',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Account info ──────────────────────────────────────────────────
          _SectionCard(
            children: [
              _InfoRow(icon: Iconsax.user,      label: 'Full Name', value: user?.fullName ?? '—'),
              _Divider(),
              _InfoRow(icon: Iconsax.sms,       label: 'Email',     value: user?.email ?? '—'),
              _Divider(),
              _InfoRow(icon: Iconsax.call,      label: 'Phone',     value: user?.phone ?? '—'),
            ],
          ),

          const SizedBox(height: 16),

          // ── Role & Switching ──────────────────────────────────────────────
          _SectionCard(
            children: [
              if (user?.hasUsoRole == true) ...[
                _ActionRow(
                  icon: Iconsax.briefcase,
                  label: 'Switch to Service Provider',
                  color: const Color(0xFF0466C8),
                  loading: _activatingUso,
                  onTap: _switchToUso,
                ),
              ] else ...[
                _ActionRow(
                  icon: Iconsax.briefcase,
                  label: 'Become a Service Provider',
                  color: const Color(0xFF0466C8),
                  loading: _activatingUso,
                  onTap: _activateUso,
                ),
              ],
            ],
          ),

          const SizedBox(height: 16),

          // ── Logout ────────────────────────────────────────────────────────
          _SectionCard(
            children: [
              _ActionRow(
                icon: Iconsax.logout,
                label: 'Log out',
                color: AppColors.error,
                onTap: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: Colors.white,
                      title: const Text('Log out'),
                      content: const Text(
                        'Are you sure you want to log out?',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
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
            ],
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  String _initials(String? name) {
    if (name == null || name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name[0].toUpperCase();
  }
}

// ── Shared widgets ───────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const Divider(
        height: 1,
        indent: 52,
        endIndent: 0,
        color: AppColors.tertiaryBackground,
      );
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textTertiary),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textTertiary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    color: AppColors.textPrimary,
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
    this.loading = false,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool loading;

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
                  fontSize: 15,
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (loading)
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: color,
                ),
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
