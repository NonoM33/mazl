import 'package:intl/intl.dart';
import 'package:kosher_dart/kosher_dart.dart';

/// Service for Jewish calendar data.
///
/// All values are computed dynamically from [kosher_dart] for the current
/// (or any) date. Nothing is hardcoded to a specific Gregorian year: holidays,
/// the weekly parasha and the Friday candle-lighting / Havdala times are all
/// derived from the Hebrew calendar and astronomical calculations.
class JewishCalendarService {
  static final JewishCalendarService _instance =
      JewishCalendarService._internal();
  factory JewishCalendarService() => _instance;
  JewishCalendarService._internal();

  /// Default location used for astronomical calculations (candle lighting,
  /// Havdala). Defaults to Paris, the primary audience of the app. Times are
  /// therefore real, longitude/latitude-derived values rather than per-month
  /// constants. Diaspora rules (`inIsrael = false`) apply.
  static const String _locationName = 'Paris';
  static const double _latitude = 48.8566;
  static const double _longitude = 2.3522;
  static const double _elevation = 35;

  /// How far ahead (in days) we scan the Hebrew calendar for upcoming holidays.
  /// A little over one year guarantees at least one full cycle of every
  /// annual holiday whatever the current date.
  static const int _lookaheadDays = 400;

  final DateFormat _timeFormatter = DateFormat('HH:mm');

  /// Get upcoming Jewish holidays, computed dynamically from today.
  ///
  /// Scans the Hebrew calendar day by day and collapses multi-day festivals
  /// (Pessah, Souccot, Hanoucca...) into a single entry with an [endDate].
  List<JewishHoliday> getUpcomingHolidays() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final calendar = JewishCalendar()..inIsrael = false;
    calendar.setUseModernHolidays(true);

    final Map<int, JewishHoliday> byHoliday = {};

    for (var offset = 0; offset < _lookaheadDays; offset++) {
      final date = today.add(Duration(days: offset));
      calendar.setDate(date);

      final index = calendar.getYomTovIndex();
      final meta = _holidayMeta[index];
      if (meta == null) {
        continue;
      }

      final existing = byHoliday[meta.groupKey];
      if (existing == null) {
        byHoliday[meta.groupKey] = JewishHoliday(
          id: meta.id,
          date: date,
          type: meta.type,
          ideas: meta.ideas,
        );
      } else if (_isContiguous(existing, date)) {
        // Extend the running festival with each additional consecutive day.
        byHoliday[meta.groupKey] = JewishHoliday(
          id: existing.id,
          date: existing.date,
          endDate: date,
          type: existing.type,
          ideas: existing.ideas,
        );
      }
    }

    final holidays = byHoliday.values.toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    return holidays.take(5).toList();
  }

  /// Whether [date] continues the festival already recorded in [existing]
  /// (same run, one day after the last recorded day).
  bool _isContiguous(JewishHoliday existing, DateTime date) {
    final lastDay = existing.endDate ?? existing.date;
    return date.difference(lastDay).inDays == 1;
  }

  /// Get this week's Shabbat info, with a real parasha and astronomically
  /// computed candle-lighting / Havdala times for [_locationName].
  ShabbatInfo getThisWeekShabbat() {
    final now = DateTime.now();
    // Find the coming Friday (or today if today is Friday).
    var friday = DateTime(now.year, now.month, now.day);
    while (friday.weekday != DateTime.friday) {
      friday = friday.add(const Duration(days: 1));
    }
    final saturday = friday.add(const Duration(days: 1));

    final candleLightingAt = _zmanimFor(friday).getCandleLighting()?.toLocal();
    final havdalaAt = _zmanimFor(saturday).getTzais()?.toLocal();
    return ShabbatInfo(
      parsha: _getParsha(saturday),
      candleLighting: _clock(candleLightingAt),
      havdala: _clock(havdalaAt),
      candleLightingAt: candleLightingAt,
      havdalaAt: havdalaAt,
      date: friday,
    );
  }

  /// Couple activities for an occasion. Their wording belongs to the
  /// presentation layer, which names each one from its [OccasionActivityId].
  List<OccasionActivity> getActivitiesForOccasion(JewishOccasion occasion) {
    switch (occasion) {
      case JewishOccasion.shabbat:
        return const [
          OccasionActivity(
            id: OccasionActivityId.shabbatDinner,
            icon: 'utensils',
            category: OccasionActivityCategory.preparation,
          ),
          OccasionActivity(
            id: OccasionActivityId.shabbatCandles,
            icon: 'flame',
            category: OccasionActivityCategory.spiritual,
          ),
          OccasionActivity(
            id: OccasionActivityId.shabbatWalk,
            icon: 'footprints',
            category: OccasionActivityCategory.relaxation,
          ),
          OccasionActivity(
            id: OccasionActivityId.shabbatParasha,
            icon: 'book',
            category: OccasionActivityCategory.spiritual,
          ),
        ];
      case JewishOccasion.pesach:
        return const [
          OccasionActivity(
            id: OccasionActivityId.pesachSeder,
            icon: 'table',
            category: OccasionActivityCategory.preparation,
          ),
          OccasionActivity(
            id: OccasionActivityId.pesachCleaning,
            icon: 'sparkles',
            category: OccasionActivityCategory.preparation,
          ),
        ];
    }
  }

  /// The parasha of the week of [saturday], via kosher_dart.
  ///
  /// On weeks with no regular parasha (a festival falls on Shabbat)
  /// kosher_dart answers [Parsha.NONE]; we then look one week ahead so the UI
  /// always has a portion to display.
  Parsha _getParsha(DateTime saturday) {
    final calendar = JewishCalendar.fromDateTime(saturday)..inIsrael = false;
    var parsha = calendar.getParshah();
    if (parsha == Parsha.NONE) {
      final next = JewishCalendar.fromDateTime(
        saturday.add(const Duration(days: 7)),
      )..inIsrael = false;
      parsha = next.getParshah();
    }
    return parsha;
  }

  /// `HH:mm` (24 h) of [moment], or `--:--` when the sun does not set.
  String _clock(DateTime? moment) =>
      moment == null ? '--:--' : _timeFormatter.format(moment);

  /// Build a zmanim calendar anchored on [date] at the configured location.
  ComplexZmanimCalendar _zmanimFor(DateTime date) {
    final location = GeoLocation.setLocation(
      _locationName,
      _latitude,
      _longitude,
      date,
    )..setElevation(_elevation);
    return ComplexZmanimCalendar.intGeoLocation(location)..setCalendar(date);
  }

  /// Curated metadata keyed by kosher_dart's Yom Tov index.
  ///
  /// kosher_dart computes *which* holiday any date is; this map only says which
  /// holiday it is for the app and which couple ideas go with it. The words
  /// (names, descriptions, ideas) are written by the presentation layer, per
  /// language. [groupKey] lets the multi-day festivals whose consecutive days
  /// share different indices (e.g. Succos -> Chol Hamoed -> Shemini Atzeres)
  /// collapse into one entry.
  static final Map<int, _HolidayMeta> _holidayMeta = {
    JewishCalendar.ROSH_HASHANA: const _HolidayMeta(
      groupKey: JewishCalendar.ROSH_HASHANA,
      id: JewishHolidayId.roshHashana,
      type: HolidayType.major,
      ideas: [HolidayIdea.festiveDinner, HolidayIdea.tashlich],
    ),
    JewishCalendar.YOM_KIPPUR: const _HolidayMeta(
      groupKey: JewishCalendar.YOM_KIPPUR,
      id: JewishHolidayId.yomKippur,
      type: HolidayType.major,
      ideas: [HolidayIdea.mutualForgiveness],
    ),
    JewishCalendar.SUCCOS: const _HolidayMeta(
      groupKey: JewishCalendar.SUCCOS,
      id: JewishHolidayId.sukkot,
      type: HolidayType.major,
      ideas: [HolidayIdea.buildSukkah, HolidayIdea.inviteFriends],
    ),
    JewishCalendar.CHOL_HAMOED_SUCCOS: const _HolidayMeta(
      groupKey: JewishCalendar.SUCCOS,
      id: JewishHolidayId.sukkot,
      type: HolidayType.major,
      ideas: [HolidayIdea.buildSukkah, HolidayIdea.inviteFriends],
    ),
    JewishCalendar.HOSHANA_RABBA: const _HolidayMeta(
      groupKey: JewishCalendar.SUCCOS,
      id: JewishHolidayId.sukkot,
      type: HolidayType.major,
      ideas: [HolidayIdea.buildSukkah, HolidayIdea.inviteFriends],
    ),
    JewishCalendar.SHEMINI_ATZERES: const _HolidayMeta(
      groupKey: JewishCalendar.SHEMINI_ATZERES,
      id: JewishHolidayId.sheminiAtzeret,
      type: HolidayType.major,
      ideas: [HolidayIdea.prayerForRain],
    ),
    JewishCalendar.SIMCHAS_TORAH: const _HolidayMeta(
      groupKey: JewishCalendar.SIMCHAS_TORAH,
      id: JewishHolidayId.simchatTorah,
      type: HolidayType.major,
      ideas: [HolidayIdea.danceWithTorah],
    ),
    JewishCalendar.CHANUKAH: const _HolidayMeta(
      groupKey: JewishCalendar.CHANUKAH,
      id: JewishHolidayId.hanukkah,
      type: HolidayType.major,
      ideas: [HolidayIdea.lightCandlesTogether, HolidayIdea.homemadeSufganiyot],
    ),
    JewishCalendar.TU_BESHVAT: const _HolidayMeta(
      groupKey: JewishCalendar.TU_BESHVAT,
      id: JewishHolidayId.tuBishvat,
      type: HolidayType.minor,
    ),
    JewishCalendar.PURIM: const _HolidayMeta(
      groupKey: JewishCalendar.PURIM,
      id: JewishHolidayId.purim,
      type: HolidayType.major,
      ideas: [HolidayIdea.coupleCostumes, HolidayIdea.mishloachManot],
    ),
    JewishCalendar.SHUSHAN_PURIM: const _HolidayMeta(
      groupKey: JewishCalendar.PURIM,
      id: JewishHolidayId.purim,
      type: HolidayType.major,
      ideas: [HolidayIdea.coupleCostumes, HolidayIdea.mishloachManot],
    ),
    JewishCalendar.PESACH: const _HolidayMeta(
      groupKey: JewishCalendar.PESACH,
      id: JewishHolidayId.pesach,
      type: HolidayType.major,
      ideas: [HolidayIdea.romanticSeder, HolidayIdea.tripToIsrael],
    ),
    JewishCalendar.CHOL_HAMOED_PESACH: const _HolidayMeta(
      groupKey: JewishCalendar.PESACH,
      id: JewishHolidayId.pesach,
      type: HolidayType.major,
      ideas: [HolidayIdea.romanticSeder, HolidayIdea.tripToIsrael],
    ),
    JewishCalendar.YOM_HASHOAH: const _HolidayMeta(
      groupKey: JewishCalendar.YOM_HASHOAH,
      id: JewishHolidayId.yomHashoah,
      type: HolidayType.memorial,
    ),
    JewishCalendar.YOM_HAZIKARON: const _HolidayMeta(
      groupKey: JewishCalendar.YOM_HAZIKARON,
      id: JewishHolidayId.yomHazikaron,
      type: HolidayType.memorial,
    ),
    JewishCalendar.YOM_HAATZMAUT: const _HolidayMeta(
      groupKey: JewishCalendar.YOM_HAATZMAUT,
      id: JewishHolidayId.yomHaatzmaut,
      type: HolidayType.israeli,
      ideas: [HolidayIdea.israeliBarbecue, HolidayIdea.concertOrParty],
    ),
    JewishCalendar.YOM_YERUSHALAYIM: const _HolidayMeta(
      groupKey: JewishCalendar.YOM_YERUSHALAYIM,
      id: JewishHolidayId.yomYerushalayim,
      type: HolidayType.israeli,
    ),
    JewishCalendar.LAG_BAOMER: const _HolidayMeta(
      groupKey: JewishCalendar.LAG_BAOMER,
      id: JewishHolidayId.lagBaomer,
      type: HolidayType.minor,
      ideas: [HolidayIdea.campfire, HolidayIdea.picnic],
    ),
    JewishCalendar.SHAVUOS: const _HolidayMeta(
      groupKey: JewishCalendar.SHAVUOS,
      id: JewishHolidayId.shavuot,
      type: HolidayType.major,
      ideas: [HolidayIdea.homemadeCheesecake, HolidayIdea.studyNight],
    ),
  };
}

/// Presentation-free metadata attached to a computed holiday.
class _HolidayMeta {
  final int groupKey;
  final JewishHolidayId id;
  final HolidayType type;
  final List<HolidayIdea> ideas;

  const _HolidayMeta({
    required this.groupKey,
    required this.id,
    required this.type,
    this.ideas = const [],
  });
}

/// The holidays the calendar shows. The screen names each one in the member's
/// language; [hebrewName] is the Hebrew name, the same in every language.
enum JewishHolidayId {
  roshHashana('ראש השנה'),
  yomKippur('יום כיפור'),
  sukkot('סוכות'),
  sheminiAtzeret('שמיני עצרת'),
  simchatTorah('שמחת תורה'),
  hanukkah('חנוכה'),
  tuBishvat('ט״ו בשבט'),
  purim('פורים'),
  pesach('פסח'),
  yomHashoah('יום השואה'),
  yomHazikaron('יום הזיכרון'),
  yomHaatzmaut('יום העצמאות'),
  yomYerushalayim('יום ירושלים'),
  lagBaomer('ל״ג בעומר'),
  shavuot('שבועות');

  const JewishHolidayId(this.hebrewName);

  final String hebrewName;
}

/// A suggestion for a couple to share on a holiday.
enum HolidayIdea {
  festiveDinner,
  tashlich,
  mutualForgiveness,
  buildSukkah,
  inviteFriends,
  prayerForRain,
  danceWithTorah,
  lightCandlesTogether,
  homemadeSufganiyot,
  coupleCostumes,
  mishloachManot,
  romanticSeder,
  tripToIsrael,
  israeliBarbecue,
  concertOrParty,
  campfire,
  picnic,
  homemadeCheesecake,
  studyNight,
}

/// Model for a Jewish holiday
class JewishHoliday {
  final JewishHolidayId id;
  final DateTime date;
  final DateTime? endDate;
  final HolidayType type;
  final List<HolidayIdea> ideas;

  JewishHoliday({
    required this.id,
    required this.date,
    this.endDate,
    required this.type,
    this.ideas = const [],
  });

  String get hebrewName => id.hebrewName;

  int get daysUntil => date.difference(DateTime.now()).inDays;

  bool get isToday {
    final now = DateTime.now();
    return date.year == now.year &&
           date.month == now.month &&
           date.day == now.day;
  }

  bool get isOngoing {
    if (endDate == null) return isToday;
    final now = DateTime.now();
    return now.isAfter(date.subtract(const Duration(days: 1))) &&
           now.isBefore(endDate!.add(const Duration(days: 1)));
  }
}

/// Holiday type enum
enum HolidayType {
  major,
  minor,
  memorial,
  israeli,
}

extension HolidayTypeExtension on HolidayType {
  String get emoji {
    switch (this) {
      case HolidayType.major:
        return '';
      case HolidayType.minor:
        return '';
      case HolidayType.memorial:
        return '';
      case HolidayType.israeli:
        return '';
    }
  }
}

/// Model for Shabbat info
class ShabbatInfo {
  /// The parasha read this Shabbat (the next one when a festival takes the
  /// day); the screen writes its name in the member's language.
  final Parsha parsha;

  /// Candle lighting and Havdala as `HH:mm` (24 h), `--:--` when unknown.
  final String candleLighting;
  final String havdala;

  /// The same moments as dates, for screens that format them by language.
  final DateTime? candleLightingAt;
  final DateTime? havdalaAt;
  final DateTime date;

  ShabbatInfo({
    required this.parsha,
    required this.candleLighting,
    required this.havdala,
    this.candleLightingAt,
    this.havdalaAt,
    required this.date,
  });
}

/// The occasions the calendar suggests activities for.
enum JewishOccasion { shabbat, pesach }

/// One activity suggested for an occasion.
enum OccasionActivityId {
  shabbatDinner,
  shabbatCandles,
  shabbatWalk,
  shabbatParasha,
  pesachSeder,
  pesachCleaning,
}

enum OccasionActivityCategory { preparation, spiritual, relaxation }

/// Model for a couple activity suggested for an occasion.
class OccasionActivity {
  final OccasionActivityId id;
  final String icon;
  final OccasionActivityCategory category;

  const OccasionActivity({
    required this.id,
    required this.icon,
    required this.category,
  });
}
