import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../../../../core/motion/mazl_motion.dart';
import 'star_frame.dart';

/// How the hanukkiah that stands in for the star during Hanukkah is drawn at
/// one moment: same pull, loading and bloom as « Le trait », with the night's
/// candles lighting one by one instead of the triangles.
@immutable
class HanukkiahFrame {
  const HanukkiahFrame({
    required this.body,
    required this.scale,
    required this.flames,
  });

  /// Nine candle places, left to right; the shamash stands in the middle.
  static const slots = 9;
  static const shamash = 4;

  /// Share of the hanukkiah's outline drawn, 0 → 1.
  final double body;
  final double scale;

  /// Size of the flame on each of the [slots], left to right: 0 unlit, 1
  /// burning, above 1 swelling.
  final List<double> flames;

  /// The candles burning on [night] (1 to 8), left to right: they are set from
  /// the right, one more each night.
  static List<int> litSlots(int night) {
    final candles = [
      for (var slot = 0; slot < slots; slot++)
        if (slot != shamash) slot,
    ];
    return candles.sublist(candles.length - night.clamp(0, candles.length));
  }

  /// The order the flames light in: the shamash, then the newest candle (the
  /// leftmost) towards the right.
  static List<int> lightingOrder(int night) => [shamash, ...litSlots(night)];

  factory HanukkiahFrame.of(StarPose pose, int night) {
    final order = lightingOrder(night);
    List<double> each(double Function(int slot, int rank) size) => [
      for (var slot = 0; slot < slots; slot++)
        order.contains(slot) ? size(slot, order.indexOf(slot)) : 0,
    ];
    return switch (pose) {
      StarPulled(:final progress) => _pulled(
        progress.clamp(0.0, 1.0),
        order.length,
        each,
      ),
      StarLoading(reduced: true) ||
      StarBlooming(reduced: true) ||
      StarSettled() => HanukkiahFrame(
        body: 1,
        scale: 1,
        flames: each((_, _) => 1),
      ),
      StarLoading(:final elapsed) => HanukkiahFrame(
        body: 1,
        scale: 1,
        flames: each((slot, _) => _flicker(elapsed, slot)),
      ),
      StarBlooming(:final progress) => HanukkiahFrame(
        body: 1,
        scale: 1,
        flames: each(
          (_, _) =>
              1 +
              (MazlMotion.refreshBloomScale - 1) *
                  math.sin(math.pi * math.min(1, progress.clamp(0, 1) / 0.6)),
        ),
      ),
    };
  }

  /// The outline draws itself over the first half of the pull, then the
  /// flames light one after the other over the second.
  static HanukkiahFrame _pulled(
    double p,
    int flameCount,
    List<double> Function(double Function(int slot, int rank)) each,
  ) {
    final lighting = ((p - 0.5) / 0.5).clamp(0.0, 1.0);
    return HanukkiahFrame(
      body: (p * 2).clamp(0.0, 1.0),
      scale: 0.6 + 0.4 * p,
      flames: each((_, rank) => (lighting * flameCount - rank).clamp(0.0, 1.0)),
    );
  }

  /// Each flame flickers on its own, and rests at full size on every whole
  /// loading turn, where the bloom takes over.
  static double _flicker(Duration elapsed, int slot) {
    final cycles =
        elapsed.inMicroseconds / MazlMotion.refreshCycle.inMicroseconds;
    final envelope = math.sin(math.pi * (cycles % 1));
    return 1 +
        MazlMotion.refreshFlameFlicker *
            envelope *
            math.sin(2 * math.pi * (3 * cycles + slot * 0.29));
  }

  @override
  bool operator ==(Object other) =>
      other is HanukkiahFrame &&
      other.body == body &&
      other.scale == scale &&
      listEquals(other.flames, flames);

  @override
  int get hashCode => Object.hash(body, scale, Object.hashAll(flames));
}
