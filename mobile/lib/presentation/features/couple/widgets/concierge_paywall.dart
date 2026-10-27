import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/layout/fold_spread.dart';
import '../../../../l10n/l10n.dart';
import 'couple_kit.dart';

/// The concierge for a couple without MAZL Couple: what the service does and
/// the way to the subscription. No list, no field: nothing here can create a
/// request.
class ConciergePaywall extends StatelessWidget {
  const ConciergePaywall({super.key, required this.onDiscover});

  final VoidCallback onDiscover;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final safe = MediaQuery.paddingOf(context);
    final services = [
      (LucideIcons.utensils, l10n.coupleConciergeQuickTable),
      (LucideIcons.partyPopper, l10n.coupleConciergeQuickSurprise),
      (LucideIcons.gift, l10n.coupleConciergeQuickGift),
      (LucideIcons.luggage, l10n.coupleConciergeQuickWeekend),
    ];
    return FoldSpread(
      padding: EdgeInsets.fromLTRB(24, safe.top + 16, 24, safe.bottom + 24),
      start: [
        CoupleHeader(
          eyebrow: l10n.coupleConciergeEyebrow,
          title: l10n.coupleConciergeTitle,
        ),
        const SizedBox(height: 12),
        Text(
          l10n.coupleConciergePaywallLine,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 24),
      ],
      end: [
        for (final (icon, label) in services) ...[
          _Service(icon: icon, label: label),
          const SizedBox(height: 12),
        ],
        const SizedBox(height: 12),
        FilledButton(
          key: const ValueKey('concierge-discover'),
          onPressed: onDiscover,
          child: Text(l10n.coupleConciergeDiscover),
        ),
      ],
    );
  }
}

class _Service extends StatelessWidget {
  const _Service({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return CoupleCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      radius: 20,
      child: Row(
        children: [
          Icon(icon, size: 22, color: scheme.primary),
          const SizedBox(width: 14),
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.titleSmall),
          ),
        ],
      ),
    );
  }
}
