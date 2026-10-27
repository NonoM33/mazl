import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/motion/mazl_motion.dart';
import '../../../../l10n/l10n.dart';

/// Stroke of the thread, in logical pixels.
const typingThreadStrokeWidth = 2.0;

// Geometry of the thread, in logical pixels, for the 56 × 36 bubble.
const _sideInset = 10.0; // free space between the bubble edge and the thread
const _rippleHeight = 1.5; // amplitude of the ripple along the thread
const _rippleWaves = 1.5; // ripples along the whole thread
const _loopTurnAdvance = 2.0; // forward travel per radian across the knot
const _loopWidth = 9.0; // how far the knot swings sideways when tied
const _loopHeight = 6.0; // half the height of the loop when tied
const _straightSamples = 20; // points on each straight side
const _loopSamples = 48; // points across the knot

/// The thread of « … écrit » at cycle time [t] in [0, 1), as a polyline from
/// its left end to its right end, inside [size].
///
/// It ripples between two anchored ends and ties a knot at the centre, as on
/// the tsitsit: the knot is a loop, so the thread crosses itself while it is
/// tied and never when it is undone. A pure function of [t], periodic in 1:
/// the drawing at 0 and at 1 is the same, so the loop never jumps.
List<Offset> typingThreadPoints(double t, Size size) {
  final left = _sideInset;
  final right = size.width - _sideInset;
  final centerX = size.width / 2;
  final centerY = size.height / 2;
  final knot = _knotTied(t);
  final loopHalfSpan = _loopTurnAdvance * math.pi;
  // The loop rises above the thread: the thread sags under it (see onThread)
  // so the knot stays centred, while both ends stay anchored.

  Offset onThread(double x, double y) {
    final along = (x - left) / (right - left);
    final ripple =
        _rippleHeight *
        (1 - 0.5 * knot) *
        math.sin(math.pi * along.clamp(0.0, 1.0)) *
        math.sin(2 * math.pi * (_rippleWaves * along - t));
    final sag = _loopHeight * knot * math.sin(math.pi * along.clamp(0.0, 1.0));
    return Offset(x, y + ripple + sag);
  }

  final points = <Offset>[];
  for (var i = 0; i < _straightSamples; i++) {
    final x = left + (centerX - loopHalfSpan - left) * i / _straightSamples;
    points.add(onThread(x, centerY));
  }
  for (var i = 0; i <= _loopSamples; i++) {
    final turn = -math.pi + 2 * math.pi * i / _loopSamples;
    points.add(
      onThread(
        centerX + _loopTurnAdvance * turn - _loopWidth * knot * math.sin(turn),
        centerY - _loopHeight * knot * (1 + math.cos(turn)),
      ),
    );
  }
  for (var i = 1; i <= _straightSamples; i++) {
    final x =
        centerX +
        loopHalfSpan +
        (right - centerX - loopHalfSpan) * i / _straightSamples;
    points.add(onThread(x, centerY));
  }
  return points;
}

/// 0 while the thread is untied (with a short rest at both ends of the
/// cycle), 1 while the knot is tied, easing in and out between the two.
double _knotTied(double t) {
  final bell = 0.5 - 0.5 * math.cos(2 * math.pi * t);
  final x = ((bell - 0.1) / 0.8).clamp(0.0, 1.0);
  return x * x * (3 - 2 * x);
}

/// Draws [typingThreadPoints] at cycle time [t] in a single [color].
class TypingThreadPainter extends CustomPainter {
  const TypingThreadPainter({required this.t, required this.color});

  final double t;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final points = typingThreadPoints(t, size);
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = typingThreadStrokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(TypingThreadPainter old) =>
      old.t != t || old.color != color;
}

/// « Noémie écrit… » as a received bubble: a tekhelet thread that ties a knot
/// and undoes it, like the ones of the tsitsit (docs/design/CHAT.md §3).
/// Still, with the knot tied, when animations are disabled.
class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: MazlMotion.typingThreadCycle,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MazlMotion.reduced(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final reduced = MazlMotion.reduced(context);
    return Semantics(
      label: context.l10n.chatTypingSemantics,
      child: Container(
        width: 56,
        height: 36,
        decoration: BoxDecoration(
          color: scheme.surfaceContainer,
          borderRadius: const BorderRadiusDirectional.only(
            topStart: Radius.circular(22),
            topEnd: Radius.circular(22),
            bottomEnd: Radius.circular(22),
            bottomStart: Radius.circular(6),
          ),
        ),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) => CustomPaint(
            painter: TypingThreadPainter(
              t: reduced
                  ? MazlMotion.typingThreadKnotFormed
                  : _controller.value,
              color: scheme.primary,
            ),
          ),
        ),
      ),
    );
  }
}
