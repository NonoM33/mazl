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

/// The day label pinned at the top: a full-width band, 8 px above and below
/// the text, on the page colour at 92 %.
class StickyDateLabel extends StatelessWidget {
  const StickyDateLabel(this.label, {super.key});

  /// 8 + one line of the 11 px label at 1.3 + 8.
  static const height = 16 + 11 * 1.3;

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

/// Always occupies the band's height, so the list never jumps when the label
/// appears; shows [StickyDateLabel] when there is one.
class StickyDateBand extends StatelessWidget {
  const StickyDateBand({super.key, required this.label});

  final String? label;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: StickyDateLabel.height,
    child: label == null ? null : StickyDateLabel(label!),
  );
}
