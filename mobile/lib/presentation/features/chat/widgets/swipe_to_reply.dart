import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/motion/mazl_motion.dart';
import '../../../common/widgets/directional_icon.dart';

/// Drag a row toward the END of the screen to reply (to the right in French,
/// to the left in Hebrew; docs/design/CHAT.md §6): the row follows the finger
/// up to [threshold], then resists up to [MazlMotion.replyMaxOffset].
/// A reply arrow appears in the START margin and, at the threshold, pops and
/// turns accent with a light haptic; releasing past it replies. The row goes
/// home on a spring seeded with the release velocity.
class SwipeToReply extends StatefulWidget {
  const SwipeToReply({
    super.key,
    required this.child,
    required this.onReply,
    this.enabled = true,
  });

  static const threshold = MazlMotion.replyThreshold;

  final Widget child;
  final VoidCallback onReply;
  final bool enabled;

  @override
  State<SwipeToReply> createState() => _SwipeToReplyState();
}

class _SwipeToReplyState extends State<SwipeToReply>
    with TickerProviderStateMixin {
  /// Finger travel that puts the row at [MazlMotion.replyMaxOffset]; beyond it
  /// the finger can go on without the row (and a reversal answers at once).
  static const _maxTravel =
      MazlMotion.replyThreshold +
      (MazlMotion.replyMaxOffset - MazlMotion.replyThreshold) /
          MazlMotion.replyResistance;

  late final AnimationController _home = AnimationController.unbounded(
    vsync: this,
  )..addListener(() => setState(() => _dx = _home.value));
  late final AnimationController _pop = AnimationController(
    vsync: this,
    duration: MazlMotion.popDuration,
  );
  late final Animation<double> _popScale = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween(
        begin: 1.0,
        end: MazlMotion.popScale,
      ).chain(CurveTween(curve: Curves.easeOut)),
      weight: 1,
    ),
    TweenSequenceItem(
      tween: Tween(
        begin: MazlMotion.popScale,
        end: 1.0,
      ).chain(CurveTween(curve: Curves.easeIn)),
      weight: 1,
    ),
  ]).animate(_pop);

  /// How far the row has moved toward the END side, always >= 0.
  double _dx = 0;
  double _travel = 0;
  bool _armed = false;

  @override
  void dispose() {
    _home.dispose();
    _pop.dispose();
    super.dispose();
  }

  double _rowOffset(double travel, {required bool reduced}) {
    if (travel <= MazlMotion.replyThreshold) return travel;
    if (reduced) return MazlMotion.replyThreshold;
    return (MazlMotion.replyThreshold +
            (travel - MazlMotion.replyThreshold) * MazlMotion.replyResistance)
        .clamp(0.0, MazlMotion.replyMaxOffset);
  }

  void _start(DragStartDetails _) {
    _home.stop();
    _travel = _dx.clamp(0.0, MazlMotion.replyThreshold);
    if (_dx > MazlMotion.replyThreshold) {
      _travel =
          MazlMotion.replyThreshold +
          (_dx - MazlMotion.replyThreshold) / MazlMotion.replyResistance;
    }
  }

  /// +1 when the end side is on the right (left to right), -1 on the left.
  double get _toEnd =>
      Directionality.of(context) == TextDirection.rtl ? -1.0 : 1.0;

  void _update(DragUpdateDetails d) {
    final reduced = MazlMotion.reduced(context);
    _travel = (_travel + d.delta.dx * _toEnd).clamp(0.0, _maxTravel);
    final next = _rowOffset(_travel, reduced: reduced);
    final armed = next >= MazlMotion.replyThreshold;
    if (armed && !_armed) {
      HapticFeedback.lightImpact();
      if (!reduced) _pop.forward(from: 0);
    }
    setState(() {
      _dx = next;
      _armed = armed;
    });
  }

  void _cancel() {
    _armed = false;
    _goHome(0);
  }

  void _end(DragEndDetails details) {
    if (_armed) widget.onReply();
    _armed = false;
    _goHome(details.velocity.pixelsPerSecond.dx * _toEnd);
  }

  void _goHome(double fingerVelocity) {
    if (_dx == 0) return;
    _home.value = _dx;
    if (MazlMotion.reduced(context)) {
      _home.animateTo(
        0,
        duration: MazlMotion.reducedReturn,
        curve: Curves.easeOutCubic,
      );
      return;
    }
    // Past the threshold the row moves at a fraction of the finger's speed.
    final rowVelocity = _dx > MazlMotion.replyThreshold
        ? fingerVelocity * MazlMotion.replyResistance
        : fingerVelocity;
    _home
        .animateWith(SpringSimulation(MazlMotion.spring, _dx, 0, rowVelocity))
        .then((_) {
          if (mounted) setState(() => _dx = 0);
        });
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;
    final scheme = Theme.of(context).colorScheme;
    final progress = (_dx / MazlMotion.replyThreshold).clamp(0.0, 1.0);
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragStart: _start,
      onHorizontalDragUpdate: _update,
      onHorizontalDragEnd: _end,
      onHorizontalDragCancel: _cancel,
      child: Stack(
        children: [
          if (_dx > 0)
            Positioned.fill(
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Padding(
                  padding: const EdgeInsetsDirectional.only(start: 20),
                  child: Opacity(
                    opacity: progress,
                    child: Transform.scale(
                      scale: 0.6 + 0.4 * progress,
                      child: ScaleTransition(
                        key: const Key('reply-icon-pop'),
                        scale: _popScale,
                        child: DirectionalIcon(
                          LucideIcons.reply,
                          size: 20,
                          color: _armed
                              ? scheme.primary
                              : scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          Transform.translate(offset: Offset(_dx * _toEnd, 0), child: widget.child),
        ],
      ),
    );
  }
}
