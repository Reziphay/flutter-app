import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:reziphay_mobile/app/theme/app_colors.dart';
import 'package:reziphay_mobile/app/theme/app_spacing.dart';
import 'package:reziphay_mobile/core/widgets/app_button.dart';
import 'package:reziphay_mobile/core/widgets/app_card.dart';
import 'package:reziphay_mobile/core/widgets/empty_state.dart';
import 'package:reziphay_mobile/features/discovery/data/discovery_repository.dart';
import 'package:reziphay_mobile/features/discovery/models/discovery_models.dart';
import 'package:reziphay_mobile/features/provider_management/data/provider_management_repository.dart';
import 'package:reziphay_mobile/features/provider_management/models/provider_management_models.dart';
import 'package:reziphay_mobile/features/provider_management/presentation/pages/provider_services_page.dart';
import 'package:reziphay_mobile/features/provider_management/presentation/widgets/provider_management_widgets.dart';

const _noBrandValue = '__no_brand__';

class ProviderServiceFormPage extends ConsumerStatefulWidget {
  const ProviderServiceFormPage({super.key, this.serviceId});

  static const createPath = '/provider/services/create';
  static const editPath = '/provider/services/:serviceId/edit';

  static String editLocation(String serviceId) =>
      '/provider/services/$serviceId/edit';

  final String? serviceId;

  bool get isEditing => serviceId != null;

  @override
  ConsumerState<ProviderServiceFormPage> createState() =>
      _ProviderServiceFormPageState();
}

class _ProviderServiceFormPageState
    extends ConsumerState<ProviderServiceFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _priceController = TextEditingController();
  final _summaryController = TextEditingController();
  final _aboutController = TextEditingController();
  final _waitingTimeController = TextEditingController();
  final _leadTimeController = TextEditingController();
  final _freeCancellationController = TextEditingController();

  String? _initializedFor;
  String? _selectedCategoryId;
  String? _selectedBrandId;
  ApprovalMode _approvalMode = ApprovalMode.manual;
  ManagedServiceType _serviceType = ManagedServiceType.solo;
  bool _isAvailable = true;
  bool _isSaving = false;
  bool _isDeleting = false;
  bool _canArchive = false;
  Set<VisibilityLabel> _visibilityLabels = {VisibilityLabel.common};
  List<AvailabilityWindow> _slots = const [];
  List<String> _exceptionNotes = const [];
  List<String> _galleryLabels = const [];

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _priceController.dispose();
    _summaryController.dispose();
    _aboutController.dispose();
    _waitingTimeController.dispose();
    _leadTimeController.dispose();
    _freeCancellationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(discoveryCategoriesProvider);
    final brandsAsync = ref.watch(providerManagedBrandsProvider);
    final serviceAsync = widget.isEditing
        ? ref.watch(providerManagedServiceProvider(widget.serviceId!))
        : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit service' : 'Create service'),
      ),
      body: brandsAsync.when(
        data: (brandData) {
          if (widget.isEditing) {
            return serviceAsync!.when(
              data: (managedService) {
                _hydrateIfNeeded(
                  key: managedService.detail.summary.id,
                  draft: managedService.draft,
                  categories: categories,
                  availableBrands: brandData.brands,
                  canArchive: managedService.canArchive,
                );
                return _buildForm(
                  context,
                  categories: categories,
                  availableBrands: brandData.brands,
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: EmptyState(
                  title: 'Could not load service',
                  description: error.toString(),
                ),
              ),
            );
          }

          _hydrateIfNeeded(
            key: 'create',
            draft: _defaultDraft(
              categories: categories,
              availableBrands: brandData.brands,
            ),
            categories: categories,
            availableBrands: brandData.brands,
            canArchive: false,
          );
          return _buildForm(
            context,
            categories: categories,
            availableBrands: brandData.brands,
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: EmptyState(
            title: 'Could not load service form',
            description: error.toString(),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.md,
          ),
          child: AppButton(
            label: widget.isEditing ? 'Save service' : 'Create service',
            isLoading: _isSaving,
            onPressed: _isReadyForSave(categories)
                ? () => _save(categories)
                : null,
          ),
        ),
      ),
    );
  }

  Widget _buildForm(
    BuildContext context, {
    required List<DiscoveryCategory> categories,
    required List<ProviderManagedBrandListItem> availableBrands,
  }) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.xxxl,
        ),
        children: [
          ManagementSectionCard(
            title: 'Basics',
            subtitle:
                'Keep the public description tight. Detailed expectations belong in the service notes below.',
            child: Column(
              children: [
                TextFormField(
                  controller: _nameController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(labelText: 'Service name'),
                  validator: _requiredValidator,
                ),
                const SizedBox(height: AppSpacing.md),
                DropdownButtonFormField<String>(
                  initialValue: _selectedCategoryId,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: categories
                      .map(
                        (category) => DropdownMenuItem<String>(
                          value: category.id,
                          child: Text(category.name),
                        ),
                      )
                      .toList(),
                  onChanged: (value) =>
                      setState(() => _selectedCategoryId = value),
                ),
                const SizedBox(height: AppSpacing.md),
                DropdownButtonFormField<String>(
                  initialValue: _selectedBrandId ?? _noBrandValue,
                  decoration: const InputDecoration(labelText: 'Brand'),
                  items: [
                    const DropdownMenuItem<String>(
                      value: _noBrandValue,
                      child: Text('Self branded'),
                    ),
                    ...availableBrands.map(
                      (brand) => DropdownMenuItem<String>(
                        value: brand.summary.id,
                        child: Text(brand.summary.name),
                      ),
                    ),
                  ],
                  onChanged: (value) => setState(
                    () => _selectedBrandId =
                        value == null || value == _noBrandValue ? null : value,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _addressController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(labelText: 'Address'),
                  validator: _requiredValidator,
                ),
                const SizedBox(height: AppSpacing.md),
                SegmentedButton<ManagedServiceType>(
                  showSelectedIcon: false,
                  segments: ManagedServiceType.values
                      .map(
                        (value) => ButtonSegment<ManagedServiceType>(
                          value: value,
                          label: Text(value.label),
                        ),
                      )
                      .toList(),
                  selected: {_serviceType},
                  onSelectionChanged: (selection) =>
                      setState(() => _serviceType = selection.first),
                ),
                const SizedBox(height: AppSpacing.sm),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Visible in discovery'),
                  subtitle: Text(
                    _isAvailable
                        ? 'Customers can request current availability.'
                        : 'The service stays hidden from availability-driven ranking.',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
                  ),
                  value: _isAvailable,
                  onChanged: (value) => setState(() => _isAvailable = value),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          ManagementSectionCard(
            title: 'Pricing and visibility',
            child: Column(
              children: [
                TextFormField(
                  controller: _priceController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Price (AZN)',
                    hintText: 'Leave empty for price on request',
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                SegmentedButton<ApprovalMode>(
                  showSelectedIcon: false,
                  segments: ApprovalMode.values
                      .map(
                        (value) => ButtonSegment<ApprovalMode>(
                          value: value,
                          label: Text(
                            value == ApprovalMode.manual
                                ? 'Manual'
                                : 'Automatic',
                          ),
                        ),
                      )
                      .toList(),
                  selected: {_approvalMode},
                  onSelectionChanged: (selection) {
                    setState(() {
                      _approvalMode = selection.first;
                      _slots = _slots
                          .map(
                            (slot) => AvailabilityWindow(
                              startsAt: slot.startsAt,
                              label: slot.label,
                              available: slot.available,
                              note: _slotNoteForMode(),
                            ),
                          )
                          .toList();
                    });
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _approvalMode.detailDescription,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Visibility labels',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                VisibilityLabelSelector(
                  selected: _visibilityLabels,
                  onChanged: (next) => setState(() => _visibilityLabels = next),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          ManagementSectionCard(
            title: 'Availability rules',
            subtitle:
                'Keep this lightweight. Define a few requestable windows instead of forcing a heavy slot builder.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_slots.isEmpty)
                  const EmptyState(
                    title: 'No requestable windows',
                    description:
                        'Add the next real times you want customers to request.',
                  )
                else
                  ..._slots.map(
                    (slot) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: AppCard(
                        color: AppColors.surfaceSoft,
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    slot.label,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleSmall,
                                  ),
                                  if (slot.note != null) ...[
                                    const SizedBox(height: AppSpacing.xxs),
                                    Text(
                                      slot.note!,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: AppColors.textMuted,
                                          ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () => setState(
                                () => _slots = _slots
                                    .where(
                                      (entry) =>
                                          entry.startsAt != slot.startsAt,
                                    )
                                    .toList(),
                              ),
                              icon: const Icon(Icons.delete_outline),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: AppSpacing.md),
                AppButton(
                  label: 'Add requestable window',
                  variant: AppButtonVariant.secondary,
                  icon: Icons.add,
                  onPressed: _addSlot,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          ManagementSectionCard(
            title: 'Exceptions and settings',
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _waitingTimeController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Waiting time (min)',
                        ),
                        validator: _positiveIntValidator,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: TextFormField(
                        controller: _leadTimeController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Lead time (h)',
                        ),
                        validator: _positiveIntValidator,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _freeCancellationController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Free cancellation deadline (h)',
                  ),
                  validator: _positiveIntValidator,
                ),
                const SizedBox(height: AppSpacing.lg),
                EditableStringList(
                  items: _exceptionNotes,
                  emptyTitle: 'No exception notes',
                  emptyDescription:
                      'Add closed days or special rules customers should respect.',
                  addLabel: 'Add exception note',
                  onAdd: _addException,
                  onRemove: (value) => setState(
                    () => _exceptionNotes = _exceptionNotes
                        .where((item) => item != value)
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          ManagementSectionCard(
            title: 'Description and media',
            child: Column(
              children: [
                TextFormField(
                  controller: _summaryController,
                  maxLines: 3,
                  textInputAction: TextInputAction.newline,
                  decoration: const InputDecoration(
                    labelText: 'Discovery summary',
                    hintText:
                        'Short public description used in lists and cards.',
                  ),
                  validator: _requiredValidator,
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _aboutController,
                  maxLines: 5,
                  textInputAction: TextInputAction.newline,
                  decoration: const InputDecoration(
                    labelText: 'About this service',
                    hintText:
                        'Explain how the service works, what the customer should expect, and why the approval mode is set this way.',
                  ),
                  validator: _requiredValidator,
                ),
                const SizedBox(height: AppSpacing.lg),
                EditableStringList(
                  items: _galleryLabels,
                  emptyTitle: 'No gallery labels',
                  emptyDescription:
                      'Add lightweight media placeholders until real upload wiring is connected.',
                  addLabel: 'Add media label',
                  onAdd: _addGalleryLabel,
                  onRemove: (value) => setState(
                    () => _galleryLabels = _galleryLabels
                        .where((item) => item != value)
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
          if (widget.isEditing && _canArchive) ...[
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              label: 'Delete service',
              variant: AppButtonVariant.destructive,
              isLoading: _isDeleting,
              onPressed: _archiveService,
            ),
          ],
        ],
      ),
    );
  }

  void _hydrateIfNeeded({
    required String key,
    required ProviderServiceDraft draft,
    required List<DiscoveryCategory> categories,
    required List<ProviderManagedBrandListItem> availableBrands,
    required bool canArchive,
  }) {
    if (_initializedFor == key) {
      return;
    }

    final resolvedCategoryId =
        categories.any((category) => category.id == draft.categoryId)
        ? draft.categoryId
        : (categories.isEmpty ? null : categories.first.id);
    final resolvedBrandId =
        draft.brandId != null &&
            availableBrands.any((brand) => brand.summary.id == draft.brandId)
        ? draft.brandId
        : null;

    _nameController.text = draft.name;
    _addressController.text = draft.addressLine;
    _priceController.text = draft.price == null ? '' : draft.price!.toString();
    _summaryController.text = draft.descriptionSnippet;
    _aboutController.text = draft.about;
    _waitingTimeController.text = draft.waitingTimeMinutes.toString();
    _leadTimeController.text = draft.leadTimeHours.toString();
    _freeCancellationController.text = draft.freeCancellationHours.toString();
    _selectedCategoryId = resolvedCategoryId;
    _selectedBrandId = resolvedBrandId;
    _approvalMode = draft.approvalMode;
    _serviceType = draft.serviceType;
    _isAvailable = draft.isAvailable;
    _visibilityLabels = draft.visibilityLabels.toSet();
    _slots = List<AvailabilityWindow>.of(draft.requestableSlots);
    _exceptionNotes = List<String>.of(draft.exceptionNotes);
    _galleryLabels = List<String>.of(draft.galleryLabels);
    _canArchive = canArchive;
    _initializedFor = key;
  }

  ProviderServiceDraft _defaultDraft({
    required List<DiscoveryCategory> categories,
    required List<ProviderManagedBrandListItem> availableBrands,
  }) {
    final category = categories.isEmpty ? null : categories.first;
    final address = availableBrands.isEmpty
        ? ''
        : availableBrands.first.summary.addressLine;

    return ProviderServiceDraft(
      name: '',
      categoryId: category?.id ?? '',
      categoryName: category?.name ?? '',
      addressLine: address,
      descriptionSnippet: '',
      about: '',
      approvalMode: ApprovalMode.manual,
      isAvailable: true,
      serviceType: ManagedServiceType.solo,
      waitingTimeMinutes: 10,
      leadTimeHours: 1,
      freeCancellationHours: 2,
      visibilityLabels: const [VisibilityLabel.common],
      requestableSlots: const [],
      exceptionNotes: const [],
      galleryLabels: const [],
      brandId: availableBrands.isEmpty
          ? null
          : availableBrands.first.summary.id,
      brandName: availableBrands.isEmpty
          ? null
          : availableBrands.first.summary.name,
      price: null,
    );
  }

  bool _isReadyForSave(List<DiscoveryCategory> categories) =>
      !_isSaving && !_isDeleting && categories.isNotEmpty;

  Future<void> _save(List<DiscoveryCategory> categories) async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Select a category.')));
      return;
    }
    if (_slots.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one requestable window.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final category = categories.firstWhere(
        (entry) => entry.id == _selectedCategoryId,
      );
      final draft = ProviderServiceDraft(
        name: _nameController.text.trim(),
        categoryId: category.id,
        categoryName: category.name,
        addressLine: _addressController.text.trim(),
        descriptionSnippet: _summaryController.text.trim(),
        about: _aboutController.text.trim(),
        approvalMode: _approvalMode,
        isAvailable: _isAvailable,
        serviceType: _serviceType,
        waitingTimeMinutes: int.parse(_waitingTimeController.text.trim()),
        leadTimeHours: int.parse(_leadTimeController.text.trim()),
        freeCancellationHours: int.parse(
          _freeCancellationController.text.trim(),
        ),
        visibilityLabels: _visibilityLabels.isEmpty
            ? const [VisibilityLabel.common]
            : _visibilityLabels.toList(),
        requestableSlots: _slots,
        exceptionNotes: _exceptionNotes,
        galleryLabels: _galleryLabels,
        brandId: _selectedBrandId,
        brandName: null,
        price: _priceController.text.trim().isEmpty
            ? null
            : double.tryParse(_priceController.text.trim()),
      );

      if (widget.isEditing) {
        await ref
            .read(providerManagementActionsProvider)
            .updateService(serviceId: widget.serviceId!, draft: draft);
      } else {
        await ref.read(providerManagementActionsProvider).createService(draft);
      }

      if (!mounted) {
        return;
      }

      context.go(ProviderServicesPage.path);
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _archiveService() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete service'),
          content: const Text(
            'This removes the service from provider management and customer discovery. Existing reservation history still keeps the original record.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true || widget.serviceId == null) {
      return;
    }

    setState(() => _isDeleting = true);

    try {
      await ref
          .read(providerManagementActionsProvider)
          .archiveService(widget.serviceId!);

      if (!mounted) {
        return;
      }

      context.go(ProviderServicesPage.path);
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) {
        setState(() => _isDeleting = false);
      }
    }
  }

  Future<void> _addSlot() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      firstDate: now,
      lastDate: now.add(const Duration(days: 90)),
      initialDate: now.add(const Duration(days: 1)),
    );
    if (date == null || !mounted) {
      return;
    }

    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 10, minute: 0),
    );
    if (time == null) {
      return;
    }

    final startsAt = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );

    setState(() {
      _slots = [
        ..._slots,
        AvailabilityWindow(
          startsAt: startsAt,
          label: DateFormat('EEE, MMM d · HH:mm').format(startsAt),
          available: true,
          note: _slotNoteForMode(),
        ),
      ]..sort((a, b) => a.startsAt.compareTo(b.startsAt));
    });
  }

  Future<void> _addException() async {
    final value = await showManagementTextSheet(
      context,
      title: 'Add exception note',
      labelText: 'Exception',
      hintText:
          'Example: Closed on public holidays or remote-only every Friday.',
      buttonLabel: 'Add note',
    );
    if (value == null || value.isEmpty) {
      return;
    }

    setState(() => _exceptionNotes = [..._exceptionNotes, value]);
  }

  Future<void> _addGalleryLabel() async {
    final value = await showManagementTextSheet(
      context,
      title: 'Add media label',
      labelText: 'Media label',
      hintText: 'Example: Treatment room, product shelf, or before/after.',
      buttonLabel: 'Add label',
    );
    if (value == null || value.isEmpty) {
      return;
    }

    setState(() => _galleryLabels = [..._galleryLabels, value]);
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Required';
    }
    return null;
  }

  String? _positiveIntValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Required';
    }
    final parsed = int.tryParse(value.trim());
    if (parsed == null || parsed < 0) {
      return 'Enter a valid number';
    }
    return null;
  }

  String _slotNoteForMode() => switch (_approvalMode) {
    ApprovalMode.manual => 'Manual approval',
    ApprovalMode.automatic => 'Auto confirm',
  };
}
