import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../core/motion/mazl_motion.dart';

/// Runs one accent thread over [child], in reading direction, in a calm loop.
/// The thread only shows where [child] paints something, so on a skeleton it
/// reads as a line crossing the blocks of the content to come.
///
/// One ticker per instance. Under « Réduire les animations » there is no
/// thread and no ticker: the child is shown as is.
class LoadingThread extends StatefulWidget {
  const LoadingThread({super.key, required this.child});

  final Widget child;

  @override
  State<LoadingThread> createState() => _LoadingThreadState();
}

class _LoadingThreadState extends State<LoadingThread>
    with SingleTickerProviderStateMixin {
  late final AnimationController _clock = AnimationController(
    vsync: this,
    duration: MazlMotion.loadingThreadPeriod,
  );
  bool _reduced = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduced = MazlMotion.reduced(context);
    if (_reduced) {
      _clock.stop();
    } else if (!_clock.isAnimating) {
      _clock.repeat();
    }
  }

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _ThreadPaint(
      progress: _reduced ? null : _clock,
      color: Theme.of(context).colorScheme.primary,
      textDirection: Directionality.of(context),
      child: widget.child,
    );
  }
}

class _ThreadPaint extends SingleChildRenderObjectWidget {
  const _ThreadPaint({
    required this.progress,
    required this.color,
    required this.textDirection,
    required super.child,
  });

  final Animation<double>? progress;
  final Color color;
  final TextDirection textDirection;

  @override
  RenderLoadingThread createRenderObject(BuildContext context) =>
      RenderLoadingThread(
        progress: progress,
        color: color,
        textDirection: textDirection,
      );

  @override
  void updateRenderObject(
    BuildContext context,
    RenderLoadingThread renderObject,
  ) {
    renderObject
      ..progress = progress
      ..color = color
      ..textDirection = textDirection;
  }
}

/// Paints its child, then the thread on top of what the child painted.
class RenderLoadingThread extends RenderProxyBox {
  RenderLoadingThread({
    required Animation<double>? progress,
    required Color color,
    required TextDirection textDirection,
  }) : _progress = progress,
       _color = color,
       _textDirection = textDirection;

  Animation<double>? _progress;
  Color _color;
  TextDirection _textDirection;

  Animation<double>? get progress => _progress;
  set progress(Animation<double>? value) {
    if (identical(value, _progress)) return;
    if (attached) _progress?.removeListener(markNeedsPaint);
    _progress = value;
    if (attached) _progress?.addListener(markNeedsPaint);
    markNeedsPaint();
  }

  Color get color => _color;
  set color(Color value) {
    if (value == _color) return;
    _color = value;
    markNeedsPaint();
  }

  TextDirection get textDirection => _textDirection;
  set textDirection(TextDirection value) {
    if (value == _textDirection) return;
    _textDirection = value;
    markNeedsPaint();
  }

  /// Share of the pass done, eased: 0 at the reading start, 1 at its end.
  double get _along =>
      MazlMotion.loadingThreadCurve.transform(_progress?.value ?? 0);

  /// The thread in this box's own coordinates, or null when there is none.
  Rect? get threadRect {
    if (_progress == null || size.isEmpty) return null;
    final width = MazlMotion.loadingThreadWidth;
    final travel = size.width - width;
    final start = _textDirection == TextDirection.ltr
        ? _along * travel
        : (1 - _along) * travel;
    return Rect.fromLTWH(start, 0, width, size.height);
  }

  /// The thread's colour at its centre: the accent, faded near both edges.
  Color get threadColor {
    final edge = MazlMotion.loadingThreadEdgeFade;
    final fade =
        (_along / edge).clamp(0.0, 1.0) * ((1 - _along) / edge).clamp(0.0, 1.0);
    return _color.withValues(alpha: _color.a * fade);
  }

  @override
  bool get alwaysNeedsCompositing => child != null;

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _progress?.addListener(markNeedsPaint);
  }

  @override
  void detach() {
    _progress?.removeListener(markNeedsPaint);
    super.detach();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final rect = threadRect;
    if (child == null) return;
    if (rect == null) {
      layer = null;
      super.paint(context, offset);
      return;
    }
    final centre = threadColor;
    final end = centre.withValues(alpha: 0);
    final fade = MazlMotion.loadingThreadEndFade;
    final shader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [end, centre, centre, end],
      stops: [0, fade, 1 - fade, 1],
    ).createShader(Offset.zero & rect.size);
    final thread = (layer as ShaderMaskLayer?) ?? ShaderMaskLayer();
    layer = thread
      ..shader = shader
      ..maskRect = rect.shift(offset)
      ..blendMode = BlendMode.srcATop;
    context.pushLayer(thread, super.paint, offset);
  }
}
