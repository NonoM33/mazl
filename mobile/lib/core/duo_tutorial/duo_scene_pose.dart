import 'dart:ui' show Size;

import 'package:flutter/foundation.dart';

import '../layout/fold_state.dart';
import 'duo_tutorial_step.dart';

/// Le sens du pli, vu de la fenêtre de l'app : vertical quand l'appareil est
/// tenu comme un livre, horizontal comme un portable.
enum DuoAxis { vertical, horizontal }

/// Ce que la page 3D reçoit à chaque changement : la pose RÉELLE de l'appareil
/// et l'étape du tutoriel. C'est le seul message de Dart vers la scène
/// (`window.mazlDuo.setPose`, voir `assets/duo_tutorial/pose_math.js`).
@immutable
class DuoScenePose {
  const DuoScenePose({
    required this.hinge,
    required this.angle,
    required this.axis,
    required this.sideways,
    required this.verticalBar,
    required this.step,
    required this.validated,
    required this.reduceMotion,
  });

  /// La pose de [fold] dans une fenêtre de [size], à l'étape [step].
  factory DuoScenePose.from({
    required FoldState fold,
    required Size size,
    required DuoTutorialStep step,
    required bool validated,
    required bool reduceMotion,
  }) {
    final landscape = size.width > size.height;
    return DuoScenePose(
      hinge: fold.hinge,
      angle: _rounded(fold.angle ?? _defaultAngle(fold.hinge)),
      axis: switch (fold.hinge) {
        HingeStatus.partiallyOpen =>
          foldRunsDownThePage(fold, size)
              ? DuoAxis.vertical
              : DuoAxis.horizontal,
        _ => landscape ? DuoAxis.vertical : DuoAxis.horizontal,
      },
      sideways: isTentWindow(fold, size),
      verticalBar: fold.verticalBar,
      step: step,
      validated: validated,
      reduceMotion: reduceMotion,
    );
  }

  final HingeStatus hinge;

  /// Ouverture de la charnière en radians : 0 fermé, pi à plat.
  final double angle;
  final DuoAxis axis;

  /// La pose tente : posé en V sur la table, écran extérieur en paysage
  /// (voir [isTentWindow]).
  final bool sideways;
  final VerticalBarSide? verticalBar;
  final DuoTutorialStep step;

  /// Le geste de l'étape est fait : la scène tient ses éclats et trace son trait.
  final bool validated;

  /// « Réduire les animations » : la scène saute à la pose, sans l'animer.
  final bool reduceMotion;

  /// Quand le système ne donne pas l'angle : celui, typique, de la charnière.
  static double _defaultAngle(HingeStatus hinge) => switch (hinge) {
    HingeStatus.closed => 0,
    HingeStatus.partiallyOpen => 1.9,
    HingeStatus.fullyOpen || HingeStatus.unknown => 3.14159,
  };

  /// Trois décimales : un bruit de capteur ne fait pas une pose de plus.
  static double _rounded(double angle) => (angle * 1000).roundToDouble() / 1000;

  /// Le message tel que la page le lit.
  Map<String, Object?> toMessage() => {
    'hinge': hinge.name,
    'angle': angle,
    'axis': axis.name,
    'sideways': sideways,
    'verticalBar': verticalBar?.name,
    'step': step.name,
    'stepIndex': step.index,
    'validated': validated,
    'reduceMotion': reduceMotion,
  };

  @override
  bool operator ==(Object other) =>
      other is DuoScenePose &&
      other.hinge == hinge &&
      other.angle == angle &&
      other.axis == axis &&
      other.sideways == sideways &&
      other.verticalBar == verticalBar &&
      other.step == step &&
      other.validated == validated &&
      other.reduceMotion == reduceMotion;

  @override
  int get hashCode => Object.hash(
    hinge,
    angle,
    axis,
    sideways,
    verticalBar,
    step,
    validated,
    reduceMotion,
  );
}
