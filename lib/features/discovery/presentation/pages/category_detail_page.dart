import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:reziphay_mobile/app/theme/app_colors.dart';
import 'package:reziphay_mobile/app/theme/app_spacing.dart';
import 'package:reziphay_mobile/core/widgets/empty_state.dart';
import 'package:reziphay_mobile/features/discovery/data/discovery_repository.dart';
import 'package:reziphay_mobile/features/discovery/models/discovery_models.dart';
import 'package:reziphay_mobile/features/discovery/presentation/pages/service_detail_page.dart';
import 'package:reziphay_mobile/features/discovery/presentation/widgets/discovery_cards.dart';
import 'package:reziphay_mobile/features/discovery/presentation/widgets/discovery_search_sheets.dart';

class CategoryDetailPage extends ConsumerStatefulWidget {
  const CategoryDetailPage({required this.categoryId, super.key});

  static const path = '/customer/category/:categoryId';

  static String location(String categoryId) => '/customer/category/$categoryId';

  final String categoryId;

  @override
  ConsumerState<CategoryDetailPage> createState() => _CategoryDetailPageState();
}

class _CategoryDetailPageState extends ConsumerState<CategoryDetailPage> {
  SearchSort _sort = SearchSort.proximity;
  bool _availableOnly = false;

  @override
  Widget build(BuildContext context) {
    final category = ref.watch(discoveryCategoryProvider(widget.categoryId));
    if (category == null) {
      return const Scaffold(
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.xl),
            child: EmptyState(
              title: 'Category not found',
              description: 'The selected category could not be loaded.',
            ),
          ),
        ),
      );
    }

    final request = DiscoverySearchRequest(
      query: '',
      filters: SearchFilters(
        categoryId: widget.categoryId,
        availableOnly: _availableOnly,
      ),
      sort: _sort,
    );
    final resultsAsync = ref.watch(discoverySearchProvider(request));

    return Scaffold(
      appBar: AppBar(title: Text(category.name)),
      body: resultsAsync.when(
        data: (results) {
          final services = results.services;

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              Text(
                category.description,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: _pickSort,
                    icon: const Icon(Icons.sort),
                    label: Text(_sort.label),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  FilterChip(
                    label: const Text('Available only'),
                    selected: _availableOnly,
                    onSelected: (value) {
                      setState(() => _availableOnly = value);
                    },
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              if (services.isEmpty)
                const EmptyState(
                  title: 'No services yet',
                  description:
                      'Try broadening the availability setting or return to search.',
                )
              else
                ...services.map(
                  (service) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: ServiceCard(
                      service: service,
                      width: double.infinity,
                      onTap: () =>
                          context.go(ServiceDetailPage.location(service.id)),
                    ),
                  ),
                ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: EmptyState(
            title: 'Could not load category',
            description: error.toString(),
          ),
        ),
      ),
    );
  }

  Future<void> _pickSort() async {
    final selected = await showModalBottomSheet<SearchSort>(
      context: context,
      showDragHandle: true,
      builder: (context) => DiscoverySortSheet(selectedSort: _sort),
    );

    if (selected != null) {
      setState(() => _sort = selected);
    }
  }
}
