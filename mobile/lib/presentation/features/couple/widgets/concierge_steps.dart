import 'package:flutter/material.dart';

import '../../../../l10n/l10n.dart';

/// The three steps of a request: received, idea chosen, booked by the team.
/// The steps reached are filled with the accent, the others stay neutral.
class ConciergeStepsBar extends StatelessWidget {
  const ConciergeStepsBar({super.key, required this.step});

  /// 1 request received, 2 idea chosen, 3 booked by the team.
  final int step;

  static String _state(bool on) => on ? 'on' : 'off';

  static String labelOf(AppLocalizations l10n, int step) => switch (step) {
    1 => l10n.coupleConciergeStep1,
    2 => l10n.coupleConciergeStep2,
    _ => l10n.coupleConciergeStep3,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final style = Theme.of(context).textTheme.labelMedium;
    final reached = step.clamp(1, 3);
    return Semantics(
      container: true,
      label: l10n.coupleConciergeStepSemantics(reached, labelOf(l10n, reached)),
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              for (var i = 1; i <= 3; i++) ...[
                if (i > 1) const SizedBox(width: 6),
                Expanded(
                  child: Container(
                    key: ValueKey('concierge-step-$i-${_state(i <= reached)}'),
                    height: 4,
                    decoration: BoxDecoration(
                      color: i <= reached
                          ? scheme.primary
                          : scheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 1; i <= 3; i++) ...[
                if (i > 1) const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    labelOf(l10n, i),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: style?.copyWith(
                      color: i <= reached
                          ? scheme.onSurface
                          : scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
