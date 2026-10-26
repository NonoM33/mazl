import 'package:kosher_dart/kosher_dart.dart';

import 'jewish_calendar_service.dart';

/// What the Shabbat display (the phone standing on a table like a tent) puts
/// in the middle of the screen at a given moment.
enum RestDisplayMoment {
  /// Shabbat or a festival is on: from candle lighting to nightfall.
  resting,

  /// A night of Hanukkah is coming (the candles of tonight).
  hanukkah,

  /// The day of candle lighting, before it: Friday, or the eve of a festival.
  eve,

  /// A day of the Omer count.
  omer,

  /// Any other day: the display waits for the next rest.
  ordinary,
}

/// One rest: Shabbat, or a festival with a ban on work (Rosh Hashana, Yom
/// Kippur, Sukkot, Shemini Atzeret, Simchat Torah, Pesach, Shavuot), together
/// with the Shabbat or festival days that touch it. Everything comes from
/// kosher_dart; nothing is written by hand.
class RestPeriod {
  const RestPeriod({
    required this.entry,
    required this.exit,
    required this.timesKnown,
    this.holiday,
    this.parsha,
  });

  /// Candle lighting of the evening before the first day of the rest.
  final DateTime entry;

  /// Nightfall at the end of the last day of the rest.
  final DateTime exit;

  /// False where the sun does not set (the instants are then only a day's
  /// bounds): the screen writes no hour.
  final bool timesKnown;

  /// The festival of the day being shown, null for a Shabbat.
  final JewishHolidayId? holiday;

  /// The parasha of a Shabbat, null on a festival or when none is read.
  final Parsha? parsha;

  bool get isShabbat => holiday == null;
}

/// The content chosen for a moment: the main thing to show, and the rest
/// (the current one or the next one) whose times are always written.
class RestDisplayContent {
  const RestDisplayContent({
    required this.moment,
    required this.rest,
    this.hanukkahNight,
    this.omerDay,
  });

  final RestDisplayMoment moment;
  final RestPeriod rest;

  /// 1 to 8, only for [RestDisplayMoment.hanukkah]: the night whose candles
  /// are lit tonight.
  final int? hanukkahNight;

  /// 1 to 49, only for [RestDisplayMoment.omer].
  final int? omerDay;
}

/// Chooses the content of the display from the date and the place.
///
/// The clock is a parameter: the screen passes the phone's, tests their own.
class RestDisplayResolver {
  RestDisplayResolver({JewishCalendarService? calendar})
    : _service = calendar ?? JewishCalendarService();

  final JewishCalendarService _service;

  /// How far back (the rest in progress started up to three days ago) and
  /// ahead (a rest is never further than a few weeks) the calendar is read.
  static const _daysBack = 3;
  static const _daysAhead = 45;

  /// The festivals with a ban on work, by kosher_dart's Yom Tov index.
  static final Map<int, JewishHolidayId> _festivals = {
    JewishCalendar.ROSH_HASHANA: JewishHolidayId.roshHashana,
    JewishCalendar.YOM_KIPPUR: JewishHolidayId.yomKippur,
    JewishCalendar.SUCCOS: JewishHolidayId.sukkot,
    JewishCalendar.SHEMINI_ATZERES: JewishHolidayId.sheminiAtzeret,
    JewishCalendar.SIMCHAS_TORAH: JewishHolidayId.simchatTorah,
    JewishCalendar.PESACH: JewishHolidayId.pesach,
    JewishCalendar.SHAVUOS: JewishHolidayId.shavuot,
  };

  RestDisplayContent resolve({
    required DateTime now,
    ShabbatLocation location = ShabbatLocation.paris,
  }) {
    final instant = now.toLocal();
    final today = _day(instant);
    final rest = _currentOrNextRest(instant, today, location);
    final resting = !instant.isBefore(rest.entry);
    if (resting) {
      return RestDisplayContent(moment: RestDisplayMoment.resting, rest: rest);
    }
    final night = _hanukkahNight(today);
    if (night != null) {
      return RestDisplayContent(
        moment: RestDisplayMoment.hanukkah,
        rest: rest,
        hanukkahNight: night,
      );
    }
    if (_day(rest.entry) == today) {
      return RestDisplayContent(moment: RestDisplayMoment.eve, rest: rest);
    }
    final omer = _omerDay(instant, today, location);
    if (omer != null) {
      return RestDisplayContent(
        moment: RestDisplayMoment.omer,
        rest: rest,
        omerDay: omer,
      );
    }
    return RestDisplayContent(moment: RestDisplayMoment.ordinary, rest: rest);
  }

  /// The night of Hanukkah whose candles are lit on the evening of [today]:
  /// the day of Hanukkah of tomorrow's date, since the Hebrew day begins at
  /// sunset.
  int? _hanukkahNight(DateTime today) {
    final night = _calendar(_addDays(today, 1)).getDayOfChanukah();
    return night >= 1 && night <= 8 ? night : null;
  }

  /// The day of the Omer, counted at nightfall: before it the day that is
  /// running, after it the day that begins.
  int? _omerDay(DateTime now, DateTime today, ShabbatLocation location) {
    final nightfall = _service.zmanimFor(today, location).getTzais();
    final counting = nightfall != null && !now.isBefore(nightfall);
    final day = _calendar(counting ? _addDays(today, 1) : today).getDayOfOmer();
    return day >= 1 && day <= 49 ? day : null;
  }

  /// The first rest that is not over at [now]: the one in progress, else the
  /// next.
  RestPeriod _currentOrNextRest(
    DateTime now,
    DateTime today,
    ShabbatLocation location,
  ) {
    var run = <_RestDay>[];
    for (var offset = -_daysBack; offset <= _daysAhead; offset++) {
      final date = _addDays(today, offset);
      final day = _restDay(date);
      if (day != null) {
        run.add(day);
        continue;
      }
      if (run.isEmpty) continue;
      final period = _period(run, now, today, location);
      if (period.exit.isAfter(now)) return period;
      run = [];
    }
    // A run still open at the end of the window cannot be the nearest one:
    // the window is wider than any gap between two rests.
    throw RestNotFoundError(today);
  }

  /// The day as a rest day (Shabbat or a festival), null on a working day.
  _RestDay? _restDay(DateTime date) {
    final calendar = _calendar(date);
    if (!calendar.isAssurBemelacha()) return null;
    return _RestDay(date, _festivals[calendar.getYomTovIndex()]);
  }

  RestPeriod _period(
    List<_RestDay> run,
    DateTime now,
    DateTime today,
    ShabbatLocation location,
  ) {
    final first = run.first.date;
    final last = run.last.date;
    final entry = _candleLighting(_addDays(first, -1), location);
    final exit = _service.zmanimFor(last, location).getTzais()?.toLocal();
    final current = _currentDay(run, now, today, location);
    final shabbat = current.holiday == null;
    return RestPeriod(
      entry: entry ?? first,
      exit: exit ?? _addDays(last, 1),
      timesKnown: entry != null && exit != null,
      holiday: current.holiday,
      parsha: shabbat && current.date.weekday == DateTime.saturday
          ? _service.weeklyParsha(current.date)
          : null,
    );
  }

  /// The day of the run that is being lived or, before it begins, its first.
  /// The Hebrew day changes at sunset.
  _RestDay _currentDay(
    List<_RestDay> run,
    DateTime now,
    DateTime today,
    ShabbatLocation location,
  ) {
    final sunset = _service.zmanimFor(today, location).getSunset();
    final hebrewDay = sunset != null && !now.isBefore(sunset)
        ? _addDays(today, 1)
        : today;
    return run.firstWhere(
      (day) => !day.date.isBefore(hebrewDay),
      orElse: () => run.last,
    );
  }

  /// Candle lighting on the evening of [eve]: 18 minutes before sunset. Worked
  /// out here rather than by kosher_dart's own candle lighting, which answers
  /// nothing on some eves of festivals.
  DateTime? _candleLighting(DateTime eve, ShabbatLocation location) {
    final zmanim = _service.zmanimFor(eve, location);
    final sunset = zmanim.getSeaLevelSunset();
    if (sunset == null) return null;
    return sunset
        .subtract(Duration(minutes: zmanim.getCandleLightingOffset().round()))
        .toLocal();
  }

  JewishCalendar _calendar(DateTime date) =>
      JewishCalendar.fromDateTime(date)..inIsrael = false;

  static DateTime _day(DateTime moment) =>
      DateTime(moment.year, moment.month, moment.day);

  static DateTime _addDays(DateTime date, int days) =>
      DateTime(date.year, date.month, date.day + days);
}

class _RestDay {
  const _RestDay(this.date, this.holiday);

  final DateTime date;
  final JewishHolidayId? holiday;
}

/// The calendar window held no rest: the window is wider than any gap between
/// two rests, so this only says the calendar library broke its promise.
class RestNotFoundError extends Error {
  RestNotFoundError(this.today);

  final DateTime today;

  @override
  String toString() => '$runtimeType($today)';
}
