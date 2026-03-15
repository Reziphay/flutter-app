// my_services_screen.dart
// Reziphay — USO: manage own services
//
// Author: Vugar Safarzada (@vugarsafarzada)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/endpoints.dart';
import '../../../state/app_state.dart';

// ── Model ──────────────────────────────────────────────────────────────────

class _ServiceItem {
  const _ServiceItem({
    required this.id,
    required this.name,
    required this.isActive,
    this.categoryName,
    this.priceAmount,
    this.priceCurrency,
    this.brandName,
    this.photoUrl,
  });

  final String id;
  final String name;
  final bool isActive;
  final String? categoryName;
  final num? priceAmount;
  final String? priceCurrency;
  final String? brandName;
  final String? photoUrl;

  factory _ServiceItem.fromJson(Map<String, dynamic> json) {
    final cat   = json['category'] as Map<String, dynamic>?;
    final brand = json['brand']    as Map<String, dynamic>?;
    final photos = json['photos']  as List<dynamic>?;

    return _ServiceItem(
      id:            json['id']       as String,
      name:          json['name']     as String,
      isActive:      json['isActive'] as bool? ?? true,
      categoryName:  cat?['name']     as String?,
      priceAmount:   json['priceAmount'] as num?,
      priceCurrency: json['priceCurrency'] as String?,
      brandName:     brand?['name']   as String?,
      photoUrl:      photos?.isNotEmpty == true
          ? (photos!.first as Map<String, dynamic>)['url'] as String?
          : null,
    );
  }
}

// ── Provider ───────────────────────────────────────────────────────────────

final _myServicesProvider =
    AsyncNotifierProvider<_MyServicesNotifier, List<_ServiceItem>>(
  _MyServicesNotifier.new,
);

class _MyServicesNotifier extends AsyncNotifier<List<_ServiceItem>> {
  @override
  Future<List<_ServiceItem>> build() async {
    final authStatus = ref.watch(appStateProvider.select((s) => s.authStatus));
    if (authStatus != AuthStatus.authenticated) return [];
    return _fetchMyServices();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetchMyServices);
  }

  static Future<List<_ServiceItem>> _fetchMyServices() async {
    final json = await ApiClient.instance.get<Map<String, dynamic>>(
      Endpoints.myServices,
      fromJson: (j) => j,
    );
    final items = json['items'] as List<dynamic>? ?? [];
    return items
        .map((e) => _ServiceItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

// ── Screen ─────────────────────────────────────────────────────────────────

class MyServicesScreen extends ConsumerWidget {
  const MyServicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final primary = context.palette.primary;
    final async   = ref.watch(_myServicesProvider);
    final isLoading = ref.watch(_myServicesProvider.select((s) => s.isLoading));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'My Services',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: primary,
                          ),
                        ),
                        const Text(
                          'Manage your services',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: isLoading
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: primary,
                            ),
                          )
                        : Icon(Iconsax.refresh, color: primary),
                    onPressed: isLoading
                        ? null
                        : () => ref.read(_myServicesProvider.notifier).refresh(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: async.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Iconsax.warning_2, size: 48, color: AppColors.textTertiary),
                      const SizedBox(height: 12),
                      const Text('Something went wrong'),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () =>
                            ref.read(_myServicesProvider.notifier).refresh(),
                        child: const Text('Try again'),
                      ),
                    ],
                  ),
                ),
                data: (items) {
                  if (items.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Iconsax.briefcase, size: 64, color: AppColors.textTertiary),
                          SizedBox(height: 16),
                          Text(
                            'No services yet',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Add your first service to start receiving bookings',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    );
                  }
                  return RefreshIndicator(
                    color: primary,
                    onRefresh: () =>
                        ref.read(_myServicesProvider.notifier).refresh(),
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, i) =>
                          _ServiceCard(service: items[i]),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Service Card ────────────────────────────────────────────────────────────

class _ServiceCard extends ConsumerWidget {
  const _ServiceCard({required this.service});

  final _ServiceItem service;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final primary = context.palette.primary;
    final s = service;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push('/service/${s.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Photo / placeholder
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  image: s.photoUrl != null
                      ? DecorationImage(
                          image: NetworkImage(s.photoUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: s.photoUrl == null
                    ? Icon(Iconsax.briefcase, color: primary, size: 24)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            s.name,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        // Active indicator
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: s.isActive
                                ? AppColors.success
                                : AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                    if (s.categoryName != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        s.categoryName!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                    if (s.priceAmount != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        '${s.priceAmount!.toStringAsFixed(2)} ${s.priceCurrency ?? ''}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: primary,
                        ),
                      ),
                    ],
                    if (s.brandName != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        s.brandName!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textTertiary),
            ],
          ),
        ),
      ),
    );
  }
}
