import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../../../core/motion/mazl_motion.dart';
import 'swipe_deck_animator.dart';
import 'swipe_deck_physics.dart';
import 'swipe_deck_pose.dart';
import 'swipe_deck_types.dart';
import 'swipe_intent_discs.dart';

export 'swipe_deck_types.dart';
export 'swipe_progress_scale.dart';

/// A stack of cards that leave by being thrown: Discover's profiles and the
/// couple's activities.
///
/// The top card follows the finger, the one below comes up as it travels, a
/// white disc in the corner says what the gesture means, and at the threshold
/// there is one haptic and one small pop. A card that is not thrown far or fast
/// enough springs back; one the parent refuses ([onWillSwipe]) springs back
/// too, and only then does the parent hear about it ([onRefused]).
///
/// Every value comes from [MazlMotion].
class SwipeDeck extends StatefulWidget {
  const SwipeDeck({
    super.key,
    required this.controller,
    required this.itemCount,
    required this.cardBuilder,
    required this.allowed,
    this.intents = const {},
    this.heavyHapticOn = const {},
    this.onWillSwipe,
    this.onSwiped,
    this.onRefused,
    this.onUndone,
    this.onEnd,
  });

  final SwipeDeckController controller;
  final int itemCount;

  /// Builds the card for [index]. [isTop] is false for the one waiting below:
  /// it is not interactive and gets no progress to follow.
  final Widget Function(BuildContext context, int index, bool isTop)
  cardBuilder;

  /// The directions a card may leave in.
  final Set<SwipeDirection> allowed;

  /// The disc shown for each direction.
  final Map<SwipeDirection, SwipeIntent> intents;

  /// Directions whose commit, by finger, also gives a medium impact.
  final Set<SwipeDirection> heavyHapticOn;

  /// Asked at commit time, before the card moves. False keeps the card.
  final SwipeVerdict? onWillSwipe;

  /// The card has left.
  final void Function(int index, SwipeDirection direction)? onSwiped;

  /// The verdict was no, and the card is back in place.
  final void Function(int index, SwipeDirection direction)? onRefused;

  /// The card at [index] is back on top.
  final void Function(int index)? onUndone;

  /// The last card has left.
  final VoidCallback? onEnd;

  @override
  State<SwipeDeck> createState() => _SwipeDeckState();
}

enum _Phase { idle, dragging, deciding, exiting, returning }

class _Exit {
  const _Exit(this.index, this.pose, this.pivot, this.grabbedLower);

  final int index;
  final DeckPose pose;
  final Offset pivot;
  final bool grabbedLower;
}

class _SwipeDeckState extends State<SwipeDeck>
    with TickerProviderStateMixin
    implements SwipeDeckHandle {
  final ValueNotifier<DeckPose> _pose = ValueNotifier(DeckPose.rest);
  late final DeckAnimator _animator = DeckAnimator(this);
  late final AnimationController _pop = AnimationController(
    vsync: this,
    duration: MazlMotion.popDuration,
  );
  final List<_Exit> _history = [];

  int _index = 0;
  Size _size = Size.zero;
  bool _reduced = false;
  _Phase _phase = _Phase.idle;

  Offset _finger = Offset.zero;
  Offset _pivot = Offset.zero;
  bool _grabbedLower = false;
  SwipeDirection? _armed;
  SwipeDirection? _popDirection;

  Set<SwipeDirection> get _allowed => widget.allowed;

  @override
  void initState() {
    super.initState();
    widget.controller.attach(this);
  }

  @override
  void didUpdateWidget(SwipeDeck oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.controller, widget.controller)) {
      oldWidget.controller.detach(this);
      widget.controller.attach(this);
    }
  }

  @override
  void dispose() {
    widget.controller.detach(this);
    _animator.dispose();
    _pop.dispose();
    _pose.dispose();
    super.dispose();
  }

  // --- Build -------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    _reduced = MazlMotion.reduced(context);
    if (_index >= widget.itemCount) return const SizedBox.shrink();
    return LayoutBuilder(
      builder: (context, constraints) {
        _size = constraints.biggest;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            if (_index + 1 < widget.itemCount)
              _layer(context, _index + 1, top: false),
            _layer(context, _index, top: true),
          ],
        );
      },
    );
  }

  Widget _layer(BuildContext context, int index, {required bool top}) {
    final card = widget.cardBuilder(context, index, top);
    final surface = GestureDetector(
      behavior: HitTestBehavior.opaque,
      dragStartBehavior: DragStartBehavior.down,
      onPanStart: top ? _onPanStart : null,
      onPanUpdate: top ? _onPanUpdate : null,
      onPanEnd: top ? _onPanEnd : null,
      onPanCancel: top ? _onPanCancel : null,
      child: Stack(
        fit: StackFit.expand,
        children: [
          card,
          if (widget.intents.isNotEmpty)
            SwipeIntentDiscs(
              progress: top
                  ? widget.controller.progress
                  : const IdleSwipeProgress(),
              pop: _pop,
              popDirection: () => _popDirection,
              intents: top ? widget.intents : const {},
              reduced: _reduced,
            ),
        ],
      ),
    );
    return Positioned.fill(
      key: ValueKey(index),
      child: AnimatedBuilder(
        animation: _pose,
        child: IgnorePointer(
          ignoring: !top,
          child: ExcludeSemantics(excluding: !top, child: surface),
        ),
        builder: (context, child) => top
            ? DeckLayers.top(
                pose: _pose.value,
                size: _size,
                pivot: _pivot,
                grabbedLower: _grabbedLower,
                reduced: _reduced,
                child: child!,
              )
            : DeckLayers.back(pose: _pose.value, size: _size, child: child!),
      ),
    );
  }

  // --- Finger ------------------------------------------------------------

  bool get _canGrab => _phase == _Phase.idle || _phase == _Phase.returning;

  void _onPanStart(DragStartDetails details) {
    if (!_canGrab) return;
    _animator.stop();
    _phase = _Phase.dragging;
    _pivot = details.localPosition;
    _grabbedLower =
        details.localPosition.dy > _size.height * MazlMotion.deckGrabLowerHalf;
    final card = _pose.value.card;
    _finger = SwipeDeckPhysics.fingerFor(card, _allowed);
    _armed = _armedBy(_progressAt(card));
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_phase != _Phase.dragging) return;
    _finger += details.delta;
    _moveCard(SwipeDeckPhysics.follow(_finger, _allowed), silent: false);
  }

  void _onPanEnd(DragEndDetails details) {
    if (_phase != _Phase.dragging) return;
    final card = _pose.value.card;
    final direction = SwipeDeckPhysics.commitDirection(
      finger: _finger,
      card: card,
      velocity: details.velocity,
      size: _size,
      allowed: _allowed,
    );
    final velocity = details.velocity.pixelsPerSecond;
    if (direction != null) {
      unawaited(_commit(direction, velocity: velocity));
    } else {
      unawaited(_springBack(velocity));
    }
  }

  void _onPanCancel() {
    if (_phase != _Phase.dragging) return;
    unawaited(_springBack(Offset.zero));
  }

  // --- Moving the card ---------------------------------------------------

  SwipeProgress _progressAt(Offset card) =>
      SwipeDeckPhysics.progress(card, _size, _allowed);

  void _setPose(DeckPose pose, {bool silent = true}) {
    _pose.value = pose;
    _syncIntent(pose.card, silent: silent);
  }

  void _moveCard(Offset card, {required bool silent}) =>
      _setPose(_pose.value.copyWith(card: card), silent: silent);

  /// Shares the progress with the buttons, and marks the crossing of the
  /// threshold: one haptic (by finger only) and one pop, once per crossing.
  void _syncIntent(Offset card, {required bool silent}) {
    final progress = _progressAt(card);
    widget.controller.progress.value = progress;
    final armed = _armedBy(progress);
    if (armed != null && armed != _armed) {
      if (!silent) unawaited(HapticFeedback.selectionClick());
      if (!_reduced) {
        _popDirection = armed;
        unawaited(_pop.forward(from: 0));
      }
    }
    _armed = armed;
  }

  static SwipeDirection? _armedBy(SwipeProgress progress) =>
      progress.value >= 1 ? progress.direction : null;

  /// Puts the card somewhere without marking a crossing of the threshold.
  void _place(DeckPose pose) {
    _pose.value = pose;
    final progress = _progressAt(pose.card);
    widget.controller.progress.value = progress;
    _armed = _armedBy(progress);
  }

  void _rest() {
    _setPose(DeckPose.rest);
    _armed = null;
    widget.controller.progress.value = SwipeProgress.none;
  }

  /// Back to the resting place: a spring that keeps the speed of the release,
  /// or, with reduced motion, a short ease-out.
  Future<bool> _springBack(Offset velocity) async {
    _animator.stop();
    _phase = _Phase.returning;
    final start = _pose.value;
    if (start.card == Offset.zero && start.extraTurn == 0) {
      _rest();
      _phase = _Phase.idle;
      return true;
    }
    final bool done;
    if (_reduced) {
      done = await _animator.run((t) {
        final u = _progressOf(t, MazlMotion.reducedReturn);
        _setPose(start.copyWith(card: Offset.lerp(start.card, Offset.zero, u)));
        return u >= 1;
      });
    } else {
      final r = SwipeDeckPhysics.resistance(start.card, _allowed);
      final x = _spring(start.card.dx, velocity.dx * r.dx);
      final y = _spring(start.card.dy, velocity.dy * r.dy);
      done = await _animator.run((t) {
        final card = Offset(x.x(t), y.x(t));
        final left = start.card.distance == 0
            ? 0.0
            : (card.distance / start.card.distance).clamp(0.0, 1.0);
        _setPose(start.copyWith(card: card, extraTurn: start.extraTurn * left));
        return x.isDone(t) && y.isDone(t);
      });
    }
    if (!done || !mounted) return false;
    _rest();
    if (_phase == _Phase.returning) _phase = _Phase.idle;
    return true;
  }

  SpringSimulation _spring(double from, double velocity) => SpringSimulation(
    MazlMotion.spring,
    from,
    0,
    velocity,
    tolerance: MazlMotion.springTolerance,
  );

  static double _progressOf(double seconds, Duration over) {
    final total = over.inMicroseconds / Duration.microsecondsPerSecond;
    return (seconds / total).clamp(0.0, 1.0);
  }

  // --- Leaving -----------------------------------------------------------

  Future<bool> _commit(
    SwipeDirection direction, {
    required Offset velocity,
  }) async {
    if (_phase == _Phase.deciding || _phase == _Phase.exiting) return false;
    _animator.stop();
    _phase = _Phase.deciding;
    final index = _index;

    final verdict = widget.onWillSwipe?.call(index, direction) ?? true;
    final allowed = verdict is bool ? verdict : await verdict;
    if (!mounted || _index != index) return false;

    if (!allowed) {
      final back = await _springBack(Offset.zero);
      if (back && mounted && _index == index) {
        widget.onRefused?.call(index, direction);
      }
      return false;
    }

    // A super like is acquired the same way by finger or by its button: the
    // one reward of the gesture (docs/design/MOUVEMENT.md, haptics table).
    if (widget.heavyHapticOn.contains(direction)) {
      unawaited(HapticFeedback.mediumImpact());
    }
    _phase = _Phase.exiting;
    final left = await _throw(direction, velocity);
    if (!left || !mounted) return false;

    _history.add(_Exit(index, _pose.value, _pivot, _grabbedLower));
    _rest();
    _phase = _Phase.idle;
    setState(() => _index = index + 1);
    widget.onSwiped?.call(index, direction);
    if (_index >= widget.itemCount) widget.onEnd?.call();
    return true;
  }

  /// The exit: along the drag and the fling, decelerating, with a little extra
  /// turn; or, with reduced motion, a fade where the card is.
  Future<bool> _throw(SwipeDirection direction, Offset velocity) {
    final from = _pose.value;
    if (_reduced) {
      return _animator.run((t) {
        final u = _progressOf(t, MazlMotion.reducedFade);
        _setPose(from.copyWith(fade: u));
        return u >= 1;
      });
    }
    final target = SwipeDeckPhysics.exitTarget(
      direction: direction,
      card: from.card,
      velocity: velocity,
      size: _size,
    );
    final side = switch (direction) {
      SwipeDirection.right => 1.0,
      SwipeDirection.left => -1.0,
      SwipeDirection.up => from.card.dx.sign,
    };
    final extra =
        side *
        MazlMotion.deckMaxRotationDegrees *
        MazlMotion.deckExitExtraRotationShare *
        math.pi /
        180 *
        (_grabbedLower ? -1 : 1);
    return _animator.run((t) {
      final u = MazlMotion.deckExitCurve.transform(
        _progressOf(t, MazlMotion.deckExit),
      );
      _setPose(
        from.copyWith(
          card: Offset.lerp(from.card, target, u),
          extraTurn: from.extraTurn + (extra - from.extraTurn) * u,
        ),
      );
      return _progressOf(t, MazlMotion.deckExit) >= 1;
    });
  }

  // --- SwipeDeckHandle ---------------------------------------------------

  @override
  Future<bool> swipe(SwipeDirection direction) {
    final busy = _phase != _Phase.idle && _phase != _Phase.returning;
    if (busy || _index >= widget.itemCount || !_allowed.contains(direction)) {
      return Future.value(false);
    }
    _animator.stop();
    _pivot = _size.center(Offset.zero);
    _grabbedLower = false;
    return _commit(direction, velocity: Offset.zero);
  }

  @override
  Future<bool> undo() async {
    final busy = _phase != _Phase.idle && _phase != _Phase.returning;
    if (busy || _history.isEmpty) return false;
    _animator.stop();
    final last = _history.removeLast();
    _pivot = last.pivot;
    _grabbedLower = last.grabbedLower;
    setState(() => _index = last.index);
    _phase = _Phase.returning;
    _place(_reduced ? const DeckPose(fade: 1) : last.pose);
    widget.onUndone?.call(last.index);
    final start = _pose.value;
    if (_reduced) {
      final done = await _animator.run((t) {
        final u = _progressOf(t, MazlMotion.reducedFade);
        _setPose(start.copyWith(fade: 1 - u));
        return u >= 1;
      });
      if (done && mounted && _phase == _Phase.returning) _phase = _Phase.idle;
      return done;
    }
    return _springBack(Offset.zero);
  }

  @override
  Future<void> bringBack() async {
    if (_phase == _Phase.deciding || _phase == _Phase.exiting) return;
    await _springBack(Offset.zero);
  }
}
