// onboarding_screen.dart
// Reziphay
//
// Author: Vugar Safarzada (@vugarsafarzada)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../models/user.dart';
import '../../state/app_state.dart';

class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.darkBg, AppColors.darkBgEnd],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const Spacer(),
                _HeroSection(),
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
      ),
    );
  }
}

// MARK: - Hero

class _HeroSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.calendar_month_rounded,
            size: 44,
            color: AppColors.primaryLight,
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Reziphay',
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Book smarter, live better',
          style: TextStyle(
            fontSize: 16,
            color: Colors.white.withValues(alpha: 0.6),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'How would you like to continue?',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.white.withValues(alpha: 0.5),
          ),
        ),
        const SizedBox(height: 16),
        _RoleCard(
          icon: Icons.person_rounded,
          title: "I'm a Customer",
          subtitle: 'Discover and book services near you',
          color: const Color(0xFF4A8FFF),
          onTap: () => onRoleSelected(UserRole.ucr),
        ),
        const SizedBox(height: 12),
        _RoleCard(
          icon: Icons.work_rounded,
          title: "I'm a Service Provider",
          subtitle: 'Manage your services and bookings',
          color: AppColors.primary,
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
    return GestureDetector(
      onTapDown:   (_) => setState(() => _pressed = true),
      onTapUp:     (_) => setState(() => _pressed = false),
      onTapCancel: ()  => setState(() => _pressed = false),
      onTap:       widget.onTap,
      child: AnimatedScale(
        scale:    _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.10),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: widget.color.withValues(alpha: 0.15),
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
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.white.withValues(alpha: 0.3),
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
