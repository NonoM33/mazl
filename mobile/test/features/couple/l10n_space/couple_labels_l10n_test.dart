import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:kosher_dart/kosher_dart.dart';
import 'package:mazl/core/services/couple_api_service.dart';
import 'package:mazl/core/services/couple_messages.dart';
import 'package:mazl/core/services/jewish_calendar_service.dart';
import 'package:mazl/l10n/l10n.dart';
import 'package:mazl/presentation/features/couple/l10n/couple_failure_label.dart';
import 'package:mazl/presentation/features/couple/l10n/jewish_calendar_labels.dart';

AppLocalizations _in(String code) => lookupAppLocalizations(Locale(code));

const _codes = ['fr', 'en', 'he', 'es', 'ru'];

void main() {
  group('échecs du mode couple', () {
    test('le français garde les phrases d\'avant', () {
      final fr = _in('fr');
      expect(
        CoupleActionFailure.notMatched.label(fr),
        "Le mode couple ne s'active qu'avec un match.",
      );
      expect(
        CoupleActionFailure.alreadyInCouple.label(fr),
        "L'un de vous est déjà en mode couple.",
      );
      expect(
        CoupleActionFailure.requestPending.label(fr),
        'Une demande est déjà en attente avec cette personne.',
      );
      expect(
        CoupleActionFailure.requestNoLongerPending.label(fr),
        "Cette demande n'est plus en attente.",
      );
      expect(
        CoupleActionFailure.unavailable.label(fr),
        "Cette personne n'est pas disponible.",
      );
      expect(
        CoupleActionFailure.self.label(fr),
        'Vous ne pouvez pas vous envoyer une demande.',
      );
      expect(
        CoupleActionFailure.cannotLeave.label(fr),
        'Impossible de quitter le mode couple pour le moment.',
      );
      expect(
        CoupleActionFailure.unknown.label(fr),
        'Une erreur est survenue, réessayez dans un instant.',
      );
    });

    test('chaque cause a une phrase dans chaque langue', () {
      for (final code in _codes) {
        final l10n = _in(code);
        for (final failure in CoupleActionFailure.values) {
          expect(
            failure.label(l10n).trim(),
            isNotEmpty,
            reason: '$code ${failure.name}',
          );
        }
        for (final kind in CoupleFailureKind.values) {
          final failure = CoupleFailure(kind, 'diagnostic in English');
          final text = failure.label(l10n);
          expect(text.trim(), isNotEmpty, reason: '$code ${kind.name}');
          expect(
            text,
            isNot(contains('diagnostic')),
            reason: 'le diagnostic ne s\'affiche jamais',
          );
        }
      }
    });

    test('le français des échecs de contenu', () {
      final fr = _in('fr');
      expect(
        const CoupleFailure(CoupleFailureKind.full, 'x').label(fr),
        'Cet événement est complet.',
      );
      expect(
        const CoupleFailure(CoupleFailureKind.notInCouple, 'x').label(fr),
        "Le mode couple n'est pas actif.",
      );
      expect(
        const CoupleFailure(CoupleFailureKind.malformed, 'x').label(fr),
        'Réponse inattendue du serveur.',
      );
    });
  });

  group('calendrier juif', () {
    test('les noms de fêtes du français sont ceux d\'avant', () {
      final fr = _in('fr');
      const before = {
        JewishHolidayId.roshHashana: ('Rosh Hashana', 'Nouvel an juif'),
        JewishHolidayId.yomKippur: ('Yom Kippour', 'Jour du Grand Pardon'),
        JewishHolidayId.sukkot: ('Souccot', 'Fête des cabanes'),
        JewishHolidayId.sheminiAtzeret: (
          'Shemini Atseret',
          'Huitième jour de rassemblement',
        ),
        JewishHolidayId.simchatTorah: ('Simhat Torah', 'Joie de la Torah'),
        JewishHolidayId.hanukkah: ('Hanoucca', 'Fête des lumières'),
        JewishHolidayId.tuBishvat: ('Tou Bichvat', 'Nouvel an des arbres'),
        JewishHolidayId.purim: ('Pourim', 'Fête des sorts'),
        JewishHolidayId.pesach: ('Pessah', 'Fête de la liberté'),
        JewishHolidayId.yomHashoah: (
          'Yom HaShoah',
          'Jour du souvenir de la Shoah',
        ),
        JewishHolidayId.yomHazikaron: (
          'Yom HaZikaron',
          'Jour du souvenir des soldats',
        ),
        JewishHolidayId.yomHaatzmaut: (
          'Yom HaAtsmaout',
          "Jour de l'indépendance d'Israël",
        ),
        JewishHolidayId.yomYerushalayim: (
          'Yom Yeroushalayim',
          'Jour de la réunification de Jérusalem',
        ),
        JewishHolidayId.lagBaomer: ('Lag BaOmer', '33eme jour du Omer'),
        JewishHolidayId.shavuot: ('Shavouot', 'Don de la Torah'),
      };
      expect(before.keys.toSet(), JewishHolidayId.values.toSet());
      for (final entry in before.entries) {
        expect(entry.key.title(fr), entry.value.$1);
        expect(entry.key.description(fr), entry.value.$2);
      }
    });

    test('en hébreu, le nom usuel de la fête est son nom hébreu', () {
      final he = _in('he');
      for (final id in JewishHolidayId.values) {
        expect(id.title(he), id.hebrewName, reason: id.name);
      }
    });

    test('chaque fête, idée et activité a un texte dans chaque langue', () {
      for (final code in _codes) {
        final l10n = _in(code);
        for (final id in JewishHolidayId.values) {
          expect(id.title(l10n).trim(), isNotEmpty, reason: '$code ${id.name}');
          expect(
            id.description(l10n).trim(),
            isNotEmpty,
            reason: '$code ${id.name}',
          );
        }
        for (final idea in HolidayIdea.values) {
          expect(
            idea.label(l10n).trim(),
            isNotEmpty,
            reason: '$code ${idea.name}',
          );
        }
        for (final activity in OccasionActivityId.values) {
          expect(
            activity.title(l10n).trim(),
            isNotEmpty,
            reason: '$code ${activity.name}',
          );
          expect(
            activity.body(l10n).trim(),
            isNotEmpty,
            reason: '$code ${activity.name}',
          );
        }
        for (final category in OccasionActivityCategory.values) {
          expect(
            category.label(l10n).trim(),
            isNotEmpty,
            reason: '$code ${category.name}',
          );
        }
      }
    });

    test('toutes les fêtes du service sont nommées et ont leurs idées', () {
      final holidays = JewishCalendarService().getUpcomingHolidays();
      expect(holidays, isNotEmpty);
      for (final holiday in holidays) {
        expect(holiday.id.title(_in('en')).trim(), isNotEmpty);
        expect(holiday.hebrewName, isNotEmpty);
      }
    });

    final regular = Parsha.values.where(
      (p) =>
          p != Parsha.NONE &&
          p != Parsha.SHKALIM &&
          p != Parsha.ZACHOR &&
          p != Parsha.PARA &&
          p != Parsha.HACHODESH,
    );

    test('le français écrit chaque paracha comme kosher_dart l\'écrivait', () {
      final formatter = HebrewDateFormatter()..hebrewFormat = false;
      for (final parsha in regular) {
        expect(
          parsha.title(_in('fr')),
          formatter.transliteratedParshaMap[parsha],
          reason: parsha.name,
        );
      }
    });

    test(
      'l\'hébreu écrit chaque paracha comme la table hébraïque de kosher_dart',
      () {
        final formatter = HebrewDateFormatter()..hebrewFormat = true;
        for (final parsha in regular) {
          // kosher_dart écrit quelques noms en orthographe défective ; l'app
          // suit l'usage courant (par exemple « מצורע », pas « מצרע »).
          var expected = formatter.hebrewParshaMap[parsha]!;
          for (final spelling in const {
            'מצרע': 'מצורע',
            'בחקתי': 'בחוקותי',
            'בהעלתך': 'בהעלותך',
            'שלח לך': 'שלח',
            'ניצבים': 'נצבים',
          }.entries) {
            expected = expected.replaceAll(spelling.key, spelling.value);
          }
          final actual = parsha.title(_in('he'));
          // Deux parashot lues ensemble : kosher_dart les sépare d'une espace,
          // l'app d'un trait d'union (maqaf).
          expect(actual.replaceAll('־', ' '), expected, reason: parsha.name);
        }
      },
    );

    test('chaque paracha a un nom dans chaque langue', () {
      for (final code in _codes) {
        for (final parsha in regular) {
          expect(
            parsha.title(_in(code)).trim(),
            isNotEmpty,
            reason: '$code ${parsha.name}',
          );
        }
      }
      expect(Parsha.NONE.title(_in('en')), isEmpty);
    });

    test('deux parashot lues ensemble s\'écrivent de leurs deux noms', () {
      expect(Parsha.VAYAKHEL_PEKUDEI.title(_in('fr')), 'Vayakhel Pekudei');
      expect(Parsha.VAYAKHEL_PEKUDEI.title(_in('en')), 'Vayakhel – Pekudei');
      expect(Parsha.VAYAKHEL_PEKUDEI.title(_in('he')), 'ויקהל־פקודי');
    });

    test('l\'activité de Shabbat du français est celle d\'avant', () {
      final fr = _in('fr');
      expect(
        OccasionActivityId.shabbatDinner.title(fr),
        'Préparer le dîner ensemble',
      );
      expect(
        OccasionActivityId.shabbatDinner.body(fr),
        'Cuisinez la Halla et le repas de fête',
      );
      expect(
        OccasionActivityId.pesachCleaning.title(fr),
        'Faire le ménage de Pessah',
      );
      expect(OccasionActivityCategory.relaxation.label(fr), 'Détente');
    });

    test('les heures de Shabbat restent lisibles par les réglages (HH:mm)', () {
      final shabbat = JewishCalendarService().getThisWeekShabbat();
      final clock = RegExp(r'^(\d{2}:\d{2}|--:--)$');
      expect(shabbat.candleLighting, matches(clock));
      expect(shabbat.havdala, matches(clock));
      expect(shabbat.parsha, isNot(Parsha.NONE));
    });
  });
}
