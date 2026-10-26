import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/duo_tutorial/duo_scene_renderer.dart';
import '../../../core/duo_tutorial/duo_tutorial_store.dart';
import 'widgets/web_view_duo_scene_renderer.dart';

/// Fabrique la scène 3D : la page three.js embarquée dans l'app, un faux rendu
/// dans les tests.
final duoSceneRendererFactoryProvider = Provider<DuoSceneRenderer Function()>(
  (ref) => WebViewDuoSceneRenderer.new,
);

/// Où l'on note que le tutoriel a été montré.
final duoTutorialStoreProvider = Provider<DuoTutorialStore>(
  (ref) => SharedPreferencesDuoTutorialStore(),
);
