import 'package:flutter/material.dart';

import '../../../../l10n/l10n.dart';
import '../../../common/widgets/mazl_components.dart';

/// One question of the check-in: a scale from 1 to 5 as five round buttons in
/// a radio group. Each button is the whole cell of its fifth of the row, at
/// least 44 pt in both directions; the chosen one is full ink.
class CheckinScale extends StatelessWidget {
  const CheckinScale({
    super.key,
    required this.question,
    required this.value,
    required this.onChanged,
  });

  final String question;
  final int? value;
  final ValueChanged<int> onChanged;

  static const int steps = 5;
  static const double _diameter = 44;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    return Semantics(
      container: true,
      label: question,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(question, style: theme.textTheme.titleSmall),
          const SizedBox(height: 4),
          Row(
            children: [
              for (var n = 1; n <= steps; n++)
                Expanded(
                  child: _Step(
                    n: n,
                    selected: value == n,
                    semanticLabel: l10n.coupleCheckinScoreLabel(question, n),
                    onTap: () => onChanged(n),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 2),
          ExcludeSemantics(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(child: Text(l10n.coupleCheckinScaleLow, style: muted)),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    l10n.coupleCheckinScaleHigh,
                    style: muted,
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({
    required this.n,
    required this.selected,
    required this.semanticLabel,
    required this.onTap,
  });

  final int n;
  final bool selected;
  final String semanticLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      label: semanticLabel,
      excludeSemantics: true,
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: kMinTapTarget + 4),
        child: InkWell(
          onTap: onTap,
          customBorder: const StadiumBorder(),
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              width: CheckinScale._diameter,
              height: CheckinScale._diameter,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? scheme.onSurface : scheme.surfaceContainer,
              ),
              child: Text(
                '$n',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: selected ? scheme.surface : scheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
