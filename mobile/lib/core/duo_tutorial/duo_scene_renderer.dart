import 'package:flutter/widgets.dart';

import 'duo_scene_pose.dart';

/// Ce que le tutoriel demande à la scène 3D, sans rien savoir de la WebView :
/// afficher la vue, lui donner la pose réelle de l'appareil. Une implémentation
/// de test note les poses reçues ; celle de l'app est une page three.js
/// embarquée.
abstract interface class DuoSceneRenderer {
  /// La vue de la scène, à poser dans l'écran.
  Widget build(BuildContext context);

  /// Donne la pose réelle à la scène (le dernier appel l'emporte).
  void showPose(DuoScenePose pose);

  void dispose();
}
