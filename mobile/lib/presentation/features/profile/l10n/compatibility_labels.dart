import '../../../../core/models/compatibility_score.dart';
import '../../../../l10n/l10n.dart';

extension CompatibilityLevelLabel on CompatibilityLevel {
  String label(AppLocalizations l10n) => switch (this) {
    CompatibilityLevel.veryCompatible => l10n.profileCompatibilityVeryHigh,
    CompatibilityLevel.compatible => l10n.profileCompatibilityHigh,
    CompatibilityLevel.average => l10n.profileCompatibilityAverage,
    CompatibilityLevel.low => l10n.profileCompatibilityLow,
  };
}

extension CompatibilityFactorKindLabel on CompatibilityFactorKind {
  String label(AppLocalizations l10n) => switch (this) {
    CompatibilityFactorKind.intentions => l10n.profileFactorIntentions,
    CompatibilityFactorKind.practice => l10n.profileFactPractice,
    CompatibilityFactorKind.age => l10n.profileFactorAge,
    CompatibilityFactorKind.distance => l10n.profileFactorDistance,
  };
}

extension CompatibilityVerdictLabel on CompatibilityVerdict {
  String label(AppLocalizations l10n) => switch (this) {
    CompatibilityVerdict.sameIntention => l10n.profileVerdictSameIntention,
    CompatibilityVerdict.differentIntention =>
      l10n.profileVerdictDifferentIntention,
    CompatibilityVerdict.sameDenomination =>
      l10n.profileVerdictSameDenomination,
    CompatibilityVerdict.similarPractice => l10n.profileVerdictSimilarPractice,
    CompatibilityVerdict.differentPractice =>
      l10n.profileVerdictDifferentPractice,
    CompatibilityVerdict.veryCloseAge => l10n.profileVerdictVeryCloseAge,
    CompatibilityVerdict.closeAge => l10n.profileVerdictCloseAge,
    CompatibilityVerdict.moderateAgeGap => l10n.profileVerdictModerateAgeGap,
    CompatibilityVerdict.largeAgeGap => l10n.profileVerdictLargeAgeGap,
    CompatibilityVerdict.veryNear => l10n.profileVerdictVeryNear,
    CompatibilityVerdict.near => l10n.profileVerdictNear,
    CompatibilityVerdict.moderateDistance =>
      l10n.profileVerdictModerateDistance,
    CompatibilityVerdict.far => l10n.profileVerdictFar,
  };
}
