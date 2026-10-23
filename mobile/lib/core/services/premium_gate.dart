import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../router/route_names.dart';
import '../../presentation/features/premium/widgets/plus_widgets.dart';
import '../theme/app_colors.dart';
import 'revenuecat_service.dart';

/// Fonctions réservées aux abonnés mazl+
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
        return 'Voir qui vous a aimé';
      case PremiumFeature.superLikes:
        return 'Super Likes';
      case PremiumFeature.boost:
        return 'Boost';
      case PremiumFeature.rewind:
        return 'Revenir en arrière';
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
        return 'Likez autant que vous voulez, sans limite quotidienne.';
      case PremiumFeature.seeWhoLikesYou:
        return 'Voyez qui vous a aimé avant même de le croiser.';
      case PremiumFeature.superLikes:
        return 'Faites-vous remarquer avec 5 Super Likes par jour.';
      case PremiumFeature.boost:
        return 'Soyez en tête de pile pendant 30 minutes.';
      case PremiumFeature.rewind:
        return 'Rattrapez un « Passer » trop rapide.';
      case PremiumFeature.readReceipts:
        return 'Sachez quand vos messages ont été lus.';
      case PremiumFeature.advancedFilters:
        return 'Filtrez par pratique, communauté, et plus.';
      case PremiumFeature.prioritySupport:
        return 'Obtenez une réponse rapide de notre équipe.';
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
  static const int freeLikesPerDay = 10;
  static const int _freeLikesPerDay = freeLikesPerDay;
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
      // Les compteurs ne font que croître au sein d'une journée : si un like a
      // été consommé avant la fin de la lecture, on garde le plus grand des
      // deux plutôt que d'écraser le compteur par une valeur périmée.
      if (storedDate == today) {
        _freeLikesUsedToday = max(
          _freeLikesUsedToday,
          prefs.getInt(_kLikesUsedKey) ?? 0,
        );
        _superLikesUsedToday = max(
          _superLikesUsedToday,
          prefs.getInt(_kSuperLikesUsedKey) ?? 0,
        );
        _boostsUsedToday = max(
          _boostsUsedToday,
          prefs.getInt(_kBoostsUsedKey) ?? 0,
        );
      }
      // Nouveau jour (ou premier lancement) : les compteurs en mémoire, s'il y
      // en a, datent d'aujourd'hui ; on fixe la nouvelle frontière.
      _quotaDate = today;
      await _persist();
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
  static bool get isPremium => debugPremiumOverride ?? _revenueCat.isMazlPro;

  /// Force le statut d'abonné dans les tests.
  @visibleForTesting
  static bool? debugPremiumOverride;

  /// Remet à zéro compteurs, cache et surcharge entre deux tests.
  @visibleForTesting
  static void resetForTest() {
    debugPremiumOverride = null;
    _freeLikesUsedToday = 0;
    _superLikesUsedToday = 0;
    _boostsUsedToday = 0;
    _quotaDate = null;
    _hydrated = false;
    _hydrating = null;
    onSuperLikesChanged = null;
  }

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

    final result = await _showSheet(
      context,
      PremiumFeatureSheet(
        title: feature.title,
        description: feature.description,
      ),
    );

    if (result == true) {
      if (!context.mounted) return false;
      return checkAccess(context, feature);
    }

    return false;
  }

  static Future<bool?> _showSheet(BuildContext context, Widget sheet) {
    return showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: AppColors.ink.withValues(alpha: 0.45),
      isScrollControlled: true,
      builder: (_) => sheet,
    );
  }

  /// Tente de consommer un like gratuit. Toujours vrai pour un abonné ; pour
  /// un utilisateur gratuit, faux (sans rien consommer) quand les likes du
  /// jour sont épuisés.
  static bool tryConsumeFreeLike() {
    if (isPremium) return true;
    if (remainingFreeLikes <= 0) return false;
    useFreeLike();
    return true;
  }

  /// Garde à appeler avant d'envoyer un like. Retourne vrai si le like peut
  /// partir (et a été décompté). Sinon ouvre la fenêtre de limite du jour et
  /// retourne faux : l'appelant n'envoie rien et rend la carte.
  static bool guardLike(BuildContext context) {
    if (tryConsumeFreeLike()) return true;
    unawaited(showDailyLimitSheet(context));
    return false;
  }

  /// Fenêtre « Vos likes du jour sont partis. », avec compte à rebours.
  /// « Découvrir mazl+ » ouvre l'offre.
  static Future<void> showDailyLimitSheet(BuildContext context) async {
    final wantsOffer = await _showSheet(
      context,
      const DailyLimitSheet(freeLikesPerDay: freeLikesPerDay),
    );
    if (wantsOffer == true && context.mounted) {
      await context.push<bool>(RoutePaths.premium);
    }
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
    return (_freeLikesPerDay - _freeLikesUsedToday).clamp(0, _freeLikesPerDay);
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

  /// Nombre de Super Likes par jour pour le statut actuel.
  static int get superLikesPerDay =>
      isPremium ? _premiumSuperLikesPerDay : _freeSuperLikesPerDay;

  /// Get remaining super likes for today.
  static int get remainingSuperLikes {
    _hydrateInBackground();
    _resetIfNewDay();
    final maxSuperLikes = isPremium
        ? _premiumSuperLikesPerDay
        : _freeSuperLikesPerDay;
    return (maxSuperLikes - _superLikesUsedToday).clamp(0, maxSuperLikes);
  }

  /// Use a super like. Persists the updated count and notifies listeners.
  static void useSuperLike() {
    _resetIfNewDay();
    final maxSuperLikes = isPremium
        ? _premiumSuperLikesPerDay
        : _freeSuperLikesPerDay;
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
    return (_premiumBoostsPerDay - _boostsUsedToday).clamp(
      0,
      _premiumBoostsPerDay,
    );
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
