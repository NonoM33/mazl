import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../l10n/l10n.dart';

class ComposerRoundButton extends StatelessWidget {
  const ComposerRoundButton({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: label,
    child: SizedBox.square(
      dimension: 48,
      child: Material(
        color: color,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Center(
            child: Icon(
              icon,
              size: 22,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
        ),
      ),
    ),
  );
}

/// Hold to record; the press is tracked by a long-press recognizer that fires
/// after 200 ms rather than the default 500.
class MicButton extends StatelessWidget {
  const MicButton({
    super.key,
    required this.recording,
    required this.lockHint,
    required this.onStart,
    required this.onMove,
    required this.onEnd,
    required this.onTap,
  });

  final bool recording;
  final bool lockHint;
  final VoidCallback onStart;
  final ValueChanged<Offset> onMove;
  final ValueChanged<LongPressEndDetails> onEnd;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: context.l10n.chatMicSemantics,
      child: RawGestureDetector(
        behavior: HitTestBehavior.opaque,
        gestures: {
          LongPressGestureRecognizer:
              GestureRecognizerFactoryWithHandlers<LongPressGestureRecognizer>(
                () => LongPressGestureRecognizer(
                  duration: const Duration(milliseconds: 200),
                ),
                (r) => r
                  ..onLongPressStart = ((_) => onStart())
                  ..onLongPressMoveUpdate = ((d) => onMove(d.offsetFromOrigin))
                  ..onLongPressEnd = onEnd,
              ),
          TapGestureRecognizer:
              GestureRecognizerFactoryWithHandlers<TapGestureRecognizer>(
                TapGestureRecognizer.new,
                (r) => r.onTap = onTap,
              ),
        },
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            SizedBox.square(
              dimension: 48,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: recording
                      ? scheme.primaryContainer
                      : Colors.transparent,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  LucideIcons.mic,
                  size: 22,
                  color: recording
                      ? scheme.onPrimaryContainer
                      : scheme.onSurface,
                ),
              ),
            ),
            if (lockHint)
              Positioned(
                bottom: 56,
                child: Container(
                  width: 36,
                  height: 64,
                  alignment: Alignment.topCenter,
                  padding: const EdgeInsets.only(top: 10),
                  decoration: BoxDecoration(
                    color: scheme.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: scheme.outline),
                  ),
                  child: Icon(
                    LucideIcons.lock,
                    size: 16,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
