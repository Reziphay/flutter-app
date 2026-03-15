// explore_screen.dart
// Reziphay
//
// Author: Vugar Safarzada (@vugarsafarzada)

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
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

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.secondaryBackground,
        body: RefreshIndicator(
          color: AppColors.primary,
          displacement: topPadding + 60,
          onRefresh: () async {
            ref.invalidate(nearbyServicesProvider);
            ref.invalidate(featuredServicesProvider);
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
              SliverToBoxAdapter(child: _NearMeSection()),
              SliverToBoxAdapter(child: _PopularBrandsSection()),
              SliverToBoxAdapter(child: _FeaturedServicesSection()),
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
    return Container(
      color: AppColors.background,
      padding: EdgeInsets.fromLTRB(20, topPadding + 16, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting
          Text(
            'Hello, ${userName ?? 'there'} 👋',
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Find the best services near you',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: AppColors.secondaryBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.tertiaryBackground),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: const Row(
          children: [
            Icon(Icons.search_rounded, color: AppColors.textSecondary, size: 20),
            SizedBox(width: 10),
            Text(
              'Search services, brands…',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Near Me ─────────────────────────────────────────────────────────────────

class _NearMeSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nearbyAsync = ref.watch(nearbyServicesProvider);

    return nearbyAsync.when(
      loading: () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Near Me',
            onSeeAll: () => context.push('/search'),
          ),
          const _HorizontalShimmer(),
        ],
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (result) {
        if (result.items.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              title: 'Near Me',
              onSeeAll: () => context.push('/search'),
            ),
            SizedBox(
              height: 210,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: result.items.length,
                itemBuilder: (_, i) => ServiceCard(
                  service: result.items[i],
                  onTap: () => context.push('/service/${result.items[i].id}'),
                  compact: true,
                ),
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

    return brandsAsync.when(
      loading: () => const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(title: 'Popular Brands'),
          _HorizontalShimmer(height: 170),
        ],
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (result) {
        if (result.items.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              title: 'Popular Brands',
              onSeeAll: () => context.push('/search?tab=brands'),
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

// ── Featured Services ────────────────────────────────────────────────────────

class _FeaturedServicesSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final featuredAsync = ref.watch(featuredServicesProvider);

    return featuredAsync.when(
      loading: () => const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(title: 'Featured'),
          _ListShimmer(),
        ],
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (result) {
        if (result.items.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              title: 'Featured',
              onSeeAll: () => context.push('/search'),
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
          color: AppColors.tertiaryBackground.withValues(alpha: _anim.value),
          borderRadius: BorderRadius.circular(widget.radius),
        ),
      ),
    );
  }
}
