import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../motion/mazl_motion.dart';

/// Pull-to-refresh of the whole app: replaces the Material spinner by a
/// Star of David drawn with a hairline stroke (docs/design/MOUVEMENT.md §9).
///
/// While the finger pulls, the upward triangle is traced first, then the
/// downward one; at the trigger threshold both are complete and interlaced.
/// While loading, the star turns slowly in the accent colour; it fades out
/// when the load ends. Under « Réduire les animations » nothing turns and
/// nothing is traced: the complete star fades in and stays still.
class MagenDavidRefresh extends StatefulWidget {
  const MagenDavidRefresh({
    super.key,
    required this.onRefresh,
    required this.child,
    this.color,
  });

  final Future<void> Function() onRefresh;
  final Widget child;

  /// Stroke colour; the theme's accent (tekhelet) when null.
  final Color? color;

  /// One turn of the loading star.
  static const turnDuration = Duration(milliseconds: 2400);

  /// Fade-out at the end of the load.
  static const fadeOutDuration = Duration(milliseconds: 250);

  /// Size of the star and distance of its centre from the top edge.
  static const starSize = 36.0;
  static const restingTop = 16.0;

  /// Share of the viewport that must be pulled to arm the refresh (the same
  /// 25 % as [RefreshIndicator]).
  static const pullShare = 0.25;

  @override
  State<MagenDavidRefresh> createState() => _MagenDavidRefreshState();
}

enum _Phase { idle, dragging, refreshing, leaving }

class _MagenDavidRefreshState extends State<MagenDavidRefresh>
    with SingleTickerProviderStateMixin {
  final _pull = ValueNotifier<double>(0);
  late final AnimationController _turn = AnimationController(
    vsync: this,
    duration: MagenDavidRefresh.turnDuration,
  );
  _Phase _phase = _Phase.idle;
  double _overscroll = 0;

  @override
  void dispose() {
    _turn.dispose();
    _pull.dispose();
    super.dispose();
  }

  void _setPhase(_Phase phase) {
    if (!mounted || phase == _phase) return;
    setState(() => _phase = phase);
    final turning = phase == _Phase.refreshing || phase == _Phase.leaving;
    if (phase == _Phase.refreshing && !MazlMotion.reduced(context)) {
      _turn.repeat();
    } else if (!turning) {
      _turn.stop();
      _turn.value = 0;
    }
  }

  void _onStatus(RefreshIndicatorStatus? status) {
    switch (status) {
      case RefreshIndicatorStatus.drag:
        _pull.value = math.min(_pull.value, 0.98);
        _setPhase(_Phase.dragging);
      case RefreshIndicatorStatus.armed:
        _pull.value = 1;
        HapticFeedback.lightImpact();
        _setPhase(_Phase.dragging);
      case RefreshIndicatorStatus.snap:
      case RefreshIndicatorStatus.refresh:
        _pull.value = 1;
        _setPhase(_Phase.refreshing);
      case RefreshIndicatorStatus.done:
      case RefreshIndicatorStatus.canceled:
        _setPhase(_phase == _Phase.idle ? _Phase.idle : _Phase.leaving);
      case null:
        break;
    }
  }

  bool _onScroll(ScrollNotification n) {
    if (n.depth != 0 || n.metrics.axis != Axis.vertical) return false;
    if (_phase == _Phase.refreshing || _phase == _Phase.leaving) return false;
    if (n is OverscrollNotification && n.dragDetails != null) {
      _overscroll += math.max(0, -n.overscroll);
    } else if (n is ScrollUpdateNotification) {
      final beyond = n.metrics.minScrollExtent - n.metrics.pixels;
      if (beyond > 0) {
        _overscroll = beyond;
      } else if (n.dragDetails != null) {
        _overscroll = 0;
      }
    } else if (n is ScrollEndNotification) {
      _overscroll = 0;
    }
    final reach = n.metrics.viewportDimension * MagenDavidRefresh.pullShare;
    _pull.value = reach > 0 ? math.min(_overscroll / reach, 0.98) : 0;
    return false;
  }

  void _onFadeEnd() {
    if (_phase == _Phase.leaving) {
      _pull.value = 0;
      _overscroll = 0;
      _setPhase(_Phase.idle);
    }
  }

  @override
  Widget build(BuildContext context) {
    final reduced = MazlMotion.reduced(context);
    final color = widget.color ?? Theme.of(context).colorScheme.primary;
    return Stack(
      children: [
        NotificationListener<ScrollNotification>(
          onNotification: _onScroll,
          child: RefreshIndicator.noSpinner(
            onRefresh: widget.onRefresh,
            onStatusChange: _onStatus,
            child: widget.child,
          ),
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: IgnorePointer(child: _overlay(color, reduced)),
        ),
      ],
    );
  }

  Widget _overlay(Color color, bool reduced) {
    return ValueListenableBuilder<double>(
      valueListenable: _pull,
      builder: (context, pull, _) {
        final leaving = _phase == _Phase.leaving;
        final visible =
            _phase == _Phase.refreshing ||
            (_phase == _Phase.dragging && pull > 0);
        // Reduced motion: the complete star, never a partial tracing.
        final progress = reduced ? 1.0 : pull;
        final opacity = visible
            ? (reduced ? 1.0 : math.min(1.0, pull * 3))
            : 0.0;
        final top = _phase == _Phase.dragging && !reduced
            ? -MagenDavidRefresh.starSize +
                  (MagenDavidRefresh.restingTop + MagenDavidRefresh.starSize) *
                      Curves.easeOut.transform(pull)
            : MagenDavidRefresh.restingTop;
        final duration = leaving
            ? (reduced
                  ? MazlMotion.reducedFade
                  : MagenDavidRefresh.fadeOutDuration)
            : (reduced ? MazlMotion.reducedFade : Duration.zero);
        return Semantics(
          label: _phase == _Phase.idle ? null : 'Actualisation',
          container: true,
          child: Align(
            alignment: Alignment.topCenter,
            child: Transform.translate(
              offset: Offset(0, top),
              child: AnimatedOpacity(
                opacity: opacity,
                duration: duration,
                onEnd: _onFadeEnd,
                child: AnimatedBuilder(
                  animation: _turn,
                  builder: (context, _) => CustomPaint(
                    size: const Size.square(MagenDavidRefresh.starSize),
                    painter: MagenDavidPainter(
                      progress: progress,
                      color: color,
                      rotation:
                          Curves.easeInOut.transform(_turn.value) * 2 * math.pi,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Draws the Star of David as two triangles with a hairline stroke.
/// [progress] 0 → nothing, 0.5 → upward triangle complete, 1 → both complete.
class MagenDavidPainter extends CustomPainter {
  const MagenDavidPainter({
    required this.progress,
    required this.color,
    this.rotation = 0,
    this.strokeWidth = 1.5,
  });

  final double progress;
  final Color color;

  /// Radians.
  final double rotation;
  final double strokeWidth;

  /// Share of the upward triangle drawn (traced during the first half).
  double get upwardFraction => (progress * 2).clamp(0.0, 1.0);

  /// Share of the downward triangle drawn (traced during the second half).
  double get downwardFraction => (progress * 2 - 1).clamp(0.0, 1.0);

  double _radius(Size size) => size.shortestSide / 2 - strokeWidth;

  Path _triangle(Size size, double startDegrees) {
    final c = size.center(Offset.zero);
    final r = _radius(size);
    Offset vertex(int i) {
      final a = (startDegrees + 120.0 * i) * math.pi / 180;
      return c + Offset(math.cos(a), math.sin(a)) * r;
    }

    return Path()
      ..moveTo(vertex(0).dx, vertex(0).dy)
      ..lineTo(vertex(1).dx, vertex(1).dy)
      ..lineTo(vertex(2).dx, vertex(2).dy)
      ..close();
  }

  Path _partial(Path full, double fraction) {
    final out = Path();
    if (fraction <= 0) return out;
    for (final metric in full.computeMetrics()) {
      out.addPath(metric.extractPath(0, metric.length * fraction), Offset.zero);
    }
    return out;
  }

  /// The part of the upward triangle drawn at the current [progress].
  Path upwardPath(Size size) => _partial(_triangle(size, -90), upwardFraction);

  /// The part of the downward triangle drawn at the current [progress].
  Path downwardPath(Size size) =>
      _partial(_triangle(size, 90), downwardFraction);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true
      ..color = color;
    final c = size.center(Offset.zero);
    canvas
      ..save()
      ..translate(c.dx, c.dy)
      ..rotate(rotation)
      ..translate(-c.dx, -c.dy)
      ..drawPath(upwardPath(size), paint)
      ..drawPath(downwardPath(size), paint)
      ..restore();
  }

  @override
  bool shouldRepaint(MagenDavidPainter old) =>
      old.progress != progress ||
      old.color != color ||
      old.rotation != rotation ||
      old.strokeWidth != strokeWidth;
}
