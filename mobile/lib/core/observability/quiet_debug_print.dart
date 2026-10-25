import 'package:flutter/foundation.dart';

/// Rend `debugPrint` muet hors du mode debug. Les ~160 appels de l'app
/// écrivent des e-mails de membres et des corps d'erreur : en release, la
/// console système du téléphone n'a rien à en lire.
void silenceDebugPrintOutsideDebug({bool isDebug = kDebugMode}) {
  if (isDebug) return;
  debugPrint = (String? message, {int? wrapWidth}) {};
}
