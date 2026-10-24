import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../l10n/l10n.dart';

/// « Noémie écrit… » as a received bubble: three dots rising one after the
/// other (docs/design/CHAT.md §3). Still when animations are disabled.
class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      label: context.l10n.chatTypingSemantics,
      child: Container(
        width: 56,
        height: 36,
        decoration: BoxDecoration(
          color: scheme.surfaceContainer,
          borderRadius: const BorderRadiusDirectional.only(
            topStart: Radius.circular(22),
            topEnd: Radius.circular(22),
            bottomEnd: Radius.circular(22),
            bottomStart: Radius.circular(6),
          ),
        ),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) => Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < 3; i++)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 2.5, vertical: 0),
                  child: Transform.translate(
                    offset: Offset(0, -_lift(i)),
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: scheme.onSurfaceVariant,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Dot [i] rises 3 px during its third of the cycle.
  double _lift(int i) {
    final phase = (_controller.value - i * 0.2) % 1.0;
    return phase < 0.4 ? 3 * math.sin(phase / 0.4 * math.pi) : 0;
  }
}
