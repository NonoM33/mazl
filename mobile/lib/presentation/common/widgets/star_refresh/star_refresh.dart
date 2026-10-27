import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../../../../core/layout/fold_state.dart';
import '../../../../core/motion/mazl_motion.dart';
import 'star_frame.dart';
import 'star_painter.dart';

/// Pull to refresh with the Star of David « Le trait » (docs/design/MOUVEMENT.md
/// §7bis): the star draws itself as the list is pulled, turns as two comets
/// while [onRefresh] runs, blooms when it is done, and the list goes back up.
///
/// Drop-in for [RefreshIndicator]. Every vertical list below it bounces and can
/// be pulled even when it is shorter than the screen. The star sits above the
/// list that is pulled (the page of a book held half open), never in the fold.
class StarRefresh extends StatefulWidget {
  const StarRefresh({super.key, required this.onRefresh, required this.child});

  final RefreshCallback onRefresh;
  final Widget child;

  @override
  State<StarRefresh> createState() => _StarRefreshState();
}

enum _Stage { idle, pulling, loading, blooming, retracting }

class _StarRefreshState extends State<StarRefresh>
    with TickerProviderStateMixin {
  static const _physics = BouncingScrollPhysics(
    parent: AlwaysScrollableScrollPhysics(),
  );

  late final Ticker _clock = createTicker(_tick);
  late final AnimationController _retract = AnimationController.unbounded(
    vsync: this,
  )..addListener(_rebuild);

  _Stage _stage = _Stage.idle;
  double _overscroll = 0;
  bool _dragging = false;
  bool _armed = false;
  bool _reduced = false;
  bool _refreshDone = false;
  Duration _elapsed = Duration.zero;
  Duration? _loadEnd;
  Rect? _fold;

  /// Horizontal centre and top of the pulled list, in this box.
  double _starX = 0;
  double _listTop = 0;

  @override
  void dispose() {
    _clock.dispose();
    _retract.dispose();
    super.dispose();
  }

  void _rebuild() => setState(() {});

  /// How far the list is held down on top of its own overscroll: up to
  /// [MazlMotion.refreshHold] while loading, so the bounce never closes the
  /// gap under the star.
  double get _hold => switch (_stage) {
    _Stage.loading ||
    _Stage.blooming => math.max(0, MazlMotion.refreshHold - _overscroll),
    _Stage.retracting => math.max(0, _retract.value),
    _Stage.idle || _Stage.pulling => 0,
  };

  Duration get _bloomDuration =>
      _reduced ? MazlMotion.reducedFade : MazlMotion.refreshBloom;

  StarPose get _pose => switch (_stage) {
    _Stage.idle ||
    _Stage.pulling => StarPulled(_overscroll / MazlMotion.refreshThreshold),
    _Stage.loading => StarLoading(
      _loadEnd == null || _elapsed < _loadEnd! ? _elapsed : _loadEnd!,
      reduced: _reduced,
    ),
    _Stage.blooming => StarBlooming(
      (_elapsed - _loadEnd!).inMicroseconds / _bloomDuration.inMicroseconds,
      reduced: _reduced,
    ),
    _Stage.retracting => const StarSettled(),
  };

  bool _onScroll(ScrollNotification notification) {
    if (notification.depth != 0 || notification.metrics.axis != Axis.vertical) {
      return false;
    }
    final metrics = notification.metrics;
    final over = math.max(0.0, metrics.minScrollExtent - metrics.pixels);
    var released = false;
    if (notification is ScrollUpdateNotification) {
      if (notification.dragDetails != null) {
        _dragging = true;
      } else if (_dragging) {
        released = true;
      }
    } else if (notification is ScrollEndNotification && _dragging) {
      released = true;
    }
    // Decide on what the finger left: the first frame after it may already
    // have bounced the list back to its top.
    if (released) {
      _dragging = false;
      _release();
    }
    _follow(over, notification.context);
    return false;
  }

  void _follow(double over, BuildContext? list) {
    if (_stage == _Stage.idle && _dragging && over > 0) {
      _stage = _Stage.pulling;
      _placeStar(list);
    }
    if (_stage == _Stage.pulling) {
      if (_dragging) {
        final armed = over >= MazlMotion.refreshThreshold;
        if (armed && !_armed) HapticFeedback.selectionClick();
        _armed = armed;
      } else if (over == 0) {
        _stage = _Stage.idle;
      }
    }
    if (over != _overscroll || _stage == _Stage.idle) {
      setState(() => _overscroll = over);
    }
  }

  void _release() {
    if (_stage != _Stage.pulling || !_armed) return;
    _armed = false;
    _reduced = MazlMotion.reduced(context);
    _refreshDone = false;
    _loadEnd = null;
    _elapsed = Duration.zero;
    setState(() => _stage = _Stage.loading);
    _clock.start();
    _runRefresh();
  }

  Future<void> _runRefresh() async {
    try {
      await widget.onRefresh();
    } finally {
      _refreshDone = true;
    }
  }

  void _tick(Duration elapsed) {
    _elapsed = elapsed;
    if (_stage == _Stage.loading && _refreshDone) {
      _loadEnd ??= _endOfLoading(elapsed);
      if (elapsed >= _loadEnd!) {
        _stage = _Stage.blooming;
        HapticFeedback.lightImpact();
      }
    }
    if (_stage == _Stage.blooming && elapsed - _loadEnd! >= _bloomDuration) {
      _clock.stop();
      _startRetract();
    }
    setState(() {});
  }

  /// Loading ends on a whole turn (the star upright) and lasts at least
  /// [MazlMotion.refreshMinCycles] turns; at once under reduced motion.
  Duration _endOfLoading(Duration now) {
    if (_reduced) return now;
    final cycle = MazlMotion.refreshCycle.inMicroseconds;
    final turns = math.max(
      MazlMotion.refreshMinCycles,
      (now.inMicroseconds / cycle).ceil(),
    );
    return Duration(microseconds: turns * cycle);
  }

  void _startRetract() {
    final from = _hold;
    _stage = _Stage.retracting;
    _retract.value = from;
    final run = _reduced
        ? _retract.animateTo(
            0,
            duration: MazlMotion.reducedReturn,
            curve: MazlMotion.reducedReturnCurve,
          )
        : _retract.animateWith(
            SpringSimulation(
              MazlMotion.spring,
              from,
              0,
              0,
              tolerance: MazlMotion.springTolerance,
            ),
          );
    run.whenCompleteOrCancel(() {
      if (!mounted || _stage != _Stage.retracting) return;
      setState(() => _stage = _Stage.idle);
    });
  }

  /// Above the middle of the pulled [list]; out of the fold when the list
  /// runs across it (the wider side wins).
  void _placeStar(BuildContext? list) {
    final own = context.findRenderObject();
    final box = list?.findRenderObject();
    if (own is! RenderBox || box is! RenderBox || !box.hasSize) {
      _starX = (own is RenderBox && own.hasSize) ? own.size.width / 2 : 0;
      _listTop = 0;
      return;
    }
    final left = box.localToGlobal(Offset.zero);
    final right = left.dx + box.size.width;
    var centre = left.dx + box.size.width / 2;
    final fold = _fold;
    const half = StarPainter.extent / 2;
    if (fold != null &&
        fold.height > fold.width &&
        centre + half > fold.left &&
        centre - half < fold.right) {
      final lead = fold.left - left.dx;
      final trail = right - fold.right;
      centre = lead >= trail ? left.dx + lead / 2 : fold.right + trail / 2;
    }
    final local = own.globalToLocal(Offset(centre, left.dy));
    _starX = local.dx;
    _listTop = local.dy;
  }

  @override
  Widget build(BuildContext context) {
    _fold = FoldScope.of(context).activeDivision;
    final hold = _hold;
    final gap = _overscroll + hold;
    return NotificationListener<ScrollNotification>(
      onNotification: _onScroll,
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(physics: _physics),
        child: Stack(
          fit: StackFit.passthrough,
          children: [
            ClipRect(
              child: Transform.translate(
                offset: Offset(0, hold),
                child: widget.child,
              ),
            ),
            if (_stage != _Stage.idle)
              Positioned(
                left: _starX - StarPainter.extent / 2,
                top: _listTop + gap / 2 - StarPainter.extent / 2,
                width: StarPainter.extent,
                height: StarPainter.extent,
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: StarPainter(
                      frame: StarFrame.of(_pose),
                      color: Theme.of(context).colorScheme.primary,
                      opacity: (gap / MazlMotion.refreshFadeInGap).clamp(
                        0.0,
                        1.0,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
