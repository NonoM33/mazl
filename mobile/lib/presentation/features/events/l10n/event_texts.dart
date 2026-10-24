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
