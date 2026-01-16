import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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

  // Track super likes used today (resets on app restart for now)
  static int _superLikesUsedToday = 0;
  static DateTime _lastResetDate = DateTime.now();

  // Callback to notify UI of changes
  static VoidCallback? onSuperLikesChanged;

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
      return checkAccess(context, feature);
    }

    return false;
  }

  /// Get remaining free likes for today (non-premium users)
  static int get remainingFreeLikes {
    if (isPremium) return -1; // Unlimited
    // TODO: Track daily likes in local storage
    return 10; // Default free limit
  }

  /// Reset daily counters if it's a new day
  static void _checkDailyReset() {
    final now = DateTime.now();
    if (now.day != _lastResetDate.day ||
        now.month != _lastResetDate.month ||
        now.year != _lastResetDate.year) {
      _superLikesUsedToday = 0;
      _lastResetDate = now;
    }
  }

  /// Get remaining super likes for today
  static int get remainingSuperLikes {
    _checkDailyReset();
    final maxSuperLikes = isPremium ? 5 : 1;
    return (maxSuperLikes - _superLikesUsedToday).clamp(0, maxSuperLikes);
  }

  /// Use a super like
  static void useSuperLike() {
    _checkDailyReset();
    _superLikesUsedToday++;
    onSuperLikesChanged?.call();
  }

  /// Get remaining boosts
  static int get remainingBoosts {
    if (!isPremium) return 0;
    return 1; // 1 per week for premium
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
                  color: AppColors.primary.withOpacity(0.3),
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
                  color: AppColors.secondary.withOpacity(0.4),
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
