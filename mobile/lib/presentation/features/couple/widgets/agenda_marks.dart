import '../../../../core/models/couple_daily.dart';
import '../../../../core/models/couple_space.dart';
import '../../../../core/services/jewish_calendar_service.dart';

/// What can sit under a day of the agenda grid: a date that matters to the
/// couple, a Jewish holiday, or a day on which an enabled ritual happens.
enum AgendaMark { importantDate, holiday, ritual }

/// The calendar day of [moment], with no time of day.
DateTime agendaDay(DateTime moment) =>
    DateTime(moment.year, moment.month, moment.day);

/// `2026-11-09`, the key of a day in widget keys.
String agendaDayKey(DateTime day) =>
    '${day.year.toString().padLeft(4, '0')}-'
    '${day.month.toString().padLeft(2, '0')}-'
    '${day.day.toString().padLeft(2, '0')}';

/// The day a date of the couple is written on. The server sends a calendar
/// date (`2026-12-01T00:00:00.000Z`): its own fields are the day, whatever the
/// time zone of the phone.
DateTime? coupleDateDay(CoupleDate date) {
  final raw = date.date;
  return raw == null ? null : DateTime(raw.year, raw.month, raw.day);
}

/// The next day [date] falls on, [today] included. A yearly date comes back
/// every year; a one-off date that is over has none.
DateTime? nextOccurrence(CoupleDate date, DateTime today) {
  final day = coupleDateDay(date);
  if (day == null) return null;
  final start = agendaDay(today);
  if (!date.isRecurring) return day.isBefore(start) ? null : day;
  final thisYear = DateTime(start.year, day.month, day.day);
  return thisYear.isBefore(start)
      ? DateTime(start.year + 1, day.month, day.day)
      : thisYear;
}

/// Whole days from [today] to [day].
int daysUntil(DateTime today, DateTime day) => DateTime.utc(
  day.year,
  day.month,
  day.day,
).difference(DateTime.utc(today.year, today.month, today.day)).inDays;

/// Everything the agenda knows about a day, computed from the three sources.
class AgendaMarks {
  const AgendaMarks({
    this.dates = const [],
    this.holidays = const [],
    this.rituals = const [],
  });

  final List<CoupleDate> dates;
  final List<JewishHoliday> holidays;
  final List<CoupleRitual> rituals;

  List<CoupleDate> datesOn(DateTime day) => [
    for (final date in dates)
      if (_fallsOn(date, day)) date,
  ];

  List<JewishHoliday> holidaysOn(DateTime day) => [
    for (final holiday in holidays)
      if (!day.isBefore(agendaDay(holiday.date)) &&
          !day.isAfter(agendaDay(holiday.endDate ?? holiday.date)))
        holiday,
  ];

  /// The enabled rituals of the day: `weekday` counts Sunday as 0, Shabbat
  /// is the Friday ritual.
  List<CoupleRitual> ritualsOn(DateTime day) => [
    for (final ritual in rituals)
      if (ritual.enabled &&
          ritual.weekday != null &&
          ritual.weekday! % 7 == day.weekday % 7)
        ritual,
  ];

  Set<AgendaMark> on(DateTime day) => {
    if (datesOn(day).isNotEmpty) AgendaMark.importantDate,
    if (holidaysOn(day).isNotEmpty) AgendaMark.holiday,
    if (ritualsOn(day).isNotEmpty) AgendaMark.ritual,
  };

  static bool _fallsOn(CoupleDate date, DateTime day) {
    final written = coupleDateDay(date);
    if (written == null) return false;
    if (date.isRecurring) {
      return written.month == day.month && written.day == day.day;
    }
    return written == day;
  }
}
