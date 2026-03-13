import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:reziphay_mobile/app/theme/app_colors.dart';
import 'package:reziphay_mobile/app/theme/app_spacing.dart';
import 'package:reziphay_mobile/core/widgets/app_card.dart';
import 'package:reziphay_mobile/core/widgets/empty_state.dart';
import 'package:reziphay_mobile/core/widgets/section_header.dart';
import 'package:reziphay_mobile/core/widgets/status_pill.dart';
import 'package:reziphay_mobile/features/discovery/data/discovery_repository.dart';
import 'package:reziphay_mobile/features/reservations/data/reservations_repository.dart';
import 'package:reziphay_mobile/features/reservations/presentation/pages/provider_reservation_detail_page.dart';
import 'package:reziphay_mobile/features/reservations/presentation/pages/provider_reservations_page.dart';
import 'package:reziphay_mobile/features/reservations/presentation/widgets/reservation_widgets.dart';

class ProviderDashboardPage extends ConsumerWidget {
  const ProviderDashboardPage({super.key});

  static const path = '/provider/dashboard';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final providerId = ref.watch(activeProviderContextProvider);
    final dashboardAsync = ref.watch(providerDashboardProvider);
    final providerAsync = ref.watch(providerDetailProvider(providerId));

    return dashboardAsync.when(
      data: (dashboard) => providerAsync.when(
        data: (providerDetail) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(providerDashboardProvider);
            ref.invalidate(providerReservationsProvider);
            await ref.read(providerDashboardProvider.future);
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.xxxl,
            ),
            children: [
              Text(
                providerDetail.summary.name,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                providerDetail.summary.headline,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
              ),
              const SizedBox(height: AppSpacing.lg),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text('Urgent manual response window'),
                        ),
                        StatusPill(
                          label: dashboard.pendingCount == 0
                              ? 'Clear'
                              : '${dashboard.pendingCount} waiting',
                          tone: dashboard.pendingCount == 0
                              ? StatusPillTone.success
                              : StatusPillTone.warning,
                          icon: dashboard.pendingCount == 0
                              ? Icons.check_circle_outline
                              : Icons.timer_outlined,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Pending manual approvals and customer change proposals should never disappear inside a generic list.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      label: 'Pending',
                      value: dashboard.pendingCount.toString().padLeft(2, '0'),
                      tone: StatusPillTone.warning,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _StatCard(
                      label: 'Today',
                      value: dashboard.todayReservations.length
                          .toString()
                          .padLeft(2, '0'),
                      tone: StatusPillTone.info,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      label: 'Services',
                      value: dashboard.serviceCount.toString().padLeft(2, '0'),
                      tone: StatusPillTone.neutral,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _StatCard(
                      label: 'Brands',
                      value: dashboard.brandCount.toString().padLeft(2, '0'),
                      tone: StatusPillTone.neutral,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              const SectionHeader(title: 'Urgent requests'),
              const SizedBox(height: AppSpacing.md),
              if (dashboard.pendingRequests.isEmpty)
                const EmptyState(
                  title: 'No urgent requests',
                  description:
                      'Incoming approvals and customer change requests will appear here.',
                )
              else
                ...dashboard.pendingRequests
                    .take(3)
                    .map(
                      (reservation) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: ReservationCard(
                          summary: reservation,
                          trailingLabel: reservation.customerName,
                          onTap: () => context.go(
                            ProviderReservationDetailPage.location(
                              reservation.id,
                            ),
                          ),
                          onExpire: () {
                            ref.invalidate(providerDashboardProvider);
                            ref.invalidate(providerReservationsProvider);
                          },
                        ),
                      ),
                    ),
              const SizedBox(height: AppSpacing.xl),
              const SectionHeader(title: 'Today'),
              const SizedBox(height: AppSpacing.md),
              if (dashboard.todayReservations.isEmpty)
                const EmptyState(
                  title: 'Nothing scheduled for today',
                  description:
                      'Today\'s reservations will appear here once appointments are confirmed.',
                )
              else
                ...dashboard.todayReservations
                    .take(3)
                    .map(
                      (reservation) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: ReservationCard(
                          summary: reservation,
                          trailingLabel: reservation.customerName,
                          onTap: () => context.go(
                            ProviderReservationDetailPage.location(
                              reservation.id,
                            ),
                          ),
                        ),
                      ),
                    ),
              const SizedBox(height: AppSpacing.xl),
              const SectionHeader(title: 'Quick actions'),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.md,
                children: [
                  _QuickActionCard(
                    title: 'Review reservations',
                    description:
                        'Open the full queue for incoming and upcoming work.',
                    icon: Icons.calendar_today_outlined,
                    onTap: () => context.go(ProviderReservationsPage.path),
                  ),
                  _QuickActionCard(
                    title: 'QR guidance',
                    description:
                        'Signed QR completion stays blocked until backend wiring exists.',
                    icon: Icons.qr_code_2_outlined,
                    onTap: () => showReservationMessageSheet(
                      context,
                      title: 'Provider QR',
                      message:
                          'QR completion must stay backend-signed, so the dashboard only exposes the entry point and guidance for now.',
                    ),
                  ),
                  _QuickActionCard(
                    title: 'Services',
                    description:
                        'Service creation and editing are still queued for Phase 4.',
                    icon: Icons.design_services_outlined,
                    onTap: () => context.go('/provider/services'),
                  ),
                  _QuickActionCard(
                    title: 'Brands',
                    description:
                        'Brand management lands after reservation operations are stable.',
                    icon: Icons.storefront_outlined,
                    onTap: () => context.go('/provider/brands'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              AppCard(
                color: AppColors.surfaceSoft,
                child: Text(
                  'Confirmed today: ${dashboard.confirmedTodayCount}. Response reliability matters as much as raw reservation volume in this product.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
                ),
              ),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: EmptyState(
            title: 'Could not load provider profile',
            description: error.toString(),
          ),
        ),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: EmptyState(
          title: 'Could not load dashboard',
          description: error.toString(),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.tone,
  });

  final String label;
  final String value;
  final StatusPillTone tone;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StatusPill(label: label, tone: tone),
          const SizedBox(height: AppSpacing.md),
          Text(value, style: Theme.of(context).textTheme.headlineMedium),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String description;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width:
          (MediaQuery.of(context).size.width -
              (AppSpacing.lg * 2) -
              AppSpacing.md) /
          2,
      child: AppCard(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(height: AppSpacing.md),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              description,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
