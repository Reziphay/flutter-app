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
    fallback: MockDiscoveryRepository(),
    onCategoriesUpdated: (categories) {
      ref
          .read(_discoveryCategoriesCacheProvider.notifier)
          .setCategories(categories);
    },
  );
});

final discoveryCategoriesProvider = Provider<List<DiscoveryCategory>>((ref) {
  final cachedCategories = ref.watch(_discoveryCategoriesCacheProvider);
  if (cachedCategories.isNotEmpty) {
    return cachedCategories;
  }

  return ref.watch(discoveryRepositoryProvider).categories;
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

class _RequestAttempt {
  const _RequestAttempt({required this.method, required this.path, this.data});

  factory _RequestAttempt.get(String path) =>
      _RequestAttempt(method: 'GET', path: path);

  factory _RequestAttempt.post(String path, {Object? data}) =>
      _RequestAttempt(method: 'POST', path: path, data: data);

  factory _RequestAttempt.patch(String path, {Object? data}) =>
      _RequestAttempt(method: 'PATCH', path: path, data: data);

  factory _RequestAttempt.put(String path, {Object? data}) =>
      _RequestAttempt(method: 'PUT', path: path, data: data);

  factory _RequestAttempt.delete(String path, {Object? data}) =>
      _RequestAttempt(method: 'DELETE', path: path, data: data);

  final String method;
  final String path;
  final Object? data;
}

DateTime _dateAt(int dayOffset, int hour, int minute) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day + dayOffset, hour, minute);
}

class BackendDiscoveryRepository implements DiscoveryRepository {
  BackendDiscoveryRepository({
    required ApiClient apiClient,
    MockDiscoveryRepository? fallback,
    void Function(List<DiscoveryCategory> categories)? onCategoriesUpdated,
  }) : _apiClient = apiClient,
       _fallback = fallback ?? MockDiscoveryRepository(),
       _onCategoriesUpdated = onCategoriesUpdated;

  static const _cacheTtl = Duration(seconds: 30);

  final ApiClient _apiClient;
  final MockDiscoveryRepository _fallback;
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
      : _fallback.categories;

  @override
  DiscoveryCategory? categoryById(String id) {
    for (final category in categories) {
      if (category.id == id) {
        return category;
      }
    }

    return _fallback.categoryById(id);
  }

  @override
  ServiceSummary? serviceSummaryById(String id) =>
      _serviceSummaryCache[id] ?? _fallback.serviceSummaryById(id);

  @override
  Future<BrandDetail> getBrandDetail(String id) async {
    try {
      final payload = await _apiClient.get<dynamic>(
        '/brands/$id',
        mapper: (data) => data,
      );
      final entity = _extractEntity(payload, ['brand', 'item']);
      final summary = _parseBrandSummary(entity);
      _rememberBrand(summary);

      final providers = entity['members'] is List
          ? _parseProviderList(entity['members'])
          : (await _fetchProviderSummaries())
                .where((provider) => provider.brandIds.contains(id))
                .toList(growable: false);
      final services = (await _fetchServiceSummaries())
          .where((service) => service.brandId == id)
          .toList(growable: false);

      return BrandDetail(
        summary: summary,
        description:
            _readString(entity, ['description', 'about', 'headline']) ??
            summary.headline,
        mapHint:
            _readString(entity, ['mapHint', 'locationHint']) ??
            'Use the saved address in your maps app for directions.',
        members: providers,
        services: services,
        reviews: const [],
      );
    } catch (_) {
      return _fallback.getBrandDetail(id);
    }
  }

  @override
  Future<CustomerHomeData> getCustomerHomeData() async {
    try {
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
          (left, right) =>
              right.popularityScore.compareTo(left.popularityScore),
        );
      final popularProviders = List<ProviderSummary>.of(providers)
        ..sort(
          (left, right) =>
              right.popularityScore.compareTo(left.popularityScore),
        );

      return CustomerHomeData(
        nearYou: nearYou.take(4).toList(growable: false),
        featured: featured.take(4).toList(growable: false),
        bestOfMonth: bestOfMonth.take(4).toList(growable: false),
        categories: fetchedCategories,
        popularBrands: popularBrands.take(3).toList(growable: false),
        popularProviders: popularProviders.take(3).toList(growable: false),
      );
    } catch (_) {
      return _fallback.getCustomerHomeData();
    }
  }

  @override
  Future<ProviderDetail> getProviderDetail(String id) async {
    try {
      final providers = await _fetchProviderSummaries();
      final summary = providers.firstWhere((provider) => provider.id == id);
      final services = (await _fetchServiceSummaries())
          .where((service) => service.providerId == id)
          .toList(growable: false);
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
    } catch (_) {
      return _fallback.getProviderDetail(id);
    }
  }

  @override
  Future<DiscoverySearchResponse> search(DiscoverySearchRequest request) async {
    try {
      final normalizedQuery = request.query.trim().toLowerCase();
      final services =
          List<ServiceSummary>.of(await _fetchServiceSummaries())
              .where(
                (service) => _matchesServiceQuery(service, normalizedQuery),
              )
              .where(
                (service) => _matchesServiceFilters(service, request.filters),
              )
              .toList()
            ..sort(
              (left, right) => _compareServices(left, right, request.sort),
            );
      final brands =
          List<BrandSummary>.of(await _fetchBrandSummaries())
              .where((brand) => _matchesBrandQuery(brand, normalizedQuery))
              .where((brand) => _matchesBrandFilters(brand, request.filters))
              .toList()
            ..sort((left, right) => _compareBrands(left, right, request.sort));
      final providers =
          List<ProviderSummary>.of(await _fetchProviderSummaries())
              .where(
                (provider) => _matchesProviderQuery(provider, normalizedQuery),
              )
              .where(
                (provider) =>
                    _matchesProviderFilters(provider, request.filters),
              )
              .toList()
            ..sort(
              (left, right) => _compareProviders(left, right, request.sort),
            );

      return DiscoverySearchResponse(
        services: services,
        brands: brands,
        providers: providers,
      );
    } catch (_) {
      return _fallback.search(request);
    }
  }

  @override
  Future<ServiceDetail> getServiceDetail(String id) async {
    try {
      final payload = await _apiClient.get<dynamic>(
        '/services/$id',
        mapper: (data) => data,
      );
      final entity = _extractEntity(payload, ['service', 'item']);
      final summary = _parseServiceSummary(entity);
      _rememberService(summary);

      final provider =
          _parseNestedProvider(entity) ??
          await _findProvider(summary.providerId);
      final brand = summary.brandId == null
          ? null
          : _parseNestedBrand(entity) ?? await _findBrand(summary.brandId!);
      final slots = _parseAvailabilityWindows(entity);

      return ServiceDetail(
        summary: summary,
        description:
            _readString(entity, [
              'description',
              'summary',
              'details',
              'descriptionSnippet',
            ]) ??
            summary.descriptionSnippet ??
            'Service details are available from the backend record.',
        about:
            _readString(entity, ['about', 'provider.bio', 'provider.about']) ??
            summary.descriptionSnippet ??
            'Provider-specific notes are available on request.',
        availabilitySummary:
            _readString(entity, [
              'availabilitySummary',
              'availability.summary',
              'availability.description',
            ]) ??
            _buildAvailabilitySummary(slots),
        requestableSlots: slots,
        waitingTimeLabel: _formatDurationLabel(
          minutes: _readInt(entity, [
            'waitingTimeMinutes',
            'waitingTime',
            'waiting_time',
          ]),
          fallback: 'Provider-defined waiting time',
        ),
        freeCancellationLabel: _formatCancellationLabel(
          hours: _readInt(entity, [
            'freeCancellationHours',
            'freeCancellationDeadlineHours',
            'free_cancellation_hours',
          ]),
        ),
        galleryMedia: _parseMediaAssets(entity),
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
      );
    } catch (_) {
      return _fallback.getServiceDetail(id);
    }
  }

  @override
  Future<ProviderServicesData> getProviderServices(String providerId) async {
    try {
      final payload = await _requestFirstSuccess<dynamic>(
        _providerServiceCollectionPaths(
          providerId,
        ).map(_RequestAttempt.get).toList(growable: false),
      );
      final items = _extractItems(payload, ['items', 'services']);
      final services = <ProviderManagedServiceListItem>[];

      for (final item in items) {
        final summary = _tryParseServiceSummary(item);
        if (summary == null) {
          continue;
        }

        _rememberService(summary);
        final entity = asJsonMap(item);
        services.add(
          ProviderManagedServiceListItem(
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
                _readInt(entity, ['leadTimeHours', 'leadTime', 'lead_time']) ??
                0,
            exceptionCount: _parseExceptionNotes(entity).length,
            canArchive:
                _readBool(entity, [
                  'canArchive',
                  'canDelete',
                  'canRemove',
                  'permissions.canArchive',
                ]) ??
                true,
          ),
        );
      }

      return ProviderServicesData(
        services: services,
        activeCount: services
            .where((service) => service.summary.isAvailable)
            .length,
        manualApprovalCount: services
            .where(
              (service) => service.summary.approvalMode == ApprovalMode.manual,
            )
            .length,
        brandLinkedCount: services
            .where((service) => service.summary.brandId != null)
            .length,
      );
    } catch (_) {
      return _fallback.getProviderServices(providerId);
    }
  }

  @override
  Future<ProviderManagedService> getProviderService({
    required String serviceId,
    required String providerId,
  }) async {
    try {
      final payload = await _requestFirstSuccess<dynamic>(
        _providerServiceDetailPaths(
          providerId: providerId,
          serviceId: serviceId,
        ).map(_RequestAttempt.get).toList(growable: false),
      );
      final entity = _extractEntity(payload, ['service', 'item']);
      final summary = _parseServiceSummary(entity);
      _rememberService(summary);

      final provider =
          _parseNestedProvider(entity) ??
          await _findProvider(summary.providerId);
      final brand = summary.brandId == null
          ? null
          : _parseNestedBrand(entity) ?? await _findBrand(summary.brandId!);
      final slots = _parseAvailabilityWindows(entity);
      final draft = _draftFromServiceEntity(
        summary: summary,
        entity: entity,
        slots: slots,
      );

      return ProviderManagedService(
        detail: ServiceDetail(
          summary: summary,
          description:
              _readString(entity, [
                'description',
                'summary',
                'details',
                'descriptionSnippet',
              ]) ??
              summary.descriptionSnippet ??
              'Service details are available from the backend record.',
          about: _readString(entity, ['about', 'serviceAbout']) ?? draft.about,
          availabilitySummary:
              _readString(entity, [
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
                    summary.descriptionSnippet ??
                    'Provider details unavailable.',
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
        canArchive:
            _readBool(entity, [
              'canArchive',
              'canDelete',
              'canRemove',
              'permissions.canArchive',
            ]) ??
            true,
      );
    } catch (_) {
      return _fallback.getProviderService(
        serviceId: serviceId,
        providerId: providerId,
      );
    }
  }

  @override
  Future<String> createProviderService({
    required String providerId,
    required ProviderServiceDraft draft,
  }) async {
    try {
      final payload = await _requestFirstSuccess<dynamic>(
        _providerServiceCollectionPaths(providerId)
            .map(
              (path) => _RequestAttempt.post(
                path,
                data: _serviceDraftPayload(
                  providerId: providerId,
                  draft: draft,
                ),
              ),
            )
            .toList(growable: false),
      );
      final entity =
          _tryExtractEntity(payload, ['service', 'item']) ?? const {};
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

      final summary = entity.isEmpty ? null : _tryParseServiceSummary(entity);
      if (summary != null) {
        _rememberService(summary);
      }
      _invalidateProviderCatalogCaches(
        providerId: providerId,
        serviceId: serviceId,
        brandId: summary?.brandId ?? draft.brandId,
      );
      return serviceId;
    } on AppException catch (error) {
      if (_shouldFallbackProviderManagement(error)) {
        return _fallback.createProviderService(
          providerId: providerId,
          draft: draft,
        );
      }
      rethrow;
    }
  }

  @override
  Future<void> updateProviderService({
    required String providerId,
    required String serviceId,
    required ProviderServiceDraft draft,
  }) async {
    try {
      final payload = await _requestFirstSuccess<dynamic>([
        for (final path in _providerServiceDetailPaths(
          providerId: providerId,
          serviceId: serviceId,
        ))
          _RequestAttempt.patch(
            path,
            data: _serviceDraftPayload(providerId: providerId, draft: draft),
          ),
        for (final path in _providerServiceDetailPaths(
          providerId: providerId,
          serviceId: serviceId,
        ))
          _RequestAttempt.put(
            path,
            data: _serviceDraftPayload(providerId: providerId, draft: draft),
          ),
      ]);
      final entity = _tryExtractEntity(payload, ['service', 'item']);
      final summary = entity == null ? null : _tryParseServiceSummary(entity);
      if (summary != null) {
        _rememberService(summary);
      }
      _invalidateProviderCatalogCaches(
        providerId: providerId,
        serviceId: serviceId,
        brandId: summary?.brandId ?? draft.brandId,
      );
    } on AppException catch (error) {
      if (_shouldFallbackProviderManagement(error)) {
        return _fallback.updateProviderService(
          providerId: providerId,
          serviceId: serviceId,
          draft: draft,
        );
      }
      rethrow;
    }
  }

  @override
  Future<void> archiveProviderService({
    required String providerId,
    required String serviceId,
  }) async {
    try {
      await _requestFirstSuccess<dynamic>([
        for (final path in _providerServiceDetailPaths(
          providerId: providerId,
          serviceId: serviceId,
        ))
          _RequestAttempt.delete(path),
        for (final path in _providerServiceDetailPaths(
          providerId: providerId,
          serviceId: serviceId,
        ))
          _RequestAttempt.post('$path/archive'),
      ]);
      _invalidateProviderCatalogCaches(
        providerId: providerId,
        serviceId: serviceId,
      );
    } on AppException catch (error) {
      if (_shouldFallbackProviderManagement(error)) {
        return _fallback.archiveProviderService(
          providerId: providerId,
          serviceId: serviceId,
        );
      }
      rethrow;
    }
  }

  @override
  Future<ProviderBrandsData> getProviderBrands(String providerId) async {
    try {
      final payload = await _requestFirstSuccess<dynamic>(
        _providerBrandCollectionPaths(
          providerId,
        ).map(_RequestAttempt.get).toList(growable: false),
      );
      final items = _extractItems(payload, ['items', 'brands']);
      final brands = <ProviderManagedBrandListItem>[];

      for (final item in items) {
        final summary = _tryParseBrandSummary(item);
        if (summary == null) {
          continue;
        }
        _rememberBrand(summary);
        final entity = asJsonMap(item);
        final joinRequests = _parseBrandJoinRequests(entity);
        brands.add(
          ProviderManagedBrandListItem(
            summary: summary,
            joinRequestCount:
                _readInt(entity, [
                  'pendingJoinRequestCount',
                  'joinRequestCount',
                  'membershipRequestCount',
                ]) ??
                joinRequests.length,
          ),
        );
      }

      return ProviderBrandsData(
        brands: brands,
        totalServiceCount: brands.fold<int>(
          0,
          (total, brand) => total + brand.summary.serviceCount,
        ),
        pendingJoinRequestCount: brands.fold<int>(
          0,
          (total, brand) => total + brand.joinRequestCount,
        ),
      );
    } catch (_) {
      return _fallback.getProviderBrands(providerId);
    }
  }

  @override
  Future<ProviderManagedBrand> getProviderBrand({
    required String brandId,
    required String providerId,
  }) async {
    try {
      final payload = await _requestFirstSuccess<dynamic>(
        _providerBrandDetailPaths(
          providerId: providerId,
          brandId: brandId,
        ).map(_RequestAttempt.get).toList(growable: false),
      );
      final entity = _extractEntity(payload, ['brand', 'item']);
      final summary = _parseBrandSummary(entity);
      _rememberBrand(summary);

      final members = entity['members'] is List
          ? _parseProviderList(entity['members'])
          : entity['providers'] is List
          ? _parseProviderList(entity['providers'])
          : (await _fetchProviderSummaries())
                .where((provider) => provider.brandIds.contains(brandId))
                .toList(growable: false);
      final services = entity['services'] is List
          ? entity['services'] is List
                ? asJsonMapList(entity['services'])
                      .map(_tryParseServiceSummary)
                      .whereType<ServiceSummary>()
                      .toList(growable: false)
                : const <ServiceSummary>[]
          : (await _fetchServiceSummaries())
                .where((service) => service.brandId == brandId)
                .toList(growable: false);
      for (final service in services) {
        _rememberService(service);
      }
      final joinRequests = _parseBrandJoinRequests(entity);
      final resolvedJoinRequests = joinRequests.isNotEmpty
          ? joinRequests
          : await _fetchProviderBrandJoinRequests(
              providerId: providerId,
              brandId: brandId,
            );
      final draft = _draftFromBrandEntity(summary: summary, entity: entity);

      return ProviderManagedBrand(
        detail: BrandDetail(
          summary: summary,
          description:
              _readString(entity, ['description', 'about', 'headline']) ??
              summary.headline,
          mapHint:
              _readString(entity, ['mapHint', 'locationHint']) ?? draft.mapHint,
          members: members,
          services: services,
          reviews: const [],
        ),
        draft: draft,
        joinRequests: resolvedJoinRequests,
      );
    } catch (_) {
      return _fallback.getProviderBrand(
        brandId: brandId,
        providerId: providerId,
      );
    }
  }

  @override
  Future<String> createProviderBrand({
    required String providerId,
    required ProviderBrandDraft draft,
  }) async {
    try {
      final payload = await _requestFirstSuccess<dynamic>(
        _providerBrandCollectionPaths(providerId)
            .map(
              (path) => _RequestAttempt.post(
                path,
                data: _brandDraftPayload(providerId: providerId, draft: draft),
              ),
            )
            .toList(growable: false),
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

      final summary = entity.isEmpty ? null : _tryParseBrandSummary(entity);
      if (summary != null) {
        _rememberBrand(summary);
      }
      _invalidateProviderCatalogCaches(
        providerId: providerId,
        brandId: brandId,
      );
      return brandId;
    } on AppException catch (error) {
      if (_shouldFallbackProviderManagement(error)) {
        return _fallback.createProviderBrand(
          providerId: providerId,
          draft: draft,
        );
      }
      rethrow;
    }
  }

  @override
  Future<void> updateProviderBrand({
    required String providerId,
    required String brandId,
    required ProviderBrandDraft draft,
  }) async {
    try {
      final payload = await _requestFirstSuccess<dynamic>([
        for (final path in _providerBrandDetailPaths(
          providerId: providerId,
          brandId: brandId,
        ))
          _RequestAttempt.patch(
            path,
            data: _brandDraftPayload(providerId: providerId, draft: draft),
          ),
        for (final path in _providerBrandDetailPaths(
          providerId: providerId,
          brandId: brandId,
        ))
          _RequestAttempt.put(
            path,
            data: _brandDraftPayload(providerId: providerId, draft: draft),
          ),
      ]);
      final entity = _tryExtractEntity(payload, ['brand', 'item']);
      final summary = entity == null ? null : _tryParseBrandSummary(entity);
      if (summary != null) {
        _rememberBrand(summary);
      }
      _invalidateProviderCatalogCaches(
        providerId: providerId,
        brandId: brandId,
      );
    } on AppException catch (error) {
      if (_shouldFallbackProviderManagement(error)) {
        return _fallback.updateProviderBrand(
          providerId: providerId,
          brandId: brandId,
          draft: draft,
        );
      }
      rethrow;
    }
  }

  @override
  Future<void> acceptBrandJoinRequest({
    required String providerId,
    required String brandId,
    required String requestId,
  }) async {
    try {
      await _requestFirstSuccess<dynamic>(
        _acceptJoinRequestPaths(
          brandId: brandId,
          providerId: providerId,
          requestId: requestId,
        ).map(_RequestAttempt.post).toList(growable: false),
      );
      _invalidateProviderCatalogCaches(
        providerId: providerId,
        brandId: brandId,
      );
    } on AppException catch (error) {
      if (_shouldFallbackProviderManagement(error)) {
        return _fallback.acceptBrandJoinRequest(
          providerId: providerId,
          brandId: brandId,
          requestId: requestId,
        );
      }
      rethrow;
    }
  }

  @override
  Future<void> rejectBrandJoinRequest({
    required String providerId,
    required String brandId,
    required String requestId,
  }) async {
    try {
      await _requestFirstSuccess<dynamic>(
        _rejectJoinRequestPaths(
          brandId: brandId,
          providerId: providerId,
          requestId: requestId,
        ).map(_RequestAttempt.post).toList(growable: false),
      );
      _invalidateProviderCatalogCaches(
        providerId: providerId,
        brandId: brandId,
      );
    } on AppException catch (error) {
      if (_shouldFallbackProviderManagement(error)) {
        return _fallback.rejectBrandJoinRequest(
          providerId: providerId,
          brandId: brandId,
          requestId: requestId,
        );
      }
      rethrow;
    }
  }

  ProviderServiceDraft _draftFromServiceEntity({
    required ServiceSummary summary,
    required JsonMap entity,
    required List<AvailabilityWindow> slots,
  }) {
    final galleryMedia = _parseMediaAssets(entity);
    return ProviderServiceDraft(
      name: summary.name,
      categoryId: summary.categoryId,
      categoryName: summary.categoryName,
      addressLine: summary.addressLine,
      descriptionSnippet:
          _readString(entity, [
            'descriptionSnippet',
            'description',
            'summary',
          ]) ??
          summary.descriptionSnippet ??
          '',
      about:
          _readString(entity, ['about', 'details', 'serviceAbout']) ??
          summary.descriptionSnippet ??
          '',
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
          _readInt(entity, ['leadTimeHours', 'leadTime', 'lead_time']) ?? 0,
      freeCancellationHours:
          _readInt(entity, [
            'freeCancellationHours',
            'freeCancellationDeadlineHours',
            'free_cancellation_hours',
          ]) ??
          0,
      visibilityLabels: summary.visibilityLabels,
      requestableSlots: slots,
      exceptionNotes: _parseExceptionNotes(entity),
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
    return ProviderBrandDraft(
      name: summary.name,
      headline: summary.headline,
      addressLine: summary.addressLine,
      description:
          _readString(entity, ['description', 'about', 'headline']) ??
          summary.headline,
      mapHint:
          _readString(entity, ['mapHint', 'locationHint']) ??
          'Use the saved address in your maps app for directions.',
      visibilityLabels: summary.visibilityLabels,
      openNow: summary.openNow,
      logoMedia:
          _parsePrimaryMediaAsset(entity, ['logoMedia', 'logo', 'brandLogo']) ??
          summary.logoMedia,
    );
  }

  List<String> _providerServiceCollectionPaths(String providerId) => [
    '/service-owners/me/services',
    '/providers/me/services',
    '/providers/$providerId/services',
    '/service-owners/$providerId/services',
  ];

  List<String> _providerServiceDetailPaths({
    required String providerId,
    required String serviceId,
  }) => [
    '/service-owners/me/services/$serviceId',
    '/providers/me/services/$serviceId',
    '/providers/$providerId/services/$serviceId',
    '/service-owners/$providerId/services/$serviceId',
  ];

  List<String> _providerBrandCollectionPaths(String providerId) => [
    '/service-owners/me/brands',
    '/providers/me/brands',
    '/providers/$providerId/brands',
    '/service-owners/$providerId/brands',
  ];

  List<String> _providerBrandDetailPaths({
    required String providerId,
    required String brandId,
  }) => [
    '/service-owners/me/brands/$brandId',
    '/providers/me/brands/$brandId',
    '/providers/$providerId/brands/$brandId',
    '/service-owners/$providerId/brands/$brandId',
  ];

  List<String> _acceptJoinRequestPaths({
    required String brandId,
    required String providerId,
    required String requestId,
  }) => [
    '/brands/$brandId/join-requests/$requestId/accept',
    '/service-owners/me/brands/$brandId/join-requests/$requestId/accept',
    '/providers/me/brands/$brandId/join-requests/$requestId/accept',
    '/providers/$providerId/brands/$brandId/join-requests/$requestId/accept',
  ];

  List<String> _rejectJoinRequestPaths({
    required String brandId,
    required String providerId,
    required String requestId,
  }) => [
    '/brands/$brandId/join-requests/$requestId/reject',
    '/service-owners/me/brands/$brandId/join-requests/$requestId/reject',
    '/providers/me/brands/$brandId/join-requests/$requestId/reject',
    '/providers/$providerId/brands/$brandId/join-requests/$requestId/reject',
  ];

  Future<List<BrandJoinRequest>> _fetchProviderBrandJoinRequests({
    required String providerId,
    required String brandId,
  }) async {
    try {
      final payload = await _requestFirstSuccess<dynamic>([
        for (final path in [
          '/brands/$brandId/join-requests',
          '/service-owners/me/brands/$brandId/join-requests',
          '/providers/me/brands/$brandId/join-requests',
          '/providers/$providerId/brands/$brandId/join-requests',
        ])
          _RequestAttempt.get(path),
      ]);
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
    } on AppException catch (error) {
      if (_shouldFallbackProviderManagement(error)) {
        return const [];
      }
      rethrow;
    }
  }

  Future<T> _requestFirstSuccess<T>(List<_RequestAttempt> attempts) async {
    final errors = <AppException>[];

    for (final attempt in attempts) {
      try {
        switch (attempt.method) {
          case 'GET':
            return await _apiClient.get<T>(
              attempt.path,
              mapper: (data) => data as T,
            );
          case 'POST':
            return await _apiClient.post<T>(
              attempt.path,
              data: attempt.data,
              mapper: (data) => data as T,
            );
          case 'PATCH':
            return await _apiClient.patch<T>(
              attempt.path,
              data: attempt.data,
              mapper: (data) => data as T,
            );
          case 'PUT':
            return await _apiClient.put<T>(
              attempt.path,
              data: attempt.data,
              mapper: (data) => data as T,
            );
          case 'DELETE':
            return await _apiClient.delete<T>(
              attempt.path,
              data: attempt.data,
              mapper: (data) => data as T,
            );
        }
      } on AppException catch (error) {
        if (_shouldTryNextProviderEndpoint(error)) {
          errors.add(error);
          continue;
        }
        rethrow;
      }
    }

    final lastError = errors.isEmpty ? null : errors.last;
    throw AppException(
      'The provider management endpoint is unavailable right now.',
      type: AppExceptionType.server,
      statusCode: lastError?.statusCode,
      code: lastError?.code,
      details: lastError?.details,
      requestId: lastError?.requestId,
    );
  }

  bool _shouldTryNextProviderEndpoint(AppException error) {
    return switch (error.statusCode) {
      404 || 405 || 501 => true,
      _ => false,
    };
  }

  bool _shouldFallbackProviderManagement(AppException error) {
    return _shouldTryNextProviderEndpoint(error);
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
    required String providerId,
    required ProviderServiceDraft draft,
  }) {
    return {
      'providerId': providerId,
      'name': draft.name.trim(),
      'categoryId': draft.categoryId,
      'categoryName': draft.categoryName,
      'brandId': draft.brandId,
      'addressLine': draft.addressLine.trim(),
      'description': draft.descriptionSnippet.trim(),
      'descriptionSnippet': draft.descriptionSnippet.trim(),
      'about': draft.about.trim(),
      'approvalMode': _approvalModeValue(draft.approvalMode),
      'isAvailable': draft.isAvailable,
      'serviceType': _serviceTypeValue(draft.serviceType),
      'waitingTimeMinutes': draft.waitingTimeMinutes,
      'leadTimeHours': draft.leadTimeHours,
      'freeCancellationHours': draft.freeCancellationHours,
      'visibilityLabels': draft.visibilityLabels
          .map(_visibilityLabelValue)
          .toList(growable: false),
      'requestableSlots': draft.requestableSlots
          .map(
            (slot) => {
              'startsAt': slot.startsAt.toUtc().toIso8601String(),
              'label': slot.label,
              'available': slot.available,
              if (slot.note != null && slot.note!.trim().isNotEmpty)
                'note': slot.note!.trim(),
            },
          )
          .toList(growable: false),
      'exceptionNotes': draft.exceptionNotes
          .map((note) => note.trim())
          .where((note) => note.isNotEmpty)
          .toList(growable: false),
      'gallery': _serializeMediaAssets(draft.galleryMedia),
      if (draft.price != null) 'price': draft.price,
    };
  }

  Map<String, dynamic> _brandDraftPayload({
    required String providerId,
    required ProviderBrandDraft draft,
  }) {
    return {
      'providerId': providerId,
      'name': draft.name.trim(),
      'headline': draft.headline.trim(),
      'addressLine': draft.addressLine.trim(),
      'description': draft.description.trim(),
      'mapHint': draft.mapHint.trim(),
      'visibilityLabels': draft.visibilityLabels
          .map(_visibilityLabelValue)
          .toList(growable: false),
      'openNow': draft.openNow,
      if (draft.logoMedia != null)
        'logo': _serializeMediaAsset(draft.logoMedia!),
    };
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

  List<BrandJoinRequest> _parseBrandJoinRequests(JsonMap item) {
    final values = _readList(item, [
      'joinRequests',
      'pendingJoinRequests',
      'membershipRequests',
    ]);
    if (values == null) {
      return const [];
    }

    return values
        .map(_tryParseBrandJoinRequest)
        .whereType<BrandJoinRequest>()
        .toList(growable: false);
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

  List<Map<String, dynamic>> _serializeMediaAssets(List<AppMediaAsset> assets) {
    return assets.map(_serializeMediaAsset).toList(growable: false);
  }

  Map<String, dynamic> _serializeMediaAsset(AppMediaAsset asset) {
    return {
      'id': asset.id,
      'label': asset.label,
      if (asset.remoteUrl != null) 'url': asset.remoteUrl,
    };
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

  String _visibilityLabelValue(VisibilityLabel label) {
    return switch (label) {
      VisibilityLabel.common => 'COMMON',
      VisibilityLabel.vip => 'VIP',
      VisibilityLabel.bestOfMonth => 'BEST_OF_MONTH',
      VisibilityLabel.sponsored => 'SPONSORED',
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

    return categories.isNotEmpty ? categories : _fallback.categories;
  }

  Future<List<ServiceSummary>> _fetchServiceSummaries({
    bool force = false,
  }) async {
    if (!force && _servicesCache != null && _isCacheFresh(_servicesFetchedAt)) {
      return _servicesCache!;
    }

    final payload = await _apiClient.get<dynamic>(
      '/services',
      mapper: (data) => data,
    );
    final items = _extractItems(payload, ['items', 'services']);
    final services = items
        .map(_tryParseServiceSummary)
        .whereType<ServiceSummary>()
        .toList(growable: false);

    _servicesCache = services;
    _servicesFetchedAt = DateTime.now();
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
  }) async {
    if (!force &&
        _providersCache != null &&
        _isCacheFresh(_providersFetchedAt)) {
      return _providersCache!;
    }

    final payload = await _apiClient.get<dynamic>(
      '/service-owners',
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

    _providersCache = providers;
    _providersFetchedAt = DateTime.now();
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

  List<ProviderSummary> _parseProviderList(dynamic value) {
    if (value is! List) {
      return const [];
    }

    return value
        .map(_tryParseProviderSummary)
        .whereType<ProviderSummary>()
        .toList(growable: false);
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
            'address.addressLine',
            'serviceAddress.addressLine',
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
      price: _readDouble(item, ['price', 'price.amount']),
      descriptionSnippet: _readString(item, [
        'descriptionSnippet',
        'description',
        'summary',
      ]),
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
    return BrandSummary(
      id: _readString(item, ['id'])!,
      name: _readString(item, ['name', 'title'])!,
      headline:
          _readString(item, ['headline', 'description', 'summary']) ??
          'Brand profile',
      addressLine:
          _readString(item, ['addressLine', 'address.addressLine']) ??
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
          _readInt(item, ['serviceCount', 'servicesCount', 'services.count']) ??
          0,
      memberCount:
          _readInt(item, ['memberCount', 'membersCount', 'members.count']) ?? 0,
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
      openNow: _readBool(item, ['openNow', 'isOpen', 'availableNow']) ?? false,
      logoMedia: _parsePrimaryMediaAsset(item, [
        'logoMedia',
        'logo',
        'brandLogo',
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
          _readBool(item, ['availableNow', 'isAvailable', 'openNow']) ?? false,
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
    if (rawSlots == null) {
      return const [];
    }

    final formatter = DateFormat('EEE, MMM d · HH:mm');
    final slots = <AvailabilityWindow>[];
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

    return slots;
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
    final id =
        _readString(asset, ['id', 'fileId', 'mediaId', 'key']) ??
        _readString(asset, ['url', 'publicUrl', 'downloadUrl', 'cdnUrl']);
    if (id == null || id.isEmpty) {
      return null;
    }

    final label = _readString(asset, ['label', 'name', 'fileName']) ?? 'Photo';
    final remoteUrl = _readString(asset, [
      'url',
      'publicUrl',
      'downloadUrl',
      'cdnUrl',
    ]);

    if (remoteUrl != null && remoteUrl.isNotEmpty) {
      return AppMediaAsset.uploaded(id: id, label: label, remoteUrl: remoteUrl);
    }

    return AppMediaAsset.generated(id: id, label: label);
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
    _providerSummaryCache[provider.id] = provider;
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
    final haystack = [
      provider.name,
      provider.headline,
      provider.bio,
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
