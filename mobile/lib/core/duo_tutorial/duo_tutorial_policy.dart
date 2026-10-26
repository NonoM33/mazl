import 'package:flutter/foundation.dart';

import '../layout/fold_state.dart';
import '../router/route_names.dart';
import 'duo_tutorial_store.dart';

export 'duo_tutorial_store.dart';

/// Le tutoriel se lance si l'appareil se plie ET s'il n'a jamais été montré.
/// Jamais sur un autre iPhone : il n'aurait aucun geste à attendre.
bool shouldShowDuoTutorial({
  required FoldState fold,
  required bool alreadySeen,
}) => fold.isFoldable && !alreadySeen;

/// Décide du lancement au démarrage et, s'il a lieu, note qu'il a été montré :
/// un second démarrage (même interrompu) ne le relance pas. Le Duo est reconnu
/// à la charnière que le système rapporte ; ailleurs, rien n'est noté, le
/// tutoriel viendra si l'app tourne un jour sur un Duo.
///
/// Un disque illisible ne bloque jamais le démarrage : pas de tutoriel.
Future<bool> decideDuoTutorialLaunch({
  required FoldState fold,
  required DuoTutorialStore store,
}) async {
  if (!fold.isFoldable) return false;
  try {
    final show = shouldShowDuoTutorial(
      fold: fold,
      alreadySeen: await store.hasBeenSeen(),
    );
    if (show) await store.markSeen();
    return show;
  } on Object catch (error) {
    debugPrint('duo tutorial: $error');
    return false;
  }
}

/// L'entrée « MAZL sur iPhone Duo » des Réglages : seulement sur le Duo.
bool showDuoTutorialInSettings(FoldState fold) => fold.isFoldable;

/// Où ouvrir le tutoriel. Avec [next], il enchaîne sur cette route à la fin
/// (le démarrage) ; sans, il revient d'où il vient (les Réglages).
String duoTutorialLocation({String? next}) => next == null
    ? RoutePaths.duoTutorial
    : Uri(
        path: RoutePaths.duoTutorial,
        queryParameters: {'next': next},
      ).toString();

/// La suite demandée dans l'adresse, seulement si c'est une route de l'app.
String? safeDuoTutorialNext(String? next) {
  if (next == null || !next.startsWith('/') || next.startsWith('//')) {
    return null;
  }
  return next;
}
