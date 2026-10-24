import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/services/jewish_calendar_service.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../l10n/l10n.dart';
import '../../../common/widgets/mazl_components.dart';
import '../l10n/jewish_calendar_labels.dart';

DateTime _dayOnly(DateTime date) => DateTime(date.year, date.month, date.day);

String _dayKey(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

class JewishCalendarScreen extends StatefulWidget {
  const JewishCalendarScreen({super.key});

  @override
  State<JewishCalendarScreen> createState() => _JewishCalendarScreenState();
}

class _JewishCalendarScreenState extends State<JewishCalendarScreen> {
  final JewishCalendarService _calendarService = JewishCalendarService();

  late DateTime _visibleMonth = DateTime(
    DateTime.now().year,
    DateTime.now().month,
  );
  DateTime? _selectedDay;

  void _shiftMonth(int delta) {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + delta);
    });
  }

  void _selectDay(DateTime day) {
    setState(() {
      _selectedDay = _selectedDay == day ? null : day;
    });
  }

  /// Every day covered by one of [holidays], for the dots of the grid.
  Set<DateTime> _holidayDays(List<JewishHoliday> holidays) {
    final days = <DateTime>{};
    for (final holiday in holidays) {
      final first = _dayOnly(holiday.date);
      final last = _dayOnly(holiday.endDate ?? holiday.date);
      for (
        var day = first;
        !day.isAfter(last);
        day = DateTime(day.year, day.month, day.day + 1)
      ) {
        days.add(day);
      }
    }
    return days;
  }

  bool _covers(JewishHoliday holiday, DateTime? day) {
    if (day == null) return false;
    final first = _dayOnly(holiday.date);
    final last = _dayOnly(holiday.endDate ?? holiday.date);
    return !day.isBefore(first) && !day.isAfter(last);
  }

  @override
  Widget build(BuildContext context) {
    final shabbat = _calendarService.getThisWeekShabbat();
    final holidays = _calendarService.getUpcomingHolidays();
    final shabbatActivities = _calendarService.getActivitiesForOccasion(
      JewishOccasion.shabbat,
    );
    final l10n = context.l10n;
    final top = MediaQuery.paddingOf(context).top;
    final bottom = MediaQuery.paddingOf(context).bottom;
    final titleStyle = Theme.of(context).textTheme.titleLarge;

    return Scaffold(
      body: ListView(
        padding: EdgeInsets.fromLTRB(24, top + 16, 24, bottom + 24),
        children: [
          Text(
            l10n.coupleSpaceCalendarTitle,
            style: const TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.w700,
              letterSpacing: -2,
              height: 1.05,
            ),
          ),
          const SizedBox(height: 24),
          _MonthGrid(
            month: _visibleMonth,
            holidayDays: _holidayDays(holidays),
            selectedDay: _selectedDay,
            onSelect: _selectDay,
            onPrevious: () => _shiftMonth(-1),
            onNext: () => _shiftMonth(1),
          ),
          const SizedBox(height: 32),
          _ShabbatCard(shabbat: shabbat),
          const SizedBox(height: 32),
          Text(l10n.coupleSpaceCalendarShabbatIdeas, style: titleStyle),
          const SizedBox(height: 12),
          for (final activity in shabbatActivities)
            _ActivityCard(activity: activity),
          const SizedBox(height: 20),
          Text(l10n.coupleSpaceCalendarUpcoming, style: titleStyle),
          const SizedBox(height: 12),
          for (final holiday in holidays)
            _HolidayCard(
              holiday: holiday,
              highlighted: _covers(holiday, _selectedDay),
            ),
        ],
      ),
    );
  }
}

/// Grille d'un mois : jour courant en pastille d'encre, jour choisi en
/// pastille d'accent, jours de fête marqués d'un point sous le chiffre.
class _MonthGrid extends StatelessWidget {
  const _MonthGrid({
    required this.month,
    required this.holidayDays,
    required this.selectedDay,
    required this.onSelect,
    required this.onPrevious,
    required this.onNext,
  });

  final DateTime month;
  final Set<DateTime> holidayDays;
  final DateTime? selectedDay;
  final ValueChanged<DateTime> onSelect;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final locale = l10n.localeName;
    final today = _dayOnly(DateTime.now());
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    // The week starts on the day the language says (Monday in French, Sunday
    // in English and Hebrew); `weekday % 7` counts Sunday as 0.
    final firstDay = MaterialLocalizations.of(context).firstDayOfWeekIndex;
    final leading =
        (DateTime(month.year, month.month).weekday % 7 - firstDay + 7) % 7;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final weekdayInitials = [
      for (var i = 0; i < 7; i++)
        // 7 January 2024 was a Sunday.
        DateFormat.EEEEE(locale).format(DateTime(2024, 1, 7 + (firstDay + i) % 7)),
    ];
    final cellCount = ((leading + daysInMonth + 6) ~/ 7) * 7;

    DateTime dayAt(int cell) =>
        DateTime(month.year, month.month, cell - leading + 1);

    final rows = <Widget>[];
    for (var start = 0; start < cellCount; start += 7) {
      rows.add(
        Row(
          children: [
            for (var cell = start; cell < start + 7; cell++)
              Expanded(
                child: cell < leading || cell >= leading + daysInMonth
                    ? const SizedBox(height: 48)
                    : _DayCell(
                        day: dayAt(cell),
                        isToday: dayAt(cell) == today,
                        isSelected: dayAt(cell) == selectedDay,
                        hasHoliday: holidayDays.contains(dayAt(cell)),
                        onTap: onSelect,
                      ),
              ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                toBeginningOfSentenceCase(
                  DateFormat.yMMMM(locale).format(month),
                  locale,
                )!,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            RoundIconButton(
              icon: rtl ? LucideIcons.chevronRight : LucideIcons.chevronLeft,
              tooltip: l10n.coupleSpaceCalendarPrevMonth,
              size: 40,
              iconSize: 18,
              onPressed: onPrevious,
            ),
            const SizedBox(width: 8),
            RoundIconButton(
              icon: rtl ? LucideIcons.chevronLeft : LucideIcons.chevronRight,
              tooltip: l10n.coupleSpaceCalendarNextMonth,
              size: 40,
              iconSize: 18,
              onPressed: onNext,
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            for (final initial in weekdayInitials)
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
        ...rows,
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.isToday,
    required this.isSelected,
    required this.hasHoliday,
    required this.onTap,
  });

  final DateTime day;
  final bool isToday;
  final bool isSelected;
  final bool hasHoliday;
  final ValueChanged<DateTime> onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
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

    return Semantics(
      button: true,
      selected: isSelected,
      label: DateFormat.MMMMd(context.l10n.localeName).format(day),
      excludeSemantics: true,
      onTap: () => onTap(day),
      child: GestureDetector(
        key: Key('calendar-cell-${_dayKey(day)}'),
        behavior: HitTestBehavior.opaque,
        onTap: () => onTap(day),
        child: SizedBox(
          height: 48,
          child: Stack(
            alignment: Alignment.topCenter,
            children: [
              Container(
                key: Key('calendar-day-${_dayKey(day)}'),
                width: 38,
                height: 38,
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
              if (hasHoliday)
                Positioned(
                  bottom: 1,
                  child: Container(
                    key: Key('calendar-dot-${_dayKey(day)}'),
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: scheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Fond brume, rayon 24 : la carte de base du calendrier.
class _MistCard extends StatelessWidget {
  const _MistCard({required this.child, this.highlighted = false});

  final Widget child;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(24),
        border: highlighted
            ? Border.all(color: scheme.primary, width: 1.5)
            : null,
      ),
      child: child,
    );
  }
}

class _ShabbatCard extends StatelessWidget {
  const _ShabbatCard({required this.shabbat});

  final ShabbatInfo shabbat;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    String clock(DateTime? moment, String fallback) => moment == null
        ? fallback
        : DateFormat.Hm(l10n.localeName).format(moment);
    return _MistCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionLabel(l10n.jewishCalendarShabbatTitle),
          const SizedBox(height: 8),
          Text(
            l10n.jewishCalendarParashat(shabbat.parsha.title(l10n)),
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontSize: 22),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _ShabbatTime(
                  label: l10n.jewishCalendarCandleLighting,
                  time: clock(shabbat.candleLightingAt, shabbat.candleLighting),
                  icon: LucideIcons.flame,
                ),
              ),
              Container(width: 1, height: 48, color: scheme.outline),
              Expanded(
                child: _ShabbatTime(
                  label: l10n.jewishCalendarHavdalah,
                  time: clock(shabbat.havdalaAt, shabbat.havdala),
                  icon: LucideIcons.star,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ShabbatTime extends StatelessWidget {
  const _ShabbatTime({
    required this.label,
    required this.time,
    required this.icon,
  });

  final String label;
  final String time;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: scheme.onSurfaceVariant),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          time,
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.8,
          ),
        ),
      ],
    );
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({required this.activity});

  final OccasionActivity activity;

  IconData get _icon {
    switch (activity.icon) {
      case 'utensils':
        return LucideIcons.utensilsCrossed;
      case 'flame':
        return LucideIcons.flame;
      case 'footprints':
        return LucideIcons.footprints;
      case 'book':
        return LucideIcons.bookOpen;
      default:
        return LucideIcons.heart;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _MistCard(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: scheme.surface,
                shape: BoxShape.circle,
              ),
              child: Icon(_icon, size: 20, color: scheme.onSurface),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionLabel(activity.category.label(l10n)),
                  const SizedBox(height: 4),
                  Text(
                    activity.id.title(l10n),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    activity.id.body(l10n),
                    style: TextStyle(
                      fontSize: 14,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HolidayCard extends StatelessWidget {
  const _HolidayCard({required this.holiday, required this.highlighted});

  final JewishHoliday holiday;
  final bool highlighted;

  String _dateLabel(AppLocalizations l10n) {
    final locale = l10n.localeName;
    final start = holiday.date;
    final end = holiday.endDate;
    final first = DateFormat.MMMd(locale).format(start);
    if (end == null || _dayOnly(end) == _dayOnly(start)) return first;
    if (end.month == start.month) {
      return l10n.coupleSpaceCalendarRangeSameMonth(
        '${start.day}',
        '${end.day}',
        DateFormat.MMM(locale).format(start),
      );
    }
    return l10n.coupleSpaceCalendarRangeOtherMonth(
      first,
      DateFormat.MMMd(locale).format(end),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final ideas = holiday.ideas;
    final String? status = holiday.isOngoing
        ? l10n.coupleSpaceCalendarOngoing
        : holiday.daysUntil <= 7
        ? l10n.coupleSpaceCalendarCountdown(holiday.daysUntil)
        : null;
    // In Hebrew the name already is the Hebrew name: show it once.
    final showHebrewName = l10n.localeName != 'he';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _MistCard(
        highlighted: highlighted,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: SectionLabel(_dateLabel(l10n))),
                if (status != null) SectionLabel(status, color: scheme.primary),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.end,
              spacing: 8,
              children: [
                Text(
                  holiday.id.title(l10n),
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontSize: 20),
                ),
                if (showHebrewName)
                  Text(
                    holiday.hebrewName,
                    style: TextStyle(
                      fontSize: 15,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              holiday.id.description(l10n),
              style: TextStyle(fontSize: 14, color: scheme.onSurfaceVariant),
            ),
            if (ideas.isNotEmpty) ...[
              const SizedBox(height: 16),
              SectionLabel(l10n.coupleSpaceCalendarIdeas),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [for (final idea in ideas) _IdeaChip(idea.label(l10n))],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _IdeaChip extends StatelessWidget {
  const _IdeaChip(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 13, color: scheme.onSurface),
      ),
    );
  }
}
