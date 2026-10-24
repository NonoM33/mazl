import '../../../../core/models/couple_anniversary.dart';
import '../../../../l10n/l10n.dart';

/// The name of a couple milestone (« 1 semaine », « 3 mois », « 1 an ») in the
/// member's language, worked out from its length: a milestone is a number of
/// days, whatever the server called it.
extension CoupleMilestoneLabel on CoupleMilestone {
  String name(AppLocalizations l10n) {
    if (days <= 0) return label;
    if (days % 365 == 0) return l10n.coupleSpaceDurationYears(days ~/ 365);
    if (days % 30 == 0) return l10n.coupleSpaceDurationMonths(days ~/ 30);
    if (days % 7 == 0) return l10n.coupleSpaceDurationWeeks(days ~/ 7);
    return l10n.coupleSpaceDurationDays(days);
  }
}
