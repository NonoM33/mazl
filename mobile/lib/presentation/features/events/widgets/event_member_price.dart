import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/models/event.dart';
import '../../../../l10n/l10n.dart';
import '../l10n/event_texts.dart';

/// The mazl+ rate of a paying event (docs/premium/MONETISATION.md §10).
///
/// A member without mazl+ sees a sober « mazl+ : 8 € » line that opens the
/// offer. A subscriber sees « Tarif membre : 8 € » first and the regular price
/// struck through. Nothing at all when the event has no real reduction.
class EventMemberPrice extends StatelessWidget {
  const EventMemberPrice({
    super.key,
    required this.event,
    required this.subscriber,
    required this.onOffer,
  });

  final Event event;

  /// Whether the member has mazl+ (`PremiumGate.isPremium`).
  final bool subscriber;

  /// A tap on the line of a member without mazl+: opens the offer.
  final VoidCallback onOffer;

  @override
  Widget build(BuildContext context) {
    final locale = context.l10n.localeName;
    final member = eventMemberPriceText(event, locale);
    if (member == null) return const SizedBox.shrink();
    final l10n = context.l10n;
    final amount = event.memberPriceCents == 0 ? l10n.eventsFree : member;
    final scheme = Theme.of(context).colorScheme;

    if (!subscriber) {
      return Semantics(
        button: true,
        label: l10n.eventsMemberPricePlusHint(amount),
        excludeSemantics: true,
        child: InkWell(
          onTap: onOffer,
          borderRadius: BorderRadius.circular(8),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44, minWidth: 44),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(LucideIcons.plus, size: 16, color: scheme.primary),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    l10n.eventsMemberPricePlus(amount),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      children: [
        Text(
          l10n.eventsMemberPrice(amount),
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: scheme.onSurface,
          ),
        ),
        Semantics(
          label: l10n.eventsPriceRegular(eventPriceText(event, locale)),
          excludeSemantics: true,
          child: Text(
            eventPriceText(event, locale),
            style: TextStyle(
              fontSize: 14,
              color: scheme.onSurfaceVariant,
              decoration: TextDecoration.lineThrough,
            ),
          ),
        ),
      ],
    );
  }
}
