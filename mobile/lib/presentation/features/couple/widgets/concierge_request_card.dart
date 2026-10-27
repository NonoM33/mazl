import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/models/couple_daily.dart';
import '../../../../l10n/l10n.dart';
import 'concierge_steps.dart';
import 'couple_kit.dart';

/// The deadline of a request, written for a member: « Avant jeudi » when the
/// wanted day is in the coming week, « Pour le 9 novembre » otherwise, nothing
/// when no day was given.
String? conciergeDeadline(
  BuildContext context,
  DateTime? wantedAt, {
  DateTime? now,
}) {
  if (wantedAt == null) return null;
  final l10n = context.l10n;
  final locale = Localizations.localeOf(context).toString();
  final today = now ?? DateTime.now();
  final first = DateTime(today.year, today.month, today.day);
  final wanted = DateTime(wantedAt.year, wantedAt.month, wantedAt.day);
  final days = wanted.difference(first).inDays;
  if (days >= 0 && days < 7) {
    return l10n.coupleConciergeBefore(DateFormat.EEEE(locale).format(wanted));
  }
  return l10n.coupleConciergeOnDate(DateFormat.MMMMd(locale).format(wanted));
}

/// One request of the list: title, deadline and the three steps. A closed or
/// cancelled one is quieter, with its state in words instead of the steps.
class ConciergeRequestCard extends StatelessWidget {
  const ConciergeRequestCard({
    super.key,
    required this.request,
    required this.onTap,
    this.selected = false,
  });

  final ConciergeSummary request;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final open = request.isOpen;
    final deadline = conciergeDeadline(context, request.wantedAt);
    final stateLine = switch (request.status) {
      ConciergeStatus.closed => l10n.coupleConciergeStatusClosed,
      ConciergeStatus.cancelled => l10n.coupleConciergeStatusCancelled,
      _ => deadline,
    };
    return Semantics(
      button: true,
      selected: selected,
      child: CoupleCard(
        outlined: selected,
        radius: 24,
        padding: EdgeInsets.all(open ? 20 : 16),
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              request.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: open
                  ? text.titleMedium
                  : text.titleSmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
            if (stateLine != null) ...[
              const SizedBox(height: 2),
              Text(stateLine, style: text.bodySmall),
            ],
            if (open) ...[
              const SizedBox(height: 16),
              ConciergeStepsBar(step: request.step),
            ],
          ],
        ),
      ),
    );
  }
}
