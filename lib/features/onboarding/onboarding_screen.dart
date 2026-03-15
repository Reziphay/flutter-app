// onboarding_screen.dart
// Reziphay
//
// Author: Vugar Safarzada (@vugarsafarzada)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/app_dynamic_colors.dart';
import '../../models/user.dart';
import '../../state/app_state.dart';

class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: context.dc.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const Spacer(),
              const _HeroSection(),
              const Spacer(),
              _RoleCardsSection(onRoleSelected: (role) {
                ref.read(appStateProvider.notifier).selectRole(role);
                context.push('/auth/phone');
              }),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}

// MARK: - Hero

class _HeroSection extends StatelessWidget {
  const _HeroSection();

  @override
  Widget build(BuildContext context) {
    final dc = context.dc;
    return Column(
      children: [
        Text(
          'Reziphay.',
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: dc.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Book smarter, live better',
          style: TextStyle(
            fontSize: 16,
            color: dc.textSecondary,
          ),
        ),
      ],
    );
  }
}

// MARK: - Role Cards

class _RoleCardsSection extends StatelessWidget {
  const _RoleCardsSection({required this.onRoleSelected});
  final void Function(UserRole) onRoleSelected;

  @override
  Widget build(BuildContext context) {
    final dc = context.dc;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'How would you like to continue?',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: dc.textSecondary,
          ),
        ),
        const SizedBox(height: 16),
        _RoleCard(
          icon: Icons.person_rounded,
          title: "I'm a Customer",
          subtitle: 'Discover and book services near you',
          color: const Color(0xFFC71F37),
          onTap: () => onRoleSelected(UserRole.ucr),
        ),
        const SizedBox(height: 12),
        _RoleCard(
          icon: Icons.work_rounded,
          title: "I'm a Service Provider",
          subtitle: 'Manage your services and bookings',
          color: const Color(0xFF0466C8),
          onTap: () => onRoleSelected(UserRole.uso),
        ),
      ],
    );
  }
}

class _RoleCard extends StatefulWidget {
  const _RoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  State<_RoleCard> createState() => _RoleCardState();
}

class _RoleCardState extends State<_RoleCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final dc = context.dc;
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: dc.cardBackground,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: dc.divider),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: widget.color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(widget.icon, color: widget.color, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: dc.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: dc.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: dc.textTertiary,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
