import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/widgets.dart';

import '../../../../core/motion/mazl_motion.dart';
import 'swipe_deck_types.dart';

/// Grows its child, up to [MazlMotion.deckButtonMaxScale], as the card above
/// it heads toward [direction]: the button that matches the gesture leans in.
class SwipeProgressScale extends StatelessWidget {
  const SwipeProgressScale({
    super.key,
    required this.progress,
    required this.direction,
    required this.child,
  });

  final ValueListenable<SwipeProgress> progress;
  final SwipeDirection direction;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<SwipeProgress>(
      valueListenable: progress,
      child: child,
      builder: (context, value, child) => Transform.scale(
        scale: 1 + (MazlMotion.deckButtonMaxScale - 1) * value.of(direction),
        child: child,
      ),
    );
  }
}
