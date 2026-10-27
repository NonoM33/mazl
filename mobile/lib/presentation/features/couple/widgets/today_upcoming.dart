import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/models/couple_daily.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../l10n/l10n.dart';
import '../../../common/widgets/mazl_components.dart';

/// « À VENIR »: the next dates, rituals and events of the couple, a date
/// column (month in mono, day big) then the title. The nearest one carries
/// the accent.
class TodayUpcoming extends StatelessWidget {
  const TodayUpcoming({
    super.key,
    required this.items,
    required this.now,
    required this.onOpen,
  });

  final List<CoupleUpcoming> items;
  final DateTime now;

  /// Called for a row that leads somewhere (an event).
  final void Function(CoupleUpcoming item) onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionLabel(l10n.coupleTodayUpcomingLabel),
        const SizedBox(height: 6),
        if (items.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              l10n.coupleTodayUpcomingEmpty,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          )
        else
          for (var i = 0; i < items.length; i++)
            _UpcomingRow(
              item: items[i],
              now: now,
              nearest: i == 0,
              last: i == items.length - 1,
              onOpen: _leadsSomewhere(items[i]) ? () => onOpen(items[i]) : null,
            ),
      ],
    );
  }

  static bool _leadsSomewhere(CoupleUpcoming item) =>
      item.kind == CoupleUpcomingKind.event && item.refId != null;
}

class _UpcomingRow extends StatelessWidget {
  const _UpcomingRow({
    required this.item,
    required this.now,
    required this.nearest,
    required this.last,
    required this.onOpen,
  });

  final CoupleUpcoming item;
  final DateTime now;
  final bool nearest;
  final bool last;
  final VoidCallback? onOpen;

  String _subtitle(BuildContext context) {
    final given = item.subtitle;
    if (given != null) return given;
    final l10n = context.l10n;
    final today = DateTime(now.year, now.month, now.day);
    final at = item.at.toLocal();
    final days = DateTime(at.year, at.month, at.day).difference(today).inDays;
    if (days <= 0) return l10n.coupleTodayDaysToday;
    if (days == 1) return l10n.coupleTodayDaysTomorrow;
    return l10n.coupleTodayDaysAhead(days);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final locale = context.l10n.localeName;
    final at = item.at.toLocal();
    final month = DateFormat.MMM(locale).format(at).replaceAll('.', '');
    final row = Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          SizedBox(
            width: 44,
            child: Column(
              children: [
                Text(
                  month.toUpperCase(),
                  style: AppTypography.eyebrow(
                    nearest ? scheme.primary : scheme.onSurfaceVariant,
                  ).copyWith(letterSpacing: 1),
                ),
                Text(
                  '${at.day}',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontSize: 20,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title, style: theme.textTheme.titleSmall),
                const SizedBox(height: 2),
                Text(_subtitle(context), style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        border: last
            ? null
            : Border(bottom: BorderSide(color: scheme.outlineVariant)),
      ),
      child: onOpen == null
          ? row
          : InkWell(
              onTap: onOpen,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: kMinTapTarget),
                child: row,
              ),
            ),
    );
  }
}
