import 'dart:math' as math;

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/widgets.dart';

import '../../../../core/motion/mazl_motion.dart';
import '../../../../core/theme/app_colors.dart';
import 'swipe_deck_types.dart';

/// The white discs in the corners of the top card: a heart top-left when the
/// card goes right, a cross top-right when it goes left, a star (or whatever
/// the deck is given) centred on top when it goes up.
///
/// Opacity and scale follow the progress of the gesture; at the threshold the
/// disc of that direction pops once. Flat white, no shadow: it must read on
/// every photo.
class SwipeIntentDiscs extends StatelessWidget {
  const SwipeIntentDiscs({
    super.key,
    required this.progress,
    required this.pop,
    required this.popDirection,
    required this.intents,
    required this.reduced,
  });

  final ValueListenable<SwipeProgress> progress;

  /// 0 → 1 while the pop plays.
  final Animation<double> pop;

  /// Which disc the pop belongs to.
  final ValueGetter<SwipeDirection?> popDirection;
  final Map<SwipeDirection, SwipeIntent> intents;

  /// No scale and no pop: the disc only fades in.
  final bool reduced;

  static Alignment alignmentOf(SwipeDirection d) => switch (d) {
    SwipeDirection.right => Alignment.topLeft,
    SwipeDirection.left => Alignment.topRight,
    SwipeDirection.up => Alignment.topCenter,
  };

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ExcludeSemantics(
        child: AnimatedBuilder(
          animation: Listenable.merge([progress, pop]),
          builder: (context, _) => Stack(
            fit: StackFit.expand,
            children: [
              for (final entry in intents.entries)
                _disc(entry.key, entry.value),
            ],
          ),
        ),
      ),
    );
  }

  Widget _disc(SwipeDirection direction, SwipeIntent intent) {
    final p = progress.value.of(direction);
    final popping = !reduced && popDirection() == direction;
    final bounce = popping
        ? 1 + (MazlMotion.popScale - 1) * math.sin(math.pi * pop.value)
        : 1.0;
    final grow = reduced
        ? 1.0
        : MazlMotion.intentDiscMinScale +
              (1 - MazlMotion.intentDiscMinScale) * p;
    return Align(
      alignment: alignmentOf(direction),
      child: Padding(
        padding: const EdgeInsets.all(MazlMotion.intentDiscInset),
        child: Opacity(
          opacity: p,
          child: Transform.scale(
            scale: grow * bounce,
            child: DecoratedBox(
              decoration: const BoxDecoration(
                color: AppColors.paper,
                shape: BoxShape.circle,
              ),
              child: SizedBox.square(
                dimension: MazlMotion.intentDiscSize,
                child: Icon(intent.icon, size: _iconSize, color: intent.color),
              ),
            ),
          ),
        ),
      ),
    );
  }

  static const _iconSize = 26.0;
}
