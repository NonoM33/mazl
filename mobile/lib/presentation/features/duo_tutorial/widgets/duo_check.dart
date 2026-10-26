import 'package:flutter/material.dart';

import '../../../../core/motion/mazl_motion.dart';
import '../../../../core/theme/app_colors.dart';

/// La petite coche de réussite : un disque tekhelet et un trait blanc qui se
/// trace d'un geste. Sous « Réduire les animations », elle apparaît tracée.
class DuoCheck extends StatelessWidget {
  const DuoCheck({super.key, this.size = 22});

  final double size;

  static const _drawDuration = Duration(milliseconds: 480);

  @override
  Widget build(BuildContext context) {
    final duration = MazlMotion.reduced(context)
        ? Duration.zero
        : _drawDuration;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, progress, _) => CustomPaint(
        size: Size.square(size),
        painter: _CheckPainter(progress),
      ),
    );
  }
}

class _CheckPainter extends CustomPainter {
  const _CheckPainter(this.progress);

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    canvas.drawCircle(
      size.center(Offset.zero),
      s / 2 * Curves.easeOut.transform((progress * 2).clamp(0, 1)),
      Paint()..color = AppColors.tekhelet,
    );
    final tick = Path()
      ..moveTo(s * 0.28, s * 0.52)
      ..lineTo(s * 0.44, s * 0.67)
      ..lineTo(s * 0.73, s * 0.35);
    final stroke = ((progress - 0.35) / 0.65).clamp(0.0, 1.0);
    final metric = tick.computeMetrics().first;
    canvas.drawPath(
      metric.extractPath(0, metric.length * stroke),
      Paint()
        ..color = AppColors.paper
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.1
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_CheckPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
