import 'package:flutter/widgets.dart';

import 'generated/app_localizations.dart';

export 'generated/app_localizations.dart';

/// `context.l10n.chatTitle` : les textes de l'interface dans la langue en
/// cours. Les clés vivent dans `lib/l10n/fragments/<feature>/app_fr.arb`.
extension AppLocalizationsContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
