import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/models/couple_daily.dart';
import '../../../../l10n/l10n.dart';

/// The four quick asks as a 2 x 2 grid of 56 pt buttons with an accent icon.
/// [onAsk] prepares the composer with the start of a sentence for that kind.
class ConciergeQuickAsks extends StatelessWidget {
  const ConciergeQuickAsks({super.key, required this.onAsk});

  final void Function(ConciergeKind kind, String start) onAsk;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final asks = [
      _Ask(
        ConciergeKind.table,
        LucideIcons.utensils,
        l10n.coupleConciergeQuickTable,
        l10n.coupleConciergeStartTable,
      ),
      _Ask(
        ConciergeKind.surprise,
        LucideIcons.partyPopper,
        l10n.coupleConciergeQuickSurprise,
        l10n.coupleConciergeStartSurprise,
      ),
      _Ask(
        ConciergeKind.gift,
        LucideIcons.gift,
        l10n.coupleConciergeQuickGift,
        l10n.coupleConciergeStartGift,
      ),
      _Ask(
        ConciergeKind.weekend,
        LucideIcons.luggage,
        l10n.coupleConciergeQuickWeekend,
        l10n.coupleConciergeStartWeekend,
      ),
    ];
    Widget cell(_Ask ask) => Expanded(
      child: _QuickAskButton(ask: ask, onTap: () => onAsk(ask.kind, ask.start)),
    );
    return Column(
      children: [
        for (var row = 0; row < 2; row++) ...[
          if (row > 0) const SizedBox(height: 12),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                cell(asks[row * 2]),
                const SizedBox(width: 12),
                cell(asks[row * 2 + 1]),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _Ask {
  const _Ask(this.kind, this.icon, this.label, this.start);

  final ConciergeKind kind;
  final IconData icon;
  final String label;
  final String start;
}

class _QuickAskButton extends StatelessWidget {
  const _QuickAskButton({required this.ask, required this.onTap});

  final _Ask ask;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: ask.label,
      excludeSemantics: true,
      child: Material(
        color: scheme.surfaceContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: ValueKey('concierge-quick-${ask.kind.name}'),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Row(
                children: [
                  Icon(ask.icon, size: 20, color: scheme.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      ask.label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
