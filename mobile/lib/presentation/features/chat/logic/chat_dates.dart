// Dates and clock times shown in a conversation. Written by hand (no Intl
// locale to initialise): French abbreviations, upper-cased by the label style.

const _weekdays = ['lun.', 'mar.', 'mer.', 'jeu.', 'ven.', 'sam.', 'dim.'];
const _months = [
  'janv.',
  'févr.',
  'mars',
  'avr.',
  'mai',
  'juin',
  'juil.',
  'août',
  'sept.',
  'oct.',
  'nov.',
  'déc.',
];

DateTime dayOf(DateTime time) {
  final local = time.toLocal();
  return DateTime(local.year, local.month, local.day);
}

bool sameDay(DateTime a, DateTime b) => dayOf(a) == dayOf(b);

/// « 20:47 ».
String clock(DateTime time) {
  final local = time.toLocal();
  return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
}

/// « Aujourd'hui », « Hier », « Mar. 21 oct. » (with the year when it is not
/// the current one). The caller upper-cases it.
String dayLabel(DateTime day, DateTime now) {
  final today = dayOf(now);
  final date = dayOf(day);
  final days = today.difference(date).inDays;
  if (days == 0) return "Aujourd'hui";
  if (days == 1) return 'Hier';
  final base =
      '${_weekdays[date.weekday - 1][0].toUpperCase()}${_weekdays[date.weekday - 1].substring(1)} '
      '${date.day} ${_months[date.month - 1]}';
  return date.year == today.year ? base : '$base ${date.year}';
}

/// « 21 oct. », for the start-of-conversation marker.
String shortDate(DateTime day) {
  final date = dayOf(day);
  return '${date.day} ${_months[date.month - 1]}';
}

/// 1:05 for a voice note duration.
String minutesSeconds(Duration d) {
  final seconds = d.inSeconds < 0 ? 0 : d.inSeconds;
  return '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
}
