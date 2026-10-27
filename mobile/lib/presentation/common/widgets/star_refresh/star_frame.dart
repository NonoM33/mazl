import 'dart:math' as math;

import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/motion/mazl_motion.dart';

/// What the refresh star is doing.
sealed class StarPose {
  const StarPose();
}

/// Being pulled: [progress] 0 → 1 up to [MazlMotion.refreshThreshold].
class StarPulled extends StarPose {
  const StarPulled(this.progress);
  final double progress;
}

/// Loading for [elapsed]; turns and runs as comets unless [reduced].
class StarLoading extends StarPose {
  const StarLoading(this.elapsed, {this.reduced = false});
  final Duration elapsed;
  final bool reduced;
}

/// Blooming once the refresh is done: [progress] 0 → 1 over
/// [MazlMotion.refreshBloom] (a plain fade when [reduced]).
class StarBlooming extends StarPose {
  const StarBlooming(this.progress, {this.reduced = false});
  final double progress;
  final bool reduced;
}

/// Whole and still, while the list goes back up.
class StarSettled extends StarPose {
  const StarSettled();
}

/// The visible part of one triangle's outline, as shares of its perimeter,
/// starting from its top (or bottom) tip and running clockwise.
@immutable
class StrokeSpan {
  const StrokeSpan(this.start, this.length);
  static const whole = StrokeSpan(0, 1);
  static const none = StrokeSpan(0, 0);

  final double start;
  final double length;

  @override
  bool operator ==(Object other) =>
      other is StrokeSpan && other.start == start && other.length == length;

  @override
  int get hashCode => Object.hash(start, length);
}

/// How the star is drawn at one moment: the pure geometry of « Le trait »,
/// kept apart from the painting so its rules can be tested.
@immutable
class StarFrame {
  const StarFrame({
    required this.turn,
    required this.scale,
    required this.up,
    required this.down,
    required this.fill,
  });

  /// Rotation in radians; a third of a turn looks the same as none.
  final double turn;
  final double scale;
  final StrokeSpan up;
  final StrokeSpan down;

  /// Opacity of the accent filling the star, 0 → 1.
  final double fill;

  static const whole = StarFrame(
    turn: 0,
    scale: 1,
    up: StrokeSpan.whole,
    down: StrokeSpan.whole,
    fill: 0,
  );

  static const _thirdTurn = 2 * math.pi / 3;
  static const _fillPeak = 0.85;

  factory StarFrame.of(StarPose pose) => switch (pose) {
    StarPulled(:final progress) => _pulled(progress.clamp(0.0, 1.0)),
    StarLoading(reduced: true) => whole,
    StarLoading(:final elapsed) => _loading(elapsed),
    StarBlooming(:final progress, reduced: true) => StarFrame(
      turn: 0,
      scale: 1,
      up: StrokeSpan.whole,
      down: StrokeSpan.whole,
      fill: _fillPeak * (1 - progress.clamp(0.0, 1.0)),
    ),
    StarBlooming(:final progress) => _blooming(progress.clamp(0.0, 1.0)),
    StarSettled() => whole,
  };

  /// The upward triangle draws itself, then the downward one, while the star
  /// turns upright and grows to full size.
  static StarFrame _pulled(double p) => StarFrame(
    turn: (p - 1) * math.pi / 2,
    scale: 0.6 + 0.4 * p,
    up: StrokeSpan(0, (p * 2).clamp(0.0, 1.0)),
    down: StrokeSpan(0, (p * 2 - 1).clamp(0.0, 1.0)),
    fill: 0,
  );

  static StarFrame _loading(Duration elapsed) {
    final cycles = _ratio(elapsed, MazlMotion.refreshCycle);
    final shrink = Curves.easeOutCubic.transform(
      _ratio(elapsed, MazlMotion.refreshCometShrink).clamp(0.0, 1.0),
    );
    final length = 1 - (1 - MazlMotion.refreshCometShare) * shrink;
    return StarFrame(
      turn: cycles * _thirdTurn,
      scale: 1,
      up: StrokeSpan(cycles % 1, length),
      down: StrokeSpan((cycles + 0.5) % 1, length),
      fill: 0,
    );
  }

  /// The comets close (where a whole loading turn left them), the star
  /// swells and fills, then settles.
  static StarFrame _blooming(double dn) {
    final close = Curves.easeOutCubic.transform((dn / 0.4).clamp(0.0, 1.0));
    final length =
        MazlMotion.refreshCometShare +
        (1 - MazlMotion.refreshCometShare) * close;
    final swell = math.sin(math.pi * math.min(1, dn / 0.6));
    return StarFrame(
      turn: 0,
      scale: 1 + (MazlMotion.refreshBloomScale - 1) * swell,
      up: StrokeSpan(0, length),
      down: StrokeSpan(0.5, length),
      fill: _fillPeak * math.sin(math.pi * dn),
    );
  }

  static double _ratio(Duration a, Duration b) =>
      a.inMicroseconds / b.inMicroseconds;

  @override
  bool operator ==(Object other) =>
      other is StarFrame &&
      other.turn == turn &&
      other.scale == scale &&
      other.up == up &&
      other.down == down &&
      other.fill == fill;

  @override
  int get hashCode => Object.hash(turn, scale, up, down, fill);
}
