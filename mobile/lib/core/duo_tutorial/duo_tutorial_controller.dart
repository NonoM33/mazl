import 'dart:async';
import 'dart:ui' show Size;

import 'package:flutter/foundation.dart';

import '../layout/fold_state.dart';
import 'duo_scene_pose.dart';
import 'duo_scene_renderer.dart';
import 'duo_tutorial_step.dart';

/// Conduit le tutoriel : l'étape en cours, la réussite d'un geste, et la pose
/// réelle donnée à la scène 3D. Il ne dessine rien et ne connaît pas la WebView
/// (voir [DuoSceneRenderer]) : on le teste avec les poses mesurées du Duo.
///
/// Un geste est validé quand sa pose est TENUE [holdDuration] (une pose
/// traversée en passant ne compte pas). Une fois validé, l'étape suivante vient
/// d'elle-même après [advanceDelay] — sauf si l'avance automatique est coupée
/// (VoiceOver) — et l'utilisateur peut toujours passer ([next], [skip]).
class DuoTutorialController extends ChangeNotifier {
  DuoTutorialController({
    required DuoSceneRenderer renderer,
    this.holdDuration = const Duration(milliseconds: 700),
    this.advanceDelay = const Duration(milliseconds: 1500),
  }) : _renderer = renderer;

  final DuoSceneRenderer _renderer;
  final Duration holdDuration;
  final Duration advanceDelay;

  DuoTutorialStep _step = DuoTutorialStep.welcome;
  bool _validated = false;
  bool _finished = false;
  bool _disposed = false;

  FoldState _fold = FoldState.unknown;
  Size _size = Size.zero;
  bool _reduceMotion = false;
  bool _autoAdvance = true;
  bool _hasPose = false;

  Timer? _hold;
  Timer? _advance;
  DuoScenePose? _sent;

  DuoTutorialStep get step => _step;

  /// De 0 à 5.
  int get index => _step.index;
  int get stepCount => DuoTutorialStep.values.length;

  /// Le geste de l'étape est fait (et tenu).
  bool get validated => _validated;

  /// Le tutoriel est terminé (dernière étape passée, ou « Passer »).
  bool get finished => _finished;

  /// Lit la pose réelle : à appeler à chaque changement de pose, de fenêtre ou
  /// de réglage d'accessibilité.
  void update({
    required FoldState fold,
    required Size size,
    bool reduceMotion = false,
    bool autoAdvance = true,
  }) {
    if (_finished || _disposed) return;
    _fold = fold;
    _size = size;
    _reduceMotion = reduceMotion;
    _autoAdvance = autoAdvance;
    _hasPose = true;
    _sendPose();
    _evaluate();
  }

  /// « Suivant » : l'étape d'après, geste fait ou non ; après la dernière, fin.
  void next() {
    if (_finished || _disposed) return;
    _cancelTimers();
    final following = _step.next;
    if (following == null) {
      _finish();
      return;
    }
    _step = following;
    _validated = false;
    _sendPose();
    _evaluate();
    notifyListeners();
  }

  /// « Passer » : termine tout de suite.
  void skip() {
    if (_finished || _disposed) return;
    _cancelTimers();
    _finish();
  }

  void _finish() {
    _finished = true;
    notifyListeners();
  }

  void _sendPose() {
    if (!_hasPose) return;
    final pose = DuoScenePose.from(
      fold: _fold,
      size: _size,
      step: _step,
      validated: _validated,
      reduceMotion: _reduceMotion,
    );
    if (pose == _sent) return;
    _sent = pose;
    _renderer.showPose(pose);
  }

  /// Compare la pose réelle au geste attendu : lance ou coupe la tenue, et
  /// l'avance automatique après la réussite.
  void _evaluate() {
    if (_validated) {
      if (!_autoAdvance) {
        _advance?.cancel();
        _advance = null;
      } else {
        _advance ??= Timer(advanceDelay, next);
      }
      return;
    }
    final met = _hasPose && _step.isDoneBy(_fold, _size);
    if (!met) {
      _hold?.cancel();
      _hold = null;
      return;
    }
    _hold ??= Timer(holdDuration, _hasBeenHeld);
  }

  void _hasBeenHeld() {
    _hold = null;
    if (_finished || _disposed || !_step.isDoneBy(_fold, _size)) return;
    _validated = true;
    _sendPose();
    _evaluate();
    notifyListeners();
  }

  void _cancelTimers() {
    _hold?.cancel();
    _advance?.cancel();
    _hold = null;
    _advance = null;
  }

  @override
  void dispose() {
    _disposed = true;
    _cancelTimers();
    super.dispose();
  }
}
