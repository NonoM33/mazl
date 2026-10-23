import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// « 3 nouveaux messages ↓ »: ink pill floating above the composer while the
/// reader is scrolled up (docs/design/CHAT.md §3). Fades in and out.
class NewMessagesPill extends StatelessWidget {
  const NewMessagesPill({super.key, required this.count, required this.onTap});

  /// Distance between the pill and the composer below it.
  static const gapAboveComposer = 12.0;

  final int count;
  final VoidCallback onTap;

  static String label(int count) =>
      count == 1 ? '1 nouveau message' : '$count nouveaux messages';

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final noMotion = MediaQuery.disableAnimationsOf(context);
    return AnimatedOpacity(
      opacity: count > 0 ? 1 : 0,
      duration: noMotion ? Duration.zero : const Duration(milliseconds: 150),
      curve: Curves.easeOutCubic,
      child: IgnorePointer(
        ignoring: count == 0,
        child: Material(
          color: scheme.onSurface,
          shape: const StadiumBorder(),
          child: InkWell(
            customBorder: const StadiumBorder(),
            onTap: onTap,
            child: SizedBox(
              height: 40,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label(count == 0 ? 1 : count),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: scheme.surface,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      LucideIcons.arrowDown,
                      size: 16,
                      color: scheme.surface,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
