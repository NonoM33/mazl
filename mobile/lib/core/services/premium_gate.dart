import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../router/route_names.dart';
import '../theme/app_colors.dart';
import 'revenuecat_service.dart';

/// Premium features that require Mazl Pro subscription
enum PremiumFeature {
  unlimitedLikes,
  seeWhoLikesYou,
  superLikes,
  boost,
  rewind,
  readReceipts,
  advancedFilters,
  prioritySupport,
}

/// Extension to get feature info
extension PremiumFeatureInfo on PremiumFeature {
  String get title {
    switch (this) {
      case PremiumFeature.unlimitedLikes:
        return 'Likes illimités';
      case PremiumFeature.seeWhoLikesYou:
        return 'Voir qui t\'aime';
      case PremiumFeature.superLikes:
        return 'Super Likes';
      case PremiumFeature.boost:
        return 'Boost';
      case PremiumFeature.rewind:
        return 'Rewind';
      case PremiumFeature.readReceipts:
        return 'Confirmations de lecture';
      case PremiumFeature.advancedFilters:
        return 'Filtres avancés';
      case PremiumFeature.prioritySupport:
        return 'Support prioritaire';
    }
  }

  String get description {
    switch (this) {
      case PremiumFeature.unlimitedLikes:
        return 'Swipe autant que tu veux, sans limite quotidienne.';
      case PremiumFeature.seeWhoLikesYou:
        return 'Découvre qui t\'a liké avant de swiper.';
      case PremiumFeature.superLikes:
        return 'Fais-toi remarquer avec des Super Likes.';
      case PremiumFeature.boost:
        return 'Sois vu en premier pendant 30 minutes.';
      case PremiumFeature.rewind:
        return 'Annule ton dernier swipe si tu as fait une erreur.';
      case PremiumFeature.readReceipts:
        return 'Sache quand tes messages ont été lus.';
      case PremiumFeature.advancedFilters:
        return 'Filtre par niveau religieux, communauté, et plus.';
      case PremiumFeature.prioritySupport:
        return 'Obtiens une réponse rapide de notre équipe.';
    }
  }

  IconData get icon {
    switch (this) {
      case PremiumFeature.unlimitedLikes:
        return Icons.favorite;
      case PremiumFeature.seeWhoLikesYou:
        return Icons.visibility;
      case PremiumFeature.superLikes:
        return Icons.star;
      case PremiumFeature.boost:
        return Icons.bolt;
      case PremiumFeature.rewind:
        return Icons.undo;
      case PremiumFeature.readReceipts:
        return Icons.done_all;
      case PremiumFeature.advancedFilters:
        return Icons.filter_list;
      case PremiumFeature.prioritySupport:
        return Icons.support_agent;
    }
  }
}

/// Helper class to gate premium features
class PremiumGate {
  static final RevenueCatService _revenueCat = RevenueCatService();

  // Persistence keys. The stored date (yyyy-MM-dd) is compared against the
  // current day; when it differs, all daily counters reset to zero.
  static const String _kDateKey = 'premium_gate_quota_date';
  static const String _kLikesUsedKey = 'premium_gate_free_likes_used';
  static const String _kSuperLikesUsedKey = 'premium_gate_super_likes_used';
  static const String _kBoostsUsedKey = 'premium_gate_boosts_used';

  // Free daily limits (premium users are unlimited and bypass these).
  static const int _freeLikesPerDay = 10;
  static const int _freeSuperLikesPerDay = 1;
  static const int _premiumSuperLikesPerDay = 5;
  static const int _premiumBoostsPerDay = 1;

  // In-memory cache hydrated from [SharedPreferences]. Public getters read this
  // cache synchronously so the existing (synchronous) call sites keep working;
  // hydration happens lazily/asynchronously on first access.
  static int _freeLikesUsedToday = 0;
  static int _superLikesUsedToday = 0;
  static int _boostsUsedToday = 0;
  static String? _quotaDate;
  static bool _hydrated = false;
  static Future<void>? _hydrating;

  // Callback to notify UI of changes
  static VoidCallback? onSuperLikesChanged;

  /// Today's date as a stable `yyyy-MM-dd` string used as the reset boundary.
  static String _today() {
    final now = DateTime.now();
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    return '${now.year}-$month-$day';
  }

  /// Load persisted counters into the in-memory cache. Safe to call multiple
  /// times; the actual work runs at most once (subsequent calls await the same
  /// future). Errors are swallowed so a storage failure never blocks the UI —
  /// the cache simply falls back to zero-usage defaults.
  static Future<void> ensureInitialized() {
    if (_hydrated) return Future<void>.value();
    return _hydrating ??= _hydrate();
  }

  static Future<void> _hydrate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedDate = prefs.getString(_kDateKey);
      final today = _today();
      if (storedDate == today) {
        _freeLikesUsedToday = prefs.getInt(_kLikesUsedKey) ?? 0;
        _superLikesUsedToday = prefs.getInt(_kSuperLikesUsedKey) ?? 0;
        _boostsUsedToday = prefs.getInt(_kBoostsUsedKey) ?? 0;
        _quotaDate = today;
      } else {
        // New day (or first launch): reset and persist the fresh boundary.
        _freeLikesUsedToday = 0;
        _superLikesUsedToday = 0;
        _boostsUsedToday = 0;
        _quotaDate = today;
        await _persist();
      }
    } catch (error, stackTrace) {
      debugPrint('PremiumGate: failed to load quotas: $error\n$stackTrace');
    } finally {
      _hydrated = true;
      _hydrating = null;
    }
  }

  /// Kick off hydration if it has not happened yet, notifying listeners once
  /// the real counts are available so any badge rendered from stale defaults
  /// refreshes. Fire-and-forget: callers must not await it.
  static void _hydrateInBackground() {
    if (_hydrated) return;
    ensureInitialized().then((_) => onSuperLikesChanged?.call());
  }

  /// Reset the in-memory counters when the day rolls over between accesses
  /// (e.g. the app stayed open past midnight). Returns true if a reset happened.
  static bool _resetIfNewDay() {
    final today = _today();
    if (_quotaDate != today) {
      _freeLikesUsedToday = 0;
      _superLikesUsedToday = 0;
      _boostsUsedToday = 0;
      _quotaDate = today;
      return true;
    }
    return false;
  }

  /// Persist the current in-memory counters. Fire-and-forget at call sites;
  /// failures are logged but never thrown so a like is never blocked by storage.
  static Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kDateKey, _quotaDate ?? _today());
      await prefs.setInt(_kLikesUsedKey, _freeLikesUsedToday);
      await prefs.setInt(_kSuperLikesUsedKey, _superLikesUsedToday);
      await prefs.setInt(_kBoostsUsedKey, _boostsUsedToday);
    } catch (error, stackTrace) {
      debugPrint('PremiumGate: failed to persist quotas: $error\n$stackTrace');
    }
  }

  /// Check if user has premium access
  static bool get isPremium => _revenueCat.isMazlPro;

  /// Check if a specific feature is available
  static bool isFeatureAvailable(PremiumFeature feature) {
    // All premium features require Mazl Pro
    return isPremium;
  }

  /// Show premium screen if feature is not available
  /// Returns true if user has access (or just purchased), false if cancelled
  static Future<bool> checkAccess(
    BuildContext context,
    PremiumFeature feature,
  ) async {
    if (isFeatureAvailable(feature)) {
      return true;
    }

    // Show premium screen
    final result = await context.push<bool>(RoutePaths.premium);

    // Refresh and check if user now has premium
    await _revenueCat.refreshCustomerInfo();
    return _revenueCat.isMazlPro || (result == true);
  }

  /// Show a bottom sheet explaining the premium feature
  static Future<bool> showFeatureGate(
    BuildContext context,
    PremiumFeature feature,
  ) async {
    if (isFeatureAvailable(feature)) {
      return true;
    }

    final result = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _PremiumFeatureSheet(feature: feature),
    );

    if (result == true) {
      if (!context.mounted) return false;
      return checkAccess(context, feature);
    }

    return false;
  }

  /// Get remaining free likes for today (non-premium users).
  ///
  /// Returns `-1` for premium (unlimited). For free users it reflects the real
  /// persisted daily count. On the very first access before hydration completes
  /// it returns the full quota and triggers a background refresh.
  static int get remainingFreeLikes {
    if (isPremium) return -1; // Unlimited
    _hydrateInBackground();
    _resetIfNewDay();
    return (_freeLikesPerDay - _freeLikesUsedToday)
        .clamp(0, _freeLikesPerDay);
  }

  /// Consume one free like. No-op for premium users (unlimited). Persists the
  /// updated count and notifies listeners so any badge refreshes.
  static void useFreeLike() {
    if (isPremium) return;
    _resetIfNewDay();
    if (_freeLikesUsedToday < _freeLikesPerDay) {
      _freeLikesUsedToday++;
    }
    unawaited(_persist());
    onSuperLikesChanged?.call();
  }

  /// Get remaining super likes for today.
  static int get remainingSuperLikes {
    _hydrateInBackground();
    _resetIfNewDay();
    final maxSuperLikes =
        isPremium ? _premiumSuperLikesPerDay : _freeSuperLikesPerDay;
    return (maxSuperLikes - _superLikesUsedToday).clamp(0, maxSuperLikes);
  }

  /// Use a super like. Persists the updated count and notifies listeners.
  static void useSuperLike() {
    _resetIfNewDay();
    final maxSuperLikes =
        isPremium ? _premiumSuperLikesPerDay : _freeSuperLikesPerDay;
    if (_superLikesUsedToday < maxSuperLikes) {
      _superLikesUsedToday++;
    }
    unawaited(_persist());
    onSuperLikesChanged?.call();
  }

  /// Get remaining boosts for today. Free users get none.
  static int get remainingBoosts {
    if (!isPremium) return 0;
    _hydrateInBackground();
    _resetIfNewDay();
    return (_premiumBoostsPerDay - _boostsUsedToday)
        .clamp(0, _premiumBoostsPerDay);
  }

  /// Consume one boost (premium only). Persists and notifies listeners.
  static void useBoost() {
    if (!isPremium) return;
    _resetIfNewDay();
    if (_boostsUsedToday < _premiumBoostsPerDay) {
      _boostsUsedToday++;
    }
    unawaited(_persist());
    onSuperLikesChanged?.call();
  }
}

class _PremiumFeatureSheet extends StatelessWidget {
  const _PremiumFeatureSheet({required this.feature});

  final PremiumFeature feature;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),

          // Icon with app gradient
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.secondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              feature.icon,
              size: 32,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),

          // Title
          Text(
            feature.title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),

          // Description
          Text(
            feature.description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),

          // Upgrade button with gradient
          Container(
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.secondary],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: AppColors.secondary.withValues(alpha: 0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
              child: const Text(
                'Passer à Mazl Pro',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Not now button
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Pas maintenant',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}
