// my_brands_screen.dart
// Reziphay — USO: manage own brands
//
// Author: Vugar Safarzada (@vugarsafarzada)

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/endpoints.dart';
import '../../../core/theme/app_dynamic_colors.dart';
import '../../../core/theme/app_palette.dart';
import '../../../state/app_state.dart';

// ── Model ──────────────────────────────────────────────────────────────────

class _BrandItem {
  const _BrandItem({
    required this.id,
    required this.name,
    this.description,
    this.email,
    this.phone,
    this.location,
    this.website,
    this.logoUrl,
    this.memberCount,
  });

  final String  id;
  final String  name;
  final String? description;
  final String? email;
  final String? phone;
  final String? location;
  final String? website;
  final String? logoUrl;
  final int?    memberCount;

  factory _BrandItem.fromJson(Map<String, dynamic> json) {
    final logoFile = json['logoFile'] as Map<String, dynamic>?;
    return _BrandItem(
      id:          json['id']          as String,
      name:        json['name']        as String,
      description: json['description'] as String?,
      email:       json['email']       as String?,
      phone:       json['phone']       as String?,
      location:    json['location']    as String?,
      website:     json['website']     as String?,
      logoUrl:     logoFile?['url']    as String?,
      memberCount: json['memberCount'] as int?,
    );
  }
}

// ── Provider ───────────────────────────────────────────────────────────────

final _myBrandsProvider =
    AsyncNotifierProvider<_MyBrandsNotifier, List<_BrandItem>>(
  _MyBrandsNotifier.new,
);

class _MyBrandsNotifier extends AsyncNotifier<List<_BrandItem>> {
  @override
  Future<List<_BrandItem>> build() async {
    final authStatus = ref.watch(appStateProvider.select((s) => s.authStatus));
    if (authStatus != AuthStatus.authenticated) return [];
    return _fetch();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }

  Future<void> delete(String brandId) async {
    await ApiClient.instance.deleteVoid(Endpoints.deleteBrand(brandId));
    state = AsyncData(
      state.value?.where((b) => b.id != brandId).toList() ?? [],
    );
  }

  static Future<List<_BrandItem>> _fetch() async {
    final json = await ApiClient.instance.get<Map<String, dynamic>>(
      Endpoints.myBrands,
      fromJson: (j) => j,
    );
    final items = json['items'] as List<dynamic>? ?? [];
    return items
        .map((e) => _BrandItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

// ── Screen ─────────────────────────────────────────────────────────────────

class MyBrandsScreen extends ConsumerWidget {
  const MyBrandsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n      = context.l10n;
    final primary   = context.palette.primary;
    final dc        = context.dc;
    final async     = ref.watch(_myBrandsProvider);
    final isLoading = ref.watch(_myBrandsProvider.select((s) => s.isLoading));

    return Scaffold(
      backgroundColor: dc.secondaryBackground,
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await context.push<bool>('/uso/brands/new');
          if (result == true) {
            ref.read(_myBrandsProvider.notifier).refresh();
          }
        },
        backgroundColor: primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add_rounded),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.myBrands,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: primary,
                          ),
                        ),
                        Text(
                          l10n.noBrandsSubtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            color: dc.textSecondary,
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
                        : () =>
                            ref.read(_myBrandsProvider.notifier).refresh(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // ── List ────────────────────────────────────────────────────
            Expanded(
              child: async.when(
                loading: () => Center(
                  child: CircularProgressIndicator(color: primary),
                ),
                error: (e, _) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Iconsax.warning_2,
                          size: 48, color: dc.textTertiary),
                      const SizedBox(height: 12),
                      Text(l10n.somethingWentWrong),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () =>
                            ref.read(_myBrandsProvider.notifier).refresh(),
                        child: Text(l10n.tryAgain),
                      ),
                    ],
                  ),
                ),
                data: (brands) {
                  if (brands.isEmpty) {
                    return _EmptyBrandsView(
                      onCreateTap: () async {
                        final result =
                            await context.push<bool>('/uso/brands/new');
                        if (result == true) {
                          ref.read(_myBrandsProvider.notifier).refresh();
                        }
                      },
                    );
                  }
                  return RefreshIndicator(
                    color: primary,
                    onRefresh: () =>
                        ref.read(_myBrandsProvider.notifier).refresh(),
                    child: ListView.separated(
                      padding:
                          const EdgeInsets.fromLTRB(16, 8, 16, 100),
                      itemCount: brands.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 16),
                      itemBuilder: (ctx, i) =>
                          _BrandCard(brand: brands[i]),
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

// ── Empty State ─────────────────────────────────────────────────────────────

class _EmptyBrandsView extends StatelessWidget {
  const _EmptyBrandsView({required this.onCreateTap});

  final VoidCallback onCreateTap;

  @override
  Widget build(BuildContext context) {
    final l10n    = context.l10n;
    final primary = context.palette.primary;
    final dc      = context.dc;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(Iconsax.shop, size: 36, color: primary.withValues(alpha: 0.5)),
            ),
            const SizedBox(height: 20),
            Text(
              l10n.noBrandsTitle,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.noBrandsSubtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: dc.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: onCreateTap,
                icon: const Icon(Icons.add_rounded, color: Colors.white),
                label: Text(
                  l10n.createBrand,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Brand Card ──────────────────────────────────────────────────────────────

class _BrandCard extends ConsumerWidget {
  const _BrandCard({required this.brand});

  final _BrandItem brand;

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Theme(
        data: theme,
        child: Localizations.override(
          context: context,
          locale: locale,
          child: AlertDialog(
            title: Text(l10n.deleteBrand),
            content: Text(
              l10n.deleteBrandConfirm,
              style: TextStyle(
                color: ctx.dc.textSecondary,
                fontSize: 14,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text(l10n.cancel),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: Text(
                  l10n.deleteBrand,
                  style: const TextStyle(color: AppPalette.error),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed != true || !context.mounted) return;
    try {
      await ref.read(_myBrandsProvider.notifier).delete(brand.id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.brandDeleted)),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.somethingWentWrong),
          backgroundColor: AppPalette.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final primary = context.palette.primary;
    final dc      = context.dc;
    final b       = brand;

    return Dismissible(
      key: ValueKey(b.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        await _confirmDelete(context, ref);
        return false;
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: AppPalette.error.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Iconsax.trash, color: AppPalette.error, size: 22),
            const SizedBox(height: 4),
            Text(
              context.l10n.deleteBrand,
              style: const TextStyle(
                fontSize: 11,
                color: AppPalette.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: dc.cardBackground,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () async {
            final changed =
                await context.push<bool>('/uso/brands/${b.id}/edit');
            if (changed == true) {
              ref.read(_myBrandsProvider.notifier).refresh();
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header row: avatar + name + arrow ──────────────
                Row(
                  children: [
                    _BrandAvatar(
                        logoUrl: b.logoUrl, name: b.name, primary: primary),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            b.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.3,
                            ),
                          ),
                          if (b.location != null) ...[
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                Icon(Iconsax.location,
                                    size: 13,
                                    color: primary.withValues(alpha: 0.6)),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    b.location!,
                                    style: TextStyle(
                                        fontSize: 13,
                                        color: dc.textSecondary,
                                        fontWeight: FontWeight.w500),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    Icon(Iconsax.arrow_right_3,
                        size: 18, color: dc.textTertiary),
                  ],
                ),

                // ── Description ────────────────────────────────────
                if (b.description != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    b.description!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: dc.textSecondary,
                      height: 1.45,
                    ),
                  ),
                ],

                // ── Divider ────────────────────────────────────────
                const SizedBox(height: 14),
                Divider(height: 1,
                    color: dc.textTertiary.withValues(alpha: 0.12)),
                const SizedBox(height: 12),

                // ── Meta chips ─────────────────────────────────────
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    if (b.phone != null)
                      _MetaChip(
                          icon: Iconsax.call,
                          label: b.phone!,
                          primary: primary,
                          dc: dc),
                    if (b.email != null)
                      _MetaChip(
                          icon: Iconsax.sms,
                          label: b.email!,
                          primary: primary,
                          dc: dc),
                    if (b.website != null)
                      _MetaChip(
                          icon: Iconsax.global,
                          label: b.website!
                              .replaceFirst(RegExp(r'https?://'), ''),
                          primary: primary,
                          dc: dc),
                    if (b.memberCount != null)
                      _MetaChip(
                          icon: Iconsax.people,
                          label: '${b.memberCount}',
                          primary: primary,
                          dc: dc),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Meta Chip ─────────────────────────────────────────────────────────────────

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.icon,
    required this.label,
    required this.primary,
    required this.dc,
  });

  final IconData           icon;
  final String             label;
  final Color              primary;
  final AppDynamicColors   dc;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: primary.withValues(alpha: 0.65)),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: dc.textSecondary),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

// ── Brand Avatar ─────────────────────────────────────────────────────────────

class _BrandAvatar extends StatelessWidget {
  const _BrandAvatar({
    required this.logoUrl,
    required this.name,
    required this.primary,
  });

  final String? logoUrl;
  final String  name;
  final Color   primary;

  @override
  Widget build(BuildContext context) {
    if (logoUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: CachedNetworkImage(
          imageUrl: logoUrl!,
          width: 72,
          height: 72,
          fit: BoxFit.cover,
          placeholder: (_, __) => _placeholder(),
          errorWidget: (_, __, ___) => _placeholder(),
        ),
      );
    }
    return _placeholder();
  }

  Widget _placeholder() {
    final initials = name.isNotEmpty
        ? name.trim().split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join().toUpperCase()
        : '?';
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: primary,
          ),
        ),
      ),
    );
  }
}
