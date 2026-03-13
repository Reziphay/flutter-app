import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:reziphay_mobile/app/theme/app_colors.dart';
import 'package:reziphay_mobile/app/theme/app_spacing.dart';
import 'package:reziphay_mobile/core/auth/session_controller.dart';
import 'package:reziphay_mobile/core/widgets/app_card.dart';
import 'package:reziphay_mobile/core/widgets/empty_state.dart';
import 'package:reziphay_mobile/core/widgets/section_header.dart';
import 'package:reziphay_mobile/core/widgets/status_pill.dart';
import 'package:reziphay_mobile/features/customer/presentation/pages/search_page.dart';
import 'package:reziphay_mobile/features/discovery/data/discovery_repository.dart';
import 'package:reziphay_mobile/features/discovery/presentation/pages/brand_detail_page.dart';
import 'package:reziphay_mobile/features/discovery/presentation/pages/category_detail_page.dart';
import 'package:reziphay_mobile/features/discovery/presentation/pages/provider_detail_page.dart';
import 'package:reziphay_mobile/features/discovery/presentation/pages/service_detail_page.dart';
import 'package:reziphay_mobile/features/discovery/presentation/widgets/discovery_cards.dart';

class CustomerHomePage extends ConsumerWidget {
  const CustomerHomePage({super.key});

  static const path = '/customer/home';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionControllerProvider).session;
    final name = session?.user.fullName.split(' ').first ?? 'there';
    final textTheme = Theme.of(context).textTheme;
    final homeAsync = ref.watch(customerHomeProvider);

    return homeAsync.when(
      data: (home) => ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.xxxl,
        ),
        children: [
          Text('Good to see you, $name', style: textTheme.headlineMedium),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Discovery should feel curated, useful, and calm even when location access is unavailable.',
            style: textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppCard(
            onTap: () => context.go(SearchPage.path),
            child: Row(
              children: [
                const Icon(Icons.search, color: AppColors.primary),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    'Search services, brands, or providers',
                    style: textTheme.bodyLarge?.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppCard(
            color: AppColors.surfaceMuted,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.location_searching_outlined,
                  color: AppColors.primary,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Location stays optional',
                        style: textTheme.titleMedium,
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        'Browse normally without permission. When location is enabled later, near-me ranking can become more accurate.',
                        style: textTheme.bodySmall?.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const StatusPill(label: 'Optional', tone: StatusPillTone.info),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          const SectionHeader(title: 'Near you'),
          const SizedBox(height: AppSpacing.md),
          _HorizontalSection(
            height: 380,
            children: home.nearYou
                .map(
                  (service) => ServiceCard(
                    service: service,
                    onTap: () =>
                        context.go(ServiceDetailPage.location(service.id)),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: AppSpacing.xl),
          const SectionHeader(title: 'Featured'),
          const SizedBox(height: AppSpacing.md),
          _HorizontalSection(
            height: 380,
            children: home.featured
                .map(
                  (service) => ServiceCard(
                    service: service,
                    onTap: () =>
                        context.go(ServiceDetailPage.location(service.id)),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: AppSpacing.xl),
          const SectionHeader(title: 'Categories'),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: home.categories
                .map(
                  (category) => ActionChip(
                    label: Text(category.name),
                    onPressed: () =>
                        context.go(CategoryDetailPage.location(category.id)),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: AppSpacing.xl),
          const SectionHeader(title: 'Best of month'),
          const SizedBox(height: AppSpacing.md),
          _HorizontalSection(
            height: 380,
            children: home.bestOfMonth
                .map(
                  (service) => ServiceCard(
                    service: service,
                    onTap: () =>
                        context.go(ServiceDetailPage.location(service.id)),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: AppSpacing.xl),
          const SectionHeader(title: 'Popular brands'),
          const SizedBox(height: AppSpacing.md),
          _HorizontalSection(
            height: 360,
            children: home.popularBrands
                .map(
                  (brand) => BrandCard(
                    brand: brand,
                    onTap: () => context.go(BrandDetailPage.location(brand.id)),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: AppSpacing.xl),
          const SectionHeader(title: 'Popular providers'),
          const SizedBox(height: AppSpacing.md),
          _HorizontalSection(
            height: 280,
            children: home.popularProviders
                .map(
                  (provider) => ProviderCard(
                    provider: provider,
                    onTap: () =>
                        context.go(ProviderDetailPage.location(provider.id)),
                  ),
                )
                .toList(),
          ),
        ],
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: EmptyState(
          title: 'Could not load discovery',
          description: error.toString(),
        ),
      ),
    );
  }
}

class _HorizontalSection extends StatelessWidget {
  const _HorizontalSection({required this.children, required this.height});

  final List<Widget> children;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) {
      return const EmptyState(
        title: 'Nothing here yet',
        description:
            'This section will populate as discovery data becomes available.',
      );
    }

    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: children.length,
        separatorBuilder: (context, index) =>
            const SizedBox(width: AppSpacing.md),
        itemBuilder: (context, index) => children[index],
      ),
    );
  }
}
