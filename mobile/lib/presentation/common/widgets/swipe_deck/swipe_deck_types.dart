import 'dart:async';

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/widgets.dart';

/// The directions a card can leave in. Down is not one of them: it is always
/// resisted, then the card springs back.
enum SwipeDirection { left, right, up }

/// How far the top card is from committing, 0 → 1, and in which direction.
@immutable
class SwipeProgress {
  const SwipeProgress(this.direction, this.value);

  static const none = SwipeProgress(null, 0);

  final SwipeDirection? direction;
  final double value;

  /// The progress toward [other], 0 when the card is not heading there.
  double of(SwipeDirection other) => direction == other ? value : 0;

  @override
  bool operator ==(Object other) =>
      other is SwipeProgress &&
      other.direction == direction &&
      other.value == value;

  @override
  int get hashCode => Object.hash(direction, value);
}

/// A progress that never moves: what a card that is not on top follows.
class IdleSwipeProgress implements ValueListenable<SwipeProgress> {
  const IdleSwipeProgress();

  @override
  SwipeProgress get value => SwipeProgress.none;

  @override
  void addListener(VoidCallback listener) {}

  @override
  void removeListener(VoidCallback listener) {}
}

/// What the white disc in the corner of the card shows for one direction.
@immutable
class SwipeIntent {
  const SwipeIntent({required this.icon, required this.color});

  final IconData icon;
  final Color color;
}

/// The deck's side of the [SwipeDeckController]: what the controller drives.
abstract interface class SwipeDeckHandle {
  Future<bool> swipe(SwipeDirection direction);
  Future<bool> undo();
  Future<void> bringBack();
}

/// Drives a `SwipeDeck` from outside (buttons, undo) and exposes the progress
/// of the gesture in progress, so the buttons under the card can follow it.
class SwipeDeckController {
  /// The gesture in progress; [SwipeProgress.none] at rest.
  final ValueNotifier<SwipeProgress> progress = ValueNotifier(
    SwipeProgress.none,
  );

  SwipeDeckHandle? _deck;

  /// Called by the deck that owns this controller.
  void attach(SwipeDeckHandle deck) => _deck = deck;

  void detach(SwipeDeckHandle deck) {
    if (identical(_deck, deck)) _deck = null;
  }

  /// Throws the top card, as a finger would. False when the card stayed: the
  /// direction is not allowed, the deck is busy, or the parent refused.
  Future<bool> swipe(SwipeDirection direction) =>
      _deck?.swipe(direction) ?? Future.value(false);

  /// Brings the last card back from the side it left. False when there is none.
  Future<bool> undo() => _deck?.undo() ?? Future.value(false);

  /// Springs the top card back to its place, from wherever it is. For a parent
  /// that decides to refuse an action after the fact.
  Future<void> bringBack() => _deck?.bringBack() ?? Future.value();

  void dispose() => progress.dispose();
}

/// Decides, when a card is about to leave, whether it may. Synchronous or not.
typedef SwipeVerdict = FutureOr<bool> Function(int index, SwipeDirection d);
