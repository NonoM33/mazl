import 'dart:math' as math;

import 'package:flutter/rendering.dart';

import 'star_frame.dart';

/// Paints the Star of David of [frame]: two triangles of [color], each showing
/// the span of its outline the frame asks for, filled when it blooms.
class StarPainter extends CustomPainter {
  const StarPainter({
    required this.frame,
    required this.color,
    this.opacity = 1,
  });

  /// Tip-to-centre radius of each triangle.
  static const radius = 18.0;

  /// Room the star needs at its biggest bloom, stroke included.
  static const extent = 56.0;

  static const _strokeWidth = 2.4;

  final StarFrame frame;
  final Color color;
  final double opacity;

  static final Path _up = _triangle(-90);
  static final Path _down = _triangle(90);
  static final Path _star = Path.combine(PathOperation.union, _up, _down);

  static Path _triangle(double firstTipDegrees) {
    final path = Path();
    for (var k = 0; k < 3; k++) {
      final angle = (firstTipDegrees + 120 * k) * math.pi / 180;
      final tip = Offset(radius * math.cos(angle), radius * math.sin(angle));
      k == 0 ? path.moveTo(tip.dx, tip.dy) : path.lineTo(tip.dx, tip.dy);
    }
    return path..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (opacity <= 0) return;
    canvas
      ..save()
      ..translate(size.width / 2, size.height / 2)
      ..rotate(frame.turn)
      ..scale(frame.scale);
    if (frame.fill > 0) {
      canvas.drawPath(
        _star,
        Paint()..color = color.withValues(alpha: frame.fill * opacity),
      );
    }
    final stroke = Paint()
      ..color = color.withValues(alpha: opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    canvas
      ..drawPath(_spanOf(_up, frame.up), stroke)
      ..drawPath(_spanOf(_down, frame.down), stroke)
      ..restore();
  }

  /// The part of [triangle]'s outline [span] covers, wrapping past its start.
  static Path _spanOf(Path triangle, StrokeSpan span) {
    if (span.length >= 1) return triangle;
    final metric = triangle.computeMetrics().first;
    final total = metric.length;
    final start = (span.start % 1) * total;
    final end = start + span.length * total;
    final path = metric.extractPath(start, math.min(end, total));
    if (end > total) {
      path.addPath(metric.extractPath(0, end - total), Offset.zero);
    }
    return path;
  }

  @override
  bool shouldRepaint(StarPainter oldDelegate) =>
      oldDelegate.frame != frame ||
      oldDelegate.color != color ||
      oldDelegate.opacity != opacity;
}
