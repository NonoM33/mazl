import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../../core/theme/app_typography.dart';
import '../../../../l10n/l10n.dart';
import 'agenda_marks.dart';

/// The dot that tells what a day holds: a full accent dot is a date that
/// matters to the couple, an accent ring a Jewish holiday, an ink dot a day of
/// an enabled ritual.
class AgendaMarkDot extends StatelessWidget {
  const AgendaMarkDot({super.key, required this.mark, this.size = 5});

  final AgendaMark mark;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ring = mark == AgendaMark.holiday;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: ring
            ? null
            : mark == AgendaMark.importantDate
            ? scheme.primary
            : scheme.onSurface,
        border: ring ? Border.all(color: scheme.primary, width: 1.4) : null,
      ),
    );
  }
}

/// The words for the marks of a day, for the screen reader and the legend.
String agendaMarkLabel(AppLocalizations l10n, AgendaMark mark) =>
    switch (mark) {
      AgendaMark.importantDate => l10n.coupleAgendaLegendDate,
      AgendaMark.holiday => l10n.coupleAgendaLegendHoliday,
      AgendaMark.ritual => l10n.coupleAgendaLegendRitual,
    };

/// The grid of one month: seven columns, the week starting on the day the
/// language says (Monday in French, Sunday in English and Hebrew), today as an
/// ink disc, the chosen day as an accent disc, a row of dots under each day.
class AgendaMonthGrid extends StatelessWidget {
  const AgendaMonthGrid({
    super.key,
    required this.month,
    required this.today,
    required this.selected,
    required this.marks,
    required this.onSelect,
    this.cellHeight = 48,
  });

  final DateTime month;
  final DateTime today;
  final DateTime? selected;
  final AgendaMarks marks;
  final ValueChanged<DateTime> onSelect;

  /// 48 pt, 44 pt (the smallest touch target) when the grid is squeezed above
  /// the fold.
  final double cellHeight;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final locale = context.l10n.localeName;
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    // `weekday % 7` counts Sunday as 0, like `firstDayOfWeekIndex`.
    final firstDay = MaterialLocalizations.of(context).firstDayOfWeekIndex;
    final leading =
        (DateTime(month.year, month.month).weekday % 7 - firstDay + 7) % 7;
    final initials = [
      for (var i = 0; i < 7; i++)
        // 7 January 2024 was a Sunday.
        DateFormat.EEEEE(
          locale,
        ).format(DateTime(2024, 1, 7 + (firstDay + i) % 7)),
    ];
    final cellCount = ((leading + daysInMonth + 6) ~/ 7) * 7;

    DateTime dayAt(int cell) =>
        DateTime(month.year, month.month, cell - leading + 1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            for (final initial in initials)
              Expanded(
                child: Center(
                  child: Text(
                    initial,
                    style: AppTypography.eyebrow(scheme.onSurfaceVariant),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        for (var start = 0; start < cellCount; start += 7)
          Row(
            children: [
              for (var cell = start; cell < start + 7; cell++)
                Expanded(
                  child: cell < leading || cell >= leading + daysInMonth
                      ? SizedBox(height: cellHeight)
                      : _DayCell(
                          day: dayAt(cell),
                          height: cellHeight,
                          isToday: dayAt(cell) == today,
                          isSelected: dayAt(cell) == selected,
                          marks: marks.on(dayAt(cell)),
                          onTap: onSelect,
                        ),
                ),
            ],
          ),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.height,
    required this.isToday,
    required this.isSelected,
    required this.marks,
    required this.onTap,
  });

  final DateTime day;
  final double height;
  final bool isToday;
  final bool isSelected;
  final Set<AgendaMark> marks;
  final ValueChanged<DateTime> onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final Color? fill;
    final Color textColor;
    if (isSelected) {
      fill = scheme.primary;
      textColor = scheme.onPrimary;
    } else if (isToday) {
      fill = scheme.onSurface;
      textColor = scheme.surface;
    } else {
      fill = null;
      textColor = scheme.onSurface;
    }
    final date = DateFormat.MMMMd(l10n.localeName).format(day);
    final label = marks.isEmpty
        ? date
        : l10n.coupleAgendaDaySemantics(
            date,
            [for (final mark in marks) agendaMarkLabel(l10n, mark)].join(', '),
          );
    final disc = height - 12;
    return Semantics(
      button: true,
      selected: isSelected,
      label: label,
      excludeSemantics: true,
      onTap: () => onTap(day),
      child: GestureDetector(
        key: Key('agenda-cell-${agendaDayKey(day)}'),
        behavior: HitTestBehavior.opaque,
        onTap: () => onTap(day),
        child: SizedBox(
          height: height,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                key: Key('agenda-day-${agendaDayKey(day)}'),
                width: disc,
                height: disc,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: fill, shape: BoxShape.circle),
                child: Text(
                  '${day.day}',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: isToday || isSelected
                        ? FontWeight.w600
                        : FontWeight.w400,
                    color: textColor,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              SizedBox(
                height: 5,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final mark in AgendaMark.values)
                      if (marks.contains(mark))
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 1.5),
                          child: KeyedSubtree(
                            key: Key(
                              'agenda-dot-${mark.name}-${agendaDayKey(day)}',
                            ),
                            child: AgendaMarkDot(mark: mark),
                          ),
                        ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Under the grid: what each kind of dot means.
class AgendaLegend extends StatelessWidget {
  const AgendaLegend({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    return Wrap(
      spacing: 16,
      runSpacing: 6,
      children: [
        for (final mark in AgendaMark.values)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AgendaMarkDot(mark: mark, size: 8),
              const SizedBox(width: 6),
              Text(
                agendaMarkLabel(l10n, mark),
                style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
              ),
            ],
          ),
      ],
    );
  }
}
