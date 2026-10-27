import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../../core/models/couple_daily.dart';
import '../../../../core/services/couple_call.dart';
import '../../../../core/services/couple_daily_api.dart';
import '../../../../l10n/l10n.dart';
import '../../../common/widgets/mazl_components.dart';
import '../l10n/couple_failure_label.dart';
import 'agenda_buttons.dart';
import 'couple_kit.dart';

const _dayKeys = ['sun', 'mon', 'tue', 'wed', 'thu', 'fri', 'sat'];

/// « Chaque vendredi · rappel une heure avant les bougies »: the line that
/// says when a ritual happens and when it reminds, in the member's language.
String ritualMeta(AppLocalizations l10n, CoupleRitual ritual) {
  final weekday = ritual.weekday;
  var when = weekday == null
      ? l10n.coupleAgendaNoDay
      : l10n.coupleAgendaWeekly(_dayKeys[weekday % 7]);
  final time = _parseTime(ritual.time);
  if (time != null) {
    final clock = DateTime(2024, 1, 1, time.hour, time.minute);
    when = l10n.coupleAgendaAtTime(
      when,
      DateFormat.jm(l10n.localeName).format(clock),
    );
  }
  return l10n.coupleAgendaRitualMeta(when, _reminder(l10n, ritual));
}

String _reminder(AppLocalizations l10n, CoupleRitual ritual) {
  final minutes = ritual.remindMinutes;
  if (minutes <= 0) return l10n.coupleAgendaNoReminder;
  final candles = ritual.kind == CoupleRitualKind.shabbat;
  if (minutes % 60 == 0) {
    return candles
        ? l10n.coupleAgendaRemindHoursCandles(minutes ~/ 60)
        : l10n.coupleAgendaRemindHours(minutes ~/ 60);
  }
  return candles
      ? l10n.coupleAgendaRemindMinutesCandles(minutes)
      : l10n.coupleAgendaRemindMinutes(minutes);
}

TimeOfDay? _parseTime(String? raw) {
  if (raw == null) return null;
  final parts = raw.split(':');
  if (parts.length < 2) return null;
  final hour = int.tryParse(parts[0]);
  final minute = int.tryParse(parts[1]);
  if (hour == null || minute == null) return null;
  return TimeOfDay(hour: hour, minute: minute);
}

/// A switch drawn 52 x 32. It only paints: the whole row around it is the
/// control, so its touch target is far over 44 pt.
class AgendaSwitch extends StatelessWidget {
  const AgendaSwitch({super.key, required this.on});

  final bool on;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      width: 52,
      height: 32,
      padding: const EdgeInsets.all(3),
      alignment: on
          ? AlignmentDirectional.centerEnd
          : AlignmentDirectional.centerStart,
      decoration: BoxDecoration(
        color: on ? scheme.primary : scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: on ? scheme.primary : scheme.outline),
      ),
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: on ? scheme.onPrimary : scheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// One ritual: its title, the line that says when, and its switch. The whole
/// row toggles.
class AgendaRitualRow extends StatelessWidget {
  const AgendaRitualRow({
    super.key,
    required this.ritual,
    required this.onToggle,
  });

  final CoupleRitual ritual;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final meta = ritualMeta(l10n, ritual);
    return Semantics(
      container: true,
      toggled: ritual.enabled,
      label: l10n.coupleAgendaRitualSemantics(ritual.title, meta),
      onTap: onToggle,
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: scheme.outlineVariant)),
        ),
        child: InkWell(
          key: Key('agenda-ritual-${ritual.id}'),
          onTap: onToggle,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 64),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ritual.title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          meta,
                          style: TextStyle(
                            fontSize: 13,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  AgendaSwitch(on: ritual.enabled),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The form that adds a ritual: a name, a day of the week, an optional time.
/// Pops `true` once the server accepted it; on failure it stays open and says
/// why.
class AddRitualSheet extends StatefulWidget {
  const AddRitualSheet({super.key, required this.api, required this.today});

  final CoupleDailyApi api;
  final DateTime today;

  @override
  State<AddRitualSheet> createState() => _AddRitualSheetState();
}

class _AddRitualSheetState extends State<AddRitualSheet> {
  final _title = TextEditingController();
  late int _weekday = widget.today.weekday % 7;
  TimeOfDay? _time;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  String? get _wireTime {
    final time = _time;
    if (time == null) return null;
    return '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time ?? const TimeOfDay(hour: 20, minute: 0),
    );
    if (picked != null && mounted) setState(() => _time = picked);
  }

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final result = await widget.api.addRitual(
      title: _title.text.trim(),
      weekday: _weekday,
      time: _wireTime,
    );
    if (!mounted) return;
    switch (result) {
      case CoupleOk():
        Navigator.pop(context, true);
      case CoupleFailed(:final failure):
        final l10n = context.l10n;
        setState(() {
          _busy = false;
          _error = l10n.coupleSpaceAddFailed(failure.label(l10n));
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final locale = l10n.localeName;
    final time = _time;
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Text(
              l10n.coupleAgendaAddRitualTitle,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          TextField(
            controller: _title,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: l10n.coupleAgendaRitualFieldTitle,
            ),
          ),
          const SizedBox(height: 20),
          SectionLabel(l10n.coupleAgendaRitualFieldDay),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var day = 0; day < 7; day++)
                CouplePill(
                  label: toBeginningOfSentenceCase(
                    // 7 January 2024 was a Sunday.
                    DateFormat.EEEE(locale).format(DateTime(2024, 1, 7 + day)),
                    locale,
                  )!,
                  selected: _weekday == day,
                  onTap: () => setState(() => _weekday = day),
                ),
            ],
          ),
          const SizedBox(height: 20),
          SectionLabel(l10n.coupleAgendaRitualFieldTime),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: AgendaPillButton(
                  label: time == null
                      ? l10n.coupleAgendaRitualPickTime
                      : DateFormat.jm(
                          locale,
                        ).format(DateTime(2024, 1, 1, time.hour, time.minute)),
                  onTap: _pickTime,
                ),
              ),
              if (time != null)
                TextButton(
                  onPressed: () => setState(() => _time = null),
                  child: Text(l10n.coupleAgendaRitualClearTime),
                ),
            ],
          ),
          const SizedBox(height: 20),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: scheme.error),
              ),
            ),
          ListenableBuilder(
            listenable: _title,
            builder: (context, _) => ElevatedButton(
              onPressed: _title.text.trim().isEmpty || _busy ? null : _submit,
              child: _busy
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: scheme.surface,
                      ),
                    )
                  : Text(l10n.coupleSpaceSheetAdd),
            ),
          ),
        ],
      ),
    );
  }
}
