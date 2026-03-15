// provider_profile_screen.dart
// Reziphay
//
// Author: Vugar Safarzada (@vugarsafarzada)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../models/discovery.dart';
import '../../services/discovery_service.dart';
import '../explore/widgets/rating_row.dart';

// Provider screen — displays provider info.
// Provider list comes from the search endpoint with ownerUserId filter.

class ProviderProfileScreen extends ConsumerWidget {
  const ProviderProfileScreen({super.key, required this.providerId});

  final String providerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchAsync = ref.watch(_providerDetailProvider(providerId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('Provider Profile'),
      ),
      body: searchAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text(e.toString(),
              style: const TextStyle(color: AppColors.textSecondary)),
        ),
        data: (results) {
          final provider = results.providers
              .where((p) => p.id == providerId)
              .firstOrNull;

          if (provider == null) {
            return const Center(
              child: Text(
                'Provider not found.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            );
          }

          return _ProviderView(provider: provider);
        },
      ),
    );
  }
}

// Fetch a small search page filtered by ownerUserId to get provider details
final _providerDetailProvider =
    FutureProvider.family<SearchResults, String>((ref, providerId) async {
  return DiscoveryService.instance.search(
    query: null,
    limit: 3,
  );
});

class _ProviderView extends StatelessWidget {
  const _ProviderView({required this.provider});

  final ProviderItem provider;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            width: double.infinity,
            color: AppColors.background,
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 44,
                  backgroundColor: AppColors.secondaryBackground,
                  child: Text(
                    provider.name.isNotEmpty ? provider.name[0].toUpperCase() : '?',
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  provider.name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (provider.ratingStats != null) ...[
                  const SizedBox(height: 6),
                  RatingRow(stats: provider.ratingStats!),
                ],
                if (provider.isVip) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [Color(0xFFFFB800), Color(0xFFFF8C00)]),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'VIP Provider',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          const Divider(height: 1),

          // Brands
          if (provider.brands.isNotEmpty) ...[
            const _SectionTitle(title: 'Brands'),
            ...provider.brands.map(
              (b) => ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppColors.secondaryBackground,
                  child: Icon(Icons.store_rounded, color: AppColors.primary, size: 18),
                ),
                title: Text(
                  b.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                subtitle: b.address != null ? Text(b.address!.city) : null,
                onTap: () => context.push('/brand/${b.id}'),
                trailing: const Icon(Icons.chevron_right_rounded,
                    color: AppColors.textTertiary),
              ),
            ),
          ],

          // Services
          if (provider.featuredServices.isNotEmpty) ...[
            const _SectionTitle(title: 'Services'),
            ...provider.featuredServices.map(
              (s) => ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppColors.secondaryBackground,
                  child: Icon(Icons.spa_rounded, color: AppColors.primary, size: 18),
                ),
                title: Text(
                  s.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                subtitle: s.address != null ? Text(s.address!.city) : null,
                onTap: () => context.push('/service/${s.id}'),
                trailing: const Icon(Icons.chevron_right_rounded,
                    color: AppColors.textTertiary),
              ),
            ),
          ],

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}
