import 'package:intl/intl.dart';

import '../../../../core/models/event.dart';
import '../../../../l10n/l10n.dart';

/// The name of an event kind in the member's language. The core only knows
/// the stable [EventKind]; the screens choose the words.
extension EventKindLabel on EventKind {
  /// Badge of a card in the list.
  String label(AppLocalizations l10n) => switch (this) {
    EventKind.shabbatDinner => l10n.eventsTypeShabbat,
    EventKind.speedDating => l10n.eventsTypeSpeedDating,
    EventKind.holiday => l10n.eventsTypeHoliday,
    EventKind.lecture => l10n.eventsTypeLecture,
    EventKind.social => l10n.eventsTypeSocial,
    EventKind.other => l10n.eventsTypeOther,
  };

  /// Filter chip above the list (the holidays chip is plural).
  String filterLabel(AppLocalizations l10n) => switch (this) {
    EventKind.holiday => l10n.eventsFilterHolidays,
    _ => label(l10n),
  };

  /// Badge on the detail screen.
  String detailLabel(AppLocalizations l10n) => switch (this) {
    EventKind.shabbatDinner => l10n.eventsTypeShabbatDinner,
    _ => label(l10n),
  };
}

/// A whole-unit price in the event's currency, written the way the
/// member's language writes it (« 25 € », « €25 »).
String eventPriceText(Event event, String locale) =>
    NumberFormat.simpleCurrency(
      locale: locale,
      name: event.currency,
      decimalDigits: 0,
    ).format(event.price);

final RegExp _clock = RegExp(r'^(\d{1,2}):(\d{2})(?::\d{2}(?:\.\d+)?)?$');

/// A time of day from the server (« 20:00:00 », « 19:30 ») the way the
/// member's language writes it: « 20 h 00 » in French, « 8:00 PM » in
/// English. Seconds are never shown. An unreadable value is returned as is.
String eventClockText(String raw, String locale) {
  final match = _clock.firstMatch(raw.trim());
  if (match == null) return raw;
  final hour = int.parse(match.group(1)!);
  final minute = int.parse(match.group(2)!);
  if (hour > 23 || minute > 59) return raw;
  final time = DateTime(2000, 1, 1, hour, minute);
  // French writes « 20 h 00 »: the 24-hour clock, with an h between.
  return locale.startsWith('fr')
      ? DateFormat.Hm(locale).format(time).replaceFirst(':', ' h ')
      : DateFormat.jm(locale).format(time);
}

/// « 20 h 00 – 22 h 30 », or just the start when the event has no end time.
/// `null` when the event has no time.
String? eventTimeText(Event event, AppLocalizations l10n) {
  final start = event.time;
  if (start == null || start.isEmpty) return null;
  final from = eventClockText(start, l10n.localeName);
  final end = event.endTime;
  if (end == null || end.isEmpty) return from;
  return l10n.eventsTimeRange(from, eventClockText(end, l10n.localeName));
}
