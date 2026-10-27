import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/motion/mazl_motion.dart';
import 'like_fill_painter.dart';

/// A heart button that fills from the exact spot the finger touched
/// (docs/design/MOUVEMENT.md): a disc grows from the touch point, clipped to
/// the button's [shape], while the finger rests; the tap takes it to the whole
/// button and the button makes the common bounce. A tap that slides away
/// empties the disc. No haptic: nothing on buttons.
///
/// Under reduced motion there is no growing disc and no bounce: the button
/// fades to its filled colour in [MazlMotion.reducedFade].
///
/// [builder] draws the content over the disc; it receives the eased fill
/// (0 → 1) so icons and labels can change colour with it.
class LikeFill extends StatefulWidget {
  const LikeFill({
    super.key,
    required this.onTap,
    required this.background,
    required this.fillColor,
    required this.shape,
    required this.builder,
    this.size,
    this.minHitSize,
  });

  static const discKey = ValueKey('like-fill-disc');
  static const popKey = ValueKey('like-fill-pop');

  final VoidCallback onTap;
  final Color background;
  final Color fillColor;
  final ShapeBorder shape;
  final Widget Function(BuildContext context, double fill) builder;

  /// Drawn size of the button; when null it takes what its parent gives.
  final Size? size;

  /// The touch area is at least this big on both sides, around the button.
  final double? minHitSize;

  @override
  State<LikeFill> createState() => _LikeFillState();
}

class _LikeFillState extends State<LikeFill> with TickerProviderStateMixin {
  late final AnimationController _fill = AnimationController(vsync: this);
  late final AnimationController _pop = AnimationController(
    vsync: this,
    duration: MazlMotion.popDuration,
  );
  final _visualKey = GlobalKey();

  Offset? _touch;
  bool _reduced = false;
  bool _confirmed = false;
  int _run = 0;

  @override
  void dispose() {
    _fill.dispose();
    _pop.dispose();
    super.dispose();
  }

  Offset? _toLocal(Offset global) {
    final box = _visualKey.currentContext?.findRenderObject() as RenderBox?;
    return box?.globalToLocal(global);
  }

  Offset _centre() {
    final box = _visualKey.currentContext?.findRenderObject() as RenderBox?;
    return box == null ? Offset.zero : box.size.center(Offset.zero);
  }

  void _down(TapDownDetails details) {
    _run++;
    _confirmed = false;
    _reduced = MazlMotion.reduced(context);
    _touch = _toLocal(details.globalPosition);
    if (_reduced) return;
    _fill.animateTo(
      MazlMotion.likeFillPreview,
      duration: MazlMotion.likeFillDuration,
    );
  }

  void _cancel() {
    if (_confirmed) return;
    _run++;
    _fill.animateTo(0, duration: MazlMotion.likeFillCancel * _fill.value);
  }

  void _tap() {
    _reduced = MazlMotion.reduced(context);
    _touch ??= _centre();
    final run = ++_run;
    _confirmed = true;
    _confirm(run);
    widget.onTap();
  }

  /// Takes the disc to the whole button, bounces, then lets the button rest.
  Future<void> _confirm(int run) async {
    if (_reduced) {
      await _fill.animateTo(1, duration: MazlMotion.reducedFade);
    } else {
      await _fill.animateTo(
        1,
        duration: MazlMotion.likeFillFinish * (1 - _fill.value),
      );
      if (!mounted || run != _run) return;
      await _pop.forward(from: 0);
    }
    if (!mounted || run != _run) return;
    await _fill.animateTo(0, duration: MazlMotion.likeFillRelease);
    if (mounted && run == _run) _confirmed = false;
  }

  /// 1 → popScale → 1 over the bounce.
  double get _popScale {
    final t = _pop.value;
    return 1 + (MazlMotion.popScale - 1) * math.sin(math.pi * t);
  }

  @override
  Widget build(BuildContext context) {
    final visual = KeyedSubtree(
      key: _visualKey,
      child: AnimatedBuilder(
        animation: Listenable.merge([_fill, _pop]),
        builder: (context, _) => Transform.scale(
          key: LikeFill.popKey,
          scale: _popScale,
          child: _buildSurface(context),
        ),
      ),
    );
    final min = widget.minHitSize;
    if (min == null) return visual;
    // The button is drawn smaller than the touch area: the margin answers
    // the touch too, like the button itself.
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      excludeFromSemantics: true,
      onTapDown: _down,
      onTapCancel: _cancel,
      onTap: _tap,
      child: ConstrainedBox(
        constraints: BoxConstraints(minWidth: min, minHeight: min),
        child: Center(widthFactor: 1, heightFactor: 1, child: visual),
      ),
    );
  }

  Widget _buildSurface(BuildContext context) {
    final fill = MazlMotion.likeFillCurve.transform(_fill.value.clamp(0, 1));
    final painter = LikeFillPainter(
      center: _touch ?? Offset.zero,
      // Reduced motion: never a part-grown disc, only a fade of the whole.
      progress: _reduced ? (_fill.value > 0 ? 1 : 0) : fill,
      opacity: _reduced ? _fill.value : 1,
      color: widget.fillColor,
    );
    final surface = Material(
      color: widget.background,
      shape: widget.shape,
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          Positioned.fill(
            child: CustomPaint(key: LikeFill.discKey, painter: painter),
          ),
          InkWell(
            onTap: _tap,
            onTapDown: _down,
            onTapCancel: _cancel,
            child: widget.builder(context, _reduced ? _fill.value : fill),
          ),
        ],
      ),
    );
    final size = widget.size;
    return size == null
        ? surface
        : SizedBox.fromSize(size: size, child: surface);
  }
}
