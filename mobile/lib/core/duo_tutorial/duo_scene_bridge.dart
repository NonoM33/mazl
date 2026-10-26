import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'duo_scene_pose.dart';

/// Le nom du canal JavaScript par lequel la page dit « prête »
/// (`window.mazlDuoBridge.postMessage('ready')` dans `assets/duo_tutorial/tutorial.js`).
const duoSceneChannelName = 'mazlDuoBridge';

/// Le message que la page envoie quand sa scène est dessinée.
const duoSceneReadyMessage = 'ready';

/// La conversation avec la page 3D, sans la WebView : Flutter envoie la pose
/// RÉELLE à chaque changement par `window.mazlDuo.setPose({...})`, la page
/// répond « prête » une fois. Avant, seule la dernière pose est retenue ; elle
/// part dès que la page est prête.
class DuoSceneScriptBridge {
  DuoSceneScriptBridge(this._run);

  final Future<void> Function(String script) _run;
  bool _ready = false;
  DuoScenePose? _pending;

  bool get isReady => _ready;

  /// Le script qui donne [pose] à la page. JSON est une expression JavaScript
  /// valide : rien n'est recollé à la main.
  static String scriptFor(DuoScenePose pose) =>
      'window.mazlDuo&&window.mazlDuo.setPose(${jsonEncode(pose.toMessage())});';

  void showPose(DuoScenePose pose) {
    if (!_ready) {
      _pending = pose;
      return;
    }
    _send(pose);
  }

  /// La page est prête : la pose qui attendait part.
  void onReady() {
    _ready = true;
    final pending = _pending;
    _pending = null;
    if (pending != null) _send(pending);
  }

  /// Un message du canal : seul « ready » compte.
  void onChannelMessage(String message) {
    if (message == duoSceneReadyMessage) onReady();
  }

  void _send(DuoScenePose pose) {
    unawaited(
      _run(scriptFor(pose)).catchError((Object error) {
        // La scène n'est qu'un décor : le tutoriel continue sans elle.
        debugPrint('duo scene: $error');
      }),
    );
  }
}
