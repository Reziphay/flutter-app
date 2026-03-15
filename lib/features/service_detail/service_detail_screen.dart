// service_detail_screen.dart
// Reziphay
//
// Author: Vugar Safarzada (@vugarsafarzada)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';

import '../../core/constants/app_colors.dart';
import '../../models/discovery.dart';
import '../../state/explore_providers.dart';
import '../explore/widgets/rating_row.dart';

class ServiceDetailScreen extends ConsumerWidget {
  const ServiceDetailScreen({super.key, required this.serviceId});

  final String serviceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final serviceAsync = ref.watch(serviceDetailProvider(serviceId));

    return serviceAsync.when(
      loading: () => Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(backgroundColor: AppColors.background, elevation: 0),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(backgroundColor: AppColors.background, elevation: 0),
        body: Center(
          child: Text(e.toString(),
              style: const TextStyle(color: AppColors.textSecondary)),
        ),
      ),
      data: (service) => _ServiceDetailView(service: service),
    );
  }
}

class _ServiceDetailView extends StatelessWidget {
  const _ServiceDetailView({required this.service});

  final ServiceItem service;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // MARK: - Hero Photo / App Bar
          SliverAppBar(
            expandedHeight: 240,
            backgroundColor: AppColors.background,
            pinned: true,
            leading: _BackButton(),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: AppColors.secondaryBackground,
                child: const Center(
                  child: Icon(Iconsax.activity, size: 80, color: AppColors.textTertiary),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name + VIP
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          service.name,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      if (service.isVip) ...[
                        const SizedBox(width: 8),
                        _VipChip(),
                      ],
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Category
                  if (service.category != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        service.category!.name,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),

                  const SizedBox(height: 16),

                  // Rating + Price row
                  Row(
                    children: [
                      if (service.ratingStats != null)
                        RatingRow(stats: service.ratingStats!),
                      const Spacer(),
                      Text(
                        service.priceDisplay,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 16),

                  // Description
                  if (service.description != null && service.description!.isNotEmpty) ...[
                    const Text(
                      'About',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      service.description!,
                      style: const TextStyle(
                        fontSize: 15,
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Brand
                  if (service.brand != null)
                    _InfoTile(
                      icon: Iconsax.shop,
                      label: 'Brand',
                      value: service.brand!.name,
                    ),

                  // Provider
                  if (service.owner != null)
                    _InfoTile(
                      icon: Iconsax.user,
                      label: 'Provider',
                      value: service.owner!.fullName,
                    ),

                  // Location
                  if (service.address != null) ...[
                    _InfoTile(
                      icon: Iconsax.location,
                      label: 'Location',
                      value: service.address!.city.isNotEmpty
                          ? service.address!.city
                          : service.address!.fullAddress,
                    ),
                    if (service.distanceKm != null)
                      Padding(
                        padding: const EdgeInsets.only(left: 44, bottom: 16),
                        child: Text(
                          _formatDistance(service.distanceKm!),
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                  ],

                  // Approval mode
                  if (service.approvalMode != null)
                    _InfoTile(
                      icon: service.approvalMode == 'AUTO'
                          ? Iconsax.tick_circle
                          : Iconsax.clock,
                      label: 'Booking',
                      value: service.approvalMode == 'AUTO'
                          ? 'Instant confirmation'
                          : 'Requires approval',
                    ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _BookButton(service: service),
    );
  }

  String _formatDistance(double km) {
    if (km < 1) return '${(km * 1000).round()} m away';
    return '${km.toStringAsFixed(1)} km away';
  }
}

// MARK: - Widgets

class _BackButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: GestureDetector(
        onTap: () => context.pop(),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
              ),
            ],
          ),
          padding: const EdgeInsets.all(6),
          child: const Icon(Iconsax.arrow_left_2, size: 20, color: AppColors.textPrimary),
        ),
      ),
    );
  }
}

class _VipChip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFFFB800), Color(0xFFFF8C00)]),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Text(
        'VIP',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: Colors.white,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textTertiary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BookButton extends StatelessWidget {
  const _BookButton({required this.service});

  final ServiceItem service;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).padding.bottom + 12),
      child: SizedBox(
        height: 52,
        child: FilledButton(
          onPressed: () {
            // Phase 3: Reservation flow
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Booking coming in Phase 3')),
            );
          },
          child: Text(
            service.approvalMode == 'AUTO' ? 'Book Now' : 'Request Booking',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}
