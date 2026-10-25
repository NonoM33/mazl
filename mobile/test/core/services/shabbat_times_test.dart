import 'package:flutter_test/flutter_test.dart';
import 'package:mazl/core/services/jewish_calendar_service.dart';

// Horaires de référence : Hebcal (hebcal.com), relevés le 2026-10-25 pour des
// coordonnées données, allumage 18 minutes avant le coucher du soleil
// (b=18) et havdala à la sortie des étoiles, soleil à 8,5° sous l'horizon
// (M=on). Source indépendante de kosher_dart. Les heures locales de la source
// sont ramenées ici à l'UTC pour ne dépendre ni du fuseau de la machine ni de
// l'heure d'été.
//
//   https://www.hebcal.com/hebcal?v=1&cfg=json&c=on&geo=pos&latitude=…
//   &longitude=…&tzid=…&M=on&b=18&start=2026-01-01&end=2026-12-31
//
// Exception : pour Jérusalem, ce service Hebcal applique sa propre avance
// (20 minutes) quelle que soit la valeur de b. L'allumage de Jérusalem est
// donc le coucher du soleil de son point d'accès /zmanim (latitude, longitude,
// tzid=Asia/Jerusalem) moins 18 minutes ; la havdala vient du même relevé que
// les autres.

const _tolerance = Duration(minutes: 2);

class _Reference {
  const _Reference(this.place, this.location, this.friday, this.candles, this.havdalah);

  final String place;
  final ShabbatLocation location;

  /// Le vendredi de l'allumage ; la havdala est le samedi qui suit.
  final DateTime friday;
  final DateTime candles;
  final DateTime havdalah;
}

const _paris = ShabbatLocation(name: 'Paris', latitude: 48.8566, longitude: 2.3522);
const _jerusalem = ShabbatLocation(name: 'Jérusalem', latitude: 31.7683, longitude: 35.2137);
const _newYork = ShabbatLocation(name: 'New York', latitude: 40.7128, longitude: -74.006);

final _references = [
  _Reference('Paris, hiver', _paris, DateTime(2026, 1, 9), DateTime.utc(2026, 1, 9, 15, 55), DateTime.utc(2026, 1, 10, 17, 8)),
  _Reference('Paris, équinoxe', _paris, DateTime(2026, 3, 20), DateTime.utc(2026, 3, 20, 17, 45), DateTime.utc(2026, 3, 21, 18, 52)),
  _Reference('Paris, été', _paris, DateTime(2026, 6, 19), DateTime.utc(2026, 6, 19, 19, 39), DateTime.utc(2026, 6, 20, 21, 4)),
  _Reference('Paris, fin octobre', _paris, DateTime(2026, 10, 30), DateTime.utc(2026, 10, 30, 16, 15), DateTime.utc(2026, 10, 31, 17, 21)),
  _Reference('Paris, décembre', _paris, DateTime(2026, 12, 18), DateTime.utc(2026, 12, 18, 15, 36), DateTime.utc(2026, 12, 19, 16, 50)),
  _Reference('Jérusalem, hiver', _jerusalem, DateTime(2026, 1, 9), DateTime.utc(2026, 1, 9, 14, 35), DateTime.utc(2026, 1, 10, 15, 33)),
  _Reference('Jérusalem, été', _jerusalem, DateTime(2026, 6, 19), DateTime.utc(2026, 6, 19, 16, 29), DateTime.utc(2026, 6, 20, 17, 30)),
  _Reference('Jérusalem, fin octobre', _jerusalem, DateTime(2026, 10, 30), DateTime.utc(2026, 10, 30, 14, 34), DateTime.utc(2026, 10, 31, 15, 28)),
  _Reference('New York, hiver', _newYork, DateTime(2026, 1, 9), DateTime.utc(2026, 1, 9, 21, 28), DateTime.utc(2026, 1, 10, 22, 33)),
  _Reference('New York, été', _newYork, DateTime(2026, 6, 19), DateTime.utc(2026, 6, 20, 0, 12), DateTime.utc(2026, 6, 21, 1, 21)),
];

void _expectWithin(DateTime? actual, DateTime expected, String what) {
  expect(actual, isNotNull, reason: what);
  final gap = actual!.toUtc().difference(expected).abs();
  expect(
    gap,
    lessThanOrEqualTo(_tolerance),
    reason: '$what : ${actual.toUtc().toIso8601String()} au lieu de '
        '${expected.toIso8601String()} (écart $gap)',
  );
}

void main() {
  final service = JewishCalendarService();

  group('horaires de Shabbat comparés à une source indépendante (±2 min)', () {
    for (final reference in _references) {
      test(reference.place, () {
        // Le mercredi de la semaine : le service cherche le vendredi suivant.
        final now = reference.friday.subtract(const Duration(days: 2));
        final shabbat = service.getThisWeekShabbat(
          location: reference.location,
          now: now,
        );

        expect(shabbat.date, reference.friday);
        _expectWithin(shabbat.candleLightingAt, reference.candles, 'allumage');
        _expectWithin(shabbat.havdalaAt, reference.havdalah, 'havdala');
      });
    }
  });

  test('sans lieu précisé, ce sont les horaires de Paris', () {
    final now = DateTime(2026, 1, 7);
    final byDefault = service.getThisWeekShabbat(now: now);
    final paris = service.getThisWeekShabbat(location: _paris, now: now);

    expect(byDefault.candleLightingAt, paris.candleLightingAt);
    expect(byDefault.havdalaAt, paris.havdalaAt);
  });

  test('un autre lieu donne d\'autres horaires, pas ceux de Paris', () {
    final now = DateTime(2026, 1, 7);
    final paris = service.getThisWeekShabbat(location: _paris, now: now);
    final jerusalem = service.getThisWeekShabbat(location: _jerusalem, now: now);

    // Jérusalem couche le soleil plus de 80 minutes (UTC) avant Paris en hiver.
    final earlier = paris.candleLightingAt!.difference(jerusalem.candleLightingAt!);
    expect(earlier, greaterThan(const Duration(minutes: 60)));
    expect(jerusalem.parsha, paris.parsha);
  });
}
