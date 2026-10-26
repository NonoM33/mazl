import 'package:flutter_test/flutter_test.dart';
import 'package:kosher_dart/kosher_dart.dart' show Parsha;
import 'package:mazl/core/services/jewish_calendar_service.dart';
import 'package:mazl/core/services/rest_display_content.dart';

// Les dates et les horaires viennent du calendrier publié par Hebcal pour
// Paris (diaspora), pas du code testé : allumage 18 minutes avant le coucher
// du soleil, havdala quand le soleil est à 8,5 degrés sous l'horizon.
//
//   Shabbat Chémot   : vendredi 9 janvier 2026, allumage 15:55 UTC ;
//                     havdala samedi 10 janvier 17:07 UTC
//   Roch Hachana    : du vendredi 11 septembre (soir) au dimanche 13 septembre
//   Kippour         : dimanche 20 septembre (soir) au lundi 21 septembre
//   Souccot         : du vendredi 25 septembre (soir) au dimanche 27 septembre
//   Chémini Atséret : samedi 3 octobre ; Sim'hat Torah : dimanche 4 octobre
//   Hanoucca        : 1er soir le vendredi 4 décembre 2026, 8e soir le
//                     vendredi 11 décembre
//   Pessah          : du mercredi 1er avril (soir) au samedi 4 avril 2026
//                     (les 2 premiers jours, puis Shabbat de Hol Hamoed)
//   Omer            : jour 1 le vendredi 3 avril ; jour 49 le jeudi 21 mai
//   Chavouot        : vendredi 22 et samedi 23 mai 2026

// Le téléphone est à l'heure du lieu du membre (Paris ici), comme celui d'un
// membre qui est chez lui : les jours se comptent sur son horloge.
final _resolver = RestDisplayResolver();

RestDisplayContent _at(DateTime now) => _resolver.resolve(now: now);

/// Le même instant, à une minute près, qu'une heure UTC publiée.
Matcher _closeTo(DateTime utc) => predicate<DateTime>(
  (actual) => actual.difference(utc).inMinutes.abs() <= 2,
  'à moins de 2 minutes de ${utc.toIso8601String()}',
);

void main() {
  group('un jour ordinaire attend le prochain Shabbat', () {
    test('un mercredi : horaires et parasha du Shabbat à venir', () {
      final content = _at(DateTime(2026, 1, 7, 12));

      expect(content.moment, RestDisplayMoment.ordinary);
      expect(content.rest.isShabbat, isTrue);
      expect(
        content.rest.entry.toUtc(),
        _closeTo(DateTime.utc(2026, 1, 9, 15, 55)),
      );
      expect(
        content.rest.exit.toUtc(),
        _closeTo(DateTime.utc(2026, 1, 10, 17, 7)),
      );
      expect(content.rest.parsha, Parsha.SHEMOS);
      expect(content.hanukkahNight, isNull);
      expect(content.omerDay, isNull);
    });

    test('le samedi soir, après la havdala : le Shabbat suivant', () {
      final content = _at(DateTime.utc(2026, 1, 10, 18));

      expect(content.moment, RestDisplayMoment.ordinary);
      expect(content.rest.entry.toUtc().day, 16);
      expect(content.rest.parsha, Parsha.VAERA);
    });
  });

  group('le vendredi, avant l\'allumage', () {
    test('le matin : la veille de Shabbat, les horaires du soir', () {
      final content = _at(DateTime(2026, 1, 9, 9));

      expect(content.moment, RestDisplayMoment.eve);
      expect(
        content.rest.entry.toUtc(),
        _closeTo(DateTime.utc(2026, 1, 9, 15, 55)),
      );
      expect(content.rest.parsha, Parsha.SHEMOS);
    });

    test('à l\'allumage même, Shabbat commence', () {
      final content = _at(DateTime.utc(2026, 1, 9, 15, 56));

      expect(content.moment, RestDisplayMoment.resting);
    });
  });

  group('Shabbat', () {
    test('le vendredi soir : Shabbat, la havdala pour sortie', () {
      final content = _at(DateTime.utc(2026, 1, 9, 19));

      expect(content.moment, RestDisplayMoment.resting);
      expect(content.rest.isShabbat, isTrue);
      expect(
        content.rest.exit.toUtc(),
        _closeTo(DateTime.utc(2026, 1, 10, 17, 7)),
      );
      expect(content.rest.parsha, Parsha.SHEMOS);
    });

    test('le samedi à midi : encore Shabbat, même parasha', () {
      final content = _at(DateTime(2026, 1, 10, 12));

      expect(content.moment, RestDisplayMoment.resting);
      expect(content.rest.parsha, Parsha.SHEMOS);
    });

    test('un Shabbat de Hol Hamoed n\'annonce pas la parasha suivante', () {
      final content = _at(DateTime(2026, 4, 4, 12));

      expect(content.moment, RestDisplayMoment.resting);
      expect(content.rest.parsha, isNull);
    });
  });

  group('Hanoucca', () {
    test(
      'le 1er soir (vendredi 4 décembre) passe avant la veille de Shabbat',
      () {
        final content = _at(DateTime(2026, 12, 4, 12));

        expect(content.moment, RestDisplayMoment.hanukkah);
        expect(content.hanukkahNight, 1);
        // Les horaires de Shabbat restent écrits : l'allumage de Shabbat suit.
        expect(content.rest.isShabbat, isTrue);
      },
    );

    test('le lundi 7 décembre : le 4e soir', () {
      final content = _at(DateTime(2026, 12, 7, 12));

      expect(content.moment, RestDisplayMoment.hanukkah);
      expect(content.hanukkahNight, 4);
    });

    test('le 8e et dernier soir (vendredi 11 décembre)', () {
      expect(_at(DateTime(2026, 12, 11, 12)).hanukkahNight, 8);
    });

    test('le samedi soir, après la havdala : le 2e soir', () {
      final content = _at(DateTime(2026, 12, 5, 22));

      expect(content.moment, RestDisplayMoment.hanukkah);
      expect(content.hanukkahNight, 2);
    });

    test('le samedi 5 décembre dans la journée : Shabbat avant tout', () {
      final content = _at(DateTime(2026, 12, 5, 12));

      expect(content.moment, RestDisplayMoment.resting);
      expect(content.hanukkahNight, isNull);
    });

    test('la veille du 1er soir et le lendemain du 8e : plus de bougies', () {
      expect(_at(DateTime(2026, 12, 2, 12)).hanukkahNight, isNull);
      expect(_at(DateTime(2026, 12, 13, 12)).hanukkahNight, isNull);
    });
  });

  group('l\'Omer', () {
    test('dimanche 12 avril à midi : le 10e jour', () {
      final content = _at(DateTime(2026, 4, 12, 12));

      expect(content.moment, RestDisplayMoment.omer);
      expect(content.omerDay, 10);
    });

    test('après la tombée de la nuit, le jour suivant se compte', () {
      expect(_at(DateTime(2026, 4, 12, 23, 30)).omerDay, 11);
    });

    test('avant le 1er jour et après le 49e : pas de compte', () {
      expect(_at(DateTime(2026, 3, 30, 12)).omerDay, isNull);
      expect(_at(DateTime(2026, 5, 25, 12)).omerDay, isNull);
      expect(_at(DateTime(2026, 5, 25, 12)).moment, RestDisplayMoment.ordinary);
    });

    test('la veille de Chavouot, la veille de fête passe avant le compte', () {
      final content = _at(DateTime(2026, 5, 21, 10));

      expect(content.moment, RestDisplayMoment.eve);
      expect(content.rest.holiday, JewishHolidayId.shavuot);
    });
  });

  group('les fêtes', () {
    test('Roch Hachana : la veille, puis les deux jours (avec Shabbat)', () {
      final eve = _at(DateTime(2026, 9, 11, 10));
      expect(eve.moment, RestDisplayMoment.eve);
      expect(eve.rest.holiday, JewishHolidayId.roshHashana);
      expect(eve.rest.parsha, isNull);

      final first = _at(DateTime(2026, 9, 12, 12));
      expect(first.moment, RestDisplayMoment.resting);
      expect(first.rest.holiday, JewishHolidayId.roshHashana);
      expect(first.rest.parsha, isNull);

      final second = _at(DateTime(2026, 9, 13, 12));
      expect(second.rest.holiday, JewishHolidayId.roshHashana);
      // La sortie est la nuit du deuxième jour, pas celle du samedi.
      expect(second.rest.exit.toUtc().day, 13);
      expect(second.rest.entry.toUtc().day, 11);
    });

    test('Kippour : la veille au soir jusqu\'à la nuit du lendemain', () {
      final eve = _at(DateTime(2026, 9, 20, 10));
      expect(eve.moment, RestDisplayMoment.eve);
      expect(eve.rest.holiday, JewishHolidayId.yomKippur);

      final day = _at(DateTime(2026, 9, 21, 12));
      expect(day.moment, RestDisplayMoment.resting);
      expect(day.rest.holiday, JewishHolidayId.yomKippur);
      expect(day.rest.exit.toUtc().day, 21);
    });

    test('Souccot, puis Chémini Atséret et Sim\'hat Torah le jour même', () {
      expect(
        _at(DateTime(2026, 9, 26, 12)).rest.holiday,
        JewishHolidayId.sukkot,
      );
      expect(
        _at(DateTime(2026, 10, 3, 12)).rest.holiday,
        JewishHolidayId.sheminiAtzeret,
      );
      expect(
        _at(DateTime(2026, 10, 4, 12)).rest.holiday,
        JewishHolidayId.simchatTorah,
      );
    });

    test('Pessah : de l\'allumage du mercredi à la nuit du samedi', () {
      final eve = _at(DateTime(2026, 4, 1, 10));
      expect(eve.moment, RestDisplayMoment.eve);
      expect(eve.rest.holiday, JewishHolidayId.pesach);

      final day = _at(DateTime(2026, 4, 2, 12));
      expect(day.moment, RestDisplayMoment.resting);
      expect(day.rest.holiday, JewishHolidayId.pesach);
      expect(day.rest.entry.toUtc().day, 1);
      expect(day.rest.exit.toUtc().day, 4);
    });

    test('Chavouot : deux jours, sans parasha', () {
      final content = _at(DateTime(2026, 5, 23, 12));

      expect(content.moment, RestDisplayMoment.resting);
      expect(content.rest.holiday, JewishHolidayId.shavuot);
      expect(content.rest.parsha, isNull);
    });

    test('un jour de Hol Hamoed attend le 7e jour de Pessah', () {
      // Lundi 6 avril : le samedi d'avant est passé, le suivant est le mercredi.
      final content = _at(DateTime(2026, 4, 6, 12));

      expect(content.rest.holiday, JewishHolidayId.pesach);
      expect(content.rest.entry.toUtc().day, 7);
      expect(content.rest.exit.toUtc().day, 9);
    });
  });

  group('les horaires de lieux sans coucher de soleil', () {
    test('un lieu inconnu du calcul n\'écrit aucune heure', () {
      // Au nord du cercle polaire en juin, le soleil ne se couche pas.
      final content = _resolver.resolve(
        now: DateTime(2026, 6, 16, 12),
        location: const ShabbatLocation(
          name: 'Nord',
          latitude: 78.2232,
          longitude: 15.6267,
        ),
      );

      expect(content.rest.timesKnown, isFalse);
    });
  });
}
