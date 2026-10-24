import 'package:flutter/material.dart';

import '../../../../core/models/chat_message.dart';

/// The heart of a double tap (docs/design/CHAT.md §4): a 64 px ❤️ that bursts
/// at the touched point, grows 0,6 → 1,2 → 1 and fades over 400 ms. Plays each
/// time [trigger] increases, centred on [origin] (in this widget's own
/// coordinates), or in the middle when there is no point.
class HeartPop extends StatefulWidget {
  const HeartPop({super.key, required this.trigger, this.origin});

  static const size = 64.0;

  final int trigger;
  final Offset? origin;

  @override
  State<HeartPop> createState() => _HeartPopState();
}

class _HeartPopState extends State<HeartPop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 400),
  );

  static final _scale = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween(
        begin: 0.6,
        end: 1.2,
      ).chain(CurveTween(curve: Curves.easeOutCubic)),
      weight: 50,
    ),
    TweenSequenceItem(
      tween: Tween(
        begin: 1.2,
        end: 1.0,
      ).chain(CurveTween(curve: Curves.easeOutCubic)),
      weight: 50,
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
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, box) {
          final origin = widget.origin ?? box.biggest.center(Offset.zero);
          return AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              if (_controller.isDismissed || _controller.isCompleted) {
                return const SizedBox.shrink();
              }
              final t = _controller.value;
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: origin.dx,
                    top: origin.dy,
                    child: FractionalTranslation(
                      translation: const Offset(-0.5, -0.5),
                      child: Opacity(
                        key: const ValueKey('heart-pop'),
                        opacity: t < 0.5
                            ? 1
                            : (1 - (t - 0.5) / 0.5).clamp(0.0, 1.0),
                        child: Transform.scale(
                          scale: _scale.transform(t),
                          child: Text(
                            allowedReactions.first,
                            softWrap: false,
                            style: const TextStyle(
                              fontSize: HeartPop.size,
                              height: 1,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
