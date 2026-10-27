import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../premium/purchase_moments.dart';
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
  readReceipts,
  advancedFilters,
  prioritySupport,
}

/// Helper class to gate premium features
class PremiumGate {
  static final SubscriptionService _subscriptions = SubscriptionService();

  /// Check if user has premium access
  static bool get isPremium => debugPremiumOverride ?? _subscriptions.isMazlPro;

  /// Force le statut d'abonné dans les tests.
  @visibleForTesting
  static bool? debugPremiumOverride;

  /// Remet la surcharge à zéro entre deux tests.
  @visibleForTesting
  static void resetForTest() {
    debugPremiumOverride = null;
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

  /// Fenêtre « Vos likes du jour sont partis. », avec compte à rebours.
  /// « Découvrir mazl+ » ouvre l'offre. La limite et l'heure de remise à zéro
  /// sont celles que le serveur a annoncées (`LikeAllowance`) ; l'app ne compte
  /// aucun like elle-même.
  static Future<void> showDailyLimitSheet(
    BuildContext context, {
    int? freeLikesPerDay,
    DateTime? resetsAt,
  }) async {
    // The same window is the offer of the « dailyLikeLimit » moment: it is
    // measured as one and no second offer follows it today.
    final wantsOffer = await PurchaseMoments.measure(
      context,
      PurchaseMoment.dailyLikeLimit,
      () async =>
          await _showSheet(
            context,
            DailyLimitSheet(
              freeLikesPerDay: freeLikesPerDay,
              resetsAt: resetsAt,
            ),
          ) ==
          true,
    );
    if (wantsOffer && context.mounted) {
      await context.push<bool>(RoutePaths.premium);
    }
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
