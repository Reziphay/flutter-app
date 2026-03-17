// brand_card.dart
// Reziphay
//
// Author: Vugar Safarzada (@vugarsafarzada)

import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_dynamic_colors.dart';
import '../../../models/discovery.dart';
import 'rating_row.dart';

class BrandCard extends StatelessWidget {
  const BrandCard({
    super.key,
    required this.brand,
    required this.onTap,
  });

  final BrandItem brand;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dc = context.dc;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: dc.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: dc.divider, width: 1),
        ),
        child: Column(
          children: [
            // Logo
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: Container(
                height: 80,
                color: dc.secondaryBackground,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Logo image or fallback icon
                    if (brand.logoUrl != null && brand.logoUrl!.isNotEmpty)
                      Image.network(
                        brand.logoUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Center(
                          child: Icon(Iconsax.shop,
                              size: 32, color: dc.textTertiary),
                        ),
                      )
                    else
                      Center(
                        child:
                            Icon(Iconsax.shop, size: 32, color: dc.textTertiary),
                      ),
                    if (brand.isVip)
                      Positioned(
                        top: 6,
                        right: 6,
                        child: _VipBadge(),
                      ),
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
                    brand.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: dc.textPrimary,
                    ),
                  ),
                  // Show location string first, fall back to address city
                  if ((brand.location != null && brand.location!.isNotEmpty) ||
                      brand.address != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      brand.location?.isNotEmpty == true
                          ? brand.location!
                          : brand.address!.city,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: dc.textSecondary,
                      ),
                    ),
                  ],
                  if (brand.ratingStats != null) ...[
                    const SizedBox(height: 6),
                    RatingRow(stats: brand.ratingStats!, small: true),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VipBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFFFB800), Color(0xFFFF8C00)]),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        l10n.badgeVip,
        style: TextStyle(
          fontSize: 8,
          fontWeight: FontWeight.w800,
          color: Colors.white,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
