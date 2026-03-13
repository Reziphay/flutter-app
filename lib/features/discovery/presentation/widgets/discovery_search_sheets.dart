import 'package:flutter/material.dart';
import 'package:reziphay_mobile/app/theme/app_spacing.dart';
import 'package:reziphay_mobile/core/widgets/app_button.dart';
import 'package:reziphay_mobile/features/discovery/models/discovery_models.dart';

class DiscoverySortSheet extends StatelessWidget {
  const DiscoverySortSheet({required this.selectedSort, super.key});

  final SearchSort selectedSort;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Sort by', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.lg),
            for (final sort in SearchSort.values)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(sort.label),
                trailing: sort == selectedSort
                    ? const Icon(Icons.check, size: 18)
                    : null,
                onTap: () => Navigator.of(context).pop(sort),
              ),
          ],
        ),
      ),
    );
  }
}

class DiscoveryFilterSheet extends StatefulWidget {
  const DiscoveryFilterSheet({
    required this.initialFilters,
    required this.categories,
    super.key,
  });

  final SearchFilters initialFilters;
  final List<DiscoveryCategory> categories;

  @override
  State<DiscoveryFilterSheet> createState() => _DiscoveryFilterSheetState();
}

class _DiscoveryFilterSheetState extends State<DiscoveryFilterSheet> {
  late SearchFilters _filters = widget.initialFilters;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Filters', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: AppSpacing.lg),
              const _SectionLabel(label: 'Category'),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  ChoiceChip(
                    label: const Text('All'),
                    selected: _filters.categoryId == null,
                    onSelected: (_) {
                      setState(() {
                        _filters = _filters.copyWith(categoryId: null);
                      });
                    },
                  ),
                  for (final category in widget.categories)
                    ChoiceChip(
                      label: Text(category.name),
                      selected: _filters.categoryId == category.id,
                      onSelected: (_) {
                        setState(() {
                          _filters = _filters.copyWith(categoryId: category.id);
                        });
                      },
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              const _SectionLabel(label: 'Price'),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  _PresetChip<double?>(
                    label: 'Any',
                    value: null,
                    selectedValue: _filters.maxPrice,
                    onSelected: (value) {
                      setState(
                        () => _filters = _filters.copyWith(maxPrice: value),
                      );
                    },
                  ),
                  _PresetChip<double?>(
                    label: '<= 40 AZN',
                    value: 40,
                    selectedValue: _filters.maxPrice,
                    onSelected: (value) {
                      setState(
                        () => _filters = _filters.copyWith(maxPrice: value),
                      );
                    },
                  ),
                  _PresetChip<double?>(
                    label: '<= 80 AZN',
                    value: 80,
                    selectedValue: _filters.maxPrice,
                    onSelected: (value) {
                      setState(
                        () => _filters = _filters.copyWith(maxPrice: value),
                      );
                    },
                  ),
                  _PresetChip<double?>(
                    label: '<= 120 AZN',
                    value: 120,
                    selectedValue: _filters.maxPrice,
                    onSelected: (value) {
                      setState(
                        () => _filters = _filters.copyWith(maxPrice: value),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              const _SectionLabel(label: 'Distance'),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  _PresetChip<double?>(
                    label: 'Any',
                    value: null,
                    selectedValue: _filters.maxDistanceKm,
                    onSelected: (value) {
                      setState(
                        () =>
                            _filters = _filters.copyWith(maxDistanceKm: value),
                      );
                    },
                  ),
                  _PresetChip<double?>(
                    label: '<= 1 km',
                    value: 1,
                    selectedValue: _filters.maxDistanceKm,
                    onSelected: (value) {
                      setState(
                        () =>
                            _filters = _filters.copyWith(maxDistanceKm: value),
                      );
                    },
                  ),
                  _PresetChip<double?>(
                    label: '<= 3 km',
                    value: 3,
                    selectedValue: _filters.maxDistanceKm,
                    onSelected: (value) {
                      setState(
                        () =>
                            _filters = _filters.copyWith(maxDistanceKm: value),
                      );
                    },
                  ),
                  _PresetChip<double?>(
                    label: '<= 5 km',
                    value: 5,
                    selectedValue: _filters.maxDistanceKm,
                    onSelected: (value) {
                      setState(
                        () =>
                            _filters = _filters.copyWith(maxDistanceKm: value),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              const _SectionLabel(label: 'Rating'),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  _PresetChip<double?>(
                    label: 'Any',
                    value: null,
                    selectedValue: _filters.minRating,
                    onSelected: (value) {
                      setState(
                        () => _filters = _filters.copyWith(minRating: value),
                      );
                    },
                  ),
                  _PresetChip<double?>(
                    label: '4.0+',
                    value: 4.0,
                    selectedValue: _filters.minRating,
                    onSelected: (value) {
                      setState(
                        () => _filters = _filters.copyWith(minRating: value),
                      );
                    },
                  ),
                  _PresetChip<double?>(
                    label: '4.5+',
                    value: 4.5,
                    selectedValue: _filters.minRating,
                    onSelected: (value) {
                      setState(
                        () => _filters = _filters.copyWith(minRating: value),
                      );
                    },
                  ),
                  _PresetChip<double?>(
                    label: '4.8+',
                    value: 4.8,
                    selectedValue: _filters.minRating,
                    onSelected: (value) {
                      setState(
                        () => _filters = _filters.copyWith(minRating: value),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _filters.availableOnly,
                onChanged: (value) {
                  setState(
                    () => _filters = _filters.copyWith(availableOnly: value),
                  );
                },
                title: const Text('Open or available only'),
                subtitle: const Text('Hide unavailable results'),
              ),
              const SizedBox(height: AppSpacing.xl),
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: 'Clear',
                      variant: AppButtonVariant.secondary,
                      onPressed: () {
                        setState(() => _filters = const SearchFilters());
                      },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: AppButton(
                      label: 'Apply',
                      onPressed: () => Navigator.of(context).pop(_filters),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PresetChip<T> extends StatelessWidget {
  const _PresetChip({
    required this.label,
    required this.value,
    required this.selectedValue,
    required this.onSelected,
  });

  final String label;
  final T value;
  final T selectedValue;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selectedValue == value,
      onSelected: (_) => onSelected(value),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(label, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}
