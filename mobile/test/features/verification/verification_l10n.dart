import 'dart:ui';

import 'package:intl/date_symbol_data_local.dart';
import 'package:mazl/l10n/l10n.dart';

/// The strings of [code] (`fr`, `en`...) outside any widget, for unit tests of
/// the functions that take an [AppLocalizations].
AppLocalizations l10nFor(String code) => lookupAppLocalizations(Locale(code));

/// The reference language, the one the screen tests run in.
AppLocalizations get frenchL10n => l10nFor('fr');

/// Loads the date patterns of every language: a widget test gets them from the
/// Material delegate, a plain unit test has to ask.
Future<void> loadDatePatterns() => initializeDateFormatting();
