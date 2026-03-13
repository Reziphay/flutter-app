import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reziphay_mobile/features/discovery/data/discovery_repository.dart';
import 'package:reziphay_mobile/features/discovery/models/discovery_models.dart';
import 'package:reziphay_mobile/features/media/models/app_media_asset.dart';
import 'package:reziphay_mobile/features/provider_management/data/provider_management_repository.dart';
import 'package:reziphay_mobile/features/provider_management/models/provider_management_models.dart';
import '../../helpers/mock_discovery_repository.dart';

void main() {
  group('ProviderManagementActions', () {
    test(
      'createService forwards picked gallery media to discovery repository',
      () async {
        final discoveryRepository = _RecordingDiscoveryRepository();
        final container = ProviderContainer(
          overrides: [
            discoveryRepositoryProvider.overrideWithValue(discoveryRepository),
          ],
        );
        addTearDown(container.dispose);

        await container
            .read(providerManagementActionsProvider)
            .createService(
              ProviderServiceDraft(
                name: 'Executive cleanup',
                categoryId: 'barber',
                categoryName: 'Barber',
                addressLine: '42 Central Ave, Baku',
                descriptionSnippet: 'Premium cleanup with manual approval.',
                about: 'Longer session with extra finishing time.',
                approvalMode: ApprovalMode.manual,
                isAvailable: true,
                serviceType: ManagedServiceType.solo,
                waitingTimeMinutes: 15,
                leadTimeHours: 2,
                freeCancellationHours: 4,
                visibilityLabels: const [VisibilityLabel.vip],
                requestableSlots: [
                  AvailabilityWindow(
                    startsAt: DateTime(2026, 3, 14, 14),
                    label: 'Tomorrow · 14:00',
                    available: true,
                  ),
                ],
                exceptionNotes: const ['Closed on Sundays.'],
                galleryMedia: [
                  AppMediaAsset(
                    id: 'picked_1',
                    label: 'Premium chair',
                    source: AppMediaSource.pickedImage,
                    bytes: Uint8List.fromList(const [1, 2, 3]),
                  ),
                ],
                brandId: 'studio-north',
                brandName: 'Studio North',
                price: 55,
              ),
            );

        final savedDraft = discoveryRepository.lastCreatedServiceDraft;
        expect(savedDraft, isNotNull);
        expect(
          savedDraft!.galleryMedia.single.source,
          AppMediaSource.pickedImage,
        );
        expect(savedDraft.galleryMedia.single.bytes, isNotNull);
      },
    );

    test(
      'createBrand forwards the picked logo to discovery repository',
      () async {
        final discoveryRepository = _RecordingDiscoveryRepository();
        final container = ProviderContainer(
          overrides: [
            discoveryRepositoryProvider.overrideWithValue(discoveryRepository),
          ],
        );
        addTearDown(container.dispose);

        await container
            .read(providerManagementActionsProvider)
            .createBrand(
              ProviderBrandDraft(
                name: 'North Atelier',
                headline: 'Small premium grooming room.',
                addressLine: '42 Central Ave, Baku',
                description:
                    'Provider-owned brand for premium appointment flow.',
                mapHint: 'Second floor above the corner cafe.',
                visibilityLabels: const [VisibilityLabel.vip],
                openNow: true,
                logoMedia: AppMediaAsset(
                  id: 'logo_1',
                  label: 'NA mark',
                  source: AppMediaSource.pickedImage,
                  bytes: Uint8List.fromList(const [3, 2, 1]),
                ),
              ),
            );

        final savedDraft = discoveryRepository.lastCreatedBrandDraft;
        expect(savedDraft, isNotNull);
        expect(savedDraft!.logoMedia, isNotNull);
        expect(savedDraft.logoMedia!.source, AppMediaSource.pickedImage);
        expect(savedDraft.logoMedia!.bytes, isNotNull);
      },
    );
  });
}

class _RecordingDiscoveryRepository extends MockDiscoveryRepository {
  ProviderServiceDraft? lastCreatedServiceDraft;
  ProviderBrandDraft? lastCreatedBrandDraft;

  @override
  Future<String> createProviderService({
    required String providerId,
    required ProviderServiceDraft draft,
  }) async {
    lastCreatedServiceDraft = draft;
    return 'svc_recorded';
  }

  @override
  Future<String> createProviderBrand({
    required String providerId,
    required ProviderBrandDraft draft,
  }) async {
    lastCreatedBrandDraft = draft;
    return 'brand_recorded';
  }
}
