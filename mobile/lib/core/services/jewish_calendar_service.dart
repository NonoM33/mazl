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

  final HebrewDateFormatter _parashaFormatter = HebrewDateFormatter()
    ..hebrewFormat = false;
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
          name: meta.name,
          hebrewName: meta.hebrewName,
          date: date,
          description: meta.description,
          type: meta.type,
          coupleIdeas: meta.coupleIdeas,
        );
      } else if (_isContiguous(existing, date)) {
        // Extend the running festival with each additional consecutive day.
        byHoliday[meta.groupKey] = JewishHoliday(
          name: existing.name,
          hebrewName: existing.hebrewName,
          date: existing.date,
          endDate: date,
          description: existing.description,
          type: existing.type,
          coupleIdeas: existing.coupleIdeas,
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

    return ShabbatInfo(
      parasha: _getParasha(saturday),
      candleLighting: _getCandleLightingTime(friday),
      havdala: _getHavdalaTime(saturday),
      date: friday,
    );
  }

  /// Get couple activities for an occasion
  List<CoupleActivity> getActivitiesForOccasion(String occasion) {
    switch (occasion) {
      case 'shabbat':
        return [
          CoupleActivity(
            title: 'Preparer le diner ensemble',
            description: 'Cuisinez la Halla et le repas de fete',
            icon: 'utensils',
            category: 'Preparation',
          ),
          CoupleActivity(
            title: 'Allumer les bougies',
            description: 'Moment de spiritualite partage',
            icon: 'flame',
            category: 'Spirituel',
          ),
          CoupleActivity(
            title: 'Promenade Shabbat',
            description: 'Ballade tranquille apres le repas',
            icon: 'footprints',
            category: 'Detente',
          ),
          CoupleActivity(
            title: 'Etude de la Parasha',
            description: 'Apprenez ensemble la portion de la semaine',
            icon: 'book',
            category: 'Spirituel',
          ),
        ];
      case 'pessah':
        return [
          CoupleActivity(
            title: 'Preparer le Seder',
            description: 'Organisez la table ensemble',
            icon: 'table',
            category: 'Preparation',
          ),
          CoupleActivity(
            title: 'Faire le menage de Pessah',
            description: 'Nettoyage de printemps en equipe',
            icon: 'sparkles',
            category: 'Preparation',
          ),
        ];
      default:
        return [];
    }
  }

  /// Transliterated parasha of the week of [saturday], via kosher_dart.
  ///
  /// Returns e.g. "Bereshis", "Vayikra". On weeks with no regular parasha
  /// (a festival falls on Shabbat) kosher_dart returns an empty string; we
  /// then look one week ahead so the UI always has a portion to display.
  String _getParasha(DateTime saturday) {
    final calendar = JewishCalendar.fromDateTime(saturday)..inIsrael = false;
    var parasha = _parashaFormatter.formatParsha(calendar);
    if (parasha.isEmpty) {
      final next = JewishCalendar.fromDateTime(
        saturday.add(const Duration(days: 7)),
      )..inIsrael = false;
      parasha = _parashaFormatter.formatParsha(next);
    }
    return parasha;
  }

  /// Real candle-lighting time (18 min before sunset by default) for the
  /// Friday [date] at [_locationName], via kosher_dart's zmanim engine.
  String _getCandleLightingTime(DateTime date) {
    final zmanim = _zmanimFor(date);
    final candle = zmanim.getCandleLighting();
    if (candle == null) {
      return '--:--';
    }
    return _timeFormatter.format(candle.toLocal());
  }

  /// Real Havdala time (tzais / nightfall) for the Saturday [date] at
  /// [_locationName], via kosher_dart's zmanim engine.
  String _getHavdalaTime(DateTime date) {
    final zmanim = _zmanimFor(date);
    final tzais = zmanim.getTzais();
    if (tzais == null) {
      return '--:--';
    }
    return _timeFormatter.format(tzais.toLocal());
  }

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

  /// Curated presentation metadata keyed by kosher_dart's Yom Tov index.
  ///
  /// kosher_dart computes *which* holiday any date is; this map only supplies
  /// the human-facing French/Hebrew labels and couple ideas. [groupKey] lets
  /// the multi-day festivals whose consecutive days share different indices
  /// (e.g. Succos -> Chol Hamoed -> Shemini Atzeres) collapse into one entry.
  static final Map<int, _HolidayMeta> _holidayMeta = {
    JewishCalendar.ROSH_HASHANA: const _HolidayMeta(
      groupKey: JewishCalendar.ROSH_HASHANA,
      name: 'Rosh Hashana',
      hebrewName: 'ראש השנה',
      description: 'Nouvel an juif',
      type: HolidayType.major,
      coupleIdeas: ['Diner festif', 'Tashlich ensemble'],
    ),
    JewishCalendar.YOM_KIPPUR: const _HolidayMeta(
      groupKey: JewishCalendar.YOM_KIPPUR,
      name: 'Yom Kippour',
      hebrewName: 'יום כיפור',
      description: 'Jour du Grand Pardon',
      type: HolidayType.major,
      coupleIdeas: ['Se demander pardon mutuellement'],
    ),
    JewishCalendar.SUCCOS: const _HolidayMeta(
      groupKey: JewishCalendar.SUCCOS,
      name: 'Souccot',
      hebrewName: 'סוכות',
      description: 'Fete des cabanes',
      type: HolidayType.major,
      coupleIdeas: ['Construire la Soucca ensemble', 'Inviter des amis'],
    ),
    JewishCalendar.CHOL_HAMOED_SUCCOS: const _HolidayMeta(
      groupKey: JewishCalendar.SUCCOS,
      name: 'Souccot',
      hebrewName: 'סוכות',
      description: 'Fete des cabanes',
      type: HolidayType.major,
      coupleIdeas: ['Construire la Soucca ensemble', 'Inviter des amis'],
    ),
    JewishCalendar.HOSHANA_RABBA: const _HolidayMeta(
      groupKey: JewishCalendar.SUCCOS,
      name: 'Souccot',
      hebrewName: 'סוכות',
      description: 'Fete des cabanes',
      type: HolidayType.major,
      coupleIdeas: ['Construire la Soucca ensemble', 'Inviter des amis'],
    ),
    JewishCalendar.SHEMINI_ATZERES: const _HolidayMeta(
      groupKey: JewishCalendar.SHEMINI_ATZERES,
      name: 'Shemini Atseret',
      hebrewName: 'שמיני עצרת',
      description: 'Huitieme jour de rassemblement',
      type: HolidayType.major,
      coupleIdeas: ['Priere pour la pluie'],
    ),
    JewishCalendar.SIMCHAS_TORAH: const _HolidayMeta(
      groupKey: JewishCalendar.SIMCHAS_TORAH,
      name: 'Simhat Torah',
      hebrewName: 'שמחת תורה',
      description: 'Joie de la Torah',
      type: HolidayType.major,
      coupleIdeas: ['Danser avec la Torah'],
    ),
    JewishCalendar.CHANUKAH: const _HolidayMeta(
      groupKey: JewishCalendar.CHANUKAH,
      name: 'Hanoucca',
      hebrewName: 'חנוכה',
      description: 'Fete des lumieres',
      type: HolidayType.major,
      coupleIdeas: ['Allumer les bougies ensemble', 'Soufganiot maison'],
    ),
    JewishCalendar.TU_BESHVAT: const _HolidayMeta(
      groupKey: JewishCalendar.TU_BESHVAT,
      name: 'Tou Bichvat',
      hebrewName: 'ט״ו בשבט',
      description: 'Nouvel an des arbres',
      type: HolidayType.minor,
    ),
    JewishCalendar.PURIM: const _HolidayMeta(
      groupKey: JewishCalendar.PURIM,
      name: 'Pourim',
      hebrewName: 'פורים',
      description: 'Fete des sorts',
      type: HolidayType.major,
      coupleIdeas: ['Deguisement en couple', 'Mishloach Manot ensemble'],
    ),
    JewishCalendar.SHUSHAN_PURIM: const _HolidayMeta(
      groupKey: JewishCalendar.PURIM,
      name: 'Pourim',
      hebrewName: 'פורים',
      description: 'Fete des sorts',
      type: HolidayType.major,
      coupleIdeas: ['Deguisement en couple', 'Mishloach Manot ensemble'],
    ),
    JewishCalendar.PESACH: const _HolidayMeta(
      groupKey: JewishCalendar.PESACH,
      name: 'Pessah',
      hebrewName: 'פסח',
      description: 'Fete de la liberte',
      type: HolidayType.major,
      coupleIdeas: ['Seder romantique', 'Voyage en Israel'],
    ),
    JewishCalendar.CHOL_HAMOED_PESACH: const _HolidayMeta(
      groupKey: JewishCalendar.PESACH,
      name: 'Pessah',
      hebrewName: 'פסח',
      description: 'Fete de la liberte',
      type: HolidayType.major,
      coupleIdeas: ['Seder romantique', 'Voyage en Israel'],
    ),
    JewishCalendar.YOM_HASHOAH: const _HolidayMeta(
      groupKey: JewishCalendar.YOM_HASHOAH,
      name: 'Yom HaShoah',
      hebrewName: 'יום השואה',
      description: 'Jour du souvenir de la Shoah',
      type: HolidayType.memorial,
    ),
    JewishCalendar.YOM_HAZIKARON: const _HolidayMeta(
      groupKey: JewishCalendar.YOM_HAZIKARON,
      name: 'Yom HaZikaron',
      hebrewName: 'יום הזיכרון',
      description: 'Jour du souvenir des soldats',
      type: HolidayType.memorial,
    ),
    JewishCalendar.YOM_HAATZMAUT: const _HolidayMeta(
      groupKey: JewishCalendar.YOM_HAATZMAUT,
      name: 'Yom HaAtsmaout',
      hebrewName: 'יום העצמאות',
      description: 'Jour de l\'independance d\'Israel',
      type: HolidayType.israeli,
      coupleIdeas: ['BBQ israelien', 'Concert/soiree'],
    ),
    JewishCalendar.YOM_YERUSHALAYIM: const _HolidayMeta(
      groupKey: JewishCalendar.YOM_YERUSHALAYIM,
      name: 'Yom Yeroushalayim',
      hebrewName: 'יום ירושלים',
      description: 'Jour de la reunification de Jerusalem',
      type: HolidayType.israeli,
    ),
    JewishCalendar.LAG_BAOMER: const _HolidayMeta(
      groupKey: JewishCalendar.LAG_BAOMER,
      name: 'Lag BaOmer',
      hebrewName: 'ל״ג בעומר',
      description: '33eme jour du Omer',
      type: HolidayType.minor,
      coupleIdeas: ['Feu de camp', 'Pique-nique'],
    ),
    JewishCalendar.SHAVUOS: const _HolidayMeta(
      groupKey: JewishCalendar.SHAVUOS,
      name: 'Shavouot',
      hebrewName: 'שבועות',
      description: 'Don de la Torah',
      type: HolidayType.major,
      coupleIdeas: ['Cheesecake maison', 'Nuit d\'etude'],
    ),
  };
}

/// Presentation-only metadata attached to a computed holiday.
class _HolidayMeta {
  final int groupKey;
  final String name;
  final String hebrewName;
  final String description;
  final HolidayType type;
  final List<String>? coupleIdeas;

  const _HolidayMeta({
    required this.groupKey,
    required this.name,
    required this.hebrewName,
    required this.description,
    required this.type,
    this.coupleIdeas,
  });
}

/// Model for a Jewish holiday
class JewishHoliday {
  final String name;
  final String hebrewName;
  final DateTime date;
  final DateTime? endDate;
  final String description;
  final HolidayType type;
  final List<String>? coupleIdeas;

  JewishHoliday({
    required this.name,
    required this.hebrewName,
    required this.date,
    this.endDate,
    required this.description,
    required this.type,
    this.coupleIdeas,
  });

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
  final String parasha;
  final String candleLighting;
  final String havdala;
  final DateTime date;

  ShabbatInfo({
    required this.parasha,
    required this.candleLighting,
    required this.havdala,
    required this.date,
  });
}

/// Model for couple activity
class CoupleActivity {
  final String title;
  final String description;
  final String icon;
  final String category;

  CoupleActivity({
    required this.title,
    required this.description,
    required this.icon,
    required this.category,
  });
}
