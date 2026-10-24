import 'package:clock/clock.dart';

import '../../../../core/web_sessions/web_session_models.dart';

String connectionMethodLabel(WebSessionMethod method) => switch (method) {
  WebSessionMethod.qr => 'Connecté par QR code',
  WebSessionMethod.google => 'Connecté avec Google',
  WebSessionMethod.apple => 'Connecté avec Apple',
};

/// « À l'instant », « Il y a 5 min », « Il y a 3 h », « Hier », « Il y a 4 j ».
String lastActivityLabel(DateTime lastSeen) {
  final elapsed = clock.now().difference(lastSeen);
  if (elapsed.inMinutes < 1) return 'Actif à l\'instant';
  if (elapsed.inMinutes < 60) return 'Actif il y a ${elapsed.inMinutes} min';
  if (elapsed.inHours < 24) return 'Actif il y a ${elapsed.inHours} h';
  if (elapsed.inDays == 1) return 'Actif hier';
  return 'Actif il y a ${elapsed.inDays} j';
}

/// « 14 h 05 », the hour a request was made.
String clockTimeLabel(DateTime time) =>
    '${time.hour} h ${time.minute.toString().padLeft(2, '0')}';
