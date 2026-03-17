// service_detail_screen.dart
// Reziphay
//
// Author: Vugar Safarzada (@vugarsafarzada)

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';

import '../../core/constants/app_colors.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_dynamic_colors.dart';
import '../../models/discovery.dart';
import '../../state/explore_providers.dart';
import '../explore/widgets/rating_row.dart';
import '../reservations/create_reservation_sheet.dart';

class ServiceDetailScreen extends ConsumerWidget {
  const ServiceDetailScreen({super.key, required this.serviceId});

  final String serviceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final serviceAsync = ref.watch(serviceDetailProvider(serviceId));
    final dc = context.dc;

    return serviceAsync.when(
      loading: () => Scaffold(
        backgroundColor: dc.background,
        appBar: AppBar(backgroundColor: dc.background, elevation: 0),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: dc.background,
        appBar: AppBar(backgroundColor: dc.background, elevation: 0),
        body: Center(
          child: Text(e.toString(),
              style: TextStyle(color: dc.textSecondary)),
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
    final l10n = context.l10n;
    final dc = context.dc;

    return Scaffold(
      backgroundColor: dc.background,
      body: CustomScrollView(
        slivers: [
          // MARK: - Hero Photo / App Bar
          SliverAppBar(
            expandedHeight: 240,
            backgroundColor: dc.background,
            pinned: true,
            leading: const _BackButton(),
            flexibleSpace: FlexibleSpaceBar(
              background: service.thumbnailUrl != null
                  ? CachedNetworkImage(
                      imageUrl: service.thumbnailUrl!,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(color: dc.secondaryBackground),
                      errorWidget: (_, __, ___) => Container(
                        color: dc.secondaryBackground,
                        child: Icon(Iconsax.activity, size: 80, color: dc.textTertiary),
                      ),
                    )
                  : Container(
                      color: dc.secondaryBackground,
                      child: Icon(Iconsax.activity, size: 80, color: dc.textTertiary),
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
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: dc.textPrimary,
                          ),
                        ),
                      ),
                      if (service.isVip) ...[
                        const SizedBox(width: 8),
                        const _VipChip(),
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
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: dc.textPrimary,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),
                  Divider(color: dc.divider),
                  const SizedBox(height: 16),

                  // Description
                  if (service.description != null && service.description!.isNotEmpty) ...[
                    Text(
                      l10n.about,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: dc.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      service.description!,
                      style: TextStyle(
                        fontSize: 15,
                        color: dc.textSecondary,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Brand
                  if (service.brand != null)
                    _ClickableEntityTile(
                      label: l10n.brandDetailLabel,
                      name: service.brand!.name,
                      photoUrl: service.brand!.logoUrl,
                      onTap: () => context.push('/brand/${service.brand!.id}'),
                    ),

                  // Provider — only shown when service has no brand
                  if (service.owner != null && service.brand == null)
                    _ClickableEntityTile(
                      label: l10n.providerLabel,
                      name: service.owner!.fullName,
                      photoUrl: service.owner!.avatarUrl,
                      onTap: () => context.push('/provider/${service.owner!.id}'),
                    ),

                  // Location
                  if (service.location != null || service.address != null) ...[
                    _InfoTile(
                      icon: Iconsax.location,
                      label: l10n.location,
                      value: service.location ??
                          (service.address!.city.isNotEmpty
                              ? service.address!.city
                              : service.address!.fullAddress),
                    ),
                    if (service.distanceKm != null)
                      Padding(
                        padding: const EdgeInsets.only(left: 44, bottom: 16),
                        child: Text(
                          _formatDistance(service.distanceKm!),
                          style: TextStyle(
                            fontSize: 13,
                            color: dc.textSecondary,
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
                      label: l10n.booking,
                      value: service.approvalMode == 'AUTO'
                          ? l10n.instantConfirmation
                          : l10n.requiresApproval,
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
  const _BackButton();

  @override
  Widget build(BuildContext context) {
    final dc = context.dc;
    return Padding(
      padding: const EdgeInsets.all(8),
      child: GestureDetector(
        onTap: () => context.pop(),
        child: Container(
          decoration: BoxDecoration(
            color: dc.cardBackground,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 8,
              ),
            ],
          ),
          padding: const EdgeInsets.all(6),
          child: Icon(Iconsax.arrow_left_2, size: 20, color: dc.textPrimary),
        ),
      ),
    );
  }
}

class _VipChip extends StatelessWidget {
  const _VipChip();

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
    final dc = context.dc;
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
                  label.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: dc.textPrimary,
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

class _ClickableEntityTile extends StatelessWidget {
  const _ClickableEntityTile({
    required this.label,
    required this.name,
    required this.onTap,
    this.photoUrl,
  });

  final String label;
  final String name;
  final VoidCallback onTap;
  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    final dc = context.dc;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: dc.secondaryBackground,
              ),
              clipBehavior: Clip.antiAlias,
              child: photoUrl != null
                  ? CachedNetworkImage(
                      imageUrl: photoUrl!,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => _AvatarInitial(name: name),
                      errorWidget: (_, __, ___) => _AvatarInitial(name: name),
                    )
                  : _AvatarInitial(name: name),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.blue,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Iconsax.arrow_right_3, size: 16, color: dc.textTertiary),
          ],
        ),
      ),
    );
  }
}

class _AvatarInitial extends StatelessWidget {
  const _AvatarInitial({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    final dc = context.dc;
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Center(
      child: Text(
        initial,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: dc.textSecondary,
        ),
      ),
    );
  }
}

class _BookButton extends StatelessWidget {
  const _BookButton({required this.service});

  final ServiceItem service;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final dc = context.dc;
    return Container(
      color: dc.background,
      padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).padding.bottom + 12),
      child: SizedBox(
        height: 52,
        child: FilledButton(
          onPressed: () async {
            final booked = await showCreateReservationSheet(context, service);
            if (booked && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(context.l10n.reservationCreated),
                  backgroundColor: AppColors.success,
                ),
              );
            }
          },
          child: Text(
            service.approvalMode == 'AUTO' ? l10n.bookNow : l10n.requestBooking,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}
