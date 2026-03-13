import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:reziphay_mobile/app/theme/app_colors.dart';
import 'package:reziphay_mobile/app/theme/app_spacing.dart';
import 'package:reziphay_mobile/core/widgets/app_button.dart';
import 'package:reziphay_mobile/core/widgets/app_card.dart';
import 'package:reziphay_mobile/core/widgets/empty_state.dart';
import 'package:reziphay_mobile/core/widgets/status_pill.dart';
import 'package:reziphay_mobile/features/provider_management/data/provider_management_repository.dart';
import 'package:reziphay_mobile/features/provider_management/models/provider_management_models.dart';
import 'package:reziphay_mobile/features/provider_management/presentation/pages/provider_brand_detail_page.dart';
import 'package:reziphay_mobile/features/provider_management/presentation/widgets/provider_management_widgets.dart';

class ProviderBrandsPage extends ConsumerWidget {
  const ProviderBrandsPage({super.key});

  static const path = '/provider/brands';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brandsAsync = ref.watch(providerManagedBrandsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Brands'),
        actions: [
          IconButton(
            onPressed: () => context.go(ProviderBrandDetailPage.createPath),
            icon: const Icon(Icons.add_circle_outline),
          ),
        ],
      ),
      body: brandsAsync.when(
        data: (data) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(providerManagedBrandsProvider);
            await ref.read(providerManagedBrandsProvider.future);
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
                      label: 'Brands',
                      value: data.brands.length.toString().padLeft(2, '0'),
                      tone: StatusPillTone.neutral,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: ManagementStatCard(
                      label: 'Services',
                      value: data.totalServiceCount.toString().padLeft(2, '0'),
                      tone: StatusPillTone.info,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              ManagementStatCard(
                label: 'Join requests',
                value: data.pendingJoinRequestCount.toString().padLeft(2, '0'),
                tone: data.pendingJoinRequestCount == 0
                    ? StatusPillTone.success
                    : StatusPillTone.warning,
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                'Brands should stay operationally useful: clear positioning, visible services, and lightweight join-request handling.',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
              ),
              const SizedBox(height: AppSpacing.xl),
              if (data.brands.isEmpty)
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const EmptyState(
                        title: 'No brands yet',
                        description:
                            'Create a brand when you want grouped service identity instead of self-branded services.',
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppButton(
                        label: 'Create brand',
                        icon: Icons.add,
                        onPressed: () =>
                            context.go(ProviderBrandDetailPage.createPath),
                      ),
                    ],
                  ),
                )
              else
                ...data.brands.map(
                  (brand) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: _ProviderBrandCard(brand: brand),
                  ),
                ),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: EmptyState(
            title: 'Could not load brands',
            description: error.toString(),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go(ProviderBrandDetailPage.createPath),
        icon: const Icon(Icons.add),
        label: const Text('Create'),
      ),
    );
  }
}

class _ProviderBrandCard extends StatelessWidget {
  const _ProviderBrandCard({required this.brand});

  final ProviderManagedBrandListItem brand;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: () =>
          context.go(ProviderBrandDetailPage.location(brand.summary.id)),
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
                      brand.summary.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      brand.summary.headline,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              if (brand.logoLabel != null)
                StatusPill(label: brand.logoLabel!, tone: StatusPillTone.info),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              StatusPill(
                label: '${brand.summary.serviceCount} services',
                tone: StatusPillTone.neutral,
              ),
              StatusPill(
                label: '${brand.summary.memberCount} members',
                tone: StatusPillTone.neutral,
              ),
              StatusPill(
                label: brand.summary.openNow ? 'Open now' : 'Closed',
                tone: brand.summary.openNow
                    ? StatusPillTone.success
                    : StatusPillTone.warning,
              ),
              if (brand.joinRequestCount > 0)
                StatusPill(
                  label: '${brand.joinRequestCount} join requests',
                  tone: StatusPillTone.warning,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            brand.summary.addressLine,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}
