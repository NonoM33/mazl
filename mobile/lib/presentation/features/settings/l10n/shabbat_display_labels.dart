import 'package:intl/intl.dart';

import '../../../../core/services/jewish_calendar_service.dart';
import '../../../../core/services/rest_display_content.dart';
import '../../../../l10n/l10n.dart';
import '../../couple/l10n/jewish_calendar_labels.dart';

/// A label and its value, as the display writes them under the clock.
class DisplayFact {
  const DisplayFact(this.label, this.value);

  final String label;
  final String value;
}

/// The words of the Shabbat display, in the member's language. The core says
/// what the moment is; these write it.
class ShabbatDisplayTexts {
  const ShabbatDisplayTexts(this.l10n, this.content, this.now);

  final AppLocalizations l10n;
  final RestDisplayContent content;
  final DateTime now;

  RestPeriod get _rest => content.rest;

  /// The small line above the title, null when there is none.
  String? get eyebrow => switch (content.moment) {
    RestDisplayMoment.eve => l10n.shabbatDisplayTonight,
    RestDisplayMoment.ordinary => l10n.shabbatDisplayComing,
    RestDisplayMoment.hanukkah => l10n.shabbatDisplayHanukkahNight(
      content.hanukkahNight!,
    ),
    RestDisplayMoment.resting || RestDisplayMoment.omer => null,
  };

  /// The big words: the greeting of Shabbat, the festival, Hanukkah or the
  /// count of the Omer.
  String get title => switch (content.moment) {
    RestDisplayMoment.omer => l10n.shabbatDisplayOmerDay(content.omerDay!),
    RestDisplayMoment.hanukkah => JewishHolidayId.hanukkah.title(l10n),
    RestDisplayMoment.resting =>
      _rest.holiday?.title(l10n) ?? l10n.shabbatDisplayShabbatShalom,
    RestDisplayMoment.eve || RestDisplayMoment.ordinary =>
      _rest.holiday?.title(l10n) ?? l10n.shabbatDisplayShabbatName,
  };

  /// The name of the rest the times below belong to, when the title does not
  /// say it already (Hanukkah and the Omer take the title).
  String? get restName => switch (content.moment) {
    RestDisplayMoment.hanukkah || RestDisplayMoment.omer =>
      _rest.holiday?.title(l10n) ?? l10n.shabbatDisplayShabbatName,
    _ => null,
  };

  /// The times of the rest and the parasha. While the rest is on, only its
  /// end is of use.
  List<DisplayFact> get facts {
    final festival = _rest.holiday != null;
    final resting = content.moment == RestDisplayMoment.resting;
    return [
      if (!resting)
        DisplayFact(
          festival
              ? l10n.shabbatDisplayFestivalEntry
              : l10n.settingsShabbatCandleLighting,
          _time(_rest.entry),
        ),
      DisplayFact(
        festival
            ? l10n.shabbatDisplayFestivalExit
            : l10n.settingsShabbatHavdalah,
        _time(_rest.exit),
      ),
      if (_rest.parsha != null)
        DisplayFact(l10n.shabbatDisplayParasha, _rest.parsha!.title(l10n)),
    ];
  }

  /// `HH:mm`, with the weekday in front when it is not today; a dash where the
  /// sun does not set.
  String _time(DateTime moment) {
    if (!_rest.timesKnown) return '—';
    final hour = DateFormat.Hm(l10n.localeName).format(moment);
    final today = DateTime(now.year, now.month, now.day);
    final sameDay = DateTime(moment.year, moment.month, moment.day) == today;
    return sameDay
        ? hour
        : '${DateFormat.E(l10n.localeName).format(moment)} $hour';
  }
}
