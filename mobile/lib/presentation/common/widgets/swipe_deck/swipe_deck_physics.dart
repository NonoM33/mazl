import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/gestures.dart';

import '../../../../core/motion/mazl_motion.dart';
import 'swipe_deck_types.dart';

/// The rules of the card deck, free of any widget: where the card is for a
/// given finger, how far it is from committing, and whether a release commits.
abstract final class SwipeDeckPhysics {
  static const _res = MazlMotion.deckBlockedResistance;

  /// Per axis, 1 where the card may go, [MazlMotion.deckBlockedResistance]
  /// where it may not (down; left / right / up when the deck refuses them).
  static Offset resistance(Offset at, Set<SwipeDirection> allowed) {
    final horizontalOk = at.dx >= 0
        ? allowed.contains(SwipeDirection.right)
        : allowed.contains(SwipeDirection.left);
    final verticalOk = at.dy < 0 && allowed.contains(SwipeDirection.up);
    return Offset(horizontalOk ? 1 : _res, verticalOk ? 1 : _res);
  }

  /// Where the card is when the finger has moved [finger] from the grab.
  static Offset follow(Offset finger, Set<SwipeDirection> allowed) {
    final r = resistance(finger, allowed);
    return Offset(finger.dx * r.dx, finger.dy * r.dy);
  }

  /// The finger offset that puts the card at [card] (inverse of [follow]).
  static Offset fingerFor(Offset card, Set<SwipeDirection> allowed) {
    final r = resistance(card, allowed);
    return Offset(card.dx / r.dx, card.dy / r.dy);
  }

  /// Radians. A card held by its lower half turns the other way, as an object
  /// pivoting on the grab point does.
  static double rotation({
    required double dx,
    required double width,
    required bool grabbedLower,
  }) {
    final turn = (dx / width).clamp(-1.0, 1.0);
    final degrees = turn * MazlMotion.deckMaxRotationDegrees;
    return degrees * math.pi / 180 * (grabbedLower ? -1 : 1);
  }

  /// The direction the card is heading to and how close it is to committing.
  static SwipeProgress progress(
    Offset card,
    Size size,
    Set<SwipeDirection> allowed,
  ) {
    var best = SwipeProgress.none;
    void consider(SwipeDirection d, double travel, double threshold) {
      if (!allowed.contains(d) || travel <= 0) return;
      final value = (travel / threshold).clamp(0.0, 1.0);
      if (value > best.value) best = SwipeProgress(d, value);
    }

    final across = MazlMotion.deckThreshold * size.width;
    consider(SwipeDirection.right, card.dx, across);
    consider(SwipeDirection.left, -card.dx, across);
    consider(
      SwipeDirection.up,
      -card.dy,
      MazlMotion.deckUpThreshold * size.height,
    );
    return best;
  }

  /// 0 → 1: how far the card below has come up, in proportion to the travel
  /// of the card on top.
  static double backProgress(Offset card, Size size) {
    final across = card.dx.abs() / size.width;
    final up = math.max(0.0, -card.dy) / size.height;
    return math.max(across, up).clamp(0.0, 1.0);
  }

  /// What a release does: the direction the card leaves in, or null.
  ///
  /// [finger] is the raw movement of the finger, [card] where the card is. A
  /// fling commits below the threshold only if it is fast, long enough and
  /// clearly along its axis, so a small vertical flick never becomes a like.
  static SwipeDirection? commitDirection({
    required Offset finger,
    required Offset card,
    required Velocity velocity,
    required Size size,
    required Set<SwipeDirection> allowed,
  }) {
    final dragged = progress(card, size, allowed);
    if (dragged.value >= 1) return dragged.direction;

    final v = velocity.pixelsPerSecond;
    const fast = MazlMotion.deckFlingVelocity;
    const far = MazlMotion.deckFlingMinDistance;
    const ratio = MazlMotion.deckFlingHorizontalRatio;

    if (v.dx.abs() > fast &&
        finger.dx.abs() >= far &&
        finger.dx.abs() > ratio * finger.dy.abs() &&
        v.dx.sign == finger.dx.sign) {
      final d = finger.dx > 0 ? SwipeDirection.right : SwipeDirection.left;
      if (allowed.contains(d)) return d;
    }
    if (-v.dy > fast &&
        -finger.dy >= far &&
        finger.dy.abs() > ratio * finger.dx.abs() &&
        allowed.contains(SwipeDirection.up)) {
      return SwipeDirection.up;
    }
    return null;
  }

  /// Where a committed card ends up: along its direction, far enough to be off
  /// screen, carrying the flick across the other axis.
  static Offset exitTarget({
    required SwipeDirection direction,
    required Offset card,
    required Offset velocity,
    required Size size,
  }) {
    const carry = MazlMotion.deckExitVelocityCarry;
    switch (direction) {
      case SwipeDirection.right:
      case SwipeDirection.left:
        final sign = direction == SwipeDirection.right ? 1 : -1;
        return Offset(
          sign * MazlMotion.deckExitDistance * size.width,
          card.dy + velocity.dy * carry,
        );
      case SwipeDirection.up:
        return Offset(
          card.dx + velocity.dx * carry,
          -MazlMotion.deckExitDistance * size.height,
        );
    }
  }
}
