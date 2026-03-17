// provider_profile_screen.dart
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
import '../../widgets/bookmark_button.dart';
import '../explore/widgets/rating_row.dart';
import '../explore/widgets/service_card.dart';

class ProviderProfileScreen extends ConsumerWidget {
  const ProviderProfileScreen({super.key, required this.providerId});

  final String providerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final servicesAsync = ref.watch(providerServicesProvider(providerId));
    final dc = context.dc;
    final l10n = context.l10n;

    return servicesAsync.when(
      loading: () => Scaffold(
        backgroundColor: dc.background,
        appBar: AppBar(backgroundColor: dc.background, elevation: 0),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: dc.background,
        appBar: AppBar(
          backgroundColor: dc.background,
          elevation: 0,
          leading: _BackButton(),
          title: Text(l10n.providerProfile,
              style: TextStyle(color: dc.textPrimary)),
        ),
        body: Center(
          child: Text(e.toString(),
              style: TextStyle(color: dc.textSecondary)),
        ),
      ),
      data: (result) {
        if (result.items.isEmpty) {
          return Scaffold(
            backgroundColor: dc.background,
            appBar: AppBar(
              backgroundColor: dc.background,
              elevation: 0,
              leading: _BackButton(),
              title: Text(l10n.providerProfile,
                  style: TextStyle(color: dc.textPrimary)),
            ),
            body: Center(
              child: Text(l10n.providerNotFound,
                  style: TextStyle(color: dc.textSecondary)),
            ),
          );
        }
        return _ProviderView(services: result.items);
      },
    );
  }
}

// MARK: - Main View

class _ProviderView extends StatelessWidget {
  const _ProviderView({required this.services});

  final List<ServiceItem> services;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final dc = context.dc;

    final owner = services.first.owner;

    // Collect unique brands
    final seenBrandIds = <String>{};
    final brands = <DiscoveryBrandRef>[];
    for (final s in services) {
      if (s.brand != null && seenBrandIds.add(s.brand!.id)) {
        brands.add(s.brand!);
      }
    }

    return Scaffold(
      backgroundColor: dc.background,
      body: CustomScrollView(
        slivers: [
          // MARK: - App Bar
          SliverAppBar(
            backgroundColor: dc.background,
            elevation: 0,
            pinned: true,
            leading: _BackButton(),
            title: Text(
              l10n.providerProfile,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: dc.textPrimary,
              ),
            ),
            actions: [
              if (owner != null) ...[
                BookmarkButton(entityType: 'owners', entityId: owner.id),
                const SizedBox(width: 4),
              ],
            ],
          ),

          // MARK: - Provider Header
          SliverToBoxAdapter(
            child: _ProviderHeader(owner: owner, services: services),
          ),

          // MARK: - Divider
          SliverToBoxAdapter(
            child: Divider(color: dc.divider, height: 1),
          ),

          // MARK: - Brands Section
          if (brands.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: _SectionTitle(title: l10n.searchTabBrands),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) => _BrandTile(brand: brands[i]),
                  childCount: brands.length,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Divider(color: dc.divider, height: 1),
            ),
          ],

          // MARK: - Services Section
          SliverToBoxAdapter(
            child: _SectionTitle(title: l10n.searchTabServices),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) => ServiceCard(
                  service: services[i],
                  onTap: () => context.push('/service/${services[i].id}'),
                ),
                childCount: services.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// MARK: - Provider Header

class _ProviderHeader extends StatelessWidget {
  const _ProviderHeader({required this.owner, required this.services});

  final DiscoveryOwner? owner;
  final List<ServiceItem> services;

  bool get _isVip => services.any((s) => s.isVip);

  @override
  Widget build(BuildContext context) {
    final dc = context.dc;
    final name = owner?.fullName ?? '';
    final avatarUrl = owner?.avatarUrl;
    final ratingStats = owner?.ratingStats;

    return Container(
      width: double.infinity,
      color: dc.background,
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
      child: Column(
        children: [
          // Avatar
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: dc.secondaryBackground,
              border: Border.all(color: dc.divider, width: 2),
            ),
            clipBehavior: Clip.antiAlias,
            child: avatarUrl != null
                ? CachedNetworkImage(
                    imageUrl: avatarUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => _InitialAvatar(name: name, large: true),
                    errorWidget: (_, __, ___) => _InitialAvatar(name: name, large: true),
                  )
                : _InitialAvatar(name: name, large: true),
          ),

          const SizedBox(height: 14),

          // Name
          if (name.isNotEmpty)
            Text(
              name,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: dc.textPrimary,
              ),
            ),

          // Rating
          if (ratingStats != null) ...[
            const SizedBox(height: 6),
            RatingRow(stats: ratingStats),
          ],

          // VIP badge
          if (_isVip) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
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
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// MARK: - Brand Tile

class _BrandTile extends StatelessWidget {
  const _BrandTile({required this.brand});

  final DiscoveryBrandRef brand;

  @override
  Widget build(BuildContext context) {
    final dc = context.dc;
    return GestureDetector(
      onTap: () => context.push('/brand/${brand.id}'),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            // Logo
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: dc.secondaryBackground,
              ),
              clipBehavior: Clip.antiAlias,
              child: brand.logoUrl != null
                  ? CachedNetworkImage(
                      imageUrl: brand.logoUrl!,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => _InitialAvatar(name: brand.name),
                      errorWidget: (_, __, ___) => _InitialAvatar(name: brand.name),
                    )
                  : _InitialAvatar(name: brand.name),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    brand.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.blue,
                    ),
                  ),
                  if (brand.ratingStats != null) ...[
                    const SizedBox(height: 3),
                    RatingRow(stats: brand.ratingStats!, small: true),
                  ],
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

// MARK: - Section Title

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final dc = context.dc;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: dc.textPrimary,
        ),
      ),
    );
  }
}

// MARK: - Back Button

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
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 6,
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

// MARK: - Initial Avatar

class _InitialAvatar extends StatelessWidget {
  const _InitialAvatar({required this.name, this.large = false});

  final String name;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final dc = context.dc;
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Center(
      child: Text(
        initial,
        style: TextStyle(
          fontSize: large ? 36 : 18,
          fontWeight: FontWeight.w700,
          color: AppColors.primary,
        ),
      ),
    );
  }
}
