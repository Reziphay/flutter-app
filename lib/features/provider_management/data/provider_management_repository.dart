import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reziphay_mobile/features/discovery/data/discovery_repository.dart';
import 'package:reziphay_mobile/features/media/data/media_upload_repository.dart';
import 'package:reziphay_mobile/features/provider_management/models/provider_management_models.dart';
import 'package:reziphay_mobile/features/reservations/data/reservations_repository.dart';

final providerManagedServicesProvider =
    FutureProvider.autoDispose<ProviderServicesData>(
      (ref) => ref
          .watch(discoveryRepositoryProvider)
          .getProviderServices(ref.watch(activeProviderContextProvider)),
    );

final providerManagedServiceProvider = FutureProvider.autoDispose
    .family<ProviderManagedService, String>(
      (ref, serviceId) => ref
          .watch(discoveryRepositoryProvider)
          .getProviderService(
            serviceId: serviceId,
            providerId: ref.watch(activeProviderContextProvider),
          ),
    );

final providerManagedBrandsProvider =
    FutureProvider.autoDispose<ProviderBrandsData>(
      (ref) => ref
          .watch(discoveryRepositoryProvider)
          .getProviderBrands(ref.watch(activeProviderContextProvider)),
    );

final providerManagedBrandProvider = FutureProvider.autoDispose
    .family<ProviderManagedBrand, String>(
      (ref, brandId) => ref
          .watch(discoveryRepositoryProvider)
          .getProviderBrand(
            brandId: brandId,
            providerId: ref.watch(activeProviderContextProvider),
          ),
    );

final providerManagementActionsProvider = Provider<ProviderManagementActions>(
  (ref) => ProviderManagementActions(ref),
);

class ProviderManagementActions {
  ProviderManagementActions(this.ref);

  final Ref ref;

  Future<String> createService(ProviderServiceDraft draft) async {
    final providerId = ref.read(activeProviderContextProvider);
    final preparedDraft = await _prepareServiceDraft(draft);
    final serviceId = await ref
        .read(discoveryRepositoryProvider)
        .createProviderService(providerId: providerId, draft: preparedDraft);
    _invalidateService(
      serviceId: serviceId,
      providerId: providerId,
      brandIds: {if (preparedDraft.brandId != null) preparedDraft.brandId!},
    );
    return serviceId;
  }

  Future<void> updateService({
    required String serviceId,
    required ProviderServiceDraft draft,
  }) async {
    final providerId = ref.read(activeProviderContextProvider);
    final existing = await ref
        .read(discoveryRepositoryProvider)
        .getProviderService(serviceId: serviceId, providerId: providerId);
    final preparedDraft = await _prepareServiceDraft(draft);

    await ref
        .read(discoveryRepositoryProvider)
        .updateProviderService(
          providerId: providerId,
          serviceId: serviceId,
          draft: preparedDraft,
        );

    _invalidateService(
      serviceId: serviceId,
      providerId: providerId,
      brandIds: {
        if (existing.detail.summary.brandId != null)
          existing.detail.summary.brandId!,
        if (preparedDraft.brandId != null) preparedDraft.brandId!,
      },
    );
  }

  Future<void> archiveService(String serviceId) async {
    final providerId = ref.read(activeProviderContextProvider);
    final existing = await ref
        .read(discoveryRepositoryProvider)
        .getProviderService(serviceId: serviceId, providerId: providerId);

    await ref
        .read(discoveryRepositoryProvider)
        .archiveProviderService(providerId: providerId, serviceId: serviceId);

    _invalidateService(
      serviceId: serviceId,
      providerId: providerId,
      brandIds: {
        if (existing.detail.summary.brandId != null)
          existing.detail.summary.brandId!,
      },
    );
  }

  Future<String> createBrand(ProviderBrandDraft draft) async {
    final providerId = ref.read(activeProviderContextProvider);
    final preparedDraft = await _prepareBrandDraft(draft);
    final brandId = await ref
        .read(discoveryRepositoryProvider)
        .createProviderBrand(providerId: providerId, draft: preparedDraft);
    _invalidateBrand(brandId: brandId, providerId: providerId);
    return brandId;
  }

  Future<void> updateBrand({
    required String brandId,
    required ProviderBrandDraft draft,
  }) async {
    final providerId = ref.read(activeProviderContextProvider);
    final preparedDraft = await _prepareBrandDraft(draft);
    await ref
        .read(discoveryRepositoryProvider)
        .updateProviderBrand(
          providerId: providerId,
          brandId: brandId,
          draft: preparedDraft,
        );
    _invalidateBrand(brandId: brandId, providerId: providerId);
  }

  Future<void> acceptJoinRequest({
    required String brandId,
    required String requestId,
  }) async {
    final providerId = ref.read(activeProviderContextProvider);
    await ref
        .read(discoveryRepositoryProvider)
        .acceptBrandJoinRequest(
          providerId: providerId,
          brandId: brandId,
          requestId: requestId,
        );
    _invalidateBrand(brandId: brandId, providerId: providerId);
  }

  Future<void> rejectJoinRequest({
    required String brandId,
    required String requestId,
  }) async {
    final providerId = ref.read(activeProviderContextProvider);
    await ref
        .read(discoveryRepositoryProvider)
        .rejectBrandJoinRequest(
          providerId: providerId,
          brandId: brandId,
          requestId: requestId,
        );
    _invalidateBrand(brandId: brandId, providerId: providerId);
  }

  void _invalidateService({
    required String serviceId,
    required String providerId,
    required Set<String> brandIds,
  }) {
    ref.invalidate(providerManagedServicesProvider);
    ref.invalidate(providerManagedServiceProvider(serviceId));
    ref.invalidate(providerDashboardProvider);
    ref.invalidate(customerHomeProvider);
    ref.invalidate(providerDetailProvider(providerId));
    ref.invalidate(serviceDetailProvider(serviceId));
    for (final brandId in brandIds) {
      ref.invalidate(brandDetailProvider(brandId));
      ref.invalidate(providerManagedBrandProvider(brandId));
    }
  }

  void _invalidateBrand({required String brandId, required String providerId}) {
    ref.invalidate(providerManagedBrandsProvider);
    ref.invalidate(providerManagedBrandProvider(brandId));
    ref.invalidate(providerDashboardProvider);
    ref.invalidate(customerHomeProvider);
    ref.invalidate(providerDetailProvider(providerId));
    ref.invalidate(brandDetailProvider(brandId));
  }

  Future<ProviderServiceDraft> _prepareServiceDraft(
    ProviderServiceDraft draft,
  ) async {
    final uploadedGallery = await ref
        .read(mediaUploadRepositoryProvider)
        .uploadImages(draft.galleryMedia, purpose: 'service_gallery');

    return draft.copyWith(galleryMedia: uploadedGallery);
  }

  Future<ProviderBrandDraft> _prepareBrandDraft(
    ProviderBrandDraft draft,
  ) async {
    final uploadedLogo = await ref
        .read(mediaUploadRepositoryProvider)
        .uploadOptionalImage(draft.logoMedia, purpose: 'brand_logo');

    return draft.copyWith(logoMedia: uploadedLogo);
  }
}
