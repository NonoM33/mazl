import 'package:intl/intl.dart';

import '../../../../core/services/premium_gate.dart';
import '../../../../core/services/store/subscription_models.dart';
import '../../../../l10n/l10n.dart';

/// Title and description of a feature reserved to mazl+ subscribers, in the
/// member's language (the « Réservé à mazl+ » sheet).
extension PremiumFeatureText on PremiumFeature {
  String title(AppLocalizations l10n) => switch (this) {
    PremiumFeature.unlimitedLikes => l10n.plusFeatureUnlimitedLikesTitle,
    PremiumFeature.seeWhoLikesYou => l10n.plusFeatureSeeWhoLikesYouTitle,
    PremiumFeature.superLikes => l10n.plusFeatureSuperLikesTitle,
    PremiumFeature.boost => l10n.plusFeatureBoostTitle,
    PremiumFeature.readReceipts => l10n.plusFeatureReadReceiptsTitle,
    PremiumFeature.advancedFilters => l10n.plusFeatureAdvancedFiltersTitle,
    PremiumFeature.prioritySupport => l10n.plusFeaturePrioritySupportTitle,
  };

  String description(AppLocalizations l10n) => switch (this) {
    PremiumFeature.unlimitedLikes => l10n.plusFeatureUnlimitedLikesDescription,
    PremiumFeature.seeWhoLikesYou => l10n.plusFeatureSeeWhoLikesYouDescription,
    PremiumFeature.superLikes => l10n.plusFeatureSuperLikesDescription,
    PremiumFeature.boost => l10n.plusFeatureBoostDescription,
    PremiumFeature.readReceipts => l10n.plusFeatureReadReceiptsDescription,
    PremiumFeature.advancedFilters =>
      l10n.plusFeatureAdvancedFiltersDescription,
    PremiumFeature.prioritySupport =>
      l10n.plusFeaturePrioritySupportDescription,
  };
}

/// The sentence for a purchase or a restore that did not succeed. The core
/// only returns the [PurchaseProblem]; the wording lives here.
String purchaseProblemText(AppLocalizations l10n, PurchaseProblem problem) =>
    switch (problem) {
      PurchaseProblem.purchaseInProgress => l10n.plusErrorPurchaseInProgress,
      PurchaseProblem.androidSoon => l10n.plusAndroidSoon,
      PurchaseProblem.ownedByAnotherAccount =>
        l10n.plusErrorOwnedByAnotherAccount,
      PurchaseProblem.invalidTransaction => l10n.plusErrorInvalidTransaction,
      PurchaseProblem.invalidBody => l10n.plusErrorInvalidBody,
      PurchaseProblem.signInAgain => l10n.plusErrorSignInAgain,
      PurchaseProblem.offline => l10n.plusErrorOffline,
      PurchaseProblem.generic => l10n.plusErrorGeneric,
      PurchaseProblem.inactive => l10n.plusErrorInactive,
      PurchaseProblem.restoreFailed => l10n.plusErrorRestoreFailed,
    };

/// A renewal or expiry date, long form (« 12 mars 2027 », « March 12, 2027 »).
/// French keeps its « 1er » for the first of the month.
String plusDateText(AppLocalizations l10n, DateTime date) {
  final locale = l10n.localeName;
  final text = DateFormat.yMMMMd(locale).format(date);
  if (locale == 'fr' && date.day == 1) return text.replaceFirst('1 ', '1er ');
  return text;
}
