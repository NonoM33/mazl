import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../router/route_names.dart';
import '../../presentation/common/widgets/mazl_sheet.dart';
import '../../presentation/features/premium/widgets/credit_packs_sheet.dart';
import '../../presentation/features/premium/widgets/plus_widgets.dart';
import '../theme/app_colors.dart';
import 'store/credit_models.dart';
import 'store/credits_service.dart';
import 'store/subscription_service.dart';

/// Fonctions réservées aux abonnés mazl+. Leur titre et leur description
/// s'écrivent dans la langue du membre (`PremiumFeatureText`).
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

/// Helper class to gate premium features
class PremiumGate {
  static final SubscriptionService _subscriptions = SubscriptionService();

  // Persistence keys. The stored date (yyyy-MM-dd) is compared against the
  // current day; when it differs, all daily counters reset to zero.
  static const String _kDateKey = 'premium_gate_quota_date';
  static const String _kLikesUsedKey = 'premium_gate_free_likes_used';

  // Free daily limits (premium users are unlimited and bypass these).
  static const int freeLikesPerDay = 10;
  static const int _freeLikesPerDay = freeLikesPerDay;

  // In-memory cache hydrated from [SharedPreferences]. Public getters read this
  // cache synchronously so the existing (synchronous) call sites keep working;
  // hydration happens lazily/asynchronously on first access.
  static int _freeLikesUsedToday = 0;
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
    } catch (error, stackTrace) {
      debugPrint('PremiumGate: failed to persist quotas: $error\n$stackTrace');
    }
  }

  /// Check if user has premium access
  static bool get isPremium => debugPremiumOverride ?? _subscriptions.isMazlPro;

  /// Force le statut d'abonné dans les tests.
  @visibleForTesting
  static bool? debugPremiumOverride;

  /// Remet à zéro compteurs, cache et surcharge entre deux tests.
  @visibleForTesting
  static void resetForTest() {
    debugPremiumOverride = null;
    _freeLikesUsedToday = 0;
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

    // Relit le statut auprès du serveur et regarde si l'utilisateur est abonné
    await _subscriptions.refresh();
    return _subscriptions.isMazlPro || (result == true);
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
      PremiumFeatureSheet(feature: feature),
    );

    if (result == true) {
      if (!context.mounted) return false;
      return checkAccess(context, feature);
    }

    return false;
  }

  static Future<bool?> _showSheet(BuildContext context, Widget sheet) {
    return showMazlSheet<bool>(
      context,
      barrierColor: AppColors.ink.withValues(alpha: 0.45),
      isScrollControlled: true,
      builder: (_) => sheet,
    );
  }

  /// Ouvre la feuille « packs » de [kind] : plus de Super Likes ou de Boosts à
  /// dépenser. « Découvrir mazl+ » ouvre l'offre. Rend vrai quand, au retour,
  /// le serveur dit qu'il y a de nouveau de quoi dépenser (achat d'un pack, ou
  /// abonnement qui rouvre l'inclus du jour).
  static Future<bool> offerCredits(
    BuildContext context,
    CreditKind kind, {
    int boostMinutes = 30,
  }) async {
    final outcome = await showMazlSheet<CreditPacksOutcome>(
      context,
      barrierColor: AppColors.ink.withValues(alpha: 0.45),
      isScrollControlled: true,
      builder: (_) => CreditPacksSheet(
        kind: kind,
        isSubscriber: isPremium,
        boostMinutes: boostMinutes,
      ),
    );
    if (outcome == CreditPacksOutcome.discoverPlus && context.mounted) {
      await context.push<bool>(RoutePaths.premium);
      await _subscriptions.refresh();
      // L'inclus du jour dépend de l'abonnement : le serveur seul le sait.
      await CreditsService().refresh();
    }
    return CreditsService().available(kind) > 0;
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

  // Boosts et Super Likes : le crédit est tenu par le SERVEUR. Ces trois
  // lectures ne font que relayer le solde que le serveur a renvoyé (0 tant
  // qu'on ne l'a pas) ; l'app n'accorde et ne décompte jamais rien d'elle-même.

  /// Super Likes inclus par jour pour le statut actuel (donné par le serveur).
  static int get superLikesPerDay =>
      CreditsService().balance?.superLike.dailyAllowance ?? 0;

  /// Super Likes qu'on peut envoyer maintenant : l'inclus du jour restant plus
  /// les crédits achetés.
  static int get remainingSuperLikes =>
      CreditsService().available(CreditKind.superLike);

  /// Boosts qu'on peut activer maintenant : l'inclus du jour restant plus les
  /// crédits achetés.
  static int get remainingBoosts =>
      CreditsService().available(CreditKind.boost);
}
