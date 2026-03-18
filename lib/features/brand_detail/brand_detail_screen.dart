// brand_detail_screen.dart
// Reziphay
//
// Author: Vugar Safarzada (@vugarsafarzada)

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_dynamic_colors.dart';
import '../../core/theme/app_palette.dart';
import '../../models/discovery.dart';
import '../../state/explore_providers.dart';
import '../../widgets/bookmark_button.dart';
import '../explore/widgets/rating_row.dart';
import '../explore/widgets/service_card.dart';

class BrandDetailScreen extends ConsumerWidget {
  const BrandDetailScreen({super.key, required this.brandId});

  final String brandId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brandAsync    = ref.watch(brandDetailProvider(brandId));
    final servicesAsync = ref.watch(brandServicesProvider(brandId));

    final l10n = context.l10n;
    final dc   = context.dc;

    return Scaffold(
      backgroundColor: dc.secondaryBackground,
      body: brandAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text(e.toString(),
              style: TextStyle(color: dc.textSecondary)),
        ),
        data: (brand) => CustomScrollView(
          slivers: [
            // ── App Bar with logo ──────────────────────────────────────
            SliverAppBar(
              expandedHeight: 220,
              backgroundColor: dc.background,
              pinned: true,
              leading: _BackButton(),
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  color: dc.secondaryBackground,
                  child: brand.logoUrl != null && brand.logoUrl!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: brand.logoUrl!,
                          fit: BoxFit.contain,
                          width: double.infinity,
                          height: double.infinity,
                          placeholder: (_, __) => Center(
                            child: Icon(Iconsax.shop,
                                size: 72, color: dc.textTertiary),
                          ),
                          errorWidget: (_, __, ___) => Center(
                            child: Icon(Iconsax.shop,
                                size: 72, color: dc.textTertiary),
                          ),
                        )
                      : Center(
                          child: Icon(Iconsax.shop,
                              size: 72, color: dc.textTertiary),
                        ),
                ),
              ),
            ),

            // ── Brand Info card ────────────────────────────────────────
            SliverToBoxAdapter(
              child: Container(
                color: dc.background,
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name + Bookmark + VIP
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            brand.name,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: dc.textPrimary,
                            ),
                          ),
                        ),
                        BookmarkButton(entityType: 'brands', entityId: brand.id),
                        if (brand.isVip) ...[
                          const SizedBox(width: 4),
                          _VipChip(),
                          const SizedBox(width: 4),
                        ],
                      ],
                    ),

                    // Rating
                    if (brand.ratingStats != null) ...[
                      const SizedBox(height: 10),
                      RatingRow(stats: brand.ratingStats!),
                    ],

                    // Meta: location / phone / website
                    if (_hasAnyMeta(brand)) ...[
                      Divider(color: dc.divider, height: 28),
                      _MetaInfoSection(brand: brand),
                    ],

                    // Owner
                    if (brand.owner != null) ...[
                      Divider(color: dc.divider, height: 28),
                      _OwnerRow(
                        owner: brand.owner!,
                        dc: dc,
                        l10n: l10n,
                        onTap: () => context.push('/provider/${brand.owner!.id}'),
                      ),
                    ],

                    // Description
                    if (brand.description != null &&
                        brand.description!.isNotEmpty) ...[
                      Divider(color: dc.divider, height: 28),
                      Text(
                        l10n.about,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: dc.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _ExpandableDescription(
                        text: brand.description!,
                        dc: dc,
                        l10n: l10n,
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // ── Gap between card and services ──────────────────────────
            const SliverToBoxAdapter(child: SizedBox(height: 8)),

            // ── Services header ────────────────────────────────────────
            SliverToBoxAdapter(
              child: Container(
                color: dc.background,
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: Text(
                  l10n.brandServices,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: dc.textPrimary,
                  ),
                ),
              ),
            ),

            // ── Services list ──────────────────────────────────────────
            servicesAsync.when(
              loading: () => const SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  ),
                ),
              ),
              error: (_, __) =>
                  const SliverToBoxAdapter(child: SizedBox.shrink()),
              data: (result) {
                if (result.items.isEmpty) {
                  return SliverToBoxAdapter(
                    child: Container(
                      color: dc.background,
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: Text(
                          l10n.brandNoServices,
                          style: TextStyle(color: dc.textSecondary),
                        ),
                      ),
                    ),
                  );
                }
                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => ServiceCard(
                        service: result.items[i],
                        onTap: () =>
                            context.push('/service/${result.items[i].id}'),
                      ),
                      childCount: result.items.length,
                    ),
                  ),
                );
              },
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
    );
  }

  bool _hasAnyMeta(BrandItem brand) =>
      (brand.location != null && brand.location!.isNotEmpty) ||
      (brand.phone != null && brand.phone!.isNotEmpty) ||
      (brand.website != null && brand.website!.isNotEmpty) ||
      brand.address != null;
}

// ─────────────────────────────────────────────────────────────────────────────
// Meta info rows (location / phone / website)
// ─────────────────────────────────────────────────────────────────────────────

class _MetaInfoSection extends StatelessWidget {
  const _MetaInfoSection({required this.brand});

  final BrandItem brand;

  Future<void> _launch(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dc = context.dc;
    final primary = context.palette.primary;

    // Determine location string: prefer brand.location string, else address
    String? locationText = brand.location;
    if ((locationText == null || locationText.isEmpty) &&
        brand.address != null) {
      final addr = brand.address!;
      locationText = addr.city.isNotEmpty
          ? '${addr.city}, ${addr.country}'
          : addr.fullAddress;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (locationText != null && locationText.isNotEmpty)
          _MetaRow(
            icon: Iconsax.location,
            label: locationText,
            dc: dc,
            iconColor: dc.textSecondary,
          ),
        if (brand.phone != null && brand.phone!.isNotEmpty) ...[
          const SizedBox(height: 6),
          _MetaRow(
            icon: Iconsax.call,
            label: brand.phone!,
            dc: dc,
            iconColor: primary,
            onTap: () => _launch('tel:${brand.phone!}'),
          ),
        ],
        if (brand.website != null && brand.website!.isNotEmpty) ...[
          const SizedBox(height: 6),
          _MetaRow(
            icon: Iconsax.global,
            label: brand.website!,
            dc: dc,
            iconColor: primary,
            onTap: () => _launch(brand.website!),
          ),
        ],
      ],
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({
    required this.icon,
    required this.label,
    required this.dc,
    required this.iconColor,
    this.onTap,
  });

  final IconData         icon;
  final String           label;
  final AppDynamicColors dc;
  final Color            iconColor;
  final VoidCallback?    onTap;

  @override
  Widget build(BuildContext context) {
    final row = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Icon(icon, size: 15, color: iconColor),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: onTap != null ? iconColor : dc.textSecondary,
              decoration: onTap != null ? TextDecoration.underline : null,
              decorationColor: iconColor,
            ),
          ),
        ),
      ],
    );
    if (onTap == null) return row;
    return GestureDetector(onTap: onTap, child: row);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Owner row
// ─────────────────────────────────────────────────────────────────────────────

class _OwnerRow extends StatelessWidget {
  const _OwnerRow({
    required this.owner,
    required this.dc,
    required this.l10n,
    required this.onTap,
  });

  final DiscoveryOwner owner;
  final AppDynamicColors dc;
  final AppLocalizations l10n;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasAvatar = owner.avatarUrl != null && owner.avatarUrl!.isNotEmpty;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
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
            child: hasAvatar
                ? CachedNetworkImage(
                    imageUrl: owner.avatarUrl!,
                    fit: BoxFit.cover,
                    placeholder: (_, __) =>
                        Icon(Iconsax.user, size: 20, color: dc.textTertiary),
                    errorWidget: (_, __, ___) =>
                        Icon(Iconsax.user, size: 20, color: dc.textTertiary),
                  )
                : Icon(Iconsax.user, size: 20, color: dc.textTertiary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.brandOwnerLabel.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    color: context.palette.primary,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  owner.fullName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppPalette.blue,
                  ),
                ),
              ],
            ),
          ),
          Icon(Iconsax.arrow_right_3, size: 16, color: dc.textTertiary),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Expandable description
// ─────────────────────────────────────────────────────────────────────────────

class _ExpandableDescription extends StatefulWidget {
  const _ExpandableDescription({
    required this.text,
    required this.dc,
    required this.l10n,
  });

  final String text;
  final AppDynamicColors dc;
  final AppLocalizations l10n;

  @override
  State<_ExpandableDescription> createState() => _ExpandableDescriptionState();
}

class _ExpandableDescriptionState extends State<_ExpandableDescription> {
  static const _collapseThreshold = 150;
  bool _expanded = false;

  bool get _needsToggle => widget.text.length > _collapseThreshold;

  @override
  Widget build(BuildContext context) {
    final primary = context.palette.primary;
    final displayText = _needsToggle && !_expanded
        ? '${widget.text.substring(0, _collapseThreshold)}…'
        : widget.text;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          displayText,
          style: TextStyle(
            fontSize: 15,
            color: widget.dc.textSecondary,
            height: 1.5,
          ),
        ),
        if (_needsToggle) ...[
          const SizedBox(height: 4),
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Text(
              _expanded ? widget.l10n.showLess : widget.l10n.showMore,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: primary,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Back button
// ─────────────────────────────────────────────────────────────────────────────

class _BackButton extends StatelessWidget {
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
            border: Border.all(color: dc.divider, width: 1),
          ),
          padding: const EdgeInsets.all(6),
          child: Icon(Iconsax.arrow_left_2, size: 20, color: dc.textPrimary),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// VIP chip
// ─────────────────────────────────────────────────────────────────────────────

class _VipChip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [Color(0xFFFFB800), Color(0xFFFF8C00)]),
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
