// search_screen.dart
// Reziphay
//
// Author: Vugar Safarzada (@vugarsafarzada)

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';

import '../../core/constants/app_colors.dart';
import '../../models/discovery.dart';
import '../../state/explore_providers.dart';
import '../explore/widgets/brand_card.dart';
import '../explore/widgets/rating_row.dart';
import '../explore/widgets/service_card.dart';
import 'search_filters_sheet.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key, this.initialTab});

  final String? initialTab;

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _searchController = TextEditingController();

  // Debouncer — fires 400ms after the user stops typing
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    if (widget.initialTab == 'brands') _tabController.index = 1;
    if (widget.initialTab == 'providers') _tabController.index = 2;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      ref.read(searchQueryProvider.notifier).update(
            (q) => q.copyWith(query: value),
          );
    });
  }

  void _openFilters() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const SearchFiltersSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final q = ref.watch(searchQueryProvider);
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: AppColors.secondaryBackground,
      body: Column(
        children: [
          // ── Custom top bar ──────────────────────────────────────────
          Container(
            color: AppColors.background,
            padding: EdgeInsets.only(top: topPadding),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Back · Search · Filter row
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Iconsax.arrow_left_2),
                        onPressed: () => context.pop(),
                      ),
                      Expanded(
                        child: _SearchInput(
                          controller: _searchController,
                          onChanged: _onSearchChanged,
                        ),
                      ),
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          IconButton(
                            icon: const Icon(Iconsax.setting_4),
                            onPressed: _openFilters,
                          ),
                          if (q.hasFilters)
                            Positioned(
                              top: 10,
                              right: 10,
                              child: Container(
                                width: 7,
                                height: 7,
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: 4),
                    ],
                  ),
                ),
                // Tab bar
                TabBar(
                  controller: _tabController,
                  labelColor: AppColors.primary,
                  unselectedLabelColor: AppColors.textSecondary,
                  indicatorColor: AppColors.primary,
                  indicatorSize: TabBarIndicatorSize.label,
                  dividerColor: AppColors.tertiaryBackground,
                  tabs: const [
                    Tab(text: 'Services'),
                    Tab(text: 'Brands'),
                    Tab(text: 'Providers'),
                  ],
                ),
              ],
            ),
          ),
          // ── Body ───────────────────────────────────────────────────
          Expanded(
            child: q.isEmpty
                ? const _EmptySearchHint()
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _ServicesTab(),
                      _BrandsTab(),
                      _ProvidersTab(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

// MARK: - Search Input

class _SearchInput extends StatelessWidget {
  const _SearchInput({
    required this.controller,
    required this.onChanged,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    const border = OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(10)),
      borderSide: BorderSide.none,
    );
    return TextField(
      controller: controller,
      autofocus: true,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      textAlignVertical: TextAlignVertical.center,
      decoration: const InputDecoration(
        hintText: 'Search services, brands…',
        hintStyle: TextStyle(color: AppColors.textTertiary, fontSize: 14),
        filled: true,
        fillColor: AppColors.secondaryBackground,
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        isDense: true,
        border: border,
        enabledBorder: border,
        focusedBorder: border,
      ),
      style: const TextStyle(
        fontSize: 15,
        color: AppColors.textPrimary,
      ),
    );
  }
}

// MARK: - Empty Hint

class _EmptySearchHint extends StatelessWidget {
  const _EmptySearchHint();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Iconsax.search_normal, size: 64, color: AppColors.textTertiary),
          SizedBox(height: 16),
          Text(
            'Start typing to search',
            style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

// MARK: - Services Tab

class _ServicesTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultsAsync = ref.watch(searchResultsProvider);

    return resultsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _ErrorView(message: e.toString()),
      data: (results) {
        if (results.services.isEmpty) {
          return const _NoResults(label: 'No services found');
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: results.services.length,
          itemBuilder: (_, i) {
            final s = results.services[i];
            return ServiceCard(
              service: s,
              onTap: () => context.push('/service/${s.id}'),
            );
          },
        );
      },
    );
  }
}

// MARK: - Brands Tab

class _BrandsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultsAsync = ref.watch(searchResultsProvider);

    return resultsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _ErrorView(message: e.toString()),
      data: (results) {
        if (results.brands.isEmpty) {
          return const _NoResults(label: 'No brands found');
        }
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.85,
          ),
          itemCount: results.brands.length,
          itemBuilder: (_, i) {
            final b = results.brands[i];
            return BrandCard(
              brand: b,
              onTap: () => context.push('/brand/${b.id}'),
            );
          },
        );
      },
    );
  }
}

// MARK: - Providers Tab

class _ProvidersTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultsAsync = ref.watch(searchResultsProvider);

    return resultsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _ErrorView(message: e.toString()),
      data: (results) {
        if (results.providers.isEmpty) {
          return const _NoResults(label: 'No providers found');
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: results.providers.length,
          itemBuilder: (_, i) => _ProviderCard(
            provider: results.providers[i],
            onTap: () => context.push('/provider/${results.providers[i].id}'),
          ),
        );
      },
    );
  }
}

// MARK: - Provider Card

class _ProviderCard extends StatelessWidget {
  const _ProviderCard({required this.provider, required this.onTap});

  final ProviderItem provider;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: AppColors.secondaryBackground,
              child: Text(
                provider.name.isNotEmpty ? provider.name[0].toUpperCase() : '?',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    provider.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (provider.brands.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      provider.brands.map((b) => b.name).join(', '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                  if (provider.featuredServices.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${provider.featuredServices.length} service${provider.featuredServices.length > 1 ? 's' : ''}',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (provider.ratingStats != null)
                  RatingRow(stats: provider.ratingStats!, small: true),
                if (provider.distanceKm != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    _formatDistance(provider.distanceKm!),
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textTertiary),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDistance(double km) {
    if (km < 1) return '${(km * 1000).round()} m';
    return '${km.toStringAsFixed(1)} km';
  }
}

// MARK: - Utils

class _NoResults extends StatelessWidget {
  const _NoResults({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Iconsax.archive_minus,
              size: 56, color: AppColors.textTertiary),
          const SizedBox(height: 12),
          Text(
            label,
            style:
                const TextStyle(fontSize: 15, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
      ),
    );
  }
}
