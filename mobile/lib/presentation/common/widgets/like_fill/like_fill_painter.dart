import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// A disc centred on [center] (the touch point, in the button's own
/// coordinates) that grows with [progress] until it covers the farthest corner
/// of the button. The button's shape clips it. [opacity] only moves under
/// reduced motion, where the disc is never partial.
class LikeFillPainter extends CustomPainter {
  const LikeFillPainter({
    required this.center,
    required this.progress,
    required this.color,
    this.opacity = 1,
  });

  final Offset center;

  /// 0 = no disc, 1 = the disc covers the whole button.
  final double progress;
  final Color color;
  final double opacity;

  /// Radius that reaches the farthest corner of [size] from [center].
  static double coverRadius(Offset center, Size size) {
    final corners = [
      Offset.zero,
      Offset(size.width, 0),
      Offset(0, size.height),
      Offset(size.width, size.height),
    ];
    return corners.map((c) => (c - center).distance).reduce(math.max);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || opacity <= 0) return;
    canvas.drawCircle(
      center,
      coverRadius(center, size) * progress,
      Paint()..color = color.withValues(alpha: color.a * opacity),
    );
  }

  @override
  bool shouldRepaint(LikeFillPainter old) =>
      old.center != center ||
      old.progress != progress ||
      old.color != color ||
      old.opacity != opacity;
}
