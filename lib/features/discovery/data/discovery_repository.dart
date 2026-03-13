import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reziphay_mobile/core/network/app_exception.dart';
import 'package:reziphay_mobile/features/discovery/models/discovery_models.dart';
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

final discoveryRepositoryProvider = Provider<DiscoveryRepository>(
  (ref) => MockDiscoveryRepository(),
);

final discoveryCategoriesProvider = Provider<List<DiscoveryCategory>>(
  (ref) => ref.watch(discoveryRepositoryProvider).categories,
);

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
      logoLabel: 'SN mark',
    ),
    'luna-dental': _BrandMeta(
      description:
          'Luna Dental uses Reziphay to make discovery and coordination easier without pretending every clinical visit fits a rigid slot engine.',
      mapHint:
          'Map preview will connect to the geolocation abstraction in a later pass.',
      logoLabel: 'LD crest',
    ),
    'form-and-flare': _BrandMeta(
      description:
          'Form & Flare focuses on studio-quality beauty sessions with careful review signals and clear availability communication.',
      mapHint:
          'Map preview will connect to the geolocation abstraction in a later pass.',
      logoLabel: 'F&F monogram',
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
      galleryLabels: ['Studio chair', 'Clean finish', 'Product shelf'],
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
      galleryLabels: ['Beard line', 'Chair setup', 'Finishing tools'],
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
      galleryLabels: ['Clinic room', 'Reception', 'Care setup'],
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
      galleryLabels: ['Procedure room', 'Clean tools', 'Aftercare desk'],
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
      galleryLabels: ['Treatment room', 'Lighting', 'Product detail'],
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
      galleryLabels: ['Overview', 'Space', 'Result'],
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
              logoLabel: _brandMetaById[brand.id]?.logoLabel,
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
    );

    _brands.add(summary);
    _brandMetaById[brandId] = _BrandMeta(
      description: draft.description.trim(),
      mapHint: draft.mapHint.trim(),
      logoLabel: draft.logoLabel?.trim(),
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
      ),
    );
    _brandMetaById[brandId] = _BrandMeta(
      description: draft.description.trim(),
      mapHint: draft.mapHint.trim(),
      logoLabel: draft.logoLabel?.trim(),
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
      galleryLabels: meta.galleryLabels,
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
      galleryLabels: meta.galleryLabels,
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
      logoLabel: meta?.logoLabel,
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
          galleryLabels: const ['Overview', 'Space', 'Result'],
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
      galleryLabels: draft.galleryLabels
          .map((label) => label.trim())
          .where((label) => label.isNotEmpty)
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
    this.logoLabel,
  });

  final String description;
  final String mapHint;
  final String? logoLabel;
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
    required this.galleryLabels,
    required this.exceptionNotes,
  });

  final String about;
  final String availabilitySummary;
  final List<AvailabilityWindow> requestableSlots;
  final int waitingTimeMinutes;
  final int freeCancellationHours;
  final int leadTimeHours;
  final ManagedServiceType serviceType;
  final List<String> galleryLabels;
  final List<String> exceptionNotes;
}

DateTime _dateAt(int dayOffset, int hour, int minute) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day + dayOffset, hour, minute);
}
