import 'dart:math' as math;

import 'package:flutter/rendering.dart';

import 'hanukkiah_frame.dart';

/// Paints the hanukkiah of [frame] in the room of the refresh star: the body
/// in [color] (the accent), the flames in [flameColor].
class HanukkiahPainter extends CustomPainter {
  const HanukkiahPainter({
    required this.frame,
    required this.color,
    required this.flameColor,
    this.opacity = 1,
  });

  static const _gap = 6.0;
  static const _armY = 6.0;
  static const _candleTop = -4.0;
  static const _shamashTop = -10.0;
  static const _strokeWidth = 2.0;

  final HanukkiahFrame frame;
  final Color color;
  final Color flameColor;
  final double opacity;

  static double _x(int slot) => (slot - HanukkiahFrame.shamash) * _gap;

  static double _top(int slot) =>
      slot == HanukkiahFrame.shamash ? _shamashTop : _candleTop;

  static final Path _body = () {
    final path = Path();
    final edge = _x(HanukkiahFrame.slots - 1);
    path
      ..moveTo(-edge, _armY)
      ..lineTo(edge, _armY)
      ..moveTo(0, _armY)
      ..lineTo(0, 18)
      ..moveTo(-8, 18)
      ..lineTo(8, 18);
    for (var slot = 0; slot < HanukkiahFrame.slots; slot++) {
      path
        ..moveTo(_x(slot), _armY)
        ..lineTo(_x(slot), _top(slot));
    }
    return path;
  }();

  @override
  void paint(Canvas canvas, Size size) {
    if (opacity <= 0) return;
    canvas
      ..save()
      ..translate(size.width / 2, size.height / 2)
      ..scale(frame.scale);
    final stroke = Paint()
      ..color = color.withValues(alpha: opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(_drawn(frame.body), stroke);
    final flame = Paint()..color = flameColor.withValues(alpha: opacity);
    for (var slot = 0; slot < HanukkiahFrame.slots; slot++) {
      final size = frame.flames[slot];
      if (size > 0) canvas.drawPath(_flame(slot, size), flame);
    }
    canvas.restore();
  }

  /// The share [body] of the outline, stroke after stroke.
  static Path _drawn(double body) {
    if (body >= 1) return _body;
    final metrics = _body.computeMetrics().toList();
    var left = body * metrics.fold(0.0, (sum, m) => sum + m.length);
    final path = Path();
    for (final metric in metrics) {
      if (left <= 0) break;
      path.addPath(
        metric.extractPath(0, math.min(left, metric.length)),
        Offset.zero,
      );
      left -= metric.length;
    }
    return path;
  }

  /// A drop standing on the wick of [slot], [size] times its full height.
  static Path _flame(int slot, double size) {
    final base = Offset(_x(slot), _top(slot) - 1.5);
    final height = 6.0 * size;
    final half = 1.8 * math.min(size, 1.2);
    return Path()
      ..moveTo(base.dx, base.dy - height)
      ..quadraticBezierTo(
        base.dx + half * 1.6,
        base.dy - height * 0.35,
        base.dx,
        base.dy,
      )
      ..quadraticBezierTo(
        base.dx - half * 1.6,
        base.dy - height * 0.35,
        base.dx,
        base.dy - height,
      )
      ..close();
  }

  @override
  bool shouldRepaint(HanukkiahPainter oldDelegate) =>
      oldDelegate.frame != frame ||
      oldDelegate.color != color ||
      oldDelegate.flameColor != flameColor ||
      oldDelegate.opacity != opacity;
}
