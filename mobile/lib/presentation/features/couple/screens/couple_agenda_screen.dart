import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/layout/fold_cut.dart';
import '../../../../core/layout/fold_spread.dart';
import '../../../../core/models/couple_daily.dart';
import '../../../../core/models/couple_space.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/services/couple_api_service.dart';
import '../../../../core/services/couple_daily_api.dart';
import '../../../../core/services/couple_service.dart';
import '../../../../core/services/jewish_calendar_service.dart';
import '../../../../l10n/l10n.dart';
import '../../../common/widgets/directional_icon.dart';
import '../../../common/widgets/fold_pages.dart';
import '../../../common/widgets/mazl_components.dart';
import '../../../common/widgets/mazl_sheet.dart';
import '../l10n/couple_failure_label.dart';
import '../widgets/agenda_buttons.dart';
import '../widgets/agenda_dates.dart';
import '../widgets/agenda_marks.dart';
import '../widgets/agenda_month_grid.dart';
import '../widgets/agenda_rituals.dart';
import '../widgets/couple_message_view.dart';
import 'couple_space_sheets.dart';

/// The agenda tab of the couple space: the month with what each day holds
/// (the couple's dates, the Jewish holidays, the days of the enabled
/// rituals), the rituals with their switch, and the dates that matter.
///
/// The rituals and the dates are two sources that load on their own: one that
/// fails does not hide the other.
class CoupleAgendaScreen extends StatefulWidget {
  const CoupleAgendaScreen({
    super.key,
    this.api,
    this.contentApi,
    this.now,
    this.holidays,
  });

  /// Injected by tests; the app uses the real clients.
  final CoupleDailyApi? api;
  final CoupleApiService? contentApi;

  /// The clock (tests set it).
  final DateTime Function()? now;

  /// The Jewish holidays of the calendar (tests set them); the app computes
  /// them locally.
  final List<JewishHoliday> Function()? holidays;

  @override
  State<CoupleAgendaScreen> createState() => _CoupleAgendaScreenState();
}

class _CoupleAgendaScreenState extends State<CoupleAgendaScreen> {
  late final CoupleDailyApi _api = widget.api ?? CoupleDailyApi.forApp();
  late final CoupleApiService _content =
      widget.contentApi ?? CoupleApiService();
  late final List<JewishHoliday> _holidays =
      widget.holidays?.call() ?? JewishCalendarService().getUpcomingHolidays();

  late DateTime _month = DateTime(_today.year, _today.month);
  DateTime? _selected;

  List<CoupleRitual>? _rituals;
  CoupleFailure? _ritualsFailure;
  List<CoupleDate>? _dates;
  CoupleFailure? _datesFailure;
  bool _loading = true;
  final Set<int> _toggling = {};

  DateTime get _today => agendaDay((widget.now ?? DateTime.now)());

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    final (rituals, dates) = await (
      _api.getRituals(),
      _content.getDates(),
    ).wait;
    if (!mounted) return;
    setState(() {
      _loading = false;
      _applyRituals(rituals, quiet: false);
      _applyDates(dates, quiet: false);
    });
  }

  Future<void> _reloadRituals() async {
    final result = await _api.getRituals();
    if (!mounted) return;
    setState(() => _applyRituals(result, quiet: true));
  }

  Future<void> _reloadDates() async {
    final result = await _content.getDates();
    if (!mounted) return;
    setState(() => _applyDates(result, quiet: true));
  }

  /// Keeps what was shown when a reload fails, and says so.
  void _applyRituals(
    CoupleResult<List<CoupleRitual>> result, {
    bool quiet = false,
  }) {
    switch (result) {
      case CoupleOk(:final value):
        _rituals = value;
        _ritualsFailure = null;
      case CoupleFailed(:final failure):
        if (quiet && _rituals != null) {
          _announce(failure);
        } else {
          _ritualsFailure = failure;
        }
    }
  }

  void _applyDates(
    CoupleResult<List<CoupleDate>> result, {
    bool quiet = false,
  }) {
    switch (result) {
      case CoupleOk(:final value):
        _dates = value;
        _datesFailure = null;
      case CoupleFailed(:final failure):
        if (quiet && _dates != null) {
          _announce(failure);
        } else {
          _datesFailure = failure;
        }
    }
  }

  void _announce(CoupleFailure failure) {
    final l10n = context.l10n;
    showCoupleError(
      context,
      l10n.coupleSpaceRefreshFailed(failure.label(l10n)),
    );
  }

  void _shiftMonth(int delta) => setState(() {
    _month = DateTime(_month.year, _month.month + delta);
  });

  void _select(DateTime day) =>
      setState(() => _selected = _selected == day ? null : day);

  Future<void> _toggle(CoupleRitual ritual) async {
    if (!_toggling.add(ritual.id)) return;
    final next = !ritual.enabled;
    setState(() => _setEnabled(ritual.id, next));
    final result = await _api.setRitualEnabled(ritual.id, next);
    _toggling.remove(ritual.id);
    if (!mounted) return;
    if (result case CoupleFailed(:final failure)) {
      setState(() => _setEnabled(ritual.id, ritual.enabled));
      final l10n = context.l10n;
      showCoupleError(
        context,
        l10n.coupleAgendaToggleFailed(failure.label(l10n)),
      );
    }
  }

  void _setEnabled(int id, bool enabled) {
    _rituals = [
      for (final r in _rituals ?? const <CoupleRitual>[])
        r.id == id ? r.copyWith(enabled: enabled) : r,
    ];
  }

  Future<void> _addMoment() async {
    final added = await showMazlSheet<bool>(
      context,
      isScrollControlled: true,
      builder: (_) => AddDateSheet(apiService: _content),
    );
    if (added == true && mounted) await _reloadDates();
  }

  Future<void> _addRitual() async {
    final added = await showMazlSheet<bool>(
      context,
      isScrollControlled: true,
      builder: (_) => AddRitualSheet(api: _api, today: _today),
    );
    if (added == true && mounted) await _reloadRituals();
  }

  AgendaMarks get _marks => AgendaMarks(
    dates: _dates ?? const [],
    holidays: _holidays,
    rituals: _rituals ?? const [],
  );

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.paddingOf(context);
    return Scaffold(
      body: _body(
        EdgeInsets.fromLTRB(24, padding.top + 16, 24, padding.bottom + 24),
      ),
    );
  }

  Widget _body(EdgeInsets padding) {
    if (_loading) return const FoldSpinner();
    final ritualsFailure = _ritualsFailure;
    final datesFailure = _datesFailure;
    if (ritualsFailure != null && datesFailure != null) {
      return CoupleMessageView.failure(ritualsFailure, onRetry: _loadAll);
    }
    return FoldCutBuilder(
      minPaneExtent: 240,
      builder: (context, cut) {
        // Set down like a laptop the month is squeezed above the fold; the
        // legend, the day and the button go to the volet below.
        final laptop = cut?.axis == FoldSplitAxis.horizontal;
        final detail = _selected == null
            ? null
            : AgendaDayDetail(day: _selected!, marks: _marks);
        final grid = AgendaMonthGrid(
          month: _month,
          today: _today,
          selected: _selected,
          marks: _marks,
          onSelect: _select,
          cellHeight: laptop ? 44 : 48,
        );
        // A short single page (the Duo set up like a tent) has no room under
        // the month for the main button: it goes right under the title.
        final short = cut == null && MediaQuery.sizeOf(context).height < 560;
        final addMoment = AgendaPillButton(
          label: context.l10n.coupleAgendaAddMoment,
          icon: LucideIcons.plus,
          filled: true,
          expand: true,
          onTap: _addMoment,
        );
        final aboutMonth = <Widget>[
          const AgendaLegend(),
          if (detail != null) ...[const SizedBox(height: 12), detail],
          if (!short) ...[const SizedBox(height: 16), addMoment],
        ];
        return FoldSpread(
          laptopVolets: true,
          padding: padding,
          start: [
            _header(compact: laptop),
            if (short) ...[const SizedBox(height: 12), addMoment],
            SizedBox(height: laptop ? 8 : 16),
            grid,
            if (!laptop) ...[const SizedBox(height: 12), ...aboutMonth],
          ],
          end: [
            if (laptop) ...[...aboutMonth, const SizedBox(height: 28)],
            ..._ritualsSection(),
            const SizedBox(height: 28),
            ..._datesSection(),
          ],
        );
      },
    );
  }

  Widget _header({required bool compact}) {
    final l10n = context.l10n;
    final locale = l10n.localeName;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final month = DateFormat.yMMMM(locale).format(_month);
    final arrows = [
      RoundIconButton(
        icon: rtl ? LucideIcons.chevronRight : LucideIcons.chevronLeft,
        tooltip: l10n.coupleSpaceCalendarPrevMonth,
        iconSize: 18,
        onPressed: () => _shiftMonth(-1),
      ),
      const SizedBox(width: 8),
      RoundIconButton(
        icon: rtl ? LucideIcons.chevronLeft : LucideIcons.chevronRight,
        tooltip: l10n.coupleSpaceCalendarNextMonth,
        iconSize: 18,
        onPressed: () => _shiftMonth(1),
      ),
    ];
    if (compact) {
      return Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionLabel(month),
                const SizedBox(height: 4),
                Text(
                  l10n.coupleAgendaTitle,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ],
            ),
          ),
          ...arrows,
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: SectionLabel(month)),
            ...arrows,
          ],
        ),
        const SizedBox(height: 4),
        Text(
          l10n.coupleAgendaTitle,
          style: Theme.of(context).textTheme.displaySmall,
        ),
      ],
    );
  }

  List<Widget> _ritualsSection() {
    final l10n = context.l10n;
    final rituals = _rituals;
    final failure = _ritualsFailure;
    return [
      SectionLabel(l10n.coupleAgendaRitualsLabel),
      const SizedBox(height: 8),
      if (rituals == null && failure != null)
        _SourceFailure(
          line: l10n.coupleAgendaRitualsFailed(failure.label(l10n)),
          onRetry: _reloadRituals,
        )
      else if (rituals != null && rituals.isEmpty)
        _EmptyRituals()
      else
        for (final ritual in rituals ?? const <CoupleRitual>[])
          AgendaRitualRow(ritual: ritual, onToggle: () => _toggle(ritual)),
      const SizedBox(height: 12),
      AgendaPillButton(
        label: l10n.coupleAgendaAddRitual,
        icon: LucideIcons.plus,
        onTap: _addRitual,
      ),
      ListenableBuilder(
        listenable: CoupleService(),
        builder: (context, _) => CoupleService().premium.active
            ? const SizedBox.shrink()
            : const _PremiumReminders(),
      ),
    ];
  }

  List<Widget> _datesSection() {
    final l10n = context.l10n;
    final dates = _dates;
    final failure = _datesFailure;
    return [
      SectionLabel(l10n.coupleAgendaDatesLabel),
      const SizedBox(height: 8),
      if (dates == null && failure != null)
        _SourceFailure(
          line: l10n.coupleAgendaDatesFailed(failure.label(l10n)),
          onRetry: _reloadDates,
        )
      else
        AgendaDatesList(
          dates: dates ?? const [],
          today: _today,
          onPrepare: () => context.go(RoutePaths.coupleConcierge),
        ),
    ];
  }
}

/// A source that did not load, with its own retry: the other one stays.
class _SourceFailure extends StatelessWidget {
  const _SourceFailure({required this.line, required this.onRetry});

  final String line;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          line,
          style: TextStyle(fontSize: 14, color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 8),
        AgendaPillButton(label: context.l10n.commonRetry, onTap: onRetry),
      ],
    );
  }
}

class _EmptyRituals extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    return Column(
      key: const Key('agenda-rituals-empty'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.coupleAgendaRitualsEmptyTitle,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Text(
          l10n.coupleAgendaRitualsEmptyLine,
          style: TextStyle(
            fontSize: 13,
            height: 1.4,
            color: scheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// Under the rituals when the couple has no MAZL Couple: the switches work,
/// the push reminders do not.
class _PremiumReminders extends StatelessWidget {
  const _PremiumReminders();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      key: const Key('agenda-premium-reminders'),
      onTap: () => context.push(RoutePaths.couplePremium),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: kMinTapTarget),
        child: Row(
          children: [
            Expanded(
              child: Text(
                context.l10n.coupleAgendaRemindersPremium,
                style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
              ),
            ),
            DirectionalIcon(
              LucideIcons.chevronRight,
              size: 16,
              color: scheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
