import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:reziphay_mobile/app/theme/app_colors.dart';
import 'package:reziphay_mobile/app/theme/app_spacing.dart';
import 'package:reziphay_mobile/core/widgets/empty_state.dart';
import 'package:reziphay_mobile/core/widgets/section_header.dart';
import 'package:reziphay_mobile/features/discovery/data/discovery_repository.dart';
import 'package:reziphay_mobile/features/discovery/models/discovery_models.dart';
import 'package:reziphay_mobile/features/discovery/presentation/pages/brand_detail_page.dart';
import 'package:reziphay_mobile/features/discovery/presentation/pages/provider_detail_page.dart';
import 'package:reziphay_mobile/features/discovery/presentation/pages/service_detail_page.dart';
import 'package:reziphay_mobile/features/discovery/presentation/widgets/discovery_cards.dart';
import 'package:reziphay_mobile/features/discovery/presentation/widgets/discovery_search_sheets.dart';

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  static const path = '/customer/search';

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final _controller = TextEditingController();
  SearchSegment _segment = SearchSegment.services;
  SearchSort _sort = SearchSort.proximity;
  SearchFilters _filters = const SearchFilters();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(discoveryCategoriesProvider);
    final categories =
        categoriesAsync.asData?.value ?? const <DiscoveryCategory>[];
    final request = DiscoverySearchRequest(
      query: _controller.text.trim(),
      filters: _filters,
      sort: _sort,
    );
    final resultsAsync = ref.watch(discoverySearchProvider(request));

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            const Expanded(child: SectionHeader(title: 'Search')),
            IconButton(
              tooltip: 'Sort',
              onPressed: _showSortSheet,
              icon: const Icon(Icons.sort),
            ),
            IconButton(
              tooltip: 'Filters',
              onPressed: categoriesAsync.isLoading
                  ? null
                  : () => _showFilterSheet(categories),
              icon: Badge.count(
                count: _filters.activeCount,
                isLabelVisible: _filters.activeCount > 0,
                child: const Icon(Icons.tune),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: _controller,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(
            labelText: 'Search',
            hintText: 'Service, brand, provider',
            prefixIcon: Icon(Icons.search),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (categoriesAsync.hasError)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Text(
              categoriesAsync.error.toString(),
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.error),
            ),
          ),
        if (_filters.hasActiveFilters)
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              if (_filters.categoryId != null)
                InputChip(
                  label: Text(_selectedCategoryLabel(categories)),
                  onDeleted: () {
                    setState(
                      () => _filters = _filters.copyWith(categoryId: null),
                    );
                  },
                ),
              if (_filters.maxPrice != null)
                InputChip(
                  label: Text(
                    '<= ${_filters.maxPrice!.toStringAsFixed(0)} AZN',
                  ),
                  onDeleted: () {
                    setState(
                      () => _filters = _filters.copyWith(maxPrice: null),
                    );
                  },
                ),
              if (_filters.maxDistanceKm != null)
                InputChip(
                  label: Text(
                    '<= ${_filters.maxDistanceKm!.toStringAsFixed(0)} km',
                  ),
                  onDeleted: () {
                    setState(
                      () => _filters = _filters.copyWith(maxDistanceKm: null),
                    );
                  },
                ),
              if (_filters.minRating != null)
                InputChip(
                  label: Text('${_filters.minRating!.toStringAsFixed(1)}+'),
                  onDeleted: () {
                    setState(
                      () => _filters = _filters.copyWith(minRating: null),
                    );
                  },
                ),
              if (_filters.availableOnly)
                InputChip(
                  label: const Text('Available only'),
                  onDeleted: () {
                    setState(
                      () => _filters = _filters.copyWith(availableOnly: false),
                    );
                  },
                ),
            ],
          )
        else
          const Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              Chip(label: Text('Distance')),
              Chip(label: Text('Rating')),
              Chip(label: Text('Price')),
              Chip(label: Text('Open now')),
              Chip(label: Text('Availability')),
            ],
          ),
        const SizedBox(height: AppSpacing.md),
        SegmentedButton<SearchSegment>(
          segments: const [
            ButtonSegment(
              value: SearchSegment.services,
              label: Text('Services'),
            ),
            ButtonSegment(value: SearchSegment.brands, label: Text('Brands')),
            ButtonSegment(
              value: SearchSegment.providers,
              label: Text('Providers'),
            ),
          ],
          selected: {_segment},
          onSelectionChanged: (selection) {
            setState(() => _segment = selection.first);
          },
        ),
        const SizedBox(height: AppSpacing.lg),
        resultsAsync.when(
          data: (results) {
            final count = switch (_segment) {
              SearchSegment.services => results.services.length,
              SearchSegment.brands => results.brands.length,
              SearchSegment.providers => results.providers.length,
            };

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$count ${_segment.label.toLowerCase()} · sorted by ${_sort.label.toLowerCase()}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
                ),
                const SizedBox(height: AppSpacing.md),
                if (count == 0)
                  const EmptyState(
                    title: 'No results',
                    description:
                        'Try clearing a filter or broadening the search query.',
                  )
                else
                  ...switch (_segment) {
                    SearchSegment.services =>
                      results.services
                          .map(
                            (service) => Padding(
                              padding: const EdgeInsets.only(
                                bottom: AppSpacing.md,
                              ),
                              child: ServiceCard(
                                service: service,
                                width: double.infinity,
                                onTap: () => context.go(
                                  ServiceDetailPage.location(service.id),
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    SearchSegment.brands =>
                      results.brands
                          .map(
                            (brand) => Padding(
                              padding: const EdgeInsets.only(
                                bottom: AppSpacing.md,
                              ),
                              child: BrandCard(
                                brand: brand,
                                width: double.infinity,
                                onTap: () => context.go(
                                  BrandDetailPage.location(brand.id),
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    SearchSegment.providers =>
                      results.providers
                          .map(
                            (provider) => Padding(
                              padding: const EdgeInsets.only(
                                bottom: AppSpacing.md,
                              ),
                              child: ProviderCard(
                                provider: provider,
                                width: double.infinity,
                                onTap: () => context.go(
                                  ProviderDetailPage.location(provider.id),
                                ),
                              ),
                            ),
                          )
                          .toList(),
                  },
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) =>
              EmptyState(title: 'Search failed', description: error.toString()),
        ),
      ],
    );
  }

  Future<void> _showFilterSheet(List<DiscoveryCategory> categories) async {
    final updatedFilters = await showModalBottomSheet<SearchFilters>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => DiscoveryFilterSheet(
        initialFilters: _filters,
        categories: categories,
      ),
    );

    if (updatedFilters != null) {
      setState(() => _filters = updatedFilters);
    }
  }

  Future<void> _showSortSheet() async {
    final selectedSort = await showModalBottomSheet<SearchSort>(
      context: context,
      showDragHandle: true,
      builder: (context) => DiscoverySortSheet(selectedSort: _sort),
    );

    if (selectedSort != null) {
      setState(() => _sort = selectedSort);
    }
  }

  String _selectedCategoryLabel(List<DiscoveryCategory> categories) {
    for (final category in categories) {
      if (category.id == _filters.categoryId) {
        return category.name;
      }
    }
    return 'Category';
  }
}
