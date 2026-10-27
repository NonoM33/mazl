import 'package:intl/intl.dart';

import '../../../../l10n/l10n.dart';

/// Whether the moment is a Saturday evening in the member's LOCAL time, from
/// 20:00: the busy hour then follows the end of Shabbat. A simple rule, on the
/// local clock, never on the UTC date the server sends.
bool isAfterShabbat(DateTime startsAt) {
  final local = startsAt.toLocal();
  return local.weekday == DateTime.saturday && local.hour >= 20;
}

/// « samedi 21 h » for [moment] (an instant, shown in local time and in the
/// member's language). On the hour the French and English clocks say the hour
/// alone (« 21 h », « 9 PM »); the other languages and any other minute show
/// « 21:00 ».
String boostMomentText(AppLocalizations l10n, DateTime moment) {
  final local = moment.toLocal();
  final locale = l10n.localeName;
  return l10n.boostMoment(
    DateFormat.EEEE(locale).format(local),
    _hourText(locale, local),
  );
}

String _hourText(String locale, DateTime local) {
  if (local.minute == 0) {
    final hourOnly = DateFormat.j(locale).format(local);
    // Spanish, Russian and Hebrew give a bare « 21 »: not a clock time.
    if (!RegExp(r'^\d+$').hasMatch(hourOnly)) return hourOnly;
  }
  return DateFormat.Hm(locale).format(local);
}
