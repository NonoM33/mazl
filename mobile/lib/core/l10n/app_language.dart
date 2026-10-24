import 'dart:ui';

/// Les langues de l'interface. Le français est la langue de référence des
/// textes ; l'anglais sert de repli quand le téléphone parle une langue que
/// l'app ne connaît pas.
enum AppLanguage {
  fr('fr', 'Français'),
  en('en', 'English'),
  he('he', 'עברית', isRightToLeft: true),
  es('es', 'Español'),
  ru('ru', 'Русский');

  const AppLanguage(this.code, this.autonym, {this.isRightToLeft = false});

  /// Code ISO 639-1, celui des fichiers `app_<code>.arb`.
  final String code;

  /// Le nom de la langue écrit dans cette langue : c'est ainsi qu'on la
  /// reconnaît dans une liste, même sans lire la langue en cours.
  final String autonym;

  final bool isRightToLeft;

  Locale get locale => Locale(code);

  static AppLanguage? fromCode(String? code) {
    for (final language in values) {
      if (language.code == code) return language;
    }
    return null;
  }
}

/// La langue d'un téléphone réglé sur une langue inconnue de l'app.
const AppLanguage fallbackLanguage = AppLanguage.en;
