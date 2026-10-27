import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mazl/l10n/l10n.dart';
import 'package:mazl/presentation/features/boost/logic/boost_moment.dart';

// The rule of « après Shabbat » (docs/premium/MONETISATION.md §8) is stated on
// the member's LOCAL time: a Saturday, from 20:00. The server sends UTC.

DateTime _utcOfLocal(int day, int hour, [int minute = 0]) =>
    DateTime(2026, 10, day, hour, minute).toUtc();

void main() {
  // 2026-10-31 is a Saturday.
  group('isAfterShabbat', () {
    test('Saturday 21:00 local is after Shabbat', () {
      expect(isAfterShabbat(_utcOfLocal(31, 21)), isTrue);
    });
    test('Saturday 20:00 local is the first hour after Shabbat', () {
      expect(isAfterShabbat(_utcOfLocal(31, 20)), isTrue);
    });
    test('Saturday 19:59 local is still Shabbat day', () {
      expect(isAfterShabbat(_utcOfLocal(31, 19, 59)), isFalse);
    });
    test('Friday 21:00 and Sunday 21:00 are not', () {
      expect(isAfterShabbat(_utcOfLocal(30, 21)), isFalse);
      expect(isAfterShabbat(DateTime(2026, 11, 1, 21).toUtc()), isFalse);
    });
    test('the day is read in local time, not in UTC', () {
      // Whatever the machine zone, the local Saturday 23:30 is after Shabbat
      // even when its UTC date is already (or still) another day.
      expect(isAfterShabbat(_utcOfLocal(31, 23, 30)), isTrue);
      expect(isAfterShabbat(_utcOfLocal(31, 0, 30)), isFalse);
    });
  });

  group('boostMomentText', () {
    setUpAll(initializeDateFormatting);

    String text(String locale, DateTime utc) =>
        boostMomentText(lookupAppLocalizations(Locale(locale)), utc);

    test('French: « samedi 21 h »', () {
      expect(text('fr', _utcOfLocal(31, 21)), 'samedi 21 h');
    });
    test(
      'English: « Saturday at 9 PM » (CLDR puts a narrow no-break space before PM)',
      () {
        expect(text('en', _utcOfLocal(31, 21)), 'Saturday at 9\u202fPM');
      },
    );
    test('a time that is not on the hour keeps its minutes', () {
      expect(text('fr', _utcOfLocal(31, 21, 30)), 'samedi 21:30');
    });
    test('Spanish, Russian and Hebrew write a 24-hour clock', () {
      expect(text('es', _utcOfLocal(31, 21)), 'sábado a las 21:00');
      expect(text('ru', _utcOfLocal(31, 21)), 'суббота в 21:00');
      expect(text('he', _utcOfLocal(31, 21)), contains('21:00'));
    });
  });
}
