import 'package:kosher_dart/kosher_dart.dart';

/// From this hour, the candles of the coming night are lit: a fixed evening
/// rather than the sunset of a place, which the refresh does not know. In
/// December the sun sets between 16:30 and 17:00 in Paris, New York and
/// Jerusalem.
const kHanukkahEveningHour = 17;

/// How many candles burn on the hanukkiah at [now], besides the shamash: 1 to
/// 8 during Hanukkah, 0 the rest of the year.
///
/// The first candle is lit on the evening before the 25th of Kislev, so from
/// [kHanukkahEveningHour] the count is the one of the next day.
int hanukkahNight(DateTime now) {
  final evening = now.hour >= kHanukkahEveningHour;
  final day = DateTime(now.year, now.month, now.day + (evening ? 1 : 0));
  final calendar = JewishCalendar()
    ..inIsrael = false
    ..setDate(day);
  final night = calendar.getDayOfChanukah();
  return night > 0 ? night : 0;
}
