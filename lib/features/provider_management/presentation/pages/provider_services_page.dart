import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:reziphay_mobile/app/theme/app_colors.dart';
import 'package:reziphay_mobile/app/theme/app_spacing.dart';
import 'package:reziphay_mobile/core/widgets/app_button.dart';
import 'package:reziphay_mobile/core/widgets/app_card.dart';
import 'package:reziphay_mobile/core/widgets/empty_state.dart';
import 'package:reziphay_mobile/core/widgets/status_pill.dart';
import 'package:reziphay_mobile/features/discovery/models/discovery_models.dart';
import 'package:reziphay_mobile/features/provider_management/data/provider_management_repository.dart';
import 'package:reziphay_mobile/features/provider_management/models/provider_management_models.dart';
import 'package:reziphay_mobile/features/provider_management/presentation/pages/provider_service_form_page.dart';
import 'package:reziphay_mobile/features/provider_management/presentation/widgets/provider_management_widgets.dart';

class ProviderServicesPage extends ConsumerWidget {
  const ProviderServicesPage({super.key});

  static const path = '/provider/services';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final servicesAsync = ref.watch(providerManagedServicesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Services'),
        actions: [
          IconButton(
            onPressed: () => context.go(ProviderServiceFormPage.createPath),
            icon: const Icon(Icons.add_circle_outline),
          ),
        ],
      ),
      body: servicesAsync.when(
        data: (data) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(providerManagedServicesProvider);
            await ref.read(providerManagedServicesProvider.future);
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.xxxl,
            ),
            children: [
              Row(
                children: [
                  Expanded(
                    child: ManagementStatCard(
                      label: 'Active',
                      value: data.activeCount.toString().padLeft(2, '0'),
                      tone: StatusPillTone.success,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: ManagementStatCard(
                      label: 'Manual',
                      value: data.manualApprovalCount.toString().padLeft(
                        2,
                        '0',
                      ),
                      tone: StatusPillTone.warning,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: ManagementStatCard(
                      label: 'Brand linked',
                      value: data.brandLinkedCount.toString().padLeft(2, '0'),
                      tone: StatusPillTone.info,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: ManagementStatCard(
                      label: 'Total',
                      value: data.services.length.toString().padLeft(2, '0'),
                      tone: StatusPillTone.neutral,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                'Keep provider tooling flexible. Services should expose enough operational control without turning the app into a calendar admin suite.',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
              ),
              const SizedBox(height: AppSpacing.xl),
              if (data.services.isEmpty)
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const EmptyState(
                        title: 'No services yet',
                        description:
                            'Create the first service with availability, approval mode, and reservation settings.',
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppButton(
                        label: 'Create service',
                        icon: Icons.add,
                        onPressed: () =>
                            context.go(ProviderServiceFormPage.createPath),
                      ),
                    ],
                  ),
                )
              else
                ...data.services.map(
                  (service) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: _ProviderServiceCard(service: service),
                  ),
                ),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: EmptyState(
            title: 'Could not load services',
            description: error.toString(),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go(ProviderServiceFormPage.createPath),
        icon: const Icon(Icons.add),
        label: const Text('Create'),
      ),
    );
  }
}

class _ProviderServiceCard extends StatelessWidget {
  const _ProviderServiceCard({required this.service});

  final ProviderManagedServiceListItem service;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: () =>
          context.go(ProviderServiceFormPage.editLocation(service.summary.id)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      service.summary.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      [
                        service.summary.categoryName,
                        service.summary.brandName ?? 'Self branded',
                      ].join(' · '),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              StatusPill(
                label: service.summary.priceLabel,
                tone: StatusPillTone.neutral,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              StatusPill(
                label: service.summary.approvalMode.label,
                tone: service.summary.approvalMode == ApprovalMode.manual
                    ? StatusPillTone.warning
                    : StatusPillTone.success,
              ),
              StatusPill(
                label: service.serviceType.label,
                tone: StatusPillTone.info,
              ),
              StatusPill(
                label: service.summary.isAvailable ? 'Available' : 'Paused',
                tone: service.summary.isAvailable
                    ? StatusPillTone.success
                    : StatusPillTone.neutral,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            service.summary.nextAvailabilityLabel,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Waiting time ${service.waitingTimeMinutes} min · Lead time ${service.leadTimeHours}h · ${service.exceptionCount} exceptions',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}
