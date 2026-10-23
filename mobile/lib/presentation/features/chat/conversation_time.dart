import 'package:intl/intl.dart';

/// Heure affichée sur une ligne de conversation, toujours en français :
/// « 09:05 » aujourd'hui, « Hier », « Mar. » cette semaine, « 15 oct. » avant.
String formatConversationTime(DateTime time, DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(time.year, time.month, time.day);
  final days = today.difference(day).inDays;
  if (days <= 0) return DateFormat.Hm('fr_FR').format(time);
  if (days == 1) return 'Hier';
  if (days < 7) return _capitalize(DateFormat.E('fr_FR').format(time));
  return DateFormat.MMMd('fr_FR').format(time);
}

String _capitalize(String text) => text.isEmpty ? text : text[0].toUpperCase() + text.substring(1);
