// service_card.dart
// Reziphay
//
// Author: Vugar Safarzada (@vugarsafarzada)

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_dynamic_colors.dart';
import '../../../models/discovery.dart';
import 'rating_row.dart';

class ServiceCard extends StatelessWidget {
  const ServiceCard({
    super.key,
    required this.service,
    required this.onTap,
    this.compact = false,
  });

  final ServiceItem service;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (compact) return _CompactCard(service: service, onTap: onTap);
    return _FullCard(service: service, onTap: onTap);
  }
}

// MARK: - Compact (horizontal scroll)

class _CompactCard extends StatelessWidget {
  const _CompactCard({required this.service, required this.onTap});

  final ServiceItem service;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dc = context.dc;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 180,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: dc.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: dc.divider, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Photo
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: SizedBox(
                height: 110,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    service.thumbnailUrl != null
                        ? CachedNetworkImage(
                            imageUrl: service.thumbnailUrl!,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(color: dc.secondaryBackground),
                            errorWidget: (_, __, ___) => Container(
                              color: dc.secondaryBackground,
                              child: Icon(Iconsax.activity, size: 36, color: dc.textTertiary),
                            ),
                          )
                        : Container(
                            color: dc.secondaryBackground,
                            child: Icon(Iconsax.activity, size: 36, color: dc.textTertiary),
                          ),
                    if (service.isVip)
                      Positioned(top: 8, left: 8, child: _VipBadge()),
                    if (service.distanceKm != null)
                      Positioned(top: 8, right: 8, child: _DistanceBadge(km: service.distanceKm!)),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: dc.textPrimary,
                    ),
                  ),
                  if (service.category != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      service.category!.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: dc.textSecondary,
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (service.ratingStats != null)
                        RatingRow(stats: service.ratingStats!, small: true),
                      Text(
                        service.priceDisplay,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: dc.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// MARK: - Full (vertical list)

class _FullCard extends StatelessWidget {
  const _FullCard({required this.service, required this.onTap});

  final ServiceItem service;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dc = context.dc;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: dc.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: dc.divider, width: 1),
        ),
        child: Row(
          children: [
            // Photo
            // Photo
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
              child: SizedBox(
                width: 90,
                height: 90,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    service.thumbnailUrl != null
                        ? CachedNetworkImage(
                            imageUrl: service.thumbnailUrl!,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(color: dc.secondaryBackground),
                            errorWidget: (_, __, ___) => Container(
                              color: dc.secondaryBackground,
                              child: Icon(Iconsax.activity, size: 30, color: dc.textTertiary),
                            ),
                          )
                        : Container(
                            color: dc.secondaryBackground,
                            child: Icon(Iconsax.activity, size: 30, color: dc.textTertiary),
                          ),
                    if (service.isVip)
                      Positioned(top: 6, left: 6, child: _VipBadge()),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      service.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: dc.textPrimary,
                      ),
                    ),
                    if (service.brand != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        service.brand!.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ] else if (service.owner != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        service.owner!.fullName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: dc.textSecondary),
                      ),
                    ],
                    if (service.location != null || service.address?.city != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Iconsax.location, size: 12, color: dc.textTertiary),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Text(
                              service.location ?? service.address!.city,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 11, color: dc.textTertiary),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (service.ratingStats != null)
                          RatingRow(stats: service.ratingStats!, small: true),
                        const Spacer(),
                        Text(
                          service.priceDisplay,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: dc.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// MARK: - Badges

class _VipBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFB800), Color(0xFFFF8C00)],
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        l10n.badgeVip,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          color: Colors.white,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _DistanceBadge extends StatelessWidget {
  const _DistanceBadge({required this.km});

  final double km;

  @override
  Widget build(BuildContext context) {
    final label = km < 1 ? '${(km * 1000).round()} m' : '${km.toStringAsFixed(1)} km';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w500),
      ),
    );
  }
}
