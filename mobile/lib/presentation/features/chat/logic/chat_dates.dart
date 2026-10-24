import 'package:intl/intl.dart';

import '../../../../l10n/l10n.dart';

// Dates and clock times shown in a conversation, in the member's language
// (`l10n.localeName`) with `intl` skeletons: no pattern is written by hand, so
// an English reader gets « Oct 21 » and a Hebrew one the Hebrew month.

DateTime dayOf(DateTime time) {
  final local = time.toLocal();
  return DateTime(local.year, local.month, local.day);
}

bool sameDay(DateTime a, DateTime b) => dayOf(a) == dayOf(b);

/// « 20:47 ».
String clock(AppLocalizations l10n, DateTime time) =>
    DateFormat.Hm(l10n.localeName).format(time.toLocal());

/// « Aujourd'hui », « Hier », « Mar. 21 oct. » (with the year when it is not
/// the current one). The caller upper-cases it.
String dayLabel(AppLocalizations l10n, DateTime day, DateTime now) {
  final today = dayOf(now);
  final date = dayOf(day);
  final days = today.difference(date).inDays;
  if (days == 0) return l10n.commonToday;
  if (days == 1) return l10n.commonYesterday;
  final format = date.year == today.year
      ? DateFormat.MMMEd(l10n.localeName)
      : DateFormat.yMMMEd(l10n.localeName);
  return _capitalize(format.format(date));
}

/// « 21 oct. », for the start-of-conversation marker.
String shortDate(AppLocalizations l10n, DateTime day) =>
    DateFormat.MMMd(l10n.localeName).format(dayOf(day));

/// 1:05 for a voice note duration.
String minutesSeconds(Duration d) {
  final seconds = d.inSeconds < 0 ? 0 : d.inSeconds;
  final rest = seconds % 60;
  final padded = rest < 10 ? '0$rest' : '$rest';
  return '${seconds ~/ 60}:$padded';
}

String _capitalize(String text) =>
    text.isEmpty ? text : text[0].toUpperCase() + text.substring(1);
