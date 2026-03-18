// search_filters_sheet.dart
// Reziphay
//
// Author: Vugar Safarzada (@vugarsafarzada)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_dynamic_colors.dart';
import '../../core/theme/app_palette.dart';
import '../../state/explore_providers.dart';

List<_SortOption> _buildSortOptions(AppLocalizations l10n) => [
  _SortOption('RELEVANCE',  l10n.sortRelevance),
  _SortOption('RATING',     l10n.sortHighestRated),
  _SortOption('PROXIMITY',  l10n.sortNearestFirst),
  _SortOption('PRICE_LOW',  l10n.sortPriceLow),
  _SortOption('PRICE_HIGH', l10n.sortPriceHigh),
  _SortOption('POPULARITY', l10n.sortMostPopular),
];

class SearchFiltersSheet extends ConsumerStatefulWidget {
  const SearchFiltersSheet({super.key});

  @override
  ConsumerState<SearchFiltersSheet> createState() => _SearchFiltersSheetState();
}

class _SearchFiltersSheetState extends ConsumerState<SearchFiltersSheet> {
  late String _sortBy;
  late RangeValues _priceRange;
  bool _hasPriceFilter = false;

  @override
  void initState() {
    super.initState();
    final q = ref.read(searchQueryProvider);
    _sortBy       = q.sortBy;
    _priceRange   = RangeValues(q.minPrice ?? 0, q.maxPrice ?? 1000);
    _hasPriceFilter = q.minPrice != null || q.maxPrice != null;
  }

  void _apply() {
    ref.read(searchQueryProvider.notifier).update(
      (q) => q.copyWith(
        sortBy:       _sortBy,
        minPrice:     _hasPriceFilter ? _priceRange.start : null,
        clearMinPrice: !_hasPriceFilter,
        maxPrice:     _hasPriceFilter ? _priceRange.end : null,
        clearMaxPrice: !_hasPriceFilter,
      ),
    );
    Navigator.of(context).pop();
  }

  void _reset() {
    ref.read(searchQueryProvider.notifier).update(
      (q) => q.copyWith(
        sortBy:       'RELEVANCE',
        clearMinPrice: true,
        clearMaxPrice: true,
        clearCategory: true,
        clearRadius:   true,
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final dc = context.dc;
    final l10n = context.l10n;
    final primary = context.palette.primary;
    final sortOptions = _buildSortOptions(l10n);
    return Container(
      decoration: BoxDecoration(
        color: dc.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: dc.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),

            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text(
                    l10n.filtersTitle,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: dc.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: _reset,
                    child: Text(l10n.filtersReset, style: TextStyle(color: primary)),
                  ),
                ],
              ),
            ),

            const Divider(),

            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sort by
                    Text(
                      l10n.filtersSortBy,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: dc.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: sortOptions.map((opt) {
                        final selected = _sortBy == opt.value;
                        return ChoiceChip(
                          label: Text(opt.label),
                          selected: selected,
                          onSelected: (_) => setState(() => _sortBy = opt.value),
                          selectedColor: primary.withValues(alpha: 0.12),
                          labelStyle: TextStyle(
                            color: selected ? primary : dc.textPrimary,
                            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                          ),
                          side: BorderSide(
                            color: selected ? primary : dc.divider,
                          ),
                          backgroundColor: dc.background,
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 24),

                    // Price range
                    Row(
                      children: [
                        Text(
                          l10n.filtersPriceRange,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: dc.textPrimary,
                          ),
                        ),
                        const Spacer(),
                        Switch(
                          value: _hasPriceFilter,
                          activeThumbColor: primary,
                          onChanged: (v) => setState(() => _hasPriceFilter = v),
                        ),
                      ],
                    ),
                    if (_hasPriceFilter) ...[
                      const SizedBox(height: 4),
                      Text(
                        '\$${_priceRange.start.toStringAsFixed(0)} – \$${_priceRange.end.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 14,
                          color: dc.textSecondary,
                        ),
                      ),
                      RangeSlider(
                        values: _priceRange,
                        min: 0,
                        max: 1000,
                        divisions: 20,
                        activeColor: primary,
                        inactiveColor: dc.divider,
                        onChanged: (v) => setState(() => _priceRange = v),
                      ),
                    ],

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // Apply button
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _apply,
                  child: Text(l10n.filtersApply),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SortOption {
  const _SortOption(this.value, this.label);

  final String value;
  final String label;
}
