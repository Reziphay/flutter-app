// favorites_screen.dart
// Reziphay — UCR: Favorite Brands, Service Owners & Services
//
// Author: Vugar Safarzada (@vugarsafarzada)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/endpoints.dart';
import '../../../core/theme/app_dynamic_colors.dart';
import '../../../core/theme/app_palette.dart';

// ── Mini models ───────────────────────────────────────────────────────────────

class _FavBrand {
  const _FavBrand({required this.id, required this.name, this.logoUrl});
  final String  id;
  final String  name;
  final String? logoUrl;

  factory _FavBrand.fromJson(Map<String, dynamic> j) => _FavBrand(
        id:      j['id']   as String,
        name:    j['name'] as String,
        logoUrl: j['logoFile']?['url'] as String?,
      );
}

class _FavOwner {
  const _FavOwner({required this.id, required this.name, this.avatarUrl});
  final String  id;
  final String  name;
  final String? avatarUrl;

  factory _FavOwner.fromJson(Map<String, dynamic> j) => _FavOwner(
        id:        j['id']       as String,
        name:      j['fullName'] as String? ?? j['name'] as String? ?? '—',
        avatarUrl: j['avatarUrl'] as String?,
      );
}

class _FavService {
  const _FavService({
    required this.id,
    required this.name,
    this.photoUrl,
    this.priceAmount,
    this.priceCurrency,
  });
  final String  id;
  final String  name;
  final String? photoUrl;
  final num?    priceAmount;
  final String? priceCurrency;

  factory _FavService.fromJson(Map<String, dynamic> j) {
    final photos    = j['photos'] as List<dynamic>?;
    String? photoUrl;
    if (photos != null && photos.isNotEmpty) {
      final file = (photos.first as Map<String, dynamic>)['file']
          as Map<String, dynamic>?;
      photoUrl = file?['url'] as String?;
    }
    final rawPrice = j['priceAmount'];
    final price    = switch (rawPrice) {
      num n    => n,
      String s => num.tryParse(s),
      _        => null,
    };
    return _FavService(
      id:            j['id']            as String,
      name:          j['name']          as String,
      photoUrl:      photoUrl,
      priceAmount:   price,
      priceCurrency: j['priceCurrency'] as String?,
    );
  }
}

// ── Screen ────────────────────────────────────────────────────────────────────

class FavoritesScreen extends ConsumerStatefulWidget {
  const FavoritesScreen({super.key});

  @override
  ConsumerState<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends ConsumerState<FavoritesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Separate loading / data / error state per tab
  bool _brandsLoading   = false;
  bool _ownersLoading   = false;
  bool _servicesLoading = false;

  List<_FavBrand>   _brands   = [];
  List<_FavOwner>   _owners   = [];
  List<_FavService> _services = [];

  String? _brandsError;
  String? _ownersError;
  String? _servicesError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() => Future.wait([
        _loadBrands(),
        _loadOwners(),
        _loadServices(),
      ]);

  Future<void> _loadBrands() async {
    setState(() { _brandsLoading = true; _brandsError = null; });
    try {
      final json = await ApiClient.instance.get<Map<String, dynamic>>(
        Endpoints.favoriteBrands,
        fromJson: (j) => j,
      );
      final items = (json['items'] as List<dynamic>? ?? [])
          .map((e) => _FavBrand.fromJson(e as Map<String, dynamic>))
          .toList();
      if (mounted) setState(() => _brands = items);
    } catch (e) {
      if (mounted) setState(() => _brandsError = e.toString());
    } finally {
      if (mounted) setState(() => _brandsLoading = false);
    }
  }

  Future<void> _loadOwners() async {
    setState(() { _ownersLoading = true; _ownersError = null; });
    try {
      final json = await ApiClient.instance.get<Map<String, dynamic>>(
        Endpoints.favoriteOwners,
        fromJson: (j) => j,
      );
      final items = (json['items'] as List<dynamic>? ?? [])
          .map((e) => _FavOwner.fromJson(e as Map<String, dynamic>))
          .toList();
      if (mounted) setState(() => _owners = items);
    } catch (e) {
      if (mounted) setState(() => _ownersError = e.toString());
    } finally {
      if (mounted) setState(() => _ownersLoading = false);
    }
  }

  Future<void> _loadServices() async {
    setState(() { _servicesLoading = true; _servicesError = null; });
    try {
      final json = await ApiClient.instance.get<Map<String, dynamic>>(
        Endpoints.favoriteServices,
        fromJson: (j) => j,
      );
      final items = (json['items'] as List<dynamic>? ?? [])
          .map((e) => _FavService.fromJson(e as Map<String, dynamic>))
          .toList();
      if (mounted) setState(() => _services = items);
    } catch (e) {
      if (mounted) setState(() => _servicesError = e.toString());
    } finally {
      if (mounted) setState(() => _servicesLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = context.palette.primary;
    final dc      = context.dc;

    return Scaffold(
      backgroundColor: dc.secondaryBackground,
      appBar: AppBar(
        backgroundColor: dc.background,
        foregroundColor: dc.textPrimary,
        title: const Text('Favorites'),
        elevation: 0,
        bottom: TabBar(
          controller:       _tabController,
          indicatorColor:   primary,
          labelColor:       primary,
          unselectedLabelColor: dc.textSecondary,
          indicatorWeight:  2.5,
          labelStyle:       const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          dividerColor:     dc.divider,
          tabs: const [
            Tab(icon: Icon(Iconsax.building, size: 18), text: 'Brands'),
            Tab(icon: Icon(Iconsax.people,   size: 18), text: 'Providers'),
            Tab(icon: Icon(Iconsax.briefcase, size: 18), text: 'Services'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // ── Brands ──────────────────────────────────────────────────────
          _buildBrandsTab(dc, primary),
          // ── Service Owners ───────────────────────────────────────────────
          _buildOwnersTab(dc, primary),
          // ── Services ─────────────────────────────────────────────────────
          _buildServicesTab(dc, primary),
        ],
      ),
    );
  }

  // ── Brands tab ────────────────────────────────────────────────────────────

  Widget _buildBrandsTab(AppDynamicColors dc, Color primary) {
    if (_brandsLoading) {
      return Center(child: CircularProgressIndicator(color: primary));
    }
    if (_brandsError != null) {
      return _ErrorState(
        dc:      dc,
        primary: primary,
        onRetry: _loadBrands,
      );
    }
    if (_brands.isEmpty) {
      return _EmptyState(
        dc:       dc,
        icon:     Iconsax.building,
        title:    'No favorite brands',
        subtitle: 'Brands you save will appear here.',
      );
    }
    return RefreshIndicator(
      color: primary,
      onRefresh: _loadBrands,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _brands.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) => GestureDetector(
          onTap: () => context.push('/brand/${_brands[i].id}'),
          child: _BrandCard(brand: _brands[i], dc: dc),
        ),
      ),
    );
  }

  // ── Owners tab ────────────────────────────────────────────────────────────

  Widget _buildOwnersTab(AppDynamicColors dc, Color primary) {
    if (_ownersLoading) {
      return Center(child: CircularProgressIndicator(color: primary));
    }
    if (_ownersError != null) {
      return _ErrorState(dc: dc, primary: primary, onRetry: _loadOwners);
    }
    if (_owners.isEmpty) {
      return _EmptyState(
        dc:       dc,
        icon:     Iconsax.people,
        title:    'No favorite providers',
        subtitle: 'Service providers you save will appear here.',
      );
    }
    return RefreshIndicator(
      color: primary,
      onRefresh: _loadOwners,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _owners.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) => GestureDetector(
          onTap: () => context.push('/provider/${_owners[i].id}'),
          child: _OwnerCard(owner: _owners[i], dc: dc),
        ),
      ),
    );
  }

  // ── Services tab ──────────────────────────────────────────────────────────

  Widget _buildServicesTab(AppDynamicColors dc, Color primary) {
    if (_servicesLoading) {
      return Center(child: CircularProgressIndicator(color: primary));
    }
    if (_servicesError != null) {
      return _ErrorState(dc: dc, primary: primary, onRetry: _loadServices);
    }
    if (_services.isEmpty) {
      return _EmptyState(
        dc:       dc,
        icon:     Iconsax.briefcase,
        title:    'No favorite services',
        subtitle: 'Services you save will appear here.',
      );
    }
    return RefreshIndicator(
      color: primary,
      onRefresh: _loadServices,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _services.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) => GestureDetector(
          onTap: () => context.push('/service/${_services[i].id}'),
          child: _ServiceCard(service: _services[i], dc: dc),
        ),
      ),
    );
  }
}

// ── List item cards ───────────────────────────────────────────────────────────

class _BrandCard extends StatelessWidget {
  const _BrandCard({required this.brand, required this.dc});
  final _FavBrand        brand;
  final AppDynamicColors dc;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:        dc.cardBackground,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color:     Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset:    const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Logo or placeholder
          Container(
            width:  44,
            height: 44,
            decoration: BoxDecoration(
              color:        dc.secondaryBackground,
              borderRadius: BorderRadius.circular(10),
            ),
            clipBehavior: Clip.hardEdge,
            child: brand.logoUrl != null
                ? Image.network(brand.logoUrl!, fit: BoxFit.cover)
                : Icon(Iconsax.building, size: 20, color: dc.textTertiary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              brand.name,
              style: TextStyle(
                fontSize:   15,
                fontWeight: FontWeight.w600,
                color:      dc.textPrimary,
              ),
            ),
          ),
          Icon(Icons.chevron_right_rounded, size: 20, color: dc.textTertiary),
        ],
      ),
    );
  }
}

class _OwnerCard extends StatelessWidget {
  const _OwnerCard({required this.owner, required this.dc});
  final _FavOwner        owner;
  final AppDynamicColors dc;

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    final primary = context.palette.primary;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:        dc.cardBackground,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color:     Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset:    const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width:  44,
            height: 44,
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            clipBehavior: Clip.hardEdge,
            child: owner.avatarUrl != null
                ? Image.network(owner.avatarUrl!, fit: BoxFit.cover)
                : Center(
                    child: Text(
                      _initials(owner.name),
                      style: TextStyle(
                        fontSize:   16,
                        fontWeight: FontWeight.w700,
                        color:      primary,
                      ),
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              owner.name,
              style: TextStyle(
                fontSize:   15,
                fontWeight: FontWeight.w600,
                color:      dc.textPrimary,
              ),
            ),
          ),
          Icon(Icons.chevron_right_rounded, size: 20, color: dc.textTertiary),
        ],
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({required this.service, required this.dc});
  final _FavService      service;
  final AppDynamicColors dc;

  @override
  Widget build(BuildContext context) {
    final primary = context.palette.primary;
    return Container(
      decoration: BoxDecoration(
        color:        dc.cardBackground,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color:     Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset:    const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.hardEdge,
      child: Row(
        children: [
          // Photo thumbnail
          SizedBox(
            width:  72,
            height: 72,
            child: service.photoUrl != null
                ? Image.network(service.photoUrl!, fit: BoxFit.cover)
                : Container(
                    color: dc.secondaryBackground,
                    child: Icon(Iconsax.briefcase, size: 24,
                        color: dc.textTertiary),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service.name,
                  style: TextStyle(
                    fontSize:   15,
                    fontWeight: FontWeight.w600,
                    color:      dc.textPrimary,
                  ),
                ),
                if (service.priceAmount != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${service.priceAmount} ${service.priceCurrency ?? ''}',
                    style: TextStyle(
                      fontSize:   13,
                      fontWeight: FontWeight.w500,
                      color:      primary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Icon(Icons.chevron_right_rounded, size: 20,
                color: dc.textTertiary),
          ),
        ],
      ),
    );
  }
}

// ── Empty / Error states ──────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.dc,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final AppDynamicColors dc;
  final IconData         icon;
  final String           title;
  final String           subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width:  80,
              height: 80,
              decoration: BoxDecoration(
                color: dc.secondaryBackground,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 36, color: dc.textTertiary),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: TextStyle(
                fontSize:   18,
                fontWeight: FontWeight.w700,
                color:      dc.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color:    dc.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.dc,
    required this.primary,
    required this.onRetry,
  });

  final AppDynamicColors dc;
  final Color            primary;
  final VoidCallback     onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Iconsax.wifi, size: 48, color: dc.textTertiary),
          const SizedBox(height: 16),
          Text(
            'Could not load favorites',
            style: TextStyle(
              fontSize:   16,
              fontWeight: FontWeight.w600,
              color:      dc.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: onRetry,
            child: Text('Try again', style: TextStyle(color: primary)),
          ),
        ],
      ),
    );
  }
}
