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
import 'package:reziphay_mobile/features/provider_management/presentation/pages/provider_brands_page.dart';
import 'package:reziphay_mobile/features/provider_management/presentation/pages/provider_service_form_page.dart';
import 'package:reziphay_mobile/features/provider_management/presentation/widgets/provider_management_widgets.dart';

class ProviderBrandDetailPage extends ConsumerStatefulWidget {
  const ProviderBrandDetailPage({super.key, this.brandId});

  static const createPath = '/provider/brands/create';
  static const path = '/provider/brands/:brandId';

  static String location(String brandId) => '/provider/brands/$brandId';

  final String? brandId;

  bool get isEditing => brandId != null;

  @override
  ConsumerState<ProviderBrandDetailPage> createState() =>
      _ProviderBrandDetailPageState();
}

class _ProviderBrandDetailPageState
    extends ConsumerState<ProviderBrandDetailPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _headlineController = TextEditingController();
  final _addressController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _mapHintController = TextEditingController();
  final _logoLabelController = TextEditingController();

  String? _initializedFor;
  bool _openNow = true;
  bool _isSaving = false;
  String? _busyJoinRequestId;
  Set<VisibilityLabel> _visibilityLabels = {VisibilityLabel.common};

  @override
  void dispose() {
    _nameController.dispose();
    _headlineController.dispose();
    _addressController.dispose();
    _descriptionController.dispose();
    _mapHintController.dispose();
    _logoLabelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brandAsync = widget.isEditing
        ? ref.watch(providerManagedBrandProvider(widget.brandId!))
        : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Brand settings' : 'Create brand'),
      ),
      body: widget.isEditing
          ? brandAsync!.when(
              data: (brand) {
                _hydrateIfNeeded(
                  key: brand.detail.summary.id,
                  draft: brand.draft,
                );
                return _buildForm(context, brand: brand);
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: EmptyState(
                  title: 'Could not load brand',
                  description: error.toString(),
                ),
              ),
            )
          : Builder(
              builder: (context) {
                _hydrateIfNeeded(
                  key: 'create',
                  draft: const ProviderBrandDraft(
                    name: '',
                    headline: '',
                    addressLine: '',
                    description: '',
                    mapHint:
                        'Map preview connects once geolocation wiring is enabled.',
                    visibilityLabels: [VisibilityLabel.common],
                    openNow: true,
                  ),
                );
                return _buildForm(context, brand: null);
              },
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
            label: widget.isEditing ? 'Save brand' : 'Create brand',
            isLoading: _isSaving,
            onPressed: _isSaving ? null : _save,
          ),
        ),
      ),
    );
  }

  Widget _buildForm(
    BuildContext context, {
    required ProviderManagedBrand? brand,
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
            title: 'Brand basics',
            subtitle:
                'Brands are operational identity, not decoration. Keep the promise clear and the address trustworthy.',
            child: Column(
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Brand name'),
                  textInputAction: TextInputAction.next,
                  validator: _requiredValidator,
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _headlineController,
                  decoration: const InputDecoration(labelText: 'Headline'),
                  textInputAction: TextInputAction.next,
                  validator: _requiredValidator,
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(labelText: 'Address'),
                  textInputAction: TextInputAction.next,
                  validator: _requiredValidator,
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _logoLabelController,
                  decoration: const InputDecoration(
                    labelText: 'Logo label',
                    hintText:
                        'Optional placeholder until media upload is wired.',
                  ),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: AppSpacing.md),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Open now'),
                  subtitle: Text(
                    _openNow
                        ? 'Discovery can show this brand as currently open.'
                        : 'Show the brand as currently closed.',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
                  ),
                  value: _openNow,
                  onChanged: (value) => setState(() => _openNow = value),
                ),
                const SizedBox(height: AppSpacing.sm),
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
            title: 'Description',
            child: Column(
              children: [
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText:
                        'Explain what the brand stands for and how it should feel operationally.',
                  ),
                  validator: _requiredValidator,
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _mapHintController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Map note',
                    hintText:
                        'Add a practical location hint while maps stay abstracted.',
                  ),
                  validator: _requiredValidator,
                ),
              ],
            ),
          ),
          if (brand != null) ...[
            const SizedBox(height: AppSpacing.lg),
            ManagementSectionCard(
              title: 'Join requests',
              subtitle:
                  'Handle incoming members without leaving the brand operations flow.',
              child: brand.joinRequests.isEmpty
                  ? const EmptyState(
                      title: 'No join requests',
                      description:
                          'New requests will appear here for accept or rejection.',
                    )
                  : Column(
                      children: brand.joinRequests
                          .map(
                            (request) => Padding(
                              padding: const EdgeInsets.only(
                                bottom: AppSpacing.md,
                              ),
                              child: AppCard(
                                color: AppColors.surfaceSoft,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            request.applicantName,
                                            style: Theme.of(
                                              context,
                                            ).textTheme.titleSmall,
                                          ),
                                        ),
                                        StatusPill(
                                          label: request.requestedAtLabel,
                                          tone: StatusPillTone.warning,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: AppSpacing.xs),
                                    Text(
                                      request.note,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: AppColors.textMuted,
                                          ),
                                    ),
                                    const SizedBox(height: AppSpacing.md),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: AppButton(
                                            label: 'Accept',
                                            isLoading:
                                                _busyJoinRequestId ==
                                                'accept:${request.id}',
                                            onPressed: () => _handleJoinRequest(
                                              requestId: request.id,
                                              accept: true,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: AppSpacing.sm),
                                        Expanded(
                                          child: AppButton(
                                            label: 'Reject',
                                            variant:
                                                AppButtonVariant.destructive,
                                            isLoading:
                                                _busyJoinRequestId ==
                                                'reject:${request.id}',
                                            onPressed: () => _handleJoinRequest(
                                              requestId: request.id,
                                              accept: false,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
            ),
            const SizedBox(height: AppSpacing.lg),
            ManagementSectionCard(
              title: 'Brand services',
              subtitle:
                  'Assign or remove brand membership from the service edit flow.',
              child: brand.detail.services.isEmpty
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const EmptyState(
                          title: 'No linked services',
                          description:
                              'Create a service or reassign an existing one into this brand.',
                        ),
                        const SizedBox(height: AppSpacing.md),
                        AppButton(
                          label: 'Create service',
                          icon: Icons.add,
                          onPressed: () =>
                              context.go(ProviderServiceFormPage.createPath),
                        ),
                      ],
                    )
                  : Column(
                      children: brand.detail.services
                          .map(
                            (service) => Padding(
                              padding: const EdgeInsets.only(
                                bottom: AppSpacing.md,
                              ),
                              child: AppCard(
                                onTap: () => context.go(
                                  ProviderServiceFormPage.editLocation(
                                    service.id,
                                  ),
                                ),
                                color: AppColors.surfaceSoft,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            service.name,
                                            style: Theme.of(
                                              context,
                                            ).textTheme.titleSmall,
                                          ),
                                        ),
                                        StatusPill(
                                          label: service.priceLabel,
                                          tone: StatusPillTone.neutral,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: AppSpacing.xxs),
                                    Text(
                                      service.nextAvailabilityLabel,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: AppColors.textMuted,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
            ),
          ],
        ],
      ),
    );
  }

  void _hydrateIfNeeded({
    required String key,
    required ProviderBrandDraft draft,
  }) {
    if (_initializedFor == key) {
      return;
    }

    _nameController.text = draft.name;
    _headlineController.text = draft.headline;
    _addressController.text = draft.addressLine;
    _descriptionController.text = draft.description;
    _mapHintController.text = draft.mapHint;
    _logoLabelController.text = draft.logoLabel ?? '';
    _openNow = draft.openNow;
    _visibilityLabels = draft.visibilityLabels.toSet();
    _initializedFor = key;
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      final draft = ProviderBrandDraft(
        name: _nameController.text.trim(),
        headline: _headlineController.text.trim(),
        addressLine: _addressController.text.trim(),
        description: _descriptionController.text.trim(),
        mapHint: _mapHintController.text.trim(),
        visibilityLabels: _visibilityLabels.isEmpty
            ? const [VisibilityLabel.common]
            : _visibilityLabels.toList(),
        openNow: _openNow,
        logoLabel: _logoLabelController.text.trim().isEmpty
            ? null
            : _logoLabelController.text.trim(),
      );

      if (widget.isEditing) {
        await ref
            .read(providerManagementActionsProvider)
            .updateBrand(brandId: widget.brandId!, draft: draft);
      } else {
        await ref.read(providerManagementActionsProvider).createBrand(draft);
      }

      if (!mounted) {
        return;
      }

      context.go(ProviderBrandsPage.path);
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

  Future<void> _handleJoinRequest({
    required String requestId,
    required bool accept,
  }) async {
    if (widget.brandId == null) {
      return;
    }

    setState(
      () => _busyJoinRequestId = '${accept ? 'accept' : 'reject'}:$requestId',
    );

    try {
      final actions = ref.read(providerManagementActionsProvider);
      if (accept) {
        await actions.acceptJoinRequest(
          brandId: widget.brandId!,
          requestId: requestId,
        );
      } else {
        await actions.rejectJoinRequest(
          brandId: widget.brandId!,
          requestId: requestId,
        );
      }

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            accept ? 'Join request accepted.' : 'Join request rejected.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) {
        setState(() => _busyJoinRequestId = null);
      }
    }
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Required';
    }
    return null;
  }
}
