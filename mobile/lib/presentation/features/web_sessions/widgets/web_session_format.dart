import 'package:clock/clock.dart';

import '../../../../core/web_sessions/web_session_models.dart';
import '../../../../l10n/l10n.dart';

String connectionMethodLabel(AppLocalizations l10n, WebSessionMethod method) =>
    switch (method) {
      WebSessionMethod.qr => l10n.webSessionsMethodQr,
      WebSessionMethod.google => l10n.webSessionsMethodGoogle,
      WebSessionMethod.apple => l10n.webSessionsMethodApple,
    };

/// « À l'instant », « Il y a 5 min », « Il y a 3 h », « Hier », « Il y a 4 j ».
String lastActivityLabel(AppLocalizations l10n, DateTime lastSeen) {
  final elapsed = clock.now().difference(lastSeen);
  if (elapsed.inMinutes < 1) return l10n.webSessionsActiveNow;
  if (elapsed.inMinutes < 60) {
    return l10n.webSessionsActiveMinutes(elapsed.inMinutes);
  }
  if (elapsed.inHours < 24) return l10n.webSessionsActiveHours(elapsed.inHours);
  if (elapsed.inDays == 1) return l10n.webSessionsActiveYesterday;
  return l10n.webSessionsActiveDays(elapsed.inDays);
}

/// « 14 h 05 », the hour a request was made.
String clockTimeLabel(AppLocalizations l10n, DateTime time) =>
    l10n.webSessionsClockTime(
      time.hour.toString(),
      time.minute.toString().padLeft(2, '0'),
    );
