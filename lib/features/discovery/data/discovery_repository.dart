import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:reziphay_mobile/core/network/api_client.dart';
import 'package:reziphay_mobile/core/network/app_exception.dart';
import 'package:reziphay_mobile/features/discovery/models/discovery_models.dart';
import 'package:reziphay_mobile/features/media/models/app_media_asset.dart';
import 'package:reziphay_mobile/features/provider_management/models/provider_management_models.dart';

abstract class DiscoveryRepository {
  List<DiscoveryCategory> get categories;

  DiscoveryCategory? categoryById(String id);

  ServiceSummary? serviceSummaryById(String id);

  Future<List<DiscoveryCategory>> getCategories();

  Future<CustomerHomeData> getCustomerHomeData();

  Future<DiscoverySearchResponse> search(DiscoverySearchRequest request);

  Future<ServiceDetail> getServiceDetail(String id);

  Future<BrandDetail> getBrandDetail(String id);

  Future<ProviderDetail> getProviderDetail(String id);

  Future<ProviderServicesData> getProviderServices(String providerId);

  Future<ProviderManagedService> getProviderService({
    required String serviceId,
    required String providerId,
  });

  Future<String> createProviderService({
    required String providerId,
    required ProviderServiceDraft draft,
  });

  Future<void> updateProviderService({
    required String providerId,
    required String serviceId,
    required ProviderServiceDraft draft,
  });

  Future<void> archiveProviderService({
    required String providerId,
    required String serviceId,
  });

  Future<ProviderBrandsData> getProviderBrands(String providerId);

  Future<ProviderManagedBrand> getProviderBrand({
    required String brandId,
    required String providerId,
  });

  Future<String> createProviderBrand({
    required String providerId,
    required ProviderBrandDraft draft,
  });

  Future<void> updateProviderBrand({
    required String providerId,
    required String brandId,
    required ProviderBrandDraft draft,
  });

  Future<void> acceptBrandJoinRequest({
    required String providerId,
    required String brandId,
    required String requestId,
  });

  Future<void> rejectBrandJoinRequest({
    required String providerId,
    required String brandId,
    required String requestId,
  });
}

final _discoveryCategoriesCacheProvider =
    NotifierProvider<_DiscoveryCategoriesCache, List<DiscoveryCategory>>(
      _DiscoveryCategoriesCache.new,
    );

final discoveryRepositoryProvider = Provider<DiscoveryRepository>((ref) {
  return BackendDiscoveryRepository(
    apiClient: ref.watch(apiClientProvider),
    onCategoriesUpdated: (categories) {
      ref
          .read(_discoveryCategoriesCacheProvider.notifier)
          .setCategories(categories);
    },
  );
});

final discoveryCategoriesProvider =
    FutureProvider.autoDispose<List<DiscoveryCategory>>((ref) async {
      final cachedCategories = ref.watch(_discoveryCategoriesCacheProvider);
      if (cachedCategories.isNotEmpty) {
        return cachedCategories;
      }

      return ref.watch(discoveryRepositoryProvider).getCategories();
    });

class _DiscoveryCategoriesCache extends Notifier<List<DiscoveryCategory>> {
  @override
  List<DiscoveryCategory> build() => const [];

  void setCategories(List<DiscoveryCategory> categories) {
    state = categories;
  }
}

final discoveryCategoryProvider = Provider.family<DiscoveryCategory?, String>(
  (ref, categoryId) =>
      ref.watch(discoveryRepositoryProvider).categoryById(categoryId),
);

final customerHomeProvider = FutureProvider.autoDispose<CustomerHomeData>(
  (ref) => ref.watch(discoveryRepositoryProvider).getCustomerHomeData(),
);

final discoverySearchProvider = FutureProvider.autoDispose
    .family<DiscoverySearchResponse, DiscoverySearchRequest>(
      (ref, request) => ref.watch(discoveryRepositoryProvider).search(request),
    );

final serviceDetailProvider = FutureProvider.autoDispose
    .family<ServiceDetail, String>(
      (ref, serviceId) =>
          ref.watch(discoveryRepositoryProvider).getServiceDetail(serviceId),
    );

final brandDetailProvider = FutureProvider.autoDispose
    .family<BrandDetail, String>(
      (ref, brandId) =>
          ref.watch(discoveryRepositoryProvider).getBrandDetail(brandId),
    );

final providerDetailProvider = FutureProvider.autoDispose
    .family<ProviderDetail, String>(
      (ref, providerId) =>
          ref.watch(discoveryRepositoryProvider).getProviderDetail(providerId),
    );

class MockDiscoveryRepository implements DiscoveryRepository {
  MockDiscoveryRepository();

  @override
  final List<DiscoveryCategory> categories = const [
    DiscoveryCategory(
      id: 'barber',
      name: 'Barber',
      description: 'Haircuts, trims, grooming, and beard care.',
    ),
    DiscoveryCategory(
      id: 'dentist',
      name: 'Dentist',
      description: 'Consultations, hygiene, and long-term oral care.',
    ),
    DiscoveryCategory(
      id: 'beauty',
      name: 'Beauty',
      description: 'Facial care, skincare, and premium beauty sessions.',
    ),
    DiscoveryCategory(
      id: 'consulting',
      name: 'Consulting',
      description: 'Advisory and strategy sessions with flexible scheduling.',
    ),
    DiscoveryCategory(
      id: 'maintenance',
      name: 'Maintenance',
      description: 'On-site help and scheduled repair services.',
    ),
  ];

  final List<BrandSummary> _brands = List.of(const [
    BrandSummary(
      id: 'studio-north',
      name: 'Studio North',
      headline: 'Minimal grooming studio with strong response reliability.',
      addressLine: '28 Nizami St, Baku',
      distanceKm: 1.2,
      rating: 4.8,
      reviewCount: 214,
      serviceCount: 2,
      memberCount: 1,
      categoryIds: ['barber'],
      visibilityLabels: [VisibilityLabel.vip, VisibilityLabel.sponsored],
      popularityScore: 94,
      openNow: true,
      logoMedia: AppMediaAsset.generated(
        id: 'studio-north-logo',
        label: 'SN mark',
      ),
    ),
    BrandSummary(
      id: 'luna-dental',
      name: 'Luna Dental',
      headline: 'Trusted dental brand with careful review-driven growth.',
      addressLine: '7 Fountain Sq, Baku',
      distanceKm: 2.3,
      rating: 4.9,
      reviewCount: 318,
      serviceCount: 2,
      memberCount: 1,
      categoryIds: ['dentist'],
      visibilityLabels: [VisibilityLabel.bestOfMonth],
      popularityScore: 97,
      openNow: true,
      logoMedia: AppMediaAsset.generated(
        id: 'luna-dental-logo',
        label: 'LD crest',
      ),
    ),
    BrandSummary(
      id: 'form-and-flare',
      name: 'Form & Flare',
      headline: 'Beauty care with a calm, appointment-first studio rhythm.',
      addressLine: '14 Tabriz St, Baku',
      distanceKm: 3.1,
      rating: 4.7,
      reviewCount: 142,
      serviceCount: 1,
      memberCount: 1,
      categoryIds: ['beauty'],
      visibilityLabels: [VisibilityLabel.common],
      popularityScore: 83,
      openNow: false,
      logoMedia: AppMediaAsset.generated(
        id: 'form-and-flare-logo',
        label: 'F&F monogram',
      ),
    ),
  ]);

  final List<ProviderSummary> _providers = List.of(const [
    ProviderSummary(
      id: 'rauf-mammadov',
      name: 'Rauf Mammadov',
      headline: 'Senior barber focused on dependable manual approvals.',
      bio:
          'Rauf works with a flexible calendar and keeps response times visible instead of overpromising instant automation.',
      distanceKm: 1.2,
      rating: 4.8,
      reviewCount: 196,
      completedReservations: 482,
      responseReliability: 'Responds in about 3 minutes',
      brandIds: ['studio-north'],
      categoryIds: ['barber'],
      visibilityLabels: [VisibilityLabel.vip],
      popularityScore: 92,
      availableNow: true,
    ),
    ProviderSummary(
      id: 'kamala-aliyeva',
      name: 'Kamala Aliyeva',
      headline:
          'Dentist with strong trust signals and detailed review history.',
      bio:
          'Kamala uses Reziphay to coordinate consultations and follow-up appointments while keeping her clinic workflow flexible.',
      distanceKm: 2.3,
      rating: 4.9,
      reviewCount: 264,
      completedReservations: 629,
      responseReliability: 'Usually confirms within 5 minutes',
      brandIds: ['luna-dental'],
      categoryIds: ['dentist'],
      visibilityLabels: [VisibilityLabel.bestOfMonth],
      popularityScore: 98,
      availableNow: true,
    ),
    ProviderSummary(
      id: 'aysel-karimova',
      name: 'Aysel Karimova',
      headline: 'Beauty expert with high completion and repeat-customer rates.',
      bio:
          'Aysel runs curated skincare sessions and keeps notes lightweight so reservations stay fast for both sides.',
      distanceKm: 3.1,
      rating: 4.7,
      reviewCount: 121,
      completedReservations: 271,
      responseReliability: 'Reply window usually under 4 minutes',
      brandIds: ['form-and-flare'],
      categoryIds: ['beauty'],
      visibilityLabels: [VisibilityLabel.common],
      popularityScore: 84,
      availableNow: false,
    ),
    ProviderSummary(
      id: 'emin-jafarov',
      name: 'Emin Jafarov',
      headline: 'Independent strategy consultant with self-branded services.',
      bio:
          'Emin offers session-based consulting and intentionally avoids rigid slot builders because most meetings need light negotiation.',
      distanceKm: 4.0,
      rating: 4.6,
      reviewCount: 61,
      completedReservations: 149,
      responseReliability: 'Replies within the same afternoon',
      brandIds: [],
      categoryIds: ['consulting'],
      visibilityLabels: [VisibilityLabel.common],
      popularityScore: 71,
      availableNow: true,
    ),
  ]);

  final List<ServiceSummary> _services = List.of(const [
    ServiceSummary(
      id: 'classic-haircut',
      name: 'Classic haircut',
      categoryId: 'barber',
      categoryName: 'Barber',
      providerId: 'rauf-mammadov',
      providerName: 'Rauf Mammadov',
      brandId: 'studio-north',
      brandName: 'Studio North',
      addressLine: '28 Nizami St, Baku',
      distanceKm: 1.2,
      rating: 4.8,
      reviewCount: 96,
      visibilityLabels: [VisibilityLabel.vip],
      approvalMode: ApprovalMode.manual,
      isAvailable: true,
      popularityScore: 90,
      nextAvailabilityLabel: 'Today · 14:00',
      price: 38,
      descriptionSnippet:
          'Clean classic cut with a manual approval window for calendar flexibility.',
    ),
    ServiceSummary(
      id: 'precision-beard-trim',
      name: 'Precision beard trim',
      categoryId: 'barber',
      categoryName: 'Barber',
      providerId: 'rauf-mammadov',
      providerName: 'Rauf Mammadov',
      brandId: 'studio-north',
      brandName: 'Studio North',
      addressLine: '28 Nizami St, Baku',
      distanceKm: 1.2,
      rating: 4.7,
      reviewCount: 58,
      visibilityLabels: [VisibilityLabel.sponsored],
      approvalMode: ApprovalMode.automatic,
      isAvailable: true,
      popularityScore: 85,
      nextAvailabilityLabel: 'Today · 16:30',
      price: 22,
      descriptionSnippet:
          'Fast grooming service with automatic confirmation enabled.',
    ),
    ServiceSummary(
      id: 'dental-consultation',
      name: 'Dental consultation',
      categoryId: 'dentist',
      categoryName: 'Dentist',
      providerId: 'kamala-aliyeva',
      providerName: 'Kamala Aliyeva',
      brandId: 'luna-dental',
      brandName: 'Luna Dental',
      addressLine: '7 Fountain Sq, Baku',
      distanceKm: 2.3,
      rating: 4.9,
      reviewCount: 141,
      visibilityLabels: [VisibilityLabel.bestOfMonth],
      approvalMode: ApprovalMode.manual,
      isAvailable: true,
      popularityScore: 96,
      nextAvailabilityLabel: 'Tomorrow · 11:00',
      price: 55,
      descriptionSnippet:
          'Initial examination and treatment planning with manual approval.',
    ),
    ServiceSummary(
      id: 'professional-cleaning',
      name: 'Professional cleaning',
      categoryId: 'dentist',
      categoryName: 'Dentist',
      providerId: 'kamala-aliyeva',
      providerName: 'Kamala Aliyeva',
      brandId: 'luna-dental',
      brandName: 'Luna Dental',
      addressLine: '7 Fountain Sq, Baku',
      distanceKm: 2.3,
      rating: 4.8,
      reviewCount: 103,
      visibilityLabels: [VisibilityLabel.common],
      approvalMode: ApprovalMode.automatic,
      isAvailable: true,
      popularityScore: 88,
      nextAvailabilityLabel: 'Friday · 10:30',
      price: 85,
      descriptionSnippet: 'Routine hygiene care with automatic confirmation.',
    ),
    ServiceSummary(
      id: 'signature-skin-reset',
      name: 'Signature skin reset',
      categoryId: 'beauty',
      categoryName: 'Beauty',
      providerId: 'aysel-karimova',
      providerName: 'Aysel Karimova',
      brandId: 'form-and-flare',
      brandName: 'Form & Flare',
      addressLine: '14 Tabriz St, Baku',
      distanceKm: 3.1,
      rating: 4.7,
      reviewCount: 74,
      visibilityLabels: [VisibilityLabel.common],
      approvalMode: ApprovalMode.manual,
      isAvailable: false,
      popularityScore: 79,
      nextAvailabilityLabel: 'Saturday · 13:00',
      price: 74,
      descriptionSnippet:
          'Longer skincare session with provider-controlled confirmation.',
    ),
    ServiceSummary(
      id: 'strategy-session',
      name: 'Strategy session',
      categoryId: 'consulting',
      categoryName: 'Consulting',
      providerId: 'emin-jafarov',
      providerName: 'Emin Jafarov',
      addressLine: 'Remote or central Baku',
      distanceKm: 4.0,
      rating: 4.6,
      reviewCount: 36,
      visibilityLabels: [VisibilityLabel.common],
      approvalMode: ApprovalMode.manual,
      isAvailable: true,
      popularityScore: 72,
      nextAvailabilityLabel: 'Monday · 18:00',
      price: 120,
      descriptionSnippet:
          'Independent consulting with flexible requestable windows.',
    ),
  ]);

  final Map<String, List<ReviewPreview>> _reviewsByEntity = Map.of(const {
    'classic-haircut': [
      ReviewPreview(
        authorName: 'Murad',
        rating: 5,
        comment:
            'Clear communication and no rushed feeling. The manual approval window was still fast.',
        dateLabel: '3 days ago',
        reply:
            'Thanks. I keep manual approvals short so the schedule stays realistic.',
      ),
      ReviewPreview(
        authorName: 'Arzu',
        rating: 4.8,
        comment: 'Strong result and accurate start time.',
        dateLabel: '2 weeks ago',
      ),
    ],
    'dental-consultation': [
      ReviewPreview(
        authorName: 'Nigar',
        rating: 5,
        comment: 'Helpful explanation and calm clinic workflow.',
        dateLabel: '5 days ago',
      ),
      ReviewPreview(
        authorName: 'Javid',
        rating: 4.9,
        comment:
            'Good consultation quality and the reservation updates were clear.',
        dateLabel: '11 days ago',
      ),
    ],
    'signature-skin-reset': [
      ReviewPreview(
        authorName: 'Leyla',
        rating: 4.7,
        comment: 'Good quality session and smooth follow-up notes.',
        dateLabel: '1 week ago',
      ),
    ],
    'studio-north': [
      ReviewPreview(
        authorName: 'Amina',
        rating: 4.8,
        comment: 'Reliable team and strong service consistency.',
        dateLabel: '4 days ago',
      ),
    ],
    'luna-dental': [
      ReviewPreview(
        authorName: 'Samir',
        rating: 5,
        comment: 'Professional staff and clear appointment flow.',
        dateLabel: '6 days ago',
      ),
    ],
    'form-and-flare': [
      ReviewPreview(
        authorName: 'Rena',
        rating: 4.7,
        comment: 'The studio feels calm and intentional.',
        dateLabel: '2 weeks ago',
      ),
    ],
    'rauf-mammadov': [
      ReviewPreview(
        authorName: 'Elvin',
        rating: 4.8,
        comment: 'Great cut and honest timing.',
        dateLabel: '1 week ago',
      ),
    ],
    'kamala-aliyeva': [
      ReviewPreview(
        authorName: 'Ali',
        rating: 5,
        comment: 'Excellent communication before and during the visit.',
        dateLabel: '3 days ago',
      ),
    ],
    'aysel-karimova': [
      ReviewPreview(
        authorName: 'Sabina',
        rating: 4.7,
        comment: 'Thoughtful care and solid advice.',
        dateLabel: '9 days ago',
      ),
    ],
    'emin-jafarov': [
      ReviewPreview(
        authorName: 'Farid',
        rating: 4.6,
        comment: 'Useful session and good pre-meeting coordination.',
        dateLabel: '10 days ago',
      ),
    ],
  });

  final Map<String, _BrandMeta> _brandMetaById = Map.of(const {
    'studio-north': _BrandMeta(
      description:
          'Studio North keeps the grooming experience calm and intentionally lightweight. Reservations stay flexible, but response times are visible and reliable.',
      mapHint:
          'Map preview will connect to the geolocation abstraction in a later pass.',
      logoMedia: AppMediaAsset.generated(
        id: 'studio-north-logo',
        label: 'SN mark',
      ),
    ),
    'luna-dental': _BrandMeta(
      description:
          'Luna Dental uses Reziphay to make discovery and coordination easier without pretending every clinical visit fits a rigid slot engine.',
      mapHint:
          'Map preview will connect to the geolocation abstraction in a later pass.',
      logoMedia: AppMediaAsset.generated(
        id: 'luna-dental-logo',
        label: 'LD crest',
      ),
    ),
    'form-and-flare': _BrandMeta(
      description:
          'Form & Flare focuses on studio-quality beauty sessions with careful review signals and clear availability communication.',
      mapHint:
          'Map preview will connect to the geolocation abstraction in a later pass.',
      logoMedia: AppMediaAsset.generated(
        id: 'form-and-flare-logo',
        label: 'F&F monogram',
      ),
    ),
  });

  final Map<String, _ServiceMeta> _serviceMetaById = {
    'classic-haircut': _ServiceMeta(
      about:
          'A clean grooming service for customers who care about reliability more than artificial instant-booking theatrics. Manual approval keeps the provider in control of real schedule conflicts.',
      availabilitySummary:
          'Selectable times remain requestable until the provider responds. If no response arrives in 5 minutes, the request expires.',
      requestableSlots: [
        AvailabilityWindow(
          startsAt: _dateAt(0, 14, 0),
          label: 'Today · 14:00',
          available: true,
          note: 'Manual approval',
        ),
        AvailabilityWindow(
          startsAt: _dateAt(0, 16, 0),
          label: 'Today · 16:00',
          available: true,
          note: 'Manual approval',
        ),
        AvailabilityWindow(
          startsAt: _dateAt(1, 11, 30),
          label: 'Tomorrow · 11:30',
          available: true,
        ),
      ],
      waitingTimeMinutes: 10,
      freeCancellationHours: 2,
      leadTimeHours: 1,
      serviceType: ManagedServiceType.solo,
      galleryMedia: [
        const AppMediaAsset.generated(
          id: 'classic-haircut-0',
          label: 'Studio chair',
        ),
        const AppMediaAsset.generated(
          id: 'classic-haircut-1',
          label: 'Clean finish',
        ),
        const AppMediaAsset.generated(
          id: 'classic-haircut-2',
          label: 'Product shelf',
        ),
      ],
      exceptionNotes: ['Closed every Sunday morning.'],
    ),
    'precision-beard-trim': _ServiceMeta(
      about:
          'Focused grooming session with lighter setup and faster turnaround. Auto approval is enabled because the provider keeps buffers elsewhere.',
      availabilitySummary:
          'Available times can confirm immediately when still open.',
      requestableSlots: [
        AvailabilityWindow(
          startsAt: _dateAt(0, 16, 30),
          label: 'Today · 16:30',
          available: true,
          note: 'Auto confirm',
        ),
        AvailabilityWindow(
          startsAt: _dateAt(0, 17, 0),
          label: 'Today · 17:00',
          available: true,
          note: 'Auto confirm',
        ),
        AvailabilityWindow(
          startsAt: _dateAt(1, 12, 0),
          label: 'Tomorrow · 12:00',
          available: true,
        ),
      ],
      waitingTimeMinutes: 10,
      freeCancellationHours: 2,
      leadTimeHours: 0,
      serviceType: ManagedServiceType.solo,
      galleryMedia: [
        const AppMediaAsset.generated(
          id: 'precision-beard-trim-0',
          label: 'Beard line',
        ),
        const AppMediaAsset.generated(
          id: 'precision-beard-trim-1',
          label: 'Chair setup',
        ),
        const AppMediaAsset.generated(
          id: 'precision-beard-trim-2',
          label: 'Finishing tools',
        ),
      ],
      exceptionNotes: const [],
    ),
    'dental-consultation': _ServiceMeta(
      about:
          'Initial consultation, examination, and treatment direction. Manual approval helps the clinic sequence prep time and follow-ups safely.',
      availabilitySummary:
          'Selectable times remain requestable until the provider responds. If no response arrives in 5 minutes, the request expires.',
      requestableSlots: [
        AvailabilityWindow(
          startsAt: _dateAt(1, 11, 0),
          label: 'Tomorrow · 11:00',
          available: true,
          note: 'Manual approval',
        ),
        AvailabilityWindow(
          startsAt: _dateAt(1, 13, 30),
          label: 'Tomorrow · 13:30',
          available: true,
          note: 'Manual approval',
        ),
        AvailabilityWindow(
          startsAt: _dateAt(5, 9, 30),
          label: 'Friday · 09:30',
          available: false,
          note: 'Filled',
        ),
      ],
      waitingTimeMinutes: 15,
      freeCancellationHours: 12,
      leadTimeHours: 4,
      serviceType: ManagedServiceType.multi,
      galleryMedia: [
        const AppMediaAsset.generated(
          id: 'dental-consultation-0',
          label: 'Clinic room',
        ),
        const AppMediaAsset.generated(
          id: 'dental-consultation-1',
          label: 'Reception',
        ),
        const AppMediaAsset.generated(
          id: 'dental-consultation-2',
          label: 'Care setup',
        ),
      ],
      exceptionNotes: ['Closed for sterilization every Monday 09:00-10:00.'],
    ),
    'professional-cleaning': _ServiceMeta(
      about:
          'Routine hygiene service designed for faster confirmation and lower coordination overhead.',
      availabilitySummary:
          'Available times can confirm immediately when still open.',
      requestableSlots: [
        AvailabilityWindow(
          startsAt: _dateAt(5, 10, 30),
          label: 'Friday · 10:30',
          available: true,
          note: 'Auto confirm',
        ),
        AvailabilityWindow(
          startsAt: _dateAt(5, 12, 0),
          label: 'Friday · 12:00',
          available: true,
          note: 'Auto confirm',
        ),
      ],
      waitingTimeMinutes: 15,
      freeCancellationHours: 12,
      leadTimeHours: 4,
      serviceType: ManagedServiceType.multi,
      galleryMedia: [
        const AppMediaAsset.generated(
          id: 'professional-cleaning-0',
          label: 'Procedure room',
        ),
        const AppMediaAsset.generated(
          id: 'professional-cleaning-1',
          label: 'Clean tools',
        ),
        const AppMediaAsset.generated(
          id: 'professional-cleaning-2',
          label: 'Aftercare desk',
        ),
      ],
      exceptionNotes: const [],
    ),
    'signature-skin-reset': _ServiceMeta(
      about:
          'Longer beauty session with a more curated workflow, so the provider prefers manual approval and clearer lead-time control.',
      availabilitySummary:
          'Selectable times remain requestable until the provider responds. If no response arrives in 5 minutes, the request expires.',
      requestableSlots: [
        AvailabilityWindow(
          startsAt: _dateAt(6, 13, 0),
          label: 'Saturday · 13:00',
          available: true,
          note: 'Manual approval',
        ),
        AvailabilityWindow(
          startsAt: _dateAt(6, 16, 0),
          label: 'Saturday · 16:00',
          available: true,
          note: 'Manual approval',
        ),
      ],
      waitingTimeMinutes: 10,
      freeCancellationHours: 2,
      leadTimeHours: 6,
      serviceType: ManagedServiceType.solo,
      galleryMedia: [
        const AppMediaAsset.generated(
          id: 'signature-skin-reset-0',
          label: 'Treatment room',
        ),
        const AppMediaAsset.generated(
          id: 'signature-skin-reset-1',
          label: 'Lighting',
        ),
        const AppMediaAsset.generated(
          id: 'signature-skin-reset-2',
          label: 'Product detail',
        ),
      ],
      exceptionNotes: ['Unavailable after 18:00 on weekdays.'],
    ),
    'strategy-session': _ServiceMeta(
      about:
          'Independent advisory session with flexible request windows. Times stay requestable because many meetings require light adjustment before confirmation.',
      availabilitySummary:
          'Selectable times remain requestable until the provider responds. If no response arrives in 5 minutes, the request expires.',
      requestableSlots: [
        AvailabilityWindow(
          startsAt: _dateAt(7, 18, 0),
          label: 'Monday · 18:00',
          available: true,
          note: 'Requestable',
        ),
        AvailabilityWindow(
          startsAt: _dateAt(8, 10, 0),
          label: 'Tuesday · 10:00',
          available: true,
          note: 'Requestable',
        ),
      ],
      waitingTimeMinutes: 5,
      freeCancellationHours: 6,
      leadTimeHours: 12,
      serviceType: ManagedServiceType.solo,
      galleryMedia: [
        const AppMediaAsset.generated(
          id: 'strategy-session-0',
          label: 'Overview',
        ),
        const AppMediaAsset.generated(id: 'strategy-session-1', label: 'Space'),
        const AppMediaAsset.generated(
          id: 'strategy-session-2',
          label: 'Result',
        ),
      ],
      exceptionNotes: ['Remote-only on Fridays.'],
    ),
  };

  final Map<String, List<BrandJoinRequest>> _brandJoinRequestsByBrandId = {
    'studio-north': List.of(const [
      BrandJoinRequest(
        id: 'join_2001',
        applicantName: 'Murad Karimov',
        note:
            'Independent barber looking to join under the Studio North brand.',
        requestedAtLabel: 'Today · 09:20',
      ),
    ]),
  };

  final Set<String> _archivedServiceIds = {};
  int _brandIdSeed = 4000;
  int _serviceIdSeed = 5000;

  Map<String, BrandSummary> get _brandsById => {
    for (final brand in _brands) brand.id: brand,
  };

  Map<String, ProviderSummary> get _providersById => {
    for (final provider in _providers) provider.id: provider,
  };

  Map<String, ServiceSummary> get _servicesById => {
    for (final service in _services) service.id: service,
  };

  List<ServiceSummary> get _discoverableServices => _services
      .where((service) => !_archivedServiceIds.contains(service.id))
      .toList();

  @override
  DiscoveryCategory? categoryById(String id) {
    for (final category in categories) {
      if (category.id == id) {
        return category;
      }
    }
    return null;
  }

  @override
  ServiceSummary? serviceSummaryById(String id) => _servicesById[id];

  @override
  Future<List<DiscoveryCategory>> getCategories() async {
    await _delay();
    return List<DiscoveryCategory>.unmodifiable(categories);
  }

  @override
  Future<BrandDetail> getBrandDetail(String id) async {
    await _delay();
    return _buildBrandDetail(id);
  }

  @override
  Future<CustomerHomeData> getCustomerHomeData() async {
    await _delay();

    final nearYou = List<ServiceSummary>.of(_discoverableServices)
      ..sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
    final featured = _discoverableServices
        .where(
          (service) =>
              service.visibilityLabels.contains(VisibilityLabel.vip) ||
              service.visibilityLabels.contains(VisibilityLabel.sponsored),
        )
        .toList();
    final bestOfMonth = _discoverableServices
        .where(
          (service) =>
              service.visibilityLabels.contains(VisibilityLabel.bestOfMonth),
        )
        .toList();
    final popularBrands = List<BrandSummary>.of(_brands)
      ..sort((a, b) => b.popularityScore.compareTo(a.popularityScore));
    final popularProviders = List<ProviderSummary>.of(_providers)
      ..sort((a, b) => b.popularityScore.compareTo(a.popularityScore));

    return CustomerHomeData(
      nearYou: nearYou.take(4).toList(),
      featured: featured.take(4).toList(),
      bestOfMonth: bestOfMonth.take(4).toList(),
      categories: categories,
      popularBrands: popularBrands.take(3).toList(),
      popularProviders: popularProviders.take(3).toList(),
    );
  }

  @override
  Future<ProviderDetail> getProviderDetail(String id) async {
    await _delay();

    final provider = _providersById[id];
    if (provider == null) {
      throw const AppException('Provider not found.');
    }

    final associatedBrands = provider.brandIds
        .map((brandId) => _brandsById[brandId])
        .whereType<BrandSummary>()
        .toList();
    final services = _discoverableServices
        .where((service) => service.providerId == id)
        .toList();

    return ProviderDetail(
      summary: provider,
      associatedBrands: associatedBrands,
      services: services,
      reviews: _reviewsByEntity[id] ?? const [],
    );
  }

  @override
  Future<DiscoverySearchResponse> search(DiscoverySearchRequest request) async {
    await _delay();

    final normalizedQuery = request.query.trim().toLowerCase();

    final services =
        List<ServiceSummary>.of(_discoverableServices)
            .where((service) => _matchesServiceQuery(service, normalizedQuery))
            .where(
              (service) => _matchesServiceFilters(service, request.filters),
            )
            .toList()
          ..sort((a, b) => _compareServices(a, b, request.sort));

    final brands =
        List<BrandSummary>.of(_brands)
            .where((brand) => _matchesBrandQuery(brand, normalizedQuery))
            .where((brand) => _matchesBrandFilters(brand, request.filters))
            .toList()
          ..sort((a, b) => _compareBrands(a, b, request.sort));

    final providers =
        List<ProviderSummary>.of(_providers)
            .where(
              (provider) => _matchesProviderQuery(provider, normalizedQuery),
            )
            .where(
              (provider) => _matchesProviderFilters(provider, request.filters),
            )
            .toList()
          ..sort((a, b) => _compareProviders(a, b, request.sort));

    return DiscoverySearchResponse(
      services: services,
      brands: brands,
      providers: providers,
    );
  }

  @override
  Future<ServiceDetail> getServiceDetail(String id) async {
    await _delay();
    return _buildServiceDetail(id);
  }

  @override
  Future<ProviderServicesData> getProviderServices(String providerId) async {
    await _delay();
    final services =
        _discoverableServices
            .where((service) => service.providerId == providerId)
            .toList()
          ..sort((a, b) => a.name.compareTo(b.name));

    final items = services.map((service) {
      final meta = _metaForService(service);
      return ProviderManagedServiceListItem(
        summary: service,
        serviceType: meta.serviceType,
        waitingTimeMinutes: meta.waitingTimeMinutes,
        leadTimeHours: meta.leadTimeHours,
        exceptionCount: meta.exceptionNotes.length,
        canArchive: _canArchiveService(service.id),
      );
    }).toList();

    return ProviderServicesData(
      services: items,
      activeCount: services.where((service) => service.isAvailable).length,
      manualApprovalCount: services
          .where((service) => service.approvalMode == ApprovalMode.manual)
          .length,
      brandLinkedCount: services
          .where((service) => service.brandId != null)
          .length,
    );
  }

  @override
  Future<ProviderManagedService> getProviderService({
    required String serviceId,
    required String providerId,
  }) async {
    await _delay();
    final service = _servicesById[serviceId];
    if (service == null || service.providerId != providerId) {
      throw const AppException('Service not found for this provider.');
    }

    return ProviderManagedService(
      detail: _buildServiceDetail(serviceId),
      draft: _draftFromService(service),
      canArchive: _canArchiveService(serviceId),
    );
  }

  @override
  Future<String> createProviderService({
    required String providerId,
    required ProviderServiceDraft draft,
  }) async {
    await _delay();
    final provider = _providersById[providerId];
    if (provider == null) {
      throw const AppException('Provider not found.');
    }

    final brand = draft.brandId == null
        ? null
        : _requireOwnedBrand(brandId: draft.brandId!, providerId: providerId);
    final category = categoryById(draft.categoryId);
    if (category == null) {
      throw const AppException('Category not found.');
    }

    final serviceId = 'service_${_serviceIdSeed++}';
    final summary = ServiceSummary(
      id: serviceId,
      name: draft.name.trim(),
      categoryId: category.id,
      categoryName: category.name,
      providerId: providerId,
      providerName: provider.name,
      brandId: brand?.id,
      brandName: brand?.name,
      addressLine: draft.addressLine.trim(),
      distanceKm: provider.distanceKm,
      rating: provider.rating,
      reviewCount: 0,
      visibilityLabels: draft.visibilityLabels,
      approvalMode: draft.approvalMode,
      isAvailable: draft.isAvailable,
      popularityScore: (provider.popularityScore - 12).clamp(20, 99),
      nextAvailabilityLabel: _nextAvailabilityLabel(draft.requestableSlots),
      price: draft.price,
      descriptionSnippet: draft.descriptionSnippet.trim(),
      coverMedia: draft.galleryMedia.isEmpty ? null : draft.galleryMedia.first,
    );

    _services.add(summary);
    _serviceMetaById[serviceId] = _serviceMetaFromDraft(draft);

    _refreshBrandSummary(brand?.id);
    _refreshProviderSummary(providerId);
    return serviceId;
  }

  @override
  Future<void> updateProviderService({
    required String providerId,
    required String serviceId,
    required ProviderServiceDraft draft,
  }) async {
    await _delay();
    final existing = _servicesById[serviceId];
    if (existing == null || existing.providerId != providerId) {
      throw const AppException('Service not found for this provider.');
    }

    final brand = draft.brandId == null
        ? null
        : _requireOwnedBrand(brandId: draft.brandId!, providerId: providerId);
    final category = categoryById(draft.categoryId);
    if (category == null) {
      throw const AppException('Category not found.');
    }

    _replaceService(
      ServiceSummary(
        id: existing.id,
        name: draft.name.trim(),
        categoryId: category.id,
        categoryName: category.name,
        providerId: existing.providerId,
        providerName: existing.providerName,
        brandId: brand?.id,
        brandName: brand?.name,
        addressLine: draft.addressLine.trim(),
        distanceKm: existing.distanceKm,
        rating: existing.rating,
        reviewCount: existing.reviewCount,
        visibilityLabels: draft.visibilityLabels,
        approvalMode: draft.approvalMode,
        isAvailable: draft.isAvailable,
        popularityScore: existing.popularityScore,
        nextAvailabilityLabel: _nextAvailabilityLabel(draft.requestableSlots),
        price: draft.price,
        descriptionSnippet: draft.descriptionSnippet.trim(),
        coverMedia: draft.galleryMedia.isEmpty
            ? null
            : draft.galleryMedia.first,
      ),
    );
    _serviceMetaById[serviceId] = _serviceMetaFromDraft(draft);

    _refreshBrandSummary(existing.brandId);
    _refreshBrandSummary(brand?.id);
    _refreshProviderSummary(providerId);
  }

  @override
  Future<void> archiveProviderService({
    required String providerId,
    required String serviceId,
  }) async {
    await _delay();
    final service = _servicesById[serviceId];
    if (service == null || service.providerId != providerId) {
      throw const AppException('Service not found for this provider.');
    }
    if (!_canArchiveService(serviceId)) {
      throw const AppException(
        'Only provider-created services can be deleted in this MVP flow.',
      );
    }

    _archivedServiceIds.add(serviceId);
    _refreshBrandSummary(service.brandId);
    _refreshProviderSummary(providerId);
  }

  @override
  Future<ProviderBrandsData> getProviderBrands(String providerId) async {
    await _delay();
    final provider = _providersById[providerId];
    if (provider == null) {
      throw const AppException('Provider not found.');
    }

    final brands =
        provider.brandIds
            .map((brandId) => _brandsById[brandId])
            .whereType<BrandSummary>()
            .toList()
          ..sort((a, b) => a.name.compareTo(b.name));

    return ProviderBrandsData(
      brands: brands
          .map(
            (brand) => ProviderManagedBrandListItem(
              summary: brand,
              joinRequestCount:
                  _brandJoinRequestsByBrandId[brand.id]?.length ?? 0,
            ),
          )
          .toList(),
      totalServiceCount: brands.fold<int>(
        0,
        (total, brand) => total + brand.serviceCount,
      ),
      pendingJoinRequestCount: brands.fold<int>(
        0,
        (total, brand) =>
            total + (_brandJoinRequestsByBrandId[brand.id]?.length ?? 0),
      ),
    );
  }

  @override
  Future<ProviderManagedBrand> getProviderBrand({
    required String brandId,
    required String providerId,
  }) async {
    await _delay();
    _requireOwnedBrand(brandId: brandId, providerId: providerId);

    return ProviderManagedBrand(
      detail: _buildBrandDetail(brandId),
      draft: _draftFromBrand(_brandsById[brandId]!),
      joinRequests: List<BrandJoinRequest>.of(
        _brandJoinRequestsByBrandId[brandId] ?? const [],
      ),
    );
  }

  @override
  Future<String> createProviderBrand({
    required String providerId,
    required ProviderBrandDraft draft,
  }) async {
    await _delay();
    final provider = _providersById[providerId];
    if (provider == null) {
      throw const AppException('Provider not found.');
    }

    final brandId = 'brand_${_brandIdSeed++}';
    final summary = BrandSummary(
      id: brandId,
      name: draft.name.trim(),
      headline: draft.headline.trim(),
      addressLine: draft.addressLine.trim(),
      distanceKm: provider.distanceKm,
      rating: provider.rating,
      reviewCount: 0,
      serviceCount: 0,
      memberCount: 1,
      categoryIds: List<String>.of(provider.categoryIds),
      visibilityLabels: draft.visibilityLabels,
      popularityScore: (provider.popularityScore - 8).clamp(20, 99),
      openNow: draft.openNow,
      logoMedia: draft.logoMedia,
    );

    _brands.add(summary);
    _brandMetaById[brandId] = _BrandMeta(
      description: draft.description.trim(),
      mapHint: draft.mapHint.trim(),
      logoMedia: draft.logoMedia,
    );
    _brandJoinRequestsByBrandId[brandId] = [];

    _replaceProvider(
      ProviderSummary(
        id: provider.id,
        name: provider.name,
        headline: provider.headline,
        bio: provider.bio,
        distanceKm: provider.distanceKm,
        rating: provider.rating,
        reviewCount: provider.reviewCount,
        completedReservations: provider.completedReservations,
        responseReliability: provider.responseReliability,
        brandIds: [...provider.brandIds, brandId],
        categoryIds: provider.categoryIds,
        visibilityLabels: provider.visibilityLabels,
        popularityScore: provider.popularityScore,
        availableNow: provider.availableNow,
      ),
    );

    return brandId;
  }

  @override
  Future<void> updateProviderBrand({
    required String providerId,
    required String brandId,
    required ProviderBrandDraft draft,
  }) async {
    await _delay();
    final existing = _requireOwnedBrand(
      brandId: brandId,
      providerId: providerId,
    );

    _replaceBrand(
      BrandSummary(
        id: existing.id,
        name: draft.name.trim(),
        headline: draft.headline.trim(),
        addressLine: draft.addressLine.trim(),
        distanceKm: existing.distanceKm,
        rating: existing.rating,
        reviewCount: existing.reviewCount,
        serviceCount: existing.serviceCount,
        memberCount: existing.memberCount,
        categoryIds: existing.categoryIds,
        visibilityLabels: draft.visibilityLabels,
        popularityScore: existing.popularityScore,
        openNow: draft.openNow,
        logoMedia: draft.logoMedia,
      ),
    );
    _brandMetaById[brandId] = _BrandMeta(
      description: draft.description.trim(),
      mapHint: draft.mapHint.trim(),
      logoMedia: draft.logoMedia,
    );
    _refreshBrandSummary(brandId);
  }

  @override
  Future<void> acceptBrandJoinRequest({
    required String providerId,
    required String brandId,
    required String requestId,
  }) async {
    await _delay();
    final brand = _requireOwnedBrand(brandId: brandId, providerId: providerId);
    final requests = _brandJoinRequestsByBrandId[brandId];
    if (requests == null ||
        requests.every((request) => request.id != requestId)) {
      throw const AppException('Join request not found.');
    }

    requests.removeWhere((request) => request.id == requestId);
    _replaceBrand(
      BrandSummary(
        id: brand.id,
        name: brand.name,
        headline: brand.headline,
        addressLine: brand.addressLine,
        distanceKm: brand.distanceKm,
        rating: brand.rating,
        reviewCount: brand.reviewCount,
        serviceCount: brand.serviceCount,
        memberCount: brand.memberCount + 1,
        categoryIds: brand.categoryIds,
        visibilityLabels: brand.visibilityLabels,
        popularityScore: brand.popularityScore,
        openNow: brand.openNow,
        logoMedia: _brandMetaById[brandId]?.logoMedia ?? brand.logoMedia,
      ),
    );
  }

  @override
  Future<void> rejectBrandJoinRequest({
    required String providerId,
    required String brandId,
    required String requestId,
  }) async {
    await _delay();
    _requireOwnedBrand(brandId: brandId, providerId: providerId);
    final requests = _brandJoinRequestsByBrandId[brandId];
    if (requests == null ||
        requests.every((request) => request.id != requestId)) {
      throw const AppException('Join request not found.');
    }
    requests.removeWhere((request) => request.id == requestId);
  }

  List<AvailabilityWindow> _availabilityForService(String serviceId) {
    return switch (serviceId) {
      'classic-haircut' => [
        AvailabilityWindow(
          startsAt: _dateAt(0, 14, 0),
          label: 'Today · 14:00',
          available: true,
          note: 'Manual approval',
        ),
        AvailabilityWindow(
          startsAt: _dateAt(0, 16, 0),
          label: 'Today · 16:00',
          available: true,
          note: 'Manual approval',
        ),
        AvailabilityWindow(
          startsAt: _dateAt(1, 11, 30),
          label: 'Tomorrow · 11:30',
          available: true,
        ),
      ],
      'precision-beard-trim' => [
        AvailabilityWindow(
          startsAt: _dateAt(0, 16, 30),
          label: 'Today · 16:30',
          available: true,
          note: 'Auto confirm',
        ),
        AvailabilityWindow(
          startsAt: _dateAt(0, 17, 0),
          label: 'Today · 17:00',
          available: true,
          note: 'Auto confirm',
        ),
        AvailabilityWindow(
          startsAt: _dateAt(1, 12, 0),
          label: 'Tomorrow · 12:00',
          available: true,
        ),
      ],
      'dental-consultation' => [
        AvailabilityWindow(
          startsAt: _dateAt(1, 11, 0),
          label: 'Tomorrow · 11:00',
          available: true,
          note: 'Manual approval',
        ),
        AvailabilityWindow(
          startsAt: _dateAt(1, 13, 30),
          label: 'Tomorrow · 13:30',
          available: true,
          note: 'Manual approval',
        ),
        AvailabilityWindow(
          startsAt: _dateAt(5, 9, 30),
          label: 'Friday · 09:30',
          available: false,
          note: 'Filled',
        ),
      ],
      'professional-cleaning' => [
        AvailabilityWindow(
          startsAt: _dateAt(5, 10, 30),
          label: 'Friday · 10:30',
          available: true,
          note: 'Auto confirm',
        ),
        AvailabilityWindow(
          startsAt: _dateAt(5, 12, 0),
          label: 'Friday · 12:00',
          available: true,
          note: 'Auto confirm',
        ),
      ],
      'signature-skin-reset' => [
        AvailabilityWindow(
          startsAt: _dateAt(6, 13, 0),
          label: 'Saturday · 13:00',
          available: true,
          note: 'Manual approval',
        ),
        AvailabilityWindow(
          startsAt: _dateAt(6, 16, 0),
          label: 'Saturday · 16:00',
          available: true,
          note: 'Manual approval',
        ),
      ],
      _ => [
        AvailabilityWindow(
          startsAt: _dateAt(7, 18, 0),
          label: 'Monday · 18:00',
          available: true,
          note: 'Requestable',
        ),
        AvailabilityWindow(
          startsAt: _dateAt(8, 10, 0),
          label: 'Tuesday · 10:00',
          available: true,
          note: 'Requestable',
        ),
      ],
    };
  }

  BrandDetail _buildBrandDetail(String brandId) {
    final brand = _brandsById[brandId];
    if (brand == null) {
      throw const AppException('Brand not found.');
    }

    final members = _providers
        .where((provider) => provider.brandIds.contains(brandId))
        .toList();
    final services = _discoverableServices
        .where((service) => service.brandId == brandId)
        .toList();
    final meta = _brandMetaById[brandId];

    return BrandDetail(
      summary: brand,
      description:
          meta?.description ??
          'This brand keeps its positioning clear, flexible, and review-driven.',
      mapHint:
          meta?.mapHint ??
          'Map preview will connect to the geolocation abstraction in a later pass.',
      members: members,
      services: services,
      reviews: _reviewsByEntity[brandId] ?? const [],
    );
  }

  ServiceDetail _buildServiceDetail(String serviceId) {
    final service = _servicesById[serviceId];
    if (service == null) {
      throw const AppException('Service not found.');
    }

    final provider = _providersById[service.providerId];
    if (provider == null) {
      throw const AppException('Provider not found for this service.');
    }

    final brand = service.brandId == null
        ? null
        : _brandsById[service.brandId!];
    final meta = _metaForService(service);

    return ServiceDetail(
      summary: service,
      description:
          service.descriptionSnippet ??
          'Flexible reservation flow with clear approval messaging.',
      about: meta.about,
      availabilitySummary: meta.availabilitySummary,
      requestableSlots: meta.requestableSlots,
      waitingTimeLabel: '${meta.waitingTimeMinutes}-minute arrival tolerance',
      freeCancellationLabel:
          'Free cancellation up to ${meta.freeCancellationHours} hours before',
      galleryMedia: meta.galleryMedia,
      provider: provider,
      brand: brand,
      reviews: _reviewsByEntity[serviceId] ?? const [],
    );
  }

  ProviderServiceDraft _draftFromService(ServiceSummary service) {
    final meta = _metaForService(service);
    return ProviderServiceDraft(
      name: service.name,
      categoryId: service.categoryId,
      categoryName: service.categoryName,
      addressLine: service.addressLine,
      descriptionSnippet: service.descriptionSnippet ?? '',
      about: meta.about,
      approvalMode: service.approvalMode,
      isAvailable: service.isAvailable,
      serviceType: meta.serviceType,
      waitingTimeMinutes: meta.waitingTimeMinutes,
      leadTimeHours: meta.leadTimeHours,
      freeCancellationHours: meta.freeCancellationHours,
      visibilityLabels: service.visibilityLabels,
      requestableSlots: meta.requestableSlots,
      exceptionNotes: meta.exceptionNotes,
      galleryMedia: meta.galleryMedia,
      brandId: service.brandId,
      brandName: service.brandName,
      price: service.price,
    );
  }

  ProviderBrandDraft _draftFromBrand(BrandSummary brand) {
    final meta = _brandMetaById[brand.id];
    return ProviderBrandDraft(
      name: brand.name,
      headline: brand.headline,
      addressLine: brand.addressLine,
      description:
          meta?.description ??
          'This brand keeps its positioning clear, flexible, and review-driven.',
      mapHint:
          meta?.mapHint ??
          'Map preview will connect to the geolocation abstraction in a later pass.',
      visibilityLabels: brand.visibilityLabels,
      openNow: brand.openNow,
      logoMedia: meta?.logoMedia ?? brand.logoMedia,
    );
  }

  _ServiceMeta _metaForService(ServiceSummary service) {
    return _serviceMetaById[service.id] ??
        _ServiceMeta(
          about:
              'Flexible reservation flow with clear availability and approval settings.',
          availabilitySummary: service.approvalMode == ApprovalMode.manual
              ? 'Selectable times remain requestable until the provider responds. If no response arrives in 5 minutes, the request expires.'
              : 'Available times can confirm immediately when still open.',
          requestableSlots: _availabilityForService(service.id),
          waitingTimeMinutes: _defaultWaitingTimeFor(service.categoryId),
          freeCancellationHours: _defaultCancellationHoursFor(
            service.categoryId,
          ),
          leadTimeHours: 1,
          serviceType: ManagedServiceType.solo,
          galleryMedia: const [
            AppMediaAsset.generated(
              id: 'fallback-service-0',
              label: 'Overview',
            ),
            AppMediaAsset.generated(id: 'fallback-service-1', label: 'Space'),
            AppMediaAsset.generated(id: 'fallback-service-2', label: 'Result'),
          ],
          exceptionNotes: const [],
        );
  }

  _ServiceMeta _serviceMetaFromDraft(ProviderServiceDraft draft) {
    final slots = List<AvailabilityWindow>.of(draft.requestableSlots)
      ..sort((a, b) => a.startsAt.compareTo(b.startsAt));
    return _ServiceMeta(
      about: draft.about.trim(),
      availabilitySummary: draft.approvalMode == ApprovalMode.manual
          ? 'Selectable times remain requestable until the provider responds. If no response arrives in 5 minutes, the request expires.'
          : 'Available times can confirm immediately when still open.',
      requestableSlots: slots,
      waitingTimeMinutes: draft.waitingTimeMinutes,
      freeCancellationHours: draft.freeCancellationHours,
      leadTimeHours: draft.leadTimeHours,
      serviceType: draft.serviceType,
      galleryMedia: draft.galleryMedia
          .map((asset) => asset.copyWith(label: asset.label.trim()))
          .where((asset) => asset.label.isNotEmpty)
          .toList(),
      exceptionNotes: draft.exceptionNotes
          .map((note) => note.trim())
          .where((note) => note.isNotEmpty)
          .toList(),
    );
  }

  BrandSummary _requireOwnedBrand({
    required String brandId,
    required String providerId,
  }) {
    final brand = _brandsById[brandId];
    final provider = _providersById[providerId];
    if (brand == null ||
        provider == null ||
        !provider.brandIds.contains(brandId)) {
      throw const AppException('Brand not found for this provider.');
    }
    return brand;
  }

  void _refreshBrandSummary(String? brandId) {
    if (brandId == null) {
      return;
    }

    final brand = _brandsById[brandId];
    if (brand == null) {
      return;
    }

    final activeServices = _discoverableServices
        .where((service) => service.brandId == brandId)
        .toList();
    final categoryIds = activeServices
        .map((service) => service.categoryId)
        .toSet()
        .toList();

    _replaceBrand(
      BrandSummary(
        id: brand.id,
        name: brand.name,
        headline: brand.headline,
        addressLine: brand.addressLine,
        distanceKm: brand.distanceKm,
        rating: brand.rating,
        reviewCount: brand.reviewCount,
        serviceCount: activeServices.length,
        memberCount: brand.memberCount,
        categoryIds: categoryIds.isEmpty ? brand.categoryIds : categoryIds,
        visibilityLabels: brand.visibilityLabels,
        popularityScore: brand.popularityScore,
        openNow: brand.openNow,
        logoMedia: _brandMetaById[brandId]?.logoMedia ?? brand.logoMedia,
      ),
    );
  }

  void _refreshProviderSummary(String providerId) {
    final provider = _providersById[providerId];
    if (provider == null) {
      return;
    }

    final services = _discoverableServices
        .where((service) => service.providerId == providerId)
        .toList();
    final categoryIds = services
        .map((service) => service.categoryId)
        .toSet()
        .toList();

    _replaceProvider(
      ProviderSummary(
        id: provider.id,
        name: provider.name,
        headline: provider.headline,
        bio: provider.bio,
        distanceKm: provider.distanceKm,
        rating: provider.rating,
        reviewCount: provider.reviewCount,
        completedReservations: provider.completedReservations,
        responseReliability: provider.responseReliability,
        brandIds: provider.brandIds,
        categoryIds: categoryIds.isEmpty ? provider.categoryIds : categoryIds,
        visibilityLabels: provider.visibilityLabels,
        popularityScore: provider.popularityScore,
        availableNow: services.any((service) => service.isAvailable),
      ),
    );
  }

  void _replaceBrand(BrandSummary updated) {
    final index = _brands.indexWhere((brand) => brand.id == updated.id);
    if (index >= 0) {
      _brands[index] = updated;
    }
  }

  void _replaceProvider(ProviderSummary updated) {
    final index = _providers.indexWhere(
      (provider) => provider.id == updated.id,
    );
    if (index >= 0) {
      _providers[index] = updated;
    }
  }

  void _replaceService(ServiceSummary updated) {
    final index = _services.indexWhere((service) => service.id == updated.id);
    if (index >= 0) {
      _services[index] = updated;
    }
  }

  bool _canArchiveService(String serviceId) => serviceId.startsWith('service_');

  String _nextAvailabilityLabel(List<AvailabilityWindow> slots) {
    final available = slots.where((slot) => slot.available).toList()
      ..sort((a, b) => a.startsAt.compareTo(b.startsAt));
    if (available.isEmpty) {
      return 'Availability on request';
    }
    return available.first.label;
  }

  int _defaultWaitingTimeFor(String categoryId) {
    return switch (categoryId) {
      'dentist' => 15,
      'consulting' => 5,
      _ => 10,
    };
  }

  int _defaultCancellationHoursFor(String categoryId) {
    return switch (categoryId) {
      'dentist' => 12,
      'consulting' => 6,
      _ => 2,
    };
  }

  int _compareBrands(BrandSummary a, BrandSummary b, SearchSort sort) {
    return switch (sort) {
      SearchSort.proximity => a.distanceKm.compareTo(b.distanceKm),
      SearchSort.rating => b.rating.compareTo(a.rating),
      SearchSort.price => 0,
      SearchSort.popularity => b.popularityScore.compareTo(a.popularityScore),
      SearchSort.availability => _boolScore(
        b.openNow,
      ).compareTo(_boolScore(a.openNow)),
    };
  }

  int _compareProviders(ProviderSummary a, ProviderSummary b, SearchSort sort) {
    return switch (sort) {
      SearchSort.proximity => a.distanceKm.compareTo(b.distanceKm),
      SearchSort.rating => b.rating.compareTo(a.rating),
      SearchSort.price => 0,
      SearchSort.popularity => b.popularityScore.compareTo(a.popularityScore),
      SearchSort.availability => _boolScore(
        b.availableNow,
      ).compareTo(_boolScore(a.availableNow)),
    };
  }

  int _compareServices(ServiceSummary a, ServiceSummary b, SearchSort sort) {
    return switch (sort) {
      SearchSort.proximity => a.distanceKm.compareTo(b.distanceKm),
      SearchSort.rating => b.rating.compareTo(a.rating),
      SearchSort.price => _priceForSort(a).compareTo(_priceForSort(b)),
      SearchSort.popularity => b.popularityScore.compareTo(a.popularityScore),
      SearchSort.availability => _boolScore(
        b.isAvailable,
      ).compareTo(_boolScore(a.isAvailable)),
    };
  }

  int _boolScore(bool value) => value ? 1 : 0;

  bool _matchesBrandFilters(BrandSummary brand, SearchFilters filters) {
    if (filters.categoryId != null &&
        !brand.categoryIds.contains(filters.categoryId)) {
      return false;
    }
    if (filters.maxDistanceKm != null &&
        brand.distanceKm > filters.maxDistanceKm!) {
      return false;
    }
    if (filters.minRating != null && brand.rating < filters.minRating!) {
      return false;
    }
    if (filters.availableOnly && !brand.openNow) {
      return false;
    }
    return true;
  }

  bool _matchesBrandQuery(BrandSummary brand, String query) {
    if (query.isEmpty) {
      return true;
    }
    final haystack = [
      brand.name,
      brand.headline,
      brand.addressLine,
      ...brand.categoryIds,
    ].join(' ').toLowerCase();
    return haystack.contains(query);
  }

  bool _matchesProviderFilters(
    ProviderSummary provider,
    SearchFilters filters,
  ) {
    if (filters.categoryId != null &&
        !provider.categoryIds.contains(filters.categoryId)) {
      return false;
    }
    if (filters.maxDistanceKm != null &&
        provider.distanceKm > filters.maxDistanceKm!) {
      return false;
    }
    if (filters.minRating != null && provider.rating < filters.minRating!) {
      return false;
    }
    if (filters.availableOnly && !provider.availableNow) {
      return false;
    }
    return true;
  }

  bool _matchesProviderQuery(ProviderSummary provider, String query) {
    if (query.isEmpty) {
      return true;
    }
    final relatedBrands = provider.brandIds
        .map((brandId) => _brandsById[brandId]?.name ?? '')
        .join(' ');
    final haystack = [
      provider.name,
      provider.headline,
      provider.bio,
      relatedBrands,
      ...provider.categoryIds,
    ].join(' ').toLowerCase();
    return haystack.contains(query);
  }

  bool _matchesServiceFilters(ServiceSummary service, SearchFilters filters) {
    if (filters.categoryId != null &&
        service.categoryId != filters.categoryId) {
      return false;
    }
    if (filters.maxPrice != null &&
        (service.price == null || service.price! > filters.maxPrice!)) {
      return false;
    }
    if (filters.maxDistanceKm != null &&
        service.distanceKm > filters.maxDistanceKm!) {
      return false;
    }
    if (filters.minRating != null && service.rating < filters.minRating!) {
      return false;
    }
    if (filters.availableOnly && !service.isAvailable) {
      return false;
    }
    return true;
  }

  bool _matchesServiceQuery(ServiceSummary service, String query) {
    if (query.isEmpty) {
      return true;
    }
    final haystack = [
      service.name,
      service.categoryName,
      service.providerName,
      service.brandName ?? '',
      service.addressLine,
      service.descriptionSnippet ?? '',
    ].join(' ').toLowerCase();
    return haystack.contains(query);
  }

  double _priceForSort(ServiceSummary service) =>
      service.price ?? double.maxFinite;

  Future<void> _delay() =>
      Future<void>.delayed(const Duration(milliseconds: 220));
}

class _BrandMeta {
  const _BrandMeta({
    required this.description,
    required this.mapHint,
    this.logoMedia,
  });

  final String description;
  final String mapHint;
  final AppMediaAsset? logoMedia;
}

class _ServiceMeta {
  const _ServiceMeta({
    required this.about,
    required this.availabilitySummary,
    required this.requestableSlots,
    required this.waitingTimeMinutes,
    required this.freeCancellationHours,
    required this.leadTimeHours,
    required this.serviceType,
    required this.galleryMedia,
    required this.exceptionNotes,
  });

  final String about;
  final String availabilitySummary;
  final List<AvailabilityWindow> requestableSlots;
  final int waitingTimeMinutes;
  final int freeCancellationHours;
  final int leadTimeHours;
  final ManagedServiceType serviceType;
  final List<AppMediaAsset> galleryMedia;
  final List<String> exceptionNotes;
}

DateTime _dateAt(int dayOffset, int hour, int minute) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day + dayOffset, hour, minute);
}

class BackendDiscoveryRepository implements DiscoveryRepository {
  BackendDiscoveryRepository({
    required ApiClient apiClient,
    void Function(List<DiscoveryCategory> categories)? onCategoriesUpdated,
  }) : _apiClient = apiClient,
       _onCategoriesUpdated = onCategoriesUpdated;

  static const _cacheTtl = Duration(seconds: 30);

  final ApiClient _apiClient;
  final void Function(List<DiscoveryCategory> categories)? _onCategoriesUpdated;

  List<DiscoveryCategory>? _categoriesCache;
  DateTime? _categoriesFetchedAt;
  List<ServiceSummary>? _servicesCache;
  DateTime? _servicesFetchedAt;
  List<BrandSummary>? _brandsCache;
  DateTime? _brandsFetchedAt;
  List<ProviderSummary>? _providersCache;
  DateTime? _providersFetchedAt;

  final Map<String, ServiceSummary> _serviceSummaryCache = {};
  final Map<String, BrandSummary> _brandSummaryCache = {};
  final Map<String, ProviderSummary> _providerSummaryCache = {};

  @override
  List<DiscoveryCategory> get categories =>
      _categoriesCache != null && _categoriesCache!.isNotEmpty
      ? List<DiscoveryCategory>.unmodifiable(_categoriesCache!)
      : const [];

  @override
  DiscoveryCategory? categoryById(String id) {
    for (final category in categories) {
      if (category.id == id) {
        return category;
      }
    }

    return null;
  }

  @override
  ServiceSummary? serviceSummaryById(String id) => _serviceSummaryCache[id];

  @override
  Future<List<DiscoveryCategory>> getCategories() => _fetchCategories();

  @override
  Future<BrandDetail> getBrandDetail(String id) async {
    final payload = await _apiClient.get<dynamic>(
      '/brands/$id',
      mapper: (data) => data,
    );
    final entity = _extractEntity(payload, ['brand', 'item']);
    final brandContent = _brandContent(entity);
    final summary = _parseBrandSummary(entity);
    _rememberBrand(summary);

    final providers = await _fetchBrandMembers(id);
    final services = await _fetchServiceSummaries(brandId: id);

    return BrandDetail(
      summary: summary,
      description: brandContent.description,
      mapHint: brandContent.mapHint,
      members: providers,
      services: services,
      reviews: const [],
    );
  }

  @override
  Future<CustomerHomeData> getCustomerHomeData() async {
    final fetchedCategories = await _fetchCategories();
    final services = await _fetchServiceSummaries();
    final brands = await _fetchBrandSummaries();
    final providers = await _fetchProviderSummaries();

    final nearYou = List<ServiceSummary>.of(services)
      ..sort((left, right) => left.distanceKm.compareTo(right.distanceKm));
    final featured = services
        .where(
          (service) =>
              service.visibilityLabels.contains(VisibilityLabel.vip) ||
              service.visibilityLabels.contains(VisibilityLabel.sponsored),
        )
        .toList(growable: false);
    final bestOfMonth = services
        .where(
          (service) =>
              service.visibilityLabels.contains(VisibilityLabel.bestOfMonth),
        )
        .toList(growable: false);
    final popularBrands = List<BrandSummary>.of(brands)
      ..sort(
        (left, right) => right.popularityScore.compareTo(left.popularityScore),
      );
    final popularProviders = List<ProviderSummary>.of(providers)
      ..sort(
        (left, right) => right.popularityScore.compareTo(left.popularityScore),
      );

    return CustomerHomeData(
      nearYou: nearYou.take(4).toList(growable: false),
      featured: featured.take(4).toList(growable: false),
      bestOfMonth: bestOfMonth.take(4).toList(growable: false),
      categories: fetchedCategories,
      popularBrands: popularBrands.take(3).toList(growable: false),
      popularProviders: popularProviders.take(3).toList(growable: false),
    );
  }

  @override
  Future<ProviderDetail> getProviderDetail(String id) async {
    final summary = await _fetchProviderSummary(id);
    final services = await _fetchServiceSummaries(ownerUserId: id);
    final brandIds = {
      ...summary.brandIds,
      for (final service in services)
        if (service.brandId != null) service.brandId!,
    };
    final brands = (await _fetchBrandSummaries())
        .where((brand) => brandIds.contains(brand.id))
        .toList(growable: false);

    return ProviderDetail(
      summary: summary,
      associatedBrands: brands,
      services: services,
      reviews: const [],
    );
  }

  @override
  Future<DiscoverySearchResponse> search(DiscoverySearchRequest request) async {
    final payload = await _apiClient.get<dynamic>(
      '/search',
      queryParameters: _searchQueryParameters(request),
      mapper: (data) => data,
    );

    final services =
        _extractItems(payload, ['services'])
            .map(_tryParseServiceSummary)
            .whereType<ServiceSummary>()
            .where(
              (service) => _matchesServiceFilters(service, request.filters),
            )
            .toList(growable: false)
          ..sort((left, right) => _compareServices(left, right, request.sort));
    final brands =
        _extractItems(payload, ['brands'])
            .map(_tryParseBrandSummary)
            .whereType<BrandSummary>()
            .where((brand) => _matchesBrandFilters(brand, request.filters))
            .toList(growable: false)
          ..sort((left, right) => _compareBrands(left, right, request.sort));
    final providers =
        _extractItems(payload, ['providers'])
            .map(_tryParseProviderSummary)
            .whereType<ProviderSummary>()
            .where(
              (provider) => _matchesProviderFilters(provider, request.filters),
            )
            .toList(growable: false)
          ..sort((left, right) => _compareProviders(left, right, request.sort));

    for (final service in services) {
      _rememberService(service);
    }
    for (final brand in brands) {
      _rememberBrand(brand);
    }
    for (final provider in providers) {
      _rememberProvider(provider);
    }

    return DiscoverySearchResponse(
      services: services,
      brands: brands,
      providers: providers,
    );
  }

  @override
  Future<ServiceDetail> getServiceDetail(String id) async {
    final payload = await _apiClient.get<dynamic>(
      '/services/$id',
      mapper: (data) => data,
    );
    final entity = _extractEntity(payload, ['service', 'item']);
    final availabilityEntity = await _tryFetchServiceAvailability(id);
    final resolvedEntity = {
      ...entity,
      ...?availabilityEntity == null
          ? null
          : {'availability': availabilityEntity},
    };
    final serviceContent = _serviceContent(resolvedEntity);
    final summary = _parseServiceSummary(resolvedEntity);
    _rememberService(summary);

    final provider =
        _parseNestedProvider(resolvedEntity) ??
        await _findProvider(summary.providerId);
    final brand = summary.brandId == null
        ? null
        : _parseNestedBrand(resolvedEntity) ??
              await _findBrand(summary.brandId!);
    final slots = _parseAvailabilityWindows(resolvedEntity);

    return ServiceDetail(
      summary: summary,
      description: serviceContent.summary,
      about: serviceContent.about,
      availabilitySummary:
          _readString(resolvedEntity, [
            'availabilitySummary',
            'availability.summary',
            'availability.description',
          ]) ??
          _buildAvailabilitySummary(slots),
      requestableSlots: slots,
      waitingTimeLabel: _formatDurationLabel(
        minutes: _readInt(resolvedEntity, [
          'waitingTimeMinutes',
          'waitingTime',
          'waiting_time',
        ]),
        fallback: 'Provider-defined waiting time',
      ),
      freeCancellationLabel: _formatCancellationLabel(
        hours:
            _readInt(resolvedEntity, [
              'freeCancellationHours',
              'freeCancellationDeadlineHours',
              'free_cancellation_hours',
            ]) ??
            ((_readInt(resolvedEntity, [
                      'freeCancellationDeadlineMinutes',
                      'free_cancellation_deadline_minutes',
                    ]) ??
                    0) ~/
                60),
      ),
      galleryMedia: _parseMediaAssets(resolvedEntity),
      provider:
          provider ??
          ProviderSummary(
            id: summary.providerId,
            name: summary.providerName,
            headline: 'Provider details',
            bio: summary.descriptionSnippet ?? 'Provider details unavailable.',
            distanceKm: summary.distanceKm,
            rating: summary.rating,
            reviewCount: summary.reviewCount,
            completedReservations: 0,
            responseReliability: 'Response time unavailable',
            brandIds: [if (summary.brandId != null) summary.brandId!],
            categoryIds: [summary.categoryId],
            visibilityLabels: const [],
            popularityScore: summary.popularityScore,
            availableNow: summary.isAvailable,
          ),
      brand: brand,
      reviews: const [],
    );
  }

  @override
  Future<ProviderServicesData> getProviderServices(String providerId) async {
    final payload = await _apiClient.get<dynamic>(
      '/services',
      queryParameters: {'ownerUserId': providerId, 'includeInactive': true},
      mapper: (data) => data,
    );
    final items = _extractItems(payload, ['items', 'services'])
        .map((item) {
          final entity = asJsonMap(item);
          final summary = _parseServiceSummary(entity);
          _rememberService(summary);
          return ProviderManagedServiceListItem(
            summary: summary,
            serviceType: _parseManagedServiceType(entity),
            waitingTimeMinutes:
                _readInt(entity, [
                  'waitingTimeMinutes',
                  'waitingTime',
                  'waiting_time',
                ]) ??
                0,
            leadTimeHours:
                ((_readInt(entity, ['minAdvanceMinutes', 'leadTimeMinutes']) ??
                            0) /
                        60)
                    .round(),
            exceptionCount: _parseExceptionNotes(entity).length,
            canArchive: true,
          );
        })
        .toList(growable: false);

    return ProviderServicesData(
      services: items,
      activeCount: items.where((service) => service.summary.isAvailable).length,
      manualApprovalCount: items
          .where(
            (service) => service.summary.approvalMode == ApprovalMode.manual,
          )
          .length,
      brandLinkedCount: items
          .where((service) => service.summary.brandId != null)
          .length,
    );
  }

  @override
  Future<ProviderManagedService> getProviderService({
    required String serviceId,
    required String providerId,
  }) async {
    final payload = await _apiClient.get<dynamic>(
      '/services/$serviceId',
      mapper: (data) => data,
    );
    final entity = _extractEntity(payload, ['service', 'item']);
    final availabilityEntity = await _tryFetchServiceAvailability(serviceId);
    final resolvedEntity = {
      ...entity,
      ...?availabilityEntity == null
          ? null
          : {'availability': availabilityEntity},
    };
    final summary = _parseServiceSummary(resolvedEntity);
    if (summary.providerId != providerId) {
      throw const AppException('Service not found for this provider.');
    }
    _rememberService(summary);

    final provider =
        _parseNestedProvider(resolvedEntity) ??
        await _findProvider(summary.providerId);
    final brand = summary.brandId == null
        ? null
        : _parseNestedBrand(resolvedEntity) ??
              await _findBrand(summary.brandId!);
    final slots = _parseAvailabilityWindows(resolvedEntity);
    final draft = _draftFromServiceEntity(
      summary: summary,
      entity: resolvedEntity,
      slots: slots,
    );

    return ProviderManagedService(
      detail: ServiceDetail(
        summary: summary,
        description: _serviceContent(resolvedEntity).summary,
        about: _serviceContent(resolvedEntity).about,
        availabilitySummary:
            _readString(resolvedEntity, [
              'availabilitySummary',
              'availability.summary',
              'availability.description',
            ]) ??
            _buildAvailabilitySummary(slots),
        requestableSlots: slots,
        waitingTimeLabel: _formatDurationLabel(
          minutes: draft.waitingTimeMinutes,
          fallback: 'Provider-defined waiting time',
        ),
        freeCancellationLabel: _formatCancellationLabel(
          hours: draft.freeCancellationHours,
        ),
        galleryMedia: draft.galleryMedia,
        provider:
            provider ??
            ProviderSummary(
              id: summary.providerId,
              name: summary.providerName,
              headline: 'Provider details',
              bio:
                  summary.descriptionSnippet ?? 'Provider details unavailable.',
              distanceKm: summary.distanceKm,
              rating: summary.rating,
              reviewCount: summary.reviewCount,
              completedReservations: 0,
              responseReliability: 'Response time unavailable',
              brandIds: [if (summary.brandId != null) summary.brandId!],
              categoryIds: [summary.categoryId],
              visibilityLabels: const [],
              popularityScore: summary.popularityScore,
              availableNow: summary.isAvailable,
            ),
        brand: brand,
        reviews: const [],
      ),
      draft: draft,
      canArchive: true,
    );
  }

  @override
  Future<String> createProviderService({
    required String providerId,
    required ProviderServiceDraft draft,
  }) async {
    final payload = await _apiClient.post<dynamic>(
      '/services',
      data: _serviceDraftPayload(draft: draft),
      mapper: (data) => data,
    );
    final entity = _tryExtractEntity(payload, ['service', 'item']) ?? const {};
    final serviceId =
        _readString(entity, ['id', 'serviceId']) ??
        (payload is Map
            ? _readString(asJsonMap(payload), ['id', 'serviceId'])
            : null);
    if (serviceId == null || serviceId.isEmpty) {
      throw const AppException(
        'Service was created but the backend did not return an identifier.',
        type: AppExceptionType.server,
      );
    }

    await _uploadServicePhotos(serviceId, draft.galleryMedia);
    _invalidateProviderCatalogCaches(
      providerId: providerId,
      serviceId: serviceId,
      brandId: draft.brandId,
    );
    return serviceId;
  }

  @override
  Future<void> updateProviderService({
    required String providerId,
    required String serviceId,
    required ProviderServiceDraft draft,
  }) async {
    final existing = await getProviderService(
      serviceId: serviceId,
      providerId: providerId,
    );
    final payload = await _apiClient.patch<dynamic>(
      '/services/$serviceId',
      data: _serviceDraftPayload(draft: draft),
      mapper: (data) => data,
    );
    final entity = _tryExtractEntity(payload, ['service', 'item']);
    final summary = entity == null ? null : _tryParseServiceSummary(entity);
    if (summary != null) {
      _rememberService(summary);
    }

    await _replaceServiceAvailabilityExceptions(
      serviceId,
      draft.requestableSlots,
    );
    await _syncServicePhotos(
      serviceId: serviceId,
      previousAssets: existing.draft.galleryMedia,
      nextAssets: draft.galleryMedia,
    );
    _invalidateProviderCatalogCaches(
      providerId: providerId,
      serviceId: serviceId,
      brandId:
          summary?.brandId ?? draft.brandId ?? existing.detail.summary.brandId,
    );
  }

  @override
  Future<void> archiveProviderService({
    required String providerId,
    required String serviceId,
  }) async {
    await _apiClient.delete<dynamic>(
      '/services/$serviceId',
      mapper: (data) => data,
    );
    _invalidateProviderCatalogCaches(
      providerId: providerId,
      serviceId: serviceId,
    );
  }

  @override
  Future<ProviderBrandsData> getProviderBrands(String providerId) async {
    final provider = await _fetchProviderSummary(providerId);
    final ownedBrandIds = provider.brandIds.toSet();
    final services = await _fetchServiceSummaries(
      ownerUserId: providerId,
      includeInactive: true,
    );
    final brands = (await _fetchBrandSummaries())
        .where((brand) => ownedBrandIds.contains(brand.id))
        .toList(growable: false);

    final joinRequestCounts = <String, int>{};
    await Future.wait(
      brands.map((brand) async {
        final requests = await _fetchProviderBrandJoinRequests(
          providerId: providerId,
          brandId: brand.id,
        );
        joinRequestCounts[brand.id] = requests.length;
      }),
    );

    final items = brands
        .map(
          (brand) => ProviderManagedBrandListItem(
            summary: brand,
            joinRequestCount: joinRequestCounts[brand.id] ?? 0,
          ),
        )
        .toList(growable: false);

    return ProviderBrandsData(
      brands: items,
      totalServiceCount: services
          .where((service) => service.brandId != null)
          .length,
      pendingJoinRequestCount: items.fold<int>(
        0,
        (total, brand) => total + brand.joinRequestCount,
      ),
    );
  }

  @override
  Future<ProviderManagedBrand> getProviderBrand({
    required String brandId,
    required String providerId,
  }) async {
    final payload = await _apiClient.get<dynamic>(
      '/brands/$brandId',
      mapper: (data) => data,
    );
    final entity = _extractEntity(payload, ['brand', 'item']);
    final summary = _parseBrandSummary(entity);
    _rememberBrand(summary);

    final provider = await _fetchProviderSummary(providerId);
    if (!provider.brandIds.contains(brandId)) {
      throw const AppException('Brand not found for this provider.');
    }

    final members = await _fetchBrandMembers(brandId);
    final services = await _fetchServiceSummaries(
      ownerUserId: providerId,
      includeInactive: true,
      brandId: brandId,
    );
    final joinRequests = await _fetchProviderBrandJoinRequests(
      providerId: providerId,
      brandId: brandId,
    );
    final draft = _draftFromBrandEntity(summary: summary, entity: entity);

    return ProviderManagedBrand(
      detail: BrandDetail(
        summary: summary,
        description: _brandContent(entity).description,
        mapHint: _brandContent(entity).mapHint,
        members: members,
        services: services,
        reviews: const [],
      ),
      draft: draft,
      joinRequests: joinRequests,
    );
  }

  @override
  Future<String> createProviderBrand({
    required String providerId,
    required ProviderBrandDraft draft,
  }) async {
    final payload = await _apiClient.post<dynamic>(
      '/brands',
      data: _brandDraftPayload(draft: draft),
      mapper: (data) => data,
    );
    final entity = _tryExtractEntity(payload, ['brand', 'item']) ?? const {};
    final brandId =
        _readString(entity, ['id', 'brandId']) ??
        (payload is Map
            ? _readString(asJsonMap(payload), ['id', 'brandId'])
            : null);
    if (brandId == null || brandId.isEmpty) {
      throw const AppException(
        'Brand was created but the backend did not return an identifier.',
        type: AppExceptionType.server,
      );
    }

    await _uploadBrandLogo(brandId, draft.logoMedia);
    _invalidateProviderCatalogCaches(providerId: providerId, brandId: brandId);
    return brandId;
  }

  @override
  Future<void> updateProviderBrand({
    required String providerId,
    required String brandId,
    required ProviderBrandDraft draft,
  }) async {
    await _apiClient.patch<dynamic>(
      '/brands/$brandId',
      data: _brandDraftPayload(draft: draft),
      mapper: (data) => data,
    );
    await _uploadBrandLogo(brandId, draft.logoMedia);
    _invalidateProviderCatalogCaches(providerId: providerId, brandId: brandId);
  }

  @override
  Future<void> acceptBrandJoinRequest({
    required String providerId,
    required String brandId,
    required String requestId,
  }) async {
    await _apiClient.post<dynamic>(
      '/brands/$brandId/join-requests/$requestId/accept',
      mapper: (data) => data,
    );
    _invalidateProviderCatalogCaches(providerId: providerId, brandId: brandId);
  }

  @override
  Future<void> rejectBrandJoinRequest({
    required String providerId,
    required String brandId,
    required String requestId,
  }) async {
    await _apiClient.post<dynamic>(
      '/brands/$brandId/join-requests/$requestId/reject',
      mapper: (data) => data,
    );
    _invalidateProviderCatalogCaches(providerId: providerId, brandId: brandId);
  }

  ProviderServiceDraft _draftFromServiceEntity({
    required ServiceSummary summary,
    required JsonMap entity,
    required List<AvailabilityWindow> slots,
  }) {
    final content = _serviceContent(entity);
    final galleryMedia = _parseMediaAssets(entity);
    return ProviderServiceDraft(
      name: summary.name,
      categoryId: summary.categoryId,
      categoryName: summary.categoryName,
      addressLine: summary.addressLine,
      descriptionSnippet: content.summary,
      about: content.about,
      approvalMode: summary.approvalMode,
      isAvailable: summary.isAvailable,
      serviceType: _parseManagedServiceType(entity),
      waitingTimeMinutes:
          _readInt(entity, [
            'waitingTimeMinutes',
            'waitingTime',
            'waiting_time',
          ]) ??
          0,
      leadTimeHours:
          _readInt(entity, ['leadTimeHours', 'leadTime', 'lead_time']) ??
          ((_readInt(entity, [
                    'minAdvanceMinutes',
                    'leadTimeMinutes',
                    'min_advance_minutes',
                  ]) ??
                  0) ~/
              60),
      freeCancellationHours:
          _readInt(entity, [
            'freeCancellationHours',
            'freeCancellationDeadlineHours',
            'free_cancellation_hours',
          ]) ??
          ((_readInt(entity, [
                    'freeCancellationDeadlineMinutes',
                    'free_cancellation_deadline_minutes',
                  ]) ??
                  0) ~/
              60),
      visibilityLabels: summary.visibilityLabels,
      requestableSlots: slots,
      exceptionNotes: content.notes,
      galleryMedia: galleryMedia,
      brandId: summary.brandId,
      brandName: summary.brandName,
      price: summary.price,
    );
  }

  ProviderBrandDraft _draftFromBrandEntity({
    required BrandSummary summary,
    required JsonMap entity,
  }) {
    final content = _brandContent(entity);
    return ProviderBrandDraft(
      name: summary.name,
      headline: content.headline,
      addressLine: summary.addressLine,
      description: content.description,
      mapHint: content.mapHint,
      visibilityLabels: summary.visibilityLabels,
      openNow: summary.openNow,
      logoMedia:
          _parsePrimaryMediaAsset(entity, [
            'logoMedia',
            'logo',
            'brandLogo',
            'logoFile',
          ]) ??
          summary.logoMedia,
    );
  }

  Future<List<BrandJoinRequest>> _fetchProviderBrandJoinRequests({
    required String providerId,
    required String brandId,
  }) async {
    final provider = await _fetchProviderSummary(providerId);
    if (!provider.brandIds.contains(brandId)) {
      throw const AppException('Brand not found for this provider.');
    }

    final payload = await _apiClient.get<dynamic>(
      '/brands/$brandId/join-requests',
      mapper: (data) => data,
    );
    final items = _extractItems(payload, [
      'items',
      'joinRequests',
      'pendingJoinRequests',
      'membershipRequests',
    ]);
    return items
        .map(_tryParseBrandJoinRequest)
        .whereType<BrandJoinRequest>()
        .toList(growable: false);
  }

  void _invalidateProviderCatalogCaches({
    required String providerId,
    String? serviceId,
    String? brandId,
  }) {
    _servicesCache = null;
    _servicesFetchedAt = null;
    _brandsCache = null;
    _brandsFetchedAt = null;
    _providersCache = null;
    _providersFetchedAt = null;
    if (serviceId != null) {
      _serviceSummaryCache.remove(serviceId);
    }
    if (brandId != null) {
      _brandSummaryCache.remove(brandId);
    }
    _providerSummaryCache.remove(providerId);
  }

  Map<String, dynamic> _serviceDraftPayload({
    required ProviderServiceDraft draft,
  }) {
    final address = _addressPayload(draft.addressLine.trim());
    return {
      'name': draft.name.trim(),
      if (draft.categoryId.isNotEmpty) 'categoryId': draft.categoryId,
      'brandId': draft.brandId,
      'address': address,
      'description': _serviceDescriptionValue(draft),
      'approvalMode': _approvalModeValue(draft.approvalMode),
      'serviceType': _serviceTypeValue(draft.serviceType),
      'waitingTimeMinutes': draft.waitingTimeMinutes,
      'minAdvanceMinutes': draft.leadTimeHours * 60,
      'freeCancellationDeadlineMinutes': draft.freeCancellationHours * 60,
      'availabilityExceptions': _availabilityExceptionsPayload(
        draft.requestableSlots,
      ),
      if (draft.price != null) ...{
        'priceAmount': draft.price,
        'priceCurrency': 'AZN',
      },
    };
  }

  Map<String, dynamic> _brandDraftPayload({required ProviderBrandDraft draft}) {
    return {
      'name': draft.name.trim(),
      'description': _brandDescriptionValue(draft),
      'primaryAddress': _addressPayload(draft.addressLine.trim()),
    };
  }

  Future<void> _replaceServiceAvailabilityExceptions(
    String serviceId,
    List<AvailabilityWindow> slots,
  ) async {
    await _apiClient.put<dynamic>(
      '/services/$serviceId/availability-exceptions',
      data: {'exceptions': _availabilityExceptionsPayload(slots)},
      mapper: (data) => data,
    );
  }

  Future<void> _uploadServicePhotos(
    String serviceId,
    List<AppMediaAsset> assets,
  ) async {
    for (final asset in assets) {
      if (!asset.hasBytes) {
        continue;
      }
      await _apiClient.post<dynamic>(
        '/services/$serviceId/photos',
        data: _mediaFormData(asset),
        headers: const {'Content-Type': 'multipart/form-data'},
        mapper: (data) => data,
      );
    }
  }

  Future<void> _syncServicePhotos({
    required String serviceId,
    required List<AppMediaAsset> previousAssets,
    required List<AppMediaAsset> nextAssets,
  }) async {
    final nextIds = nextAssets
        .where((asset) => !asset.hasBytes)
        .map((asset) => asset.id)
        .toSet();
    for (final asset in previousAssets) {
      if (asset.hasBytes || nextIds.contains(asset.id)) {
        continue;
      }
      await _apiClient.delete<dynamic>(
        '/services/$serviceId/photos/${asset.id}',
        mapper: (data) => data,
      );
    }

    await _uploadServicePhotos(serviceId, nextAssets);
  }

  Future<void> _uploadBrandLogo(String brandId, AppMediaAsset? asset) async {
    if (asset == null || !asset.hasBytes) {
      return;
    }
    await _apiClient.post<dynamic>(
      '/brands/$brandId/logo',
      data: _mediaFormData(asset),
      headers: const {'Content-Type': 'multipart/form-data'},
      mapper: (data) => data,
    );
  }

  FormData _mediaFormData(AppMediaAsset asset) {
    return FormData.fromMap({
      'file': MultipartFile.fromBytes(
        asset.bytes!,
        filename: _filenameForAsset(asset),
      ),
    });
  }

  String _filenameForAsset(AppMediaAsset asset) {
    final base = asset.label
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    if (base.isEmpty) {
      return 'upload.jpg';
    }
    return '$base.jpg';
  }

  Map<String, dynamic> _addressPayload(String fullAddress) {
    final segments = fullAddress
        .split(',')
        .map((segment) => segment.trim())
        .where((segment) => segment.isNotEmpty)
        .toList(growable: false);
    final city = segments.length >= 2 ? segments[segments.length - 1] : 'Baku';
    final country = segments.length >= 3
        ? segments.last
        : _countryForCity(city);
    return {'fullAddress': fullAddress, 'city': city, 'country': country};
  }

  String _countryForCity(String city) {
    final normalized = city.trim().toLowerCase();
    return switch (normalized) {
      'baku' || 'baku city' => 'Azerbaijan',
      _ => 'Azerbaijan',
    };
  }

  String _serviceDescriptionValue(ProviderServiceDraft draft) {
    final buffer = StringBuffer(draft.descriptionSnippet.trim());
    final about = draft.about.trim();
    if (about.isNotEmpty && about != draft.descriptionSnippet.trim()) {
      if (buffer.isNotEmpty) {
        buffer.write('\n\n');
      }
      buffer.write(about);
    }
    final notes = draft.exceptionNotes
        .map((note) => note.trim())
        .where((note) => note.isNotEmpty)
        .toList(growable: false);
    if (notes.isNotEmpty) {
      if (buffer.isNotEmpty) {
        buffer.write('\n\n');
      }
      buffer.write('Operational notes:\n');
      buffer.write(notes.map((note) => '- $note').join('\n'));
    }
    return buffer.toString().trim();
  }

  String _brandDescriptionValue(ProviderBrandDraft draft) {
    final buffer = StringBuffer(draft.headline.trim());
    final description = draft.description.trim();
    if (description.isNotEmpty && description != draft.headline.trim()) {
      if (buffer.isNotEmpty) {
        buffer.write('\n\n');
      }
      buffer.write(description);
    }
    final mapHint = draft.mapHint.trim();
    if (mapHint.isNotEmpty) {
      if (buffer.isNotEmpty) {
        buffer.write('\n\n');
      }
      buffer.write('Map note: $mapHint');
    }
    return buffer.toString().trim();
  }

  List<Map<String, dynamic>> _availabilityExceptionsPayload(
    List<AvailabilityWindow> slots,
  ) {
    return slots
        .where((slot) => slot.available)
        .map((slot) {
          final local = slot.startsAt.toUtc();
          final end = local.add(const Duration(minutes: 59));
          return {
            'date':
                '${local.year.toString().padLeft(4, '0')}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}',
            'startTime':
                '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}',
            'endTime':
                '${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}',
            if (slot.note != null && slot.note!.trim().isNotEmpty)
              'note': slot.note!.trim(),
          };
        })
        .toList(growable: false);
  }

  ManagedServiceType _parseManagedServiceType(JsonMap item) {
    final explicit = _readString(item, ['serviceType', 'service_type', 'mode']);
    if (explicit != null && explicit.toLowerCase().contains('multi')) {
      return ManagedServiceType.multi;
    }
    final providerCount = _readInt(item, ['providerCount', 'teamSize']);
    if (providerCount != null && providerCount > 1) {
      return ManagedServiceType.multi;
    }
    return ManagedServiceType.solo;
  }

  List<String> _parseExceptionNotes(JsonMap item) {
    final values = _readList(item, [
      'exceptionNotes',
      'availabilityExceptions',
      'exceptions',
    ]);
    if (values == null) {
      return const [];
    }

    final notes = <String>[];
    for (final value in values) {
      if (value is String && value.trim().isNotEmpty) {
        notes.add(value.trim());
        continue;
      }
      if (value is Map) {
        final note = _readString(asJsonMap(value), [
          'note',
          'label',
          'message',
          'reason',
          'summary',
        ]);
        if (note != null && note.isNotEmpty) {
          notes.add(note);
        }
      }
    }

    return notes;
  }

  BrandJoinRequest? _tryParseBrandJoinRequest(dynamic raw) {
    if (raw is! Map) {
      return null;
    }
    final item = asJsonMap(raw);
    final id = _readString(item, ['id', 'requestId']);
    final applicantName = _readString(item, [
      'applicantName',
      'provider.fullName',
      'provider.name',
      'fullName',
      'name',
    ]);
    if (id == null || applicantName == null) {
      return null;
    }

    final requestedAt = _readDateTime(item, ['requestedAt', 'createdAt']);
    final requestedAtLabel =
        _readString(item, ['requestedAtLabel', 'createdAtLabel']) ??
        (requestedAt == null
            ? 'Pending review'
            : DateFormat('MMM d, HH:mm').format(requestedAt.toLocal()));

    return BrandJoinRequest(
      id: id,
      applicantName: applicantName,
      note:
          _readString(item, ['note', 'message', 'reason']) ??
          'No note provided.',
      requestedAtLabel: requestedAtLabel,
    );
  }

  JsonMap? _tryExtractEntity(dynamic payload, List<String> keys) {
    if (payload is! Map) {
      return null;
    }
    return _extractEntity(payload, keys);
  }

  String _approvalModeValue(ApprovalMode mode) {
    return switch (mode) {
      ApprovalMode.manual => 'MANUAL',
      ApprovalMode.automatic => 'AUTOMATIC',
    };
  }

  String _serviceTypeValue(ManagedServiceType type) {
    return switch (type) {
      ManagedServiceType.solo => 'SOLO',
      ManagedServiceType.multi => 'MULTI',
    };
  }

  Future<List<DiscoveryCategory>> _fetchCategories({bool force = false}) async {
    if (!force &&
        _categoriesCache != null &&
        _isCacheFresh(_categoriesFetchedAt)) {
      return _categoriesCache!;
    }

    final payload = await _apiClient.get<dynamic>(
      '/categories',
      mapper: (data) => data,
    );
    final items = _extractItems(payload, ['items', 'categories']);
    final categories = items
        .map(_tryParseCategory)
        .whereType<DiscoveryCategory>()
        .toList(growable: false);

    if (categories.isNotEmpty) {
      _categoriesCache = categories;
      _categoriesFetchedAt = DateTime.now();
      _onCategoriesUpdated?.call(categories);
    }

    return categories;
  }

  Future<List<ServiceSummary>> _fetchServiceSummaries({
    bool force = false,
    String? ownerUserId,
    String? brandId,
    bool includeInactive = false,
  }) async {
    final useCache = ownerUserId == null && brandId == null && !includeInactive;
    if (useCache &&
        !force &&
        _servicesCache != null &&
        _isCacheFresh(_servicesFetchedAt)) {
      return _servicesCache!;
    }

    final queryParameters = <String, dynamic>{
      ...?ownerUserId == null ? null : {'ownerUserId': ownerUserId},
      ...?brandId == null ? null : {'brandId': brandId},
      if (includeInactive) 'includeInactive': true,
    };
    final payload = await _apiClient.get<dynamic>(
      '/services',
      queryParameters: queryParameters,
      mapper: (data) => data,
    );
    final items = _extractItems(payload, ['items', 'services']);
    final services = items
        .map(_tryParseServiceSummary)
        .whereType<ServiceSummary>()
        .toList(growable: false);

    if (useCache) {
      _servicesCache = services;
      _servicesFetchedAt = DateTime.now();
    }
    for (final service in services) {
      _rememberService(service);
    }
    return services;
  }

  Future<List<BrandSummary>> _fetchBrandSummaries({bool force = false}) async {
    if (!force && _brandsCache != null && _isCacheFresh(_brandsFetchedAt)) {
      return _brandsCache!;
    }

    final payload = await _apiClient.get<dynamic>(
      '/brands',
      mapper: (data) => data,
    );
    final items = _extractItems(payload, ['items', 'brands']);
    final brands = items
        .map(_tryParseBrandSummary)
        .whereType<BrandSummary>()
        .toList(growable: false);

    _brandsCache = brands;
    _brandsFetchedAt = DateTime.now();
    for (final brand in brands) {
      _rememberBrand(brand);
    }
    return brands;
  }

  Future<List<ProviderSummary>> _fetchProviderSummaries({
    bool force = false,
    String? ownerUserId,
  }) async {
    final useCache = ownerUserId == null;
    if (useCache &&
        !force &&
        _providersCache != null &&
        _isCacheFresh(_providersFetchedAt)) {
      return _providersCache!;
    }

    final queryParameters = ownerUserId == null
        ? null
        : <String, dynamic>{'ownerUserId': ownerUserId};
    final payload = await _apiClient.get<dynamic>(
      '/service-owners',
      queryParameters: queryParameters,
      mapper: (data) => data,
    );
    final items = _extractItems(payload, [
      'items',
      'providers',
      'serviceOwners',
      'owners',
    ]);
    final providers = items
        .map(_tryParseProviderSummary)
        .whereType<ProviderSummary>()
        .toList(growable: false);

    if (useCache) {
      _providersCache = providers;
      _providersFetchedAt = DateTime.now();
    }
    for (final provider in providers) {
      _rememberProvider(provider);
    }
    return providers;
  }

  Future<BrandSummary?> _findBrand(String id) async {
    if (_brandSummaryCache.containsKey(id)) {
      return _brandSummaryCache[id];
    }

    final brands = await _fetchBrandSummaries();
    for (final brand in brands) {
      if (brand.id == id) {
        return brand;
      }
    }

    return null;
  }

  Future<ProviderSummary?> _findProvider(String id) async {
    if (_providerSummaryCache.containsKey(id)) {
      return _providerSummaryCache[id];
    }

    final providers = await _fetchProviderSummaries();
    for (final provider in providers) {
      if (provider.id == id) {
        return provider;
      }
    }

    return null;
  }

  Future<ProviderSummary> _fetchProviderSummary(String id) async {
    final cached = _providerSummaryCache[id];
    if (cached != null) {
      return cached;
    }

    final providers = await _fetchProviderSummaries(ownerUserId: id);
    for (final provider in providers) {
      if (provider.id == id) {
        return provider;
      }
    }

    throw const AppException('Provider not found.');
  }

  Future<List<ProviderSummary>> _fetchBrandMembers(String brandId) async {
    final payload = await _apiClient.get<dynamic>(
      '/brands/$brandId/members',
      mapper: (data) => data,
    );
    final items = _extractItems(payload, ['items', 'members', 'providers']);
    final members = items
        .map(_tryParseProviderSummary)
        .whereType<ProviderSummary>()
        .toList(growable: false);
    for (final member in members) {
      _rememberProvider(member);
    }
    return members;
  }

  Future<JsonMap?> _tryFetchServiceAvailability(String serviceId) async {
    try {
      final payload = await _apiClient.get<dynamic>(
        '/services/$serviceId/availability',
        mapper: (data) => data,
      );
      return payload is Map ? asJsonMap(payload) : null;
    } on AppException catch (error) {
      if (error.statusCode == 404 || error.statusCode == 405) {
        return null;
      }
      rethrow;
    }
  }

  Map<String, dynamic> _searchQueryParameters(DiscoverySearchRequest request) {
    return {
      if (request.query.trim().isNotEmpty) 'q': request.query.trim(),
      if (request.filters.categoryId != null)
        'categoryId': request.filters.categoryId,
      if (request.filters.maxPrice != null)
        'maxPriceAmount': request.filters.maxPrice,
      if (request.filters.maxDistanceKm != null)
        'radiusKm': request.filters.maxDistanceKm,
      if (request.filters.availableOnly) 'availableOnly': true,
      'sortBy': switch (request.sort) {
        SearchSort.proximity => 'PROXIMITY',
        SearchSort.rating => 'RATING',
        SearchSort.price => 'PRICE_LOW',
        SearchSort.popularity => 'POPULARITY',
        SearchSort.availability => 'AVAILABILITY',
      },
      'limit': 25,
    };
  }

  ({String summary, String about, List<String> notes}) _serviceContent(
    JsonMap item,
  ) {
    final explicitSummary = _readString(item, [
      'descriptionSnippet',
      'summary',
    ]);
    final explicitAbout = _readString(item, [
      'about',
      'details',
      'serviceAbout',
    ]);
    final rawDescription = _readString(item, ['description']) ?? '';
    final sections = rawDescription
        .split(RegExp(r'\n\s*\n'))
        .map((section) => section.trim())
        .where((section) => section.isNotEmpty)
        .toList(growable: false);
    final notesIndex = sections.indexWhere(
      (section) => section.startsWith('Operational notes:'),
    );
    final noteSection = notesIndex == -1 ? null : sections[notesIndex];
    final notes = {
      ..._parseExceptionNotes(item),
      ...?noteSection
          ?.split('\n')
          .skip(1)
          .map((line) => line.trim().replaceFirst(RegExp(r'^-\s*'), '').trim())
          .where((line) => line.isNotEmpty),
    }.toList(growable: false);
    final contentSections = notesIndex == -1
        ? sections
        : sections.take(notesIndex).toList(growable: false);

    final summary =
        explicitSummary ??
        (contentSections.isNotEmpty
            ? contentSections.first
            : (rawDescription.trim().isEmpty
                  ? 'Service details are available from the backend record.'
                  : rawDescription.trim()));
    final aboutSections = contentSections.length > 1
        ? contentSections.skip(1).toList(growable: false)
        : const <String>[];
    final about =
        explicitAbout ??
        (aboutSections.isNotEmpty ? aboutSections.join('\n\n') : summary);

    return (summary: summary, about: about, notes: notes);
  }

  ({String headline, String description, String mapHint}) _brandContent(
    JsonMap item,
  ) {
    final explicitHeadline = _readString(item, ['headline']);
    final explicitMapHint = _readString(item, ['mapHint', 'locationHint']);
    final rawDescription = _readString(item, ['description', 'about']) ?? '';
    final sections = rawDescription
        .split(RegExp(r'\n\s*\n'))
        .map((section) => section.trim())
        .where((section) => section.isNotEmpty)
        .toList(growable: false);
    final mapSectionIndex = sections.indexWhere(
      (section) => section.startsWith('Map note:'),
    );
    final mapHint =
        explicitMapHint ??
        (mapSectionIndex == -1
            ? 'Use the saved address in your maps app for directions.'
            : sections[mapSectionIndex].replaceFirst('Map note:', '').trim());
    final contentSections = mapSectionIndex == -1
        ? sections
        : sections.take(mapSectionIndex).toList(growable: false);
    final headline =
        explicitHeadline ??
        (contentSections.isNotEmpty ? contentSections.first : 'Brand profile');
    final description = contentSections.length > 1
        ? contentSections.skip(1).join('\n\n')
        : (rawDescription.trim().isEmpty ? headline : rawDescription.trim());

    return (headline: headline, description: description, mapHint: mapHint);
  }

  DiscoveryCategory? _tryParseCategory(dynamic raw) {
    if (raw is! Map) {
      return null;
    }

    final item = asJsonMap(raw);
    final id =
        _readString(item, ['id', 'slug', 'key']) ??
        _slugify(_readString(item, ['name']) ?? '');
    final name = _readString(item, ['name', 'title']);
    if (id.isEmpty || name == null || name.isEmpty) {
      return null;
    }

    return DiscoveryCategory(
      id: id,
      name: name,
      description:
          _readString(item, ['description', 'summary']) ??
          '$name services on Reziphay.',
    );
  }

  ServiceSummary? _tryParseServiceSummary(dynamic raw) {
    if (raw is! Map) {
      return null;
    }

    final item = asJsonMap(raw);
    final id = _readString(item, ['id']);
    final name = _readString(item, ['name', 'title']);
    if (id == null || name == null) {
      return null;
    }

    return _parseServiceSummary(item);
  }

  ServiceSummary _parseServiceSummary(JsonMap item) {
    final content = _serviceContent(item);
    final categoryId =
        _readString(item, ['category.id', 'categoryId', 'category_id']) ??
        'general';
    final categoryName =
        _readString(item, ['category.name', 'categoryName', 'category']) ??
        categoryById(categoryId)?.name ??
        'General';
    final providerId =
        _readString(item, ['owner.id', 'provider.id', 'providerId']) ??
        'provider';
    final providerName =
        _readString(item, [
          'owner.fullName',
          'provider.fullName',
          'provider.name',
          'providerName',
        ]) ??
        'Provider';
    final brandId = _readString(item, ['brand.id', 'brandId', 'brand_id']);
    final brandName = _readString(item, ['brand.name', 'brandName']);

    return ServiceSummary(
      id: _readString(item, ['id'])!,
      name: _readString(item, ['name', 'title'])!,
      categoryId: categoryId,
      categoryName: categoryName,
      providerId: providerId,
      providerName: providerName,
      addressLine:
          _readString(item, [
            'addressLine',
            'address.fullAddress',
            'address.addressLine',
            'serviceAddress.addressLine',
            'brand.primaryAddress.fullAddress',
            'brand.addressLine',
          ]) ??
          'Address not specified',
      distanceKm:
          _readDouble(item, ['distanceKm', 'distance_km']) ??
          _metersToKm(
            _readDouble(item, ['distanceMeters', 'distance_meters']),
          ) ??
          0,
      rating:
          _readDouble(item, [
            'rating',
            'ratingStats.averageRating',
            'stats.averageRating',
          ]) ??
          0,
      reviewCount:
          _readInt(item, [
            'reviewCount',
            'ratingStats.reviewCount',
            'stats.reviewCount',
          ]) ??
          0,
      visibilityLabels: _parseVisibilityLabels(
        _readList(item, [
          'visibilityLabels',
          'activeVisibilityLabels',
          'visibility.labels',
        ]),
      ),
      approvalMode: _parseApprovalMode(item),
      isAvailable:
          _readBool(item, ['isAvailable', 'available', 'openNow', 'isOpen']) ??
          true,
      popularityScore:
          _readInt(item, ['popularityScore', 'stats.popularityScore']) ?? 0,
      nextAvailabilityLabel:
          _readString(item, [
            'nextAvailabilityLabel',
            'nextAvailability',
            'availability.nextLabel',
          ]) ??
          (_readBool(item, ['isAvailable', 'available']) == true
              ? 'Availability from backend'
              : 'Check availability'),
      brandId: brandId,
      brandName: brandName,
      price: _readDouble(item, ['price', 'price.amount', 'priceAmount']),
      descriptionSnippet: content.summary,
      coverMedia:
          _parsePrimaryMediaAsset(item, ['coverMedia', 'cover', 'heroMedia']) ??
          _parseMediaAssets(item).firstOrNull,
    );
  }

  BrandSummary? _tryParseBrandSummary(dynamic raw) {
    if (raw is! Map) {
      return null;
    }

    final item = asJsonMap(raw);
    final id = _readString(item, ['id']);
    final name = _readString(item, ['name', 'title']);
    if (id == null || name == null) {
      return null;
    }

    return _parseBrandSummary(item);
  }

  BrandSummary _parseBrandSummary(JsonMap item) {
    final content = _brandContent(item);
    return BrandSummary(
      id: _readString(item, ['id'])!,
      name: _readString(item, ['name', 'title'])!,
      headline: content.headline,
      addressLine:
          _readString(item, [
            'addressLine',
            'address.fullAddress',
            'address.addressLine',
            'primaryAddress.fullAddress',
          ]) ??
          'Address not specified',
      distanceKm:
          _readDouble(item, ['distanceKm']) ??
          _metersToKm(_readDouble(item, ['distanceMeters'])) ??
          0,
      rating:
          _readDouble(item, [
            'rating',
            'ratingStats.averageRating',
            'stats.averageRating',
          ]) ??
          0,
      reviewCount:
          _readInt(item, [
            'reviewCount',
            'ratingStats.reviewCount',
            'stats.reviewCount',
          ]) ??
          0,
      serviceCount:
          _readInt(item, [
            'serviceCount',
            'servicesCount',
            'services.count',
            'stats.serviceCount',
          ]) ??
          0,
      memberCount:
          _readInt(item, [
            'memberCount',
            'membersCount',
            'members.count',
            'stats.memberCount',
          ]) ??
          0,
      categoryIds: _parseCategoryIds(
        _readList(item, ['categories', 'categoryIds']),
      ),
      visibilityLabels: _parseVisibilityLabels(
        _readList(item, [
          'visibilityLabels',
          'activeVisibilityLabels',
          'visibility.labels',
        ]),
      ),
      popularityScore:
          _readInt(item, ['popularityScore', 'stats.popularityScore']) ?? 0,
      openNow: _readBool(item, ['openNow', 'isOpen', 'availableNow']) ?? true,
      logoMedia: _parsePrimaryMediaAsset(item, [
        'logoMedia',
        'logo',
        'brandLogo',
        'logoFile',
      ]),
    );
  }

  ProviderSummary? _tryParseProviderSummary(dynamic raw) {
    if (raw is! Map) {
      return null;
    }

    final item = asJsonMap(raw);
    final id = _readString(item, ['id']);
    final name = _readString(item, ['fullName', 'name']);
    if (id == null || name == null) {
      return null;
    }

    return _parseProviderSummary(item);
  }

  ProviderSummary _parseProviderSummary(JsonMap item) {
    final brandIds = _parseIds(_readList(item, ['brands', 'brandIds']));
    final categoryIds = _parseCategoryIds(
      _readList(item, ['categories', 'categoryIds']),
    );
    final responseMinutes = _readInt(item, [
      'avgResponseMinutes',
      'responseTimeMinutes',
    ]);

    return ProviderSummary(
      id: _readString(item, ['id'])!,
      name: _readString(item, ['fullName', 'name'])!,
      headline:
          _readString(item, ['headline', 'description', 'title']) ??
          'Service provider',
      bio:
          _readString(item, ['bio', 'about', 'description']) ??
          'Provider profile',
      distanceKm:
          _readDouble(item, ['distanceKm']) ??
          _metersToKm(_readDouble(item, ['distanceMeters'])) ??
          0,
      rating:
          _readDouble(item, [
            'rating',
            'ratingStats.averageRating',
            'stats.averageRating',
          ]) ??
          0,
      reviewCount:
          _readInt(item, [
            'reviewCount',
            'ratingStats.reviewCount',
            'stats.reviewCount',
          ]) ??
          0,
      completedReservations:
          _readInt(item, [
            'completedReservations',
            'completedReservationCount',
            'stats.completedReservations',
          ]) ??
          0,
      responseReliability:
          _readString(item, ['responseReliability']) ??
          (responseMinutes == null
              ? 'Response time unavailable'
              : 'Usually replies in about $responseMinutes minutes'),
      brandIds: brandIds,
      categoryIds: categoryIds,
      visibilityLabels: _parseVisibilityLabels(
        _readList(item, [
          'visibilityLabels',
          'activeVisibilityLabels',
          'visibility.labels',
        ]),
      ),
      popularityScore:
          _readInt(item, ['popularityScore', 'stats.popularityScore']) ?? 0,
      availableNow:
          _readBool(item, ['availableNow', 'isAvailable', 'openNow']) ?? true,
    );
  }

  ProviderSummary? _parseNestedProvider(JsonMap item) {
    final rawProvider = _readMap(item, ['owner', 'provider', 'serviceOwner']);
    return rawProvider == null ? null : _tryParseProviderSummary(rawProvider);
  }

  BrandSummary? _parseNestedBrand(JsonMap item) {
    final rawBrand = _readMap(item, ['brand']);
    return rawBrand == null ? null : _tryParseBrandSummary(rawBrand);
  }

  List<AvailabilityWindow> _parseAvailabilityWindows(JsonMap item) {
    final rawSlots = _readList(item, [
      'requestableSlots',
      'availability.items',
      'availability.slots',
      'availability',
    ]);
    final formatter = DateFormat('EEE, MMM d · HH:mm');
    final slots = <AvailabilityWindow>[];
    if (rawSlots != null) {
      for (final rawSlot in rawSlots) {
        if (rawSlot is! Map) {
          continue;
        }

        final slot = asJsonMap(rawSlot);
        final startsAt = _readDateTime(slot, [
          'startsAt',
          'startAt',
          'start',
          'from',
        ]);
        if (startsAt == null) {
          continue;
        }

        slots.add(
          AvailabilityWindow(
            startsAt: startsAt,
            label:
                _readString(slot, ['label', 'displayLabel']) ??
                formatter.format(startsAt.toLocal()),
            available:
                _readBool(slot, ['available', 'isAvailable', 'open']) ?? true,
            note: _readString(slot, ['note', 'status', 'summary']),
          ),
        );
      }
    }

    if (slots.isNotEmpty) {
      slots.sort((left, right) => left.startsAt.compareTo(right.startsAt));
      return slots.take(8).toList(growable: false);
    }

    final exceptionSlots = _availabilityWindowsFromExceptions(item);
    if (exceptionSlots.isNotEmpty) {
      return exceptionSlots.take(8).toList(growable: false);
    }

    final recurringSlots = _availabilityWindowsFromRules(item);
    return recurringSlots.take(8).toList(growable: false);
  }

  List<AppMediaAsset> _parseMediaAssets(JsonMap item) {
    final rawMedia = _readList(item, ['photos', 'media', 'gallery']);
    if (rawMedia == null) {
      return const [];
    }

    final assets = <AppMediaAsset>[];
    for (final rawAsset in rawMedia) {
      final asset = _parseMediaAsset(rawAsset);
      if (asset != null) {
        assets.add(asset);
      }
    }

    return assets;
  }

  AppMediaAsset? _parsePrimaryMediaAsset(JsonMap item, List<String> keys) {
    for (final key in keys) {
      final value = _readPath(item, key);
      final asset = _parseMediaAsset(value);
      if (asset != null) {
        return asset;
      }
    }

    return null;
  }

  AppMediaAsset? _parseMediaAsset(dynamic rawAsset) {
    if (rawAsset is String && rawAsset.trim().isNotEmpty) {
      final remoteUrl = rawAsset.trim();
      return AppMediaAsset.uploaded(
        id: remoteUrl,
        label: 'Photo',
        remoteUrl: remoteUrl,
      );
    }

    if (rawAsset is! Map) {
      return null;
    }

    final asset = asJsonMap(rawAsset);
    final fileEntity = _readMap(asset, ['file', 'logoFile']);
    final id =
        _readString(asset, ['id', 'fileId', 'mediaId', 'key']) ??
        (fileEntity == null ? null : _readString(fileEntity, ['id'])) ??
        _readString(asset, ['url', 'publicUrl', 'downloadUrl', 'cdnUrl']);
    if (id == null || id.isEmpty) {
      return null;
    }

    final label =
        _readString(asset, ['label', 'name', 'fileName']) ??
        (fileEntity == null
            ? null
            : _readString(fileEntity, ['originalFilename', 'name'])) ??
        'Photo';
    final remoteUrl =
        _readString(asset, ['url', 'publicUrl', 'downloadUrl', 'cdnUrl']) ??
        (fileEntity == null
            ? null
            : _readString(fileEntity, [
                'url',
                'publicUrl',
                'downloadUrl',
                'cdnUrl',
              ]));

    if (remoteUrl != null && remoteUrl.isNotEmpty) {
      return AppMediaAsset.uploaded(id: id, label: label, remoteUrl: remoteUrl);
    }

    return AppMediaAsset.generated(id: id, label: label);
  }

  List<AvailabilityWindow> _availabilityWindowsFromExceptions(JsonMap item) {
    final formatter = DateFormat('EEE, MMM d · HH:mm');
    final rawExceptions = _readList(item, [
      'availability.exceptions',
      'exceptions',
    ]);
    if (rawExceptions == null) {
      return const [];
    }

    final slots = <AvailabilityWindow>[];
    for (final rawException in rawExceptions) {
      if (rawException is! Map) {
        continue;
      }
      final exception = asJsonMap(rawException);
      if (_readBool(exception, ['isClosedAllDay']) == true) {
        continue;
      }
      final date = _readDateTime(exception, ['date']);
      final startTime = _readString(exception, ['startTime']);
      if (date == null || startTime == null) {
        continue;
      }
      final startsAt = _dateWithTime(date.toUtc(), startTime);
      if (startsAt == null || !startsAt.isAfter(DateTime.now().toUtc())) {
        continue;
      }
      slots.add(
        AvailabilityWindow(
          startsAt: startsAt,
          label: formatter.format(startsAt.toLocal()),
          available: true,
          note: _readString(exception, ['note']),
        ),
      );
    }

    slots.sort((left, right) => left.startsAt.compareTo(right.startsAt));
    return slots;
  }

  List<AvailabilityWindow> _availabilityWindowsFromRules(JsonMap item) {
    final formatter = DateFormat('EEE, MMM d · HH:mm');
    final rawRules = _readList(item, ['availability.rules', 'rules']);
    if (rawRules == null) {
      return const [];
    }

    final nowUtc = DateTime.now().toUtc();
    final manualBlocks = _parseManualBlocks(item);
    final slots = <AvailabilityWindow>[];
    for (final rawRule in rawRules) {
      if (rawRule is! Map) {
        continue;
      }
      final rule = asJsonMap(rawRule);
      if (_readBool(rule, ['isActive']) == false) {
        continue;
      }
      final dayOfWeek = _readString(rule, ['dayOfWeek']);
      final startTime = _readString(rule, ['startTime']);
      if (dayOfWeek == null || startTime == null) {
        continue;
      }
      slots.addAll(
        _nextSlotsForRule(
          dayOfWeek: dayOfWeek,
          startTime: startTime,
          nowUtc: nowUtc,
          formatter: formatter,
          manualBlocks: manualBlocks,
        ),
      );
    }

    slots.sort((left, right) => left.startsAt.compareTo(right.startsAt));
    return slots;
  }

  List<_ManualBlockWindow> _parseManualBlocks(JsonMap item) {
    final rawBlocks = _readList(item, [
      'availability.manualBlocks',
      'manualBlocks',
    ]);
    if (rawBlocks == null) {
      return const [];
    }

    final blocks = <_ManualBlockWindow>[];
    for (final rawBlock in rawBlocks) {
      if (rawBlock is! Map) {
        continue;
      }
      final block = asJsonMap(rawBlock);
      final startsAt = _readDateTime(block, ['startsAt', 'startAt']);
      final endsAt = _readDateTime(block, ['endsAt', 'endAt']);
      if (startsAt == null || endsAt == null) {
        continue;
      }
      blocks.add(_ManualBlockWindow(startsAt: startsAt, endsAt: endsAt));
    }
    return blocks;
  }

  List<AvailabilityWindow> _nextSlotsForRule({
    required String dayOfWeek,
    required String startTime,
    required DateTime nowUtc,
    required DateFormat formatter,
    required List<_ManualBlockWindow> manualBlocks,
  }) {
    final targetWeekday = _weekdayValue(dayOfWeek);
    if (targetWeekday == null) {
      return const [];
    }

    final slots = <AvailabilityWindow>[];
    for (var offset = 0; offset < 28 && slots.length < 3; offset += 1) {
      final date = DateTime.utc(nowUtc.year, nowUtc.month, nowUtc.day + offset);
      if (date.weekday != targetWeekday) {
        continue;
      }
      final startsAt = _dateWithTime(date, startTime);
      if (startsAt == null || !startsAt.isAfter(nowUtc)) {
        continue;
      }
      final overlapsBlock = manualBlocks.any(
        (block) =>
            !startsAt.isBefore(block.startsAt) &&
            startsAt.isBefore(block.endsAt),
      );
      if (overlapsBlock) {
        continue;
      }
      slots.add(
        AvailabilityWindow(
          startsAt: startsAt,
          label: formatter.format(startsAt.toLocal()),
          available: true,
          note: 'Recurring availability',
        ),
      );
    }
    return slots;
  }

  DateTime? _dateWithTime(DateTime date, String hhmm) {
    final parts = hhmm.split(':');
    if (parts.length != 2) {
      return null;
    }
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) {
      return null;
    }
    return DateTime.utc(date.year, date.month, date.day, hour, minute);
  }

  int? _weekdayValue(String raw) {
    return switch (raw.trim().toUpperCase()) {
      'MONDAY' => DateTime.monday,
      'TUESDAY' => DateTime.tuesday,
      'WEDNESDAY' => DateTime.wednesday,
      'THURSDAY' => DateTime.thursday,
      'FRIDAY' => DateTime.friday,
      'SATURDAY' => DateTime.saturday,
      'SUNDAY' => DateTime.sunday,
      _ => null,
    };
  }

  String _buildAvailabilitySummary(List<AvailabilityWindow> slots) {
    if (slots.isEmpty) {
      return 'Availability is provided by the backend for this service.';
    }

    return '${slots.length} requestable times are currently available.';
  }

  String _formatDurationLabel({
    required int? minutes,
    required String fallback,
  }) {
    if (minutes == null || minutes <= 0) {
      return fallback;
    }

    return minutes == 1 ? '1 minute' : '$minutes minutes';
  }

  String _formatCancellationLabel({required int? hours}) {
    if (hours == null || hours <= 0) {
      return 'Provider-defined cancellation policy';
    }

    return hours == 1 ? '1 hour before' : '$hours hours before';
  }

  void _rememberService(ServiceSummary service) {
    _serviceSummaryCache[service.id] = service;
  }

  void _rememberBrand(BrandSummary brand) {
    _brandSummaryCache[brand.id] = brand;
  }

  void _rememberProvider(ProviderSummary provider) {
    final existing = _providerSummaryCache[provider.id];
    if (existing == null) {
      _providerSummaryCache[provider.id] = provider;
      return;
    }

    _providerSummaryCache[provider.id] = ProviderSummary(
      id: provider.id,
      name: provider.name,
      headline: provider.headline != 'Service provider'
          ? provider.headline
          : existing.headline,
      bio: provider.bio != 'Provider profile' ? provider.bio : existing.bio,
      distanceKm: provider.distanceKm != 0
          ? provider.distanceKm
          : existing.distanceKm,
      rating: provider.rating != 0 ? provider.rating : existing.rating,
      reviewCount: provider.reviewCount != 0
          ? provider.reviewCount
          : existing.reviewCount,
      completedReservations: provider.completedReservations != 0
          ? provider.completedReservations
          : existing.completedReservations,
      responseReliability:
          provider.responseReliability != 'Response time unavailable'
          ? provider.responseReliability
          : existing.responseReliability,
      brandIds: provider.brandIds.isNotEmpty
          ? provider.brandIds
          : existing.brandIds,
      categoryIds: provider.categoryIds.isNotEmpty
          ? provider.categoryIds
          : existing.categoryIds,
      visibilityLabels: provider.visibilityLabels.isNotEmpty
          ? provider.visibilityLabels
          : existing.visibilityLabels,
      popularityScore: provider.popularityScore != 0
          ? provider.popularityScore
          : existing.popularityScore,
      availableNow: provider.availableNow || existing.availableNow,
    );
  }

  bool _isCacheFresh(DateTime? fetchedAt) {
    if (fetchedAt == null) {
      return false;
    }

    return DateTime.now().difference(fetchedAt) < _cacheTtl;
  }

  int _compareBrands(BrandSummary left, BrandSummary right, SearchSort sort) {
    return switch (sort) {
      SearchSort.proximity => left.distanceKm.compareTo(right.distanceKm),
      SearchSort.rating => right.rating.compareTo(left.rating),
      SearchSort.price => 0,
      SearchSort.popularity => right.popularityScore.compareTo(
        left.popularityScore,
      ),
      SearchSort.availability => _boolScore(
        right.openNow,
      ).compareTo(_boolScore(left.openNow)),
    };
  }

  int _compareProviders(
    ProviderSummary left,
    ProviderSummary right,
    SearchSort sort,
  ) {
    return switch (sort) {
      SearchSort.proximity => left.distanceKm.compareTo(right.distanceKm),
      SearchSort.rating => right.rating.compareTo(left.rating),
      SearchSort.price => 0,
      SearchSort.popularity => right.popularityScore.compareTo(
        left.popularityScore,
      ),
      SearchSort.availability => _boolScore(
        right.availableNow,
      ).compareTo(_boolScore(left.availableNow)),
    };
  }

  int _compareServices(
    ServiceSummary left,
    ServiceSummary right,
    SearchSort sort,
  ) {
    return switch (sort) {
      SearchSort.proximity => left.distanceKm.compareTo(right.distanceKm),
      SearchSort.rating => right.rating.compareTo(left.rating),
      SearchSort.price => _priceForSort(left).compareTo(_priceForSort(right)),
      SearchSort.popularity => right.popularityScore.compareTo(
        left.popularityScore,
      ),
      SearchSort.availability => _boolScore(
        right.isAvailable,
      ).compareTo(_boolScore(left.isAvailable)),
    };
  }

  int _boolScore(bool value) => value ? 1 : 0;

  double _priceForSort(ServiceSummary service) =>
      service.price ?? double.maxFinite;

  bool _matchesBrandFilters(BrandSummary brand, SearchFilters filters) {
    if (filters.categoryId != null &&
        !brand.categoryIds.contains(filters.categoryId)) {
      return false;
    }
    if (filters.maxDistanceKm != null &&
        brand.distanceKm > filters.maxDistanceKm!) {
      return false;
    }
    if (filters.minRating != null && brand.rating < filters.minRating!) {
      return false;
    }
    if (filters.availableOnly && !brand.openNow) {
      return false;
    }
    return true;
  }

  bool _matchesProviderFilters(
    ProviderSummary provider,
    SearchFilters filters,
  ) {
    if (filters.categoryId != null &&
        !provider.categoryIds.contains(filters.categoryId)) {
      return false;
    }
    if (filters.maxDistanceKm != null &&
        provider.distanceKm > filters.maxDistanceKm!) {
      return false;
    }
    if (filters.minRating != null && provider.rating < filters.minRating!) {
      return false;
    }
    if (filters.availableOnly && !provider.availableNow) {
      return false;
    }
    return true;
  }

  bool _matchesServiceFilters(ServiceSummary service, SearchFilters filters) {
    if (filters.categoryId != null &&
        service.categoryId != filters.categoryId) {
      return false;
    }
    if (filters.maxPrice != null &&
        (service.price == null || service.price! > filters.maxPrice!)) {
      return false;
    }
    if (filters.maxDistanceKm != null &&
        service.distanceKm > filters.maxDistanceKm!) {
      return false;
    }
    if (filters.minRating != null && service.rating < filters.minRating!) {
      return false;
    }
    if (filters.availableOnly && !service.isAvailable) {
      return false;
    }
    return true;
  }

  List<VisibilityLabel> _parseVisibilityLabels(dynamic raw) {
    final values = raw is List ? raw : const [];
    final labels = <VisibilityLabel>[];
    for (final value in values) {
      final normalized = value is String
          ? value.toLowerCase().replaceAll(RegExp(r'[\s_-]+'), '')
          : value is Map
          ? (_readString(asJsonMap(value), ['name', 'label', 'code']) ?? '')
                .toLowerCase()
                .replaceAll(RegExp(r'[\s_-]+'), '')
          : '';
      switch (normalized) {
        case 'vip':
          labels.add(VisibilityLabel.vip);
        case 'bestofmonth':
          labels.add(VisibilityLabel.bestOfMonth);
        case 'sponsored':
          labels.add(VisibilityLabel.sponsored);
        case 'common':
          labels.add(VisibilityLabel.common);
      }
    }

    return labels.isEmpty ? const [VisibilityLabel.common] : labels;
  }

  ApprovalMode _parseApprovalMode(JsonMap item) {
    final explicit = _readString(item, [
      'approvalMode',
      'approval_mode',
      'approvalType',
    ]);
    if (explicit != null) {
      final normalized = explicit.toLowerCase();
      if (normalized.contains('manual')) {
        return ApprovalMode.manual;
      }
      if (normalized.contains('auto')) {
        return ApprovalMode.automatic;
      }
    }

    final requiresManual = _readBool(item, [
      'requiresManualApproval',
      'manualApproval',
      'isManualApproval',
    ]);

    return requiresManual == true
        ? ApprovalMode.manual
        : ApprovalMode.automatic;
  }

  List<String> _parseCategoryIds(dynamic raw) {
    final ids = _parseIds(raw);
    return ids;
  }

  List<String> _parseIds(dynamic raw) {
    final values = raw is List ? raw : const [];
    final ids = <String>[];
    for (final value in values) {
      if (value is String && value.isNotEmpty) {
        ids.add(value);
      } else if (value is Map) {
        final map = asJsonMap(value);
        final id = _readString(map, ['id']);
        if (id != null && id.isNotEmpty) {
          ids.add(id);
        }
      }
    }
    return ids;
  }

  List<JsonMap> _extractItems(dynamic payload, List<String> keys) {
    if (payload is List) {
      return asJsonMapList(payload);
    }
    if (payload is Map) {
      final map = asJsonMap(payload);
      for (final key in keys) {
        final value = _readPath(map, key);
        if (value is List) {
          return asJsonMapList(value);
        }
      }
    }
    return const [];
  }

  JsonMap _extractEntity(dynamic payload, List<String> keys) {
    if (payload is Map) {
      final map = asJsonMap(payload);
      for (final key in keys) {
        final value = _readPath(map, key);
        if (value is Map) {
          return asJsonMap(value);
        }
      }
      return map;
    }

    throw const AppException(
      'Unexpected discovery payload returned by the server.',
      type: AppExceptionType.server,
    );
  }

  JsonMap? _readMap(JsonMap source, List<String> keys) {
    for (final key in keys) {
      final value = _readPath(source, key);
      if (value is Map) {
        return asJsonMap(value);
      }
    }
    return null;
  }

  List<dynamic>? _readList(JsonMap source, List<String> keys) {
    for (final key in keys) {
      final value = _readPath(source, key);
      if (value is List) {
        return value;
      }
    }
    return null;
  }

  String? _readString(JsonMap source, List<String> keys) {
    for (final key in keys) {
      final value = _readPath(source, key);
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return null;
  }

  bool? _readBool(JsonMap source, List<String> keys) {
    for (final key in keys) {
      final value = _readPath(source, key);
      if (value is bool) {
        return value;
      }
      if (value is num) {
        return value != 0;
      }
      if (value is String) {
        final normalized = value.trim().toLowerCase();
        if (normalized == 'true' || normalized == '1') {
          return true;
        }
        if (normalized == 'false' || normalized == '0') {
          return false;
        }
      }
    }
    return null;
  }

  int? _readInt(JsonMap source, List<String> keys) {
    for (final key in keys) {
      final value = _readPath(source, key);
      if (value is int) {
        return value;
      }
      if (value is num) {
        return value.toInt();
      }
      if (value is String) {
        final parsed = int.tryParse(value.trim());
        if (parsed != null) {
          return parsed;
        }
      }
    }
    return null;
  }

  double? _readDouble(JsonMap source, List<String> keys) {
    for (final key in keys) {
      final value = _readPath(source, key);
      if (value is double) {
        return value;
      }
      if (value is num) {
        return value.toDouble();
      }
      if (value is String) {
        final parsed = double.tryParse(value.trim());
        if (parsed != null) {
          return parsed;
        }
      }
    }
    return null;
  }

  DateTime? _readDateTime(JsonMap source, List<String> keys) {
    for (final key in keys) {
      final value = _readPath(source, key);
      if (value is DateTime) {
        return value;
      }
      if (value is String && value.trim().isNotEmpty) {
        final parsed = DateTime.tryParse(value.trim());
        if (parsed != null) {
          return parsed;
        }
      }
    }
    return null;
  }

  dynamic _readPath(dynamic source, String path) {
    final segments = path.split('.');
    dynamic current = source;
    for (final segment in segments) {
      if (current is Map) {
        current = current[segment];
      } else {
        return null;
      }
    }
    return current;
  }

  double? _metersToKm(double? meters) => meters == null ? null : meters / 1000;

  String _slugify(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
  }
}

class _ManualBlockWindow {
  const _ManualBlockWindow({required this.startsAt, required this.endsAt});

  final DateTime startsAt;
  final DateTime endsAt;
}
