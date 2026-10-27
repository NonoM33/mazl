import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/models/couple_daily.dart';
import '../../../../l10n/l10n.dart';

/// The ideas the assistant proposes, as a radio group: one tile of at least
/// 56 pt per idea (title, detail, price hint as the server writes it). The
/// price is a hint, never a quote.
class ConciergeOptions extends StatelessWidget {
  const ConciergeOptions({
    super.key,
    required this.options,
    required this.picked,
    required this.onPick,
  });

  final List<ConciergeOption> options;
  final int? picked;
  final ValueChanged<int> onPick;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    label: context.l10n.coupleConciergeOptionsLabel,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < options.length; i++) ...[
          if (i > 0) const SizedBox(height: 8),
          ConciergeOptionTile(
            key: ValueKey('concierge-option-$i'),
            option: options[i],
            selected: picked == i,
            onTap: () => onPick(i),
          ),
        ],
      ],
    ),
  );
}

/// One idea: a radio tile when [onTap] is given, the retained idea (marked
/// « Choisie ») when [chosen].
class ConciergeOptionTile extends StatelessWidget {
  const ConciergeOptionTile({
    super.key,
    required this.option,
    this.selected = false,
    this.chosen = false,
    this.onTap,
  });

  final ConciergeOption option;
  final bool selected;
  final bool chosen;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final highlighted = selected || chosen;
    final price = option.priceHint;
    final spoken = [
      option.title,
      if (option.details.isNotEmpty) option.details,
      ?price,
      if (chosen) l10n.coupleConciergeChosen,
    ].join('. ');
    return Semantics(
      button: onTap != null,
      inMutuallyExclusiveGroup: onTap != null,
      checked: onTap != null ? selected : null,
      label: spoken,
      excludeSemantics: true,
      child: Material(
        color: highlighted
            ? scheme.primary.withValues(alpha: 0.08)
            : scheme.surfaceContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: highlighted ? scheme.primary : scheme.outlineVariant,
            width: highlighted ? 2 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (onTap != null)
                    _Radio(selected: selected)
                  else
                    Icon(
                      LucideIcons.circleCheck,
                      size: 22,
                      color: scheme.primary,
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(option.title, style: text.titleSmall),
                        if (option.details.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(option.details, style: text.bodySmall),
                        ],
                        if (price != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            price,
                            style: text.labelLarge?.copyWith(
                              color: scheme.onSurface,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (chosen) ...[
                    const SizedBox(width: 8),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: scheme.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        child: Text(
                          l10n.coupleConciergeChosen,
                          style: text.labelMedium?.copyWith(
                            color: scheme.onPrimary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Radio extends StatelessWidget {
  const _Radio({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 22,
      height: 22,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? scheme.primary : scheme.outline,
          width: 2,
        ),
      ),
      child: selected
          ? DecoratedBox(
              decoration: BoxDecoration(
                color: scheme.primary,
                shape: BoxShape.circle,
              ),
              child: const SizedBox.square(dimension: 10),
            )
          : null,
    );
  }
}
