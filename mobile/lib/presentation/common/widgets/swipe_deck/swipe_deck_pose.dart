import 'dart:ui';

import 'package:flutter/widgets.dart';

import '../../../../core/motion/mazl_motion.dart';
import 'swipe_deck_physics.dart';

/// Where the top card is, and what it looks like there.
@immutable
class DeckPose {
  const DeckPose({this.card = Offset.zero, this.extraTurn = 0, this.fade = 0});

  static const rest = DeckPose();

  /// Offset from the resting place.
  final Offset card;

  /// Radians added to the rotation that follows [card]: the extra turn of an
  /// exit.
  final double extraTurn;

  /// 0 → 1, reduced motion only: the card dissolves instead of travelling.
  final double fade;

  DeckPose copyWith({Offset? card, double? extraTurn, double? fade}) =>
      DeckPose(
        card: card ?? this.card,
        extraTurn: extraTurn ?? this.extraTurn,
        fade: fade ?? this.fade,
      );
}

/// The two ways a layer of the deck is drawn from a [DeckPose]. Both keep the
/// same widget structure so a card keeps its state when it moves from the back
/// to the top.
abstract final class DeckLayers {
  /// The top card: follows the finger, pivoting on the grab point.
  static Widget top({
    required DeckPose pose,
    required Size size,
    required Offset pivot,
    required bool grabbedLower,
    required bool reduced,
    required Widget child,
  }) {
    final turn = reduced
        ? 0.0
        : SwipeDeckPhysics.rotation(
                dx: pose.card.dx,
                width: size.width,
                grabbedLower: grabbedLower,
              ) +
              pose.extraTurn;
    return Opacity(
      opacity: 1 - pose.fade,
      child: Transform(
        origin: pivot,
        transform: Matrix4.translationValues(
          pose.card.dx,
          pose.card.dy,
          0,
        ).multiplied(Matrix4.rotationZ(turn)),
        child: child,
      ),
    );
  }

  /// The card below: grows and rises as the one on top travels.
  static Widget back({
    required DeckPose pose,
    required Size size,
    required Widget child,
  }) {
    final travel = size.isEmpty
        ? 0.0
        : SwipeDeckPhysics.backProgress(pose.card, size);
    final q = travel > pose.fade ? travel : pose.fade;
    final scale = lerpDouble(MazlMotion.deckBackScale, 1, q)!;
    final rise = lerpDouble(MazlMotion.deckBackOffset, 0, q)!;
    return Opacity(
      opacity: 1,
      child: Transform(
        alignment: Alignment.center,
        transform: Matrix4.translationValues(
          0,
          rise,
          0,
        ).multiplied(Matrix4.diagonal3Values(scale, scale, 1)),
        child: child,
      ),
    );
  }
}
