import '../../../../l10n/generated/app_localizations_fr.dart';
import '../../../../l10n/l10n.dart';

/// Why a member deletes the account: the choices of the first sheet.
enum DeleteAccountReason {
  foundSomeone,
  noLongerUsing,
  takingBreak,
  technicalProblems,
  serviceDoesNotFit,
  other;

  /// The choice, in the member's language.
  String label(AppLocalizations l10n) => switch (this) {
    foundSomeone => l10n.settingsDeleteReasonFoundSomeone,
    noLongerUsing => l10n.settingsDeleteReasonNoLongerUsing,
    takingBreak => l10n.settingsDeleteReasonBreak,
    technicalProblems => l10n.settingsDeleteReasonTechnical,
    serviceDoesNotFit => l10n.settingsDeleteReasonService,
    other => l10n.settingsDeleteReasonOther,
  };

  /// What the server stores: the French sentence it has always received,
  /// whatever the language of the screen, so its statistics stay comparable.
  String get apiValue => label(AppLocalizationsFr());
}
