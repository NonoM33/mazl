import 'dart:ui';

import 'app_language.dart';

/// Les anciens Android annoncent encore l'hébreu sous son code retiré « iw ».
const _legacyCodes = {'iw': 'he'};

/// La langue de l'interface : celle choisie dans les réglages, sinon la
/// première langue du téléphone que l'app connaît, sinon l'anglais.
Locale resolveAppLocale(List<Locale>? deviceLocales, {AppLanguage? chosen}) {
  if (chosen != null) return chosen.locale;
  for (final locale in deviceLocales ?? const <Locale>[]) {
    final code = _legacyCodes[locale.languageCode] ?? locale.languageCode;
    final language = AppLanguage.fromCode(code);
    if (language != null) return language.locale;
  }
  return fallbackLanguage.locale;
}
