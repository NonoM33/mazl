import '../../../../core/premium/premium_settings_api.dart';
import '../../../../l10n/l10n.dart';

/// The sentence for a failed mazl+ settings call, in the member's language.
/// The server's own text is never shown. [PremiumSettingsErrorKind.plusRequired]
/// is not a failure to word: the screen opens the mazl+ offer instead.
String premiumErrorText(AppLocalizations l10n, PremiumSettingsErrorKind kind) =>
    switch (kind) {
      PremiumSettingsErrorKind.timeout => l10n.errorTimeout,
      PremiumSettingsErrorKind.network => l10n.errorNetwork,
      PremiumSettingsErrorKind.server => l10n.errorServer,
      PremiumSettingsErrorKind.sessionExpired => l10n.errorSessionExpired,
      PremiumSettingsErrorKind.invalidRequest => l10n.errorInvalid,
      PremiumSettingsErrorKind.plusRequired ||
      PremiumSettingsErrorKind.unknown => l10n.errorUnknown,
    };
