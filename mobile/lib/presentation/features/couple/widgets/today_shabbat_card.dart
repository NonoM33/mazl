import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/services/jewish_calendar_service.dart';
import '../../../../l10n/l10n.dart';
import '../../../common/widgets/mazl_components.dart';
import 'couple_kit.dart';

/// « Shabbat ensemble ce soir »: the outlined card with the moon and the
/// candle lighting hour. The chevron opens the agenda.
class TodayShabbatCard extends StatelessWidget {
  const TodayShabbatCard({
    super.key,
    required this.shabbat,
    required this.isFriday,
    required this.onOpenAgenda,
  });

  final ShabbatInfo shabbat;
  final bool isFriday;
  final VoidCallback onOpenAgenda;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    final moment = shabbat.candleLightingAt?.toLocal();
    final time = moment == null
        ? null
        : l10n.coupleTodayClock(
            moment.hour.toString(),
            moment.minute.toString().padLeft(2, '0'),
          );
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return CoupleCard(
      outlined: true,
      radius: 28,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Row(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: scheme.primaryContainer,
            ),
            child: SizedBox.square(
              dimension: 44,
              child: Icon(
                LucideIcons.moon,
                size: 20,
                color: scheme.onPrimaryContainer,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isFriday
                      ? l10n.coupleTodayShabbatTonight
                      : l10n.coupleTodayShabbatFriday,
                  style: theme.textTheme.titleMedium,
                ),
                if (time != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    l10n.coupleTodayShabbatCandles(time),
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          RoundIconButton(
            icon: rtl ? LucideIcons.chevronLeft : LucideIcons.chevronRight,
            tooltip: l10n.coupleTodayShabbatAgenda,
            onPressed: onOpenAgenda,
          ),
        ],
      ),
    );
  }
}
