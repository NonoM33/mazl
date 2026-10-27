import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../../core/models/couple_space.dart';
import '../../../../l10n/l10n.dart';
import '../l10n/jewish_calendar_labels.dart';
import 'agenda_buttons.dart';
import 'agenda_marks.dart';
import 'agenda_month_grid.dart';
import 'couple_kit.dart';

/// What the chosen day holds: the dates that matter, the holiday, the rituals
/// of the day. « Rien ce jour-là » when it holds nothing.
class AgendaDayDetail extends StatelessWidget {
  const AgendaDayDetail({super.key, required this.day, required this.marks});

  final DateTime day;
  final AgendaMarks marks;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final entries = <(AgendaMark, String)>[
      for (final date in marks.datesOn(day))
        (AgendaMark.importantDate, date.title),
      for (final holiday in marks.holidaysOn(day))
        (AgendaMark.holiday, holiday.id.title(l10n)),
      for (final ritual in marks.ritualsOn(day))
        (AgendaMark.ritual, ritual.title),
    ];
    return CoupleCard(
      key: const Key('agenda-day-detail'),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            DateFormat.MMMMEEEEd(l10n.localeName).format(day),
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          if (entries.isEmpty)
            Text(
              l10n.coupleAgendaNothing,
              style: TextStyle(fontSize: 14, color: scheme.onSurfaceVariant),
            )
          else
            for (final (mark, title) in entries)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    AgendaMarkDot(mark: mark, size: 8),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(title, style: const TextStyle(fontSize: 14)),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}

/// The dates of the couple, the closest first. The closest one is a card that
/// offers to prepare it with the concierge; the others are plain rows.
class AgendaDatesList extends StatelessWidget {
  const AgendaDatesList({
    super.key,
    required this.dates,
    required this.today,
    required this.onPrepare,
  });

  final List<CoupleDate> dates;
  final DateTime today;
  final VoidCallback onPrepare;

  @override
  Widget build(BuildContext context) {
    final upcoming = <(CoupleDate, DateTime)>[
      for (final date in dates)
        if (nextOccurrence(date, today) case final next?) (date, next),
    ]..sort((a, b) => a.$2.compareTo(b.$2));
    if (upcoming.isEmpty) return const _EmptyDates();
    final (first, firstDay) = upcoming.first;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _NextDateCard(
          date: first,
          day: firstDay,
          today: today,
          onPrepare: onPrepare,
        ),
        for (final (date, day) in upcoming.skip(1))
          _DateRow(date: date, day: day, today: today),
      ],
    );
  }
}

String _when(AppLocalizations l10n, DateTime day, DateTime today) =>
    l10n.coupleAgendaDateWhen(
      DateFormat.MMMMd(l10n.localeName).format(day),
      l10n.coupleAgendaDaysUntil(daysUntil(today, day)),
    );

Widget? _reminder(BuildContext context, CoupleDate date, TextStyle style) {
  final days = date.remindDaysBefore;
  if (days == null || days <= 0) return null;
  return Text(context.l10n.coupleAgendaDateReminder(days), style: style);
}

class _NextDateCard extends StatelessWidget {
  const _NextDateCard({
    required this.date,
    required this.day,
    required this.today,
    required this.onPrepare,
  });

  final CoupleDate date;
  final DateTime day;
  final DateTime today;
  final VoidCallback onPrepare;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final muted = TextStyle(
      fontSize: 13,
      height: 1.4,
      color: scheme.onSurfaceVariant,
    );
    final reminder = _reminder(context, date, muted);
    return CoupleCard(
      key: const Key('agenda-next-date'),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.coupleAgendaDateTitle(
              date.title,
              DateFormat.MMMMd(l10n.localeName).format(day),
            ),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(l10n.coupleAgendaDaysUntil(daysUntil(today, day)), style: muted),
          if (reminder != null) ...[const SizedBox(height: 2), reminder],
          const SizedBox(height: 10),
          Text(l10n.coupleAgendaConciergeLine, style: muted),
          const SizedBox(height: 12),
          AgendaPillButton(label: l10n.coupleAgendaPrepare, onTap: onPrepare),
        ],
      ),
    );
  }
}

class _DateRow extends StatelessWidget {
  const _DateRow({required this.date, required this.day, required this.today});

  final CoupleDate date;
  final DateTime day;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final muted = TextStyle(fontSize: 13, color: scheme.onSurfaceVariant);
    final reminder = _reminder(context, date, muted);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: scheme.outlineVariant)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            date.title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 2),
          Text(_when(l10n, day, today), style: muted),
          ?reminder,
        ],
      ),
    );
  }
}

class _EmptyDates extends StatelessWidget {
  const _EmptyDates();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    return CoupleCard(
      key: const Key('agenda-dates-empty'),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.coupleAgendaDatesEmptyTitle,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.coupleAgendaDatesEmptyLine,
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
