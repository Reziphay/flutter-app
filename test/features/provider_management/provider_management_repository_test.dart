import 'package:flutter_test/flutter_test.dart';
import 'package:reziphay_mobile/features/discovery/data/discovery_repository.dart';
import 'package:reziphay_mobile/features/discovery/models/discovery_models.dart';
import 'package:reziphay_mobile/features/provider_management/models/provider_management_models.dart';

void main() {
  group('MockDiscoveryRepository provider management', () {
    late MockDiscoveryRepository repository;

    setUp(() {
      repository = MockDiscoveryRepository();
    });

    test(
      'creating a provider brand and service updates provider-side and public catalog views',
      () async {
        final brandId = await repository.createProviderBrand(
          providerId: 'rauf-mammadov',
          draft: const ProviderBrandDraft(
            name: 'North Atelier',
            headline: 'Small premium grooming room for repeat customers.',
            addressLine: '42 Central Ave, Baku',
            description: 'Provider-owned brand for premium appointment flow.',
            mapHint: 'Second floor above the corner cafe.',
            visibilityLabels: [VisibilityLabel.vip],
            openNow: true,
            logoLabel: 'NA mark',
          ),
        );

        final serviceId = await repository.createProviderService(
          providerId: 'rauf-mammadov',
          draft: ProviderServiceDraft(
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
                startsAt: DateTime.now().add(const Duration(days: 1, hours: 4)),
                label: 'Tomorrow · 14:00',
                available: true,
                note: 'Manual approval',
              ),
            ],
            exceptionNotes: const ['Closed on Sundays.'],
            galleryLabels: const ['Premium chair'],
            brandId: brandId,
            brandName: 'North Atelier',
            price: 55,
          ),
        );

        final brands = await repository.getProviderBrands('rauf-mammadov');
        final services = await repository.getProviderServices('rauf-mammadov');
        final providerDetail = await repository.getProviderDetail(
          'rauf-mammadov',
        );
        final serviceDetail = await repository.getServiceDetail(serviceId);

        expect(
          brands.brands.any((brand) => brand.summary.id == brandId),
          isTrue,
        );
        expect(
          services.services.any((service) => service.summary.id == serviceId),
          isTrue,
        );
        expect(
          providerDetail.associatedBrands.any((brand) => brand.id == brandId),
          isTrue,
        );
        expect(
          providerDetail.services.any((service) => service.id == serviceId),
          isTrue,
        );
        expect(serviceDetail.summary.brandId, brandId);
        expect(serviceDetail.waitingTimeLabel, '15-minute arrival tolerance');
      },
    );

    test(
      'archiving a provider-created service removes it from discovery lists',
      () async {
        final serviceId = await repository.createProviderService(
          providerId: 'rauf-mammadov',
          draft: ProviderServiceDraft(
            name: 'Late-night trim',
            categoryId: 'barber',
            categoryName: 'Barber',
            addressLine: '28 Nizami St, Baku',
            descriptionSnippet: 'Created for archive coverage.',
            about: 'Fast evening cleanup.',
            approvalMode: ApprovalMode.automatic,
            isAvailable: true,
            serviceType: ManagedServiceType.solo,
            waitingTimeMinutes: 10,
            leadTimeHours: 1,
            freeCancellationHours: 2,
            visibilityLabels: const [VisibilityLabel.common],
            requestableSlots: [
              AvailabilityWindow(
                startsAt: DateTime.now().add(const Duration(days: 2)),
                label: 'In 2 days · 10:00',
                available: true,
                note: 'Auto confirm',
              ),
            ],
            exceptionNotes: const [],
            galleryLabels: const ['Evening setup'],
            price: 25,
          ),
        );

        await repository.archiveProviderService(
          providerId: 'rauf-mammadov',
          serviceId: serviceId,
        );

        final providerServices = await repository.getProviderServices(
          'rauf-mammadov',
        );
        final search = await repository.search(
          const DiscoverySearchRequest(
            query: 'late-night trim',
            filters: SearchFilters(),
            sort: SearchSort.rating,
          ),
        );

        expect(
          providerServices.services.any(
            (service) => service.summary.id == serviceId,
          ),
          isFalse,
        );
        expect(
          search.services.any((service) => service.id == serviceId),
          isFalse,
        );
        expect(repository.serviceSummaryById(serviceId), isNotNull);
      },
    );

    test(
      'accepting a join request increments brand members and clears the queue',
      () async {
        final before = await repository.getProviderBrand(
          brandId: 'studio-north',
          providerId: 'rauf-mammadov',
        );

        expect(before.joinRequests, isNotEmpty);

        await repository.acceptBrandJoinRequest(
          providerId: 'rauf-mammadov',
          brandId: 'studio-north',
          requestId: before.joinRequests.first.id,
        );

        final after = await repository.getProviderBrand(
          brandId: 'studio-north',
          providerId: 'rauf-mammadov',
        );

        expect(after.joinRequests, isEmpty);
        expect(
          after.detail.summary.memberCount,
          before.detail.summary.memberCount + 1,
        );
      },
    );
  });
}
