/// Temps restant avant minuit (heure locale) : les likes gratuits reviennent
/// à ce moment-là.
Duration timeUntilMidnight(DateTime now) {
  final midnight = DateTime(now.year, now.month, now.day + 1);
  return midnight.difference(now);
}

/// « 04:12:33 ». Jamais négatif.
String formatCountdown(Duration left) {
  final total = left.isNegative ? 0 : left.inSeconds;
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(total ~/ 3600)}:${two(total % 3600 ~/ 60)}:${two(total % 60)}';
}
