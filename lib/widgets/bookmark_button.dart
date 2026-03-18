// bookmark_button.dart
// Reziphay
//
// Author: Vugar Safarzada (@vugarsafarzada)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';

import '../core/network/api_client.dart';
import '../core/theme/app_palette.dart';
import '../core/network/endpoints.dart';
import '../core/network/network_exception.dart';

/// A bookmark toggle button for UCR users.
///
/// [entityType] must be one of: 'brands', 'owners', 'services'.
/// [entityId] is the UUID of the entity to bookmark.
///
/// The button is invisible when the current user is not UCR (API returns 403)
/// or when the user is not authenticated (API returns 401).
class BookmarkButton extends ConsumerStatefulWidget {
  const BookmarkButton({
    super.key,
    required this.entityType,
    required this.entityId,
    this.color,
  });

  /// 'brands' | 'owners' | 'services'
  final String entityType;
  final String entityId;
  final Color? color;

  @override
  ConsumerState<BookmarkButton> createState() => _BookmarkButtonState();
}

class _BookmarkButtonState extends ConsumerState<BookmarkButton> {
  bool _visible  = false; // hidden until status loads
  bool _loading  = true;  // spinner while fetching initial status
  bool _toggling = false; // spinner during add/remove
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _fetchStatus();
  }

  String get _statusUrl {
    switch (widget.entityType) {
      case 'brands':
        return Endpoints.favoriteBrandStatus(widget.entityId);
      case 'owners':
        return Endpoints.favoriteOwnerStatus(widget.entityId);
      case 'services':
      default:
        return Endpoints.favoriteServiceStatus(widget.entityId);
    }
  }

  String get _addUrl {
    switch (widget.entityType) {
      case 'brands':
        return Endpoints.addFavoriteBrand(widget.entityId);
      case 'owners':
        return Endpoints.addFavoriteOwner(widget.entityId);
      case 'services':
      default:
        return Endpoints.addFavoriteService(widget.entityId);
    }
  }

  String get _removeUrl {
    switch (widget.entityType) {
      case 'brands':
        return Endpoints.removeFavoriteBrand(widget.entityId);
      case 'owners':
        return Endpoints.removeFavoriteOwner(widget.entityId);
      case 'services':
      default:
        return Endpoints.removeFavoriteService(widget.entityId);
    }
  }

  Future<void> _fetchStatus() async {
    try {
      final result = await ApiClient.instance.get<Map<String, dynamic>>(
        _statusUrl,
        fromJson: (j) => j,
      );
      if (!mounted) return;
      setState(() {
        _isFavorite = result['isFavorite'] as bool? ?? false;
        _visible    = true;
        _loading    = false;
      });
    } on NetworkException catch (e) {
      // 401 = not authenticated, 403 = wrong role — hide the button
      if (e.statusCode == 401 || e.statusCode == 403) {
        if (mounted) setState(() { _visible = false; _loading = false; });
      } else {
        // Other errors (network, etc.) — hide silently
        if (mounted) setState(() { _visible = false; _loading = false; });
      }
    } catch (_) {
      if (mounted) setState(() { _visible = false; _loading = false; });
    }
  }

  Future<void> _toggle() async {
    if (_toggling) return;
    final wasFavorite = _isFavorite;
    // Optimistic update
    setState(() { _isFavorite = !wasFavorite; _toggling = true; });

    try {
      if (wasFavorite) {
        await ApiClient.instance.deleteVoid(_removeUrl);
      } else {
        await ApiClient.instance.postEmpty(_addUrl);
      }
    } catch (_) {
      // Revert on failure
      if (mounted) {
        setState(() => _isFavorite = wasFavorite);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not update favorites.')),
        );
      }
    } finally {
      if (mounted) setState(() => _toggling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return SizedBox(
        width: 40,
        height: 40,
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: widget.color ?? Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      );
    }

    if (!_visible) return const SizedBox.shrink();

    final iconColor = _isFavorite
        ? (widget.color ?? context.palette.primary)
        : (widget.color ?? Theme.of(context).colorScheme.primary);

    return IconButton(
      icon: Icon(
        _isFavorite ? Iconsax.heart5 : Iconsax.heart,
        color: iconColor,
      ),
      onPressed: _toggling ? null : _toggle,
    );
  }
}
