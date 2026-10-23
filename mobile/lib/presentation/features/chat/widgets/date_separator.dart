import 'package:flutter/material.dart';

import '../../../common/widgets/mazl_components.dart';

/// « AUJOURD'HUI », « MAR. 21 OCT. »: Geist Mono capitals, muted.
class DateSeparator extends StatelessWidget {
  const DateSeparator(this.label, {super.key, this.compact = false});

  final String label;

  /// Tighter, for the sticky copy.
  final bool compact;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.symmetric(vertical: compact ? 8 : 14),
    child: Center(child: SectionLabel(label)),
  );
}

/// The label kept at the top while a day's messages scroll under it, on the
/// page colour at 92 % (no blur, no pill).
class StickyDateLabel extends StatelessWidget {
  const StickyDateLabel(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: ColoredBox(
      color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.92),
      child: SizedBox(
        width: double.infinity,
        child: DateSeparator(label, compact: true),
      ),
    ),
  );
}
