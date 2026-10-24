import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/core/l10n/app_language.dart';
import 'package:mazl/core/l10n/locale_resolution.dart';

void main() {
  group('la langue suit le téléphone', () {
    test('un téléphone en français reste en français', () {
      expect(resolveAppLocale(const [Locale('fr', 'FR')]), const Locale('fr'));
    });

    test('un téléphone en hébreu passe en hébreu', () {
      expect(resolveAppLocale(const [Locale('he', 'IL')]), const Locale('he'));
    });

    test(
      '« iw », l\'ancien code Android de l\'hébreu, donne aussi l\'hébreu',
      () {
        expect(
          resolveAppLocale(const [Locale('iw', 'IL')]),
          const Locale('he'),
        );
      },
    );

    test(
      'la première langue prise en charge dans l\'ordre du téléphone gagne',
      () {
        expect(
          resolveAppLocale(const [Locale('de'), Locale('he'), Locale('fr')]),
          const Locale('he'),
        );
      },
    );

    test(
      'une langue non prise en charge se replie sur l\'anglais, pas le français',
      () {
        expect(
          resolveAppLocale(const [Locale('de', 'DE')]),
          const Locale('en'),
        );
      },
    );

    test('sans langue connue, l\'anglais', () {
      expect(resolveAppLocale(null), const Locale('en'));
      expect(resolveAppLocale(const []), const Locale('en'));
    });
  });

  group('le choix des réglages passe avant le téléphone', () {
    test('choisir l\'hébreu sur un téléphone en français', () {
      expect(
        resolveAppLocale(const [Locale('fr')], chosen: AppLanguage.he),
        const Locale('he'),
      );
    });
  });

  group('AppLanguage', () {
    test('chaque langue s\'écrit dans sa propre langue', () {
      expect(AppLanguage.fr.autonym, 'Français');
      expect(AppLanguage.en.autonym, 'English');
      expect(AppLanguage.he.autonym, 'עברית');
      expect(AppLanguage.es.autonym, 'Español');
      expect(AppLanguage.ru.autonym, 'Русский');
    });

    test('se retrouve depuis son code, inconnu donne null', () {
      expect(AppLanguage.fromCode('he'), AppLanguage.he);
      expect(AppLanguage.fromCode('xx'), isNull);
      expect(AppLanguage.fromCode(null), isNull);
    });

    test('l\'hébreu s\'écrit de droite à gauche, les autres non', () {
      expect(AppLanguage.he.isRightToLeft, isTrue);
      expect(AppLanguage.fr.isRightToLeft, isFalse);
      expect(AppLanguage.en.isRightToLeft, isFalse);
      expect(AppLanguage.es.isRightToLeft, isFalse);
      expect(AppLanguage.ru.isRightToLeft, isFalse);
    });
  });
}
