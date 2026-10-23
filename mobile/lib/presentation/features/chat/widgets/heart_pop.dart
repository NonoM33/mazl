import 'package:flutter/material.dart';

/// A filled accent heart that grows in the middle of its parent, then fades
/// (0,6 → 1,2 → 1 over 350 ms). Plays each time [trigger] increases. Lucide
/// has no filled heart, so this one is the Material glyph.
class HeartPop extends StatefulWidget {
  const HeartPop({super.key, required this.trigger});

  final int trigger;

  @override
  State<HeartPop> createState() => _HeartPopState();
}

class _HeartPopState extends State<HeartPop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 350),
  );

  static final _scale = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween(
        begin: 0.6,
        end: 1.2,
      ).chain(CurveTween(curve: Curves.easeOutCubic)),
      weight: 60,
    ),
    TweenSequenceItem(
      tween: Tween(
        begin: 1.2,
        end: 1.0,
      ).chain(CurveTween(curve: Curves.easeOutCubic)),
      weight: 40,
    ),
  ]);

  @override
  void didUpdateWidget(HeartPop old) {
    super.didUpdateWidget(old);
    if (widget.trigger > old.trigger &&
        !MediaQuery.disableAnimationsOf(context)) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          if (_controller.isDismissed || _controller.isCompleted) {
            return const SizedBox.shrink();
          }
          final t = _controller.value;
          return Center(
            child: Opacity(
              opacity: t < 0.7 ? 1 : (1 - (t - 0.7) / 0.3).clamp(0.0, 1.0),
              child: Transform.scale(
                scale: _scale.transform(t),
                child: Icon(Icons.favorite, size: 44, color: color),
              ),
            ),
          );
        },
      ),
    );
  }
}
