import 'package:intl/intl.dart';

import '../../../l10n/l10n.dart';

/// Heure affichée sur une ligne de conversation, dans la langue du membre :
/// « 09:05 » aujourd'hui, « Hier », « Mar. » cette semaine, « 15 oct. » avant.
String formatConversationTime(
  AppLocalizations l10n,
  DateTime time,
  DateTime now,
) {
  final locale = l10n.localeName;
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(time.year, time.month, time.day);
  final days = today.difference(day).inDays;
  if (days <= 0) return DateFormat.Hm(locale).format(time);
  if (days == 1) return l10n.commonYesterday;
  if (days < 7) return _capitalize(DateFormat.E(locale).format(time));
  return DateFormat.MMMd(locale).format(time);
}

String _capitalize(String text) =>
    text.isEmpty ? text : text[0].toUpperCase() + text.substring(1);
