// search_screen.dart
// Reziphay
//
// Author: Vugar Safarzada (@vugarsafarzada)

import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_dynamic_colors.dart';
import '../../core/theme/app_palette.dart';
import '../../models/discovery.dart';
import '../../state/explore_providers.dart';
import '../explore/widgets/brand_card.dart';
import '../explore/widgets/rating_row.dart';
import '../explore/widgets/service_card.dart';
import 'search_filters_sheet.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key, this.initialTab, this.showAll = false});

  final String? initialTab;
  final bool showAll;

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
    // Always reset query state on open, then apply showAll if needed.
    // This ensures reopening normal search clears any previous showAll=true.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(searchQueryProvider.notifier).state =
          SearchQuery(showAll: widget.showAll);
    });
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

    final dc = context.dc;
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: dc.secondaryBackground,
      body: Column(
        children: [
          // ── Custom top bar ──────────────────────────────────────────
          Container(
            color: dc.background,
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
                                decoration: BoxDecoration(
                                  color: context.palette.primary,
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
                  labelColor: context.palette.primary,
                  unselectedLabelColor: dc.textSecondary,
                  indicatorColor: context.palette.primary,
                  indicatorSize: TabBarIndicatorSize.label,
                  dividerColor: dc.divider,
                  tabs: [
                    Tab(text: l10n.searchTabServices),
                    Tab(text: l10n.searchTabBrands),
                    Tab(text: l10n.searchTabProviders),
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
    final dc = context.dc;
    final l10n = context.l10n;
    final border = OutlineInputBorder(
      borderRadius: const BorderRadius.all(Radius.circular(10)),
      borderSide: BorderSide.none,
    );
    return TextField(
      controller: controller,
      autofocus: true,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      textAlignVertical: TextAlignVertical.center,
      decoration: InputDecoration(
        hintText: l10n.searchHint,
        hintStyle: TextStyle(color: dc.textTertiary, fontSize: 14),
        filled: true,
        fillColor: dc.secondaryBackground,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        isDense: true,
        border: border,
        enabledBorder: border,
        focusedBorder: border,
      ),
      style: TextStyle(
        fontSize: 15,
        color: dc.textPrimary,
      ),
    );
  }
}

// MARK: - Empty Hint

class _EmptySearchHint extends StatelessWidget {
  const _EmptySearchHint();

  @override
  Widget build(BuildContext context) {
    final dc = context.dc;
    final l10n = context.l10n;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Iconsax.search_normal, size: 64, color: dc.textTertiary),
          const SizedBox(height: 16),
          Text(
            l10n.searchStartTyping,
            style: TextStyle(fontSize: 16, color: dc.textSecondary),
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
    final l10n = context.l10n;

    return resultsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _ErrorView(message: e.toString()),
      data: (results) {
        if (results.services.isEmpty) {
          return _NoResults(label: l10n.searchNoServices);
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
    final l10n = context.l10n;

    return resultsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _ErrorView(message: e.toString()),
      data: (results) {
        if (results.brands.isEmpty) {
          return _NoResults(label: l10n.searchNoBrands);
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
    final l10n = context.l10n;

    return resultsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _ErrorView(message: e.toString()),
      data: (results) {
        if (results.providers.isEmpty) {
          return _NoResults(label: l10n.searchNoProviders);
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
      child: Builder(builder: (context) {
        final dc = context.dc;
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: dc.cardBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: dc.divider, width: 1),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: dc.secondaryBackground,
                ),
                clipBehavior: Clip.antiAlias,
                child: provider.avatarUrl != null && provider.avatarUrl!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: provider.avatarUrl!,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => _InitialAvatar(name: provider.name, dc: dc),
                        errorWidget: (_, __, ___) => _InitialAvatar(name: provider.name, dc: dc),
                      )
                    : _InitialAvatar(name: provider.name, dc: dc),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      provider.name,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: dc.textPrimary,
                      ),
                    ),
                    if (provider.brands.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        provider.brands.map((b) => b.name).join(', '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: context.palette.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                    if (provider.featuredServices.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        '${provider.featuredServices.length} service${provider.featuredServices.length > 1 ? 's' : ''}',
                        style: TextStyle(fontSize: 12, color: dc.textSecondary),
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
                      style: TextStyle(fontSize: 11, color: dc.textTertiary),
                    ),
                  ],
                ],
              ),
            ],
          ),
        );
      }),
    );
  }

  String _formatDistance(double km) {
    if (km < 1) return '${(km * 1000).round()} m';
    return '${km.toStringAsFixed(1)} km';
  }
}

// MARK: - Utils

class _InitialAvatar extends StatelessWidget {
  const _InitialAvatar({required this.name, required this.dc});

  final String name;
  final AppDynamicColors dc;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: context.palette.primary,
        ),
      ),
    );
  }
}

class _NoResults extends StatelessWidget {
  const _NoResults({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final dc = context.dc;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Iconsax.archive_minus, size: 56, color: dc.textTertiary),
          const SizedBox(height: 12),
          Text(
            label,
            style: TextStyle(fontSize: 15, color: dc.textSecondary),
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
          style: TextStyle(color: context.dc.textSecondary),
        ),
      ),
    );
  }
}
