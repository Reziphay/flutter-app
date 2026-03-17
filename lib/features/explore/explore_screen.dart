// explore_screen.dart
// Reziphay
//
// Author: Vugar Safarzada (@vugarsafarzada)

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';

import '../../core/constants/app_colors.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_dynamic_colors.dart';
import '../../state/app_state.dart';
import '../../state/explore_providers.dart';
import 'widgets/brand_card.dart';
import 'widgets/category_chip_row.dart';
import 'widgets/section_header.dart';
import 'widgets/service_card.dart';

class ExploreScreen extends ConsumerWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(appStateProvider).currentUser;
    final topPadding = MediaQuery.of(context).padding.top;

    final dc = context.dc;
    final brightness = Theme.of(context).brightness;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: brightness == Brightness.dark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: dc.secondaryBackground,
        body: RefreshIndicator(
          color: AppColors.primary,
          displacement: topPadding + 60,
          onRefresh: () async {
            ref.invalidate(servicesPoolProvider);
            ref.invalidate(popularBrandsProvider);
            ref.invalidate(categoriesProvider);
          },
          child: CustomScrollView(
            slivers: [
              // ── Header ────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: _Header(
                  topPadding: topPadding,
                  userName: user?.fullName?.split(' ').first,
                  onSearchTap: () => context.push('/search'),
                ),
              ),

              // ── Category chips ────────────────────────────────────────
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: CategoryChipRow(),
                ),
              ),

              // ── Sections ──────────────────────────────────────────────
              SliverToBoxAdapter(child: _PopularBrandsSection()),
              SliverToBoxAdapter(child: _ServicesPoolSection()),
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Header ──────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({
    required this.topPadding,
    required this.onSearchTap,
    this.userName,
  });

  final double topPadding;
  final VoidCallback onSearchTap;
  final String? userName;

  @override
  Widget build(BuildContext context) {
    final dc = context.dc;
    final l10n = context.l10n;
    return Container(
      color: dc.background,
      padding: EdgeInsets.fromLTRB(20, topPadding + 16, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting
          Text(
            l10n.greeting(userName ?? 'there'),
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: dc.textPrimary,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.exploreSubtitle,
            style: TextStyle(
              fontSize: 14,
              color: dc.textSecondary,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 16),

          // Search bar
          _SearchTile(onTap: onSearchTap),
        ],
      ),
    );
  }
}

class _SearchTile extends StatelessWidget {
  const _SearchTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dc = context.dc;
    final l10n = context.l10n;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: dc.secondaryBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: dc.divider),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Row(
          children: [
            Icon(Iconsax.search_normal, color: dc.textSecondary, size: 20),
            const SizedBox(width: 10),
            Text(
              l10n.exploreSearch,
              style: TextStyle(
                fontSize: 14,
                color: dc.textSecondary,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Services Pool ────────────────────────────────────────────────────────────

class _ServicesPoolSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final poolAsync = ref.watch(servicesPoolProvider);
    final l10n = context.l10n;
    final dc = context.dc;

    return poolAsync.when(
      loading: () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: l10n.exploreFeatured,
            onSeeAll: () => context.push('/search?showAll=true'),
          ),
          const _ListShimmer(),
        ],
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.all(20),
        child: Text(
          'Error: $e',
          style: TextStyle(color: dc.textSecondary, fontSize: 13),
        ),
      ),
      data: (result) {
        if (result.items.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Text(
              l10n.brandNoServices,
              style: TextStyle(color: dc.textSecondary),
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              title: l10n.exploreFeatured,
              onSeeAll: () => context.push('/search?showAll=true'),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: result.items
                    .map((s) => ServiceCard(
                          service: s,
                          onTap: () => context.push('/service/${s.id}'),
                        ))
                    .toList(),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ── Popular Brands ───────────────────────────────────────────────────────────

class _PopularBrandsSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brandsAsync = ref.watch(popularBrandsProvider);
    final l10n = context.l10n;

    return brandsAsync.when(
      loading: () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(title: l10n.explorePopularBrands),
          const _HorizontalShimmer(height: 170),
        ],
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (result) {
        if (result.items.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              title: l10n.explorePopularBrands,
              onSeeAll: () => context.push('/search?tab=brands&showAll=true'),
            ),
            SizedBox(
              height: 170,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: result.items.length,
                itemBuilder: (_, i) => BrandCard(
                  brand: result.items[i],
                  onTap: () => context.push('/brand/${result.items[i].id}'),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}


// ── Shimmer placeholders ─────────────────────────────────────────────────────

class _HorizontalShimmer extends StatelessWidget {
  const _HorizontalShimmer({this.height = 210});

  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: 3,
        itemBuilder: (_, __) => _ShimmerBox(
          width: height == 210 ? 180 : 140,
          height: height,
          margin: const EdgeInsets.only(right: 12),
          radius: 16,
        ),
      ),
    );
  }
}

class _ListShimmer extends StatelessWidget {
  const _ListShimmer();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: List.generate(
          3,
          (_) => const _ShimmerBox(
            width: double.infinity,
            height: 90,
            margin: EdgeInsets.only(bottom: 12),
            radius: 16,
          ),
        ),
      ),
    );
  }
}

class _ShimmerBox extends StatefulWidget {
  const _ShimmerBox({
    required this.width,
    required this.height,
    this.margin = EdgeInsets.zero,
    this.radius = 12,
  });

  final double width;
  final double height;
  final EdgeInsets margin;
  final double radius;

  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.4, end: 0.8).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        width: widget.width,
        height: widget.height,
        margin: widget.margin,
        decoration: BoxDecoration(
          color: context.dc.tertiaryBackground.withValues(alpha: _anim.value),
          borderRadius: BorderRadius.circular(widget.radius),
        ),
      ),
    );
  }
}
