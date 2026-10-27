import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/layout/fold_cut.dart';
import '../../../../core/layout/fold_spread.dart';
import '../../../../core/models/couple_daily.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/couple_api_service.dart';
import '../../../../core/services/couple_daily_api.dart';
import '../../../../core/services/couple_service.dart';
import '../../../../core/services/jewish_calendar_service.dart';
import '../../../../l10n/l10n.dart';
import '../../../common/widgets/fold_pages.dart';
import '../l10n/couple_failure_label.dart';
import '../widgets/couple_message_view.dart';
import '../widgets/today_header.dart';
import '../widgets/today_link_row.dart';
import '../widgets/today_mood.dart';
import '../widgets/today_outing_card.dart';
import '../widgets/today_question_card.dart';
import '../widgets/today_shabbat_card.dart';
import '../widgets/today_upcoming.dart';
import '../../../common/widgets/star_refresh/star_refresh.dart';

/// The first tab of the couple space: the day of the two of them (the
/// question, Shabbat, what is coming, an idea, how it goes between them).
class CoupleTodayScreen extends StatefulWidget {
  const CoupleTodayScreen({super.key, this.api, this.clock});

  /// Injected by tests; the app uses the real client.
  final CoupleDailyApi? api;

  /// « Now », replaceable in the tests.
  final DateTime Function()? clock;

  @override
  State<CoupleTodayScreen> createState() => _CoupleTodayScreenState();
}

class _CoupleTodayScreenState extends State<CoupleTodayScreen> {
  late final CoupleDailyApi _api = widget.api ?? CoupleDailyApi.forApp();
  late final DateTime _now = (widget.clock ?? DateTime.now)();
  late final ShabbatInfo _shabbat = JewishCalendarService().getThisWeekShabbat(
    now: _now,
  );

  CoupleToday? _today;
  CoupleMoodChoice? _mood;
  CoupleFailure? _failure;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// Reads the page. [quiet] keeps what is shown while loading (pull to
  /// refresh, back from a page) and, on failure, keeps it and says so.
  Future<void> _load({bool quiet = false}) async {
    if (!quiet) {
      setState(() {
        _loading = true;
        _failure = null;
      });
    }
    final result = await _api.getToday();
    if (!mounted) return;
    final failure = result.failureOrNull;
    if (failure == null) return _show(result.valueOrNull!);
    if (failure.kind == CoupleFailureKind.routeMissing) {
      return _show(_pageFromCouple());
    }
    if (quiet && _today != null) {
      final l10n = context.l10n;
      showCoupleError(
        context,
        l10n.coupleSpaceRefreshFailed(failure.label(l10n)),
      );
      return;
    }
    setState(() {
      _loading = false;
      _failure = failure;
    });
  }

  void _show(CoupleToday today) => setState(() {
    _today = today;
    _mood = today.myMood;
    _failure = null;
    _loading = false;
  });

  /// The page of a server that has no `/today` yet: only what the couple
  /// already says (days, partner, subscription).
  CoupleToday _pageFromCouple() {
    final couple = CoupleService().coupleData;
    return CoupleToday(
      days: couple?.daysTogether ?? 0,
      partnerId: couple?.partnerId ?? 0,
      partnerName:
          couple?.partnerName ?? context.l10n.coupleSpacePartnerFallback,
      partnerPicture: couple?.partnerPicture,
      premium: CoupleService().premium,
    );
  }

  /// Opens a page over this one, then re-reads this one (an answer may have
  /// been given, a subscription taken).
  Future<void> _open(String path) async {
    await context.push<Object?>(path);
    if (mounted) await _load(quiet: true);
  }

  Future<void> _setMood(CoupleMoodChoice mood) async {
    final previous = _mood;
    if (previous == mood) return;
    setState(() => _mood = mood);
    final result = await _api.setMood(mood);
    if (!mounted || result.isOk || _mood != mood) return;
    setState(() => _mood = previous);
    showCoupleError(context, context.l10n.coupleTodayMoodFailed);
  }

  void _openUpcoming(CoupleUpcoming item) {
    final id = item.refId;
    if (id != null) _open(RoutePaths.coupleEventPath(id));
  }

  void _openOuting(Outing outing) => _open(
    outing.isEvent
        ? RoutePaths.coupleEventPath(outing.id)
        : RoutePaths.coupleActivityPath(outing.id),
  );

  String? get _memberFirstName {
    final words = AuthService().currentUser?.displayName?.trim().split(
      RegExp(r'\s+'),
    );
    final first = words?.first;
    return first == null || first.isEmpty ? null : first;
  }

  @override
  Widget build(BuildContext context) {
    final today = _today;
    return Scaffold(
      body: _loading && today == null
          ? const FoldSpinner()
          : today == null
          ? CoupleMessageView.failure(_failure!, onRetry: _load)
          : _page(today),
    );
  }

  Widget _page(CoupleToday today) {
    final padding = MediaQuery.paddingOf(context);
    return StarRefresh(
      onRefresh: () => _load(quiet: true),
      // Held like a book: the greeting, the question and Shabbat on the first
      // page; what is coming, the idea and the mood on the other. Like a
      // laptop the greeting and the question stay above the fold.
      child: FoldCutBuilder(
        builder: (context, cut) {
          final compact = cut?.axis == FoldSplitAxis.horizontal;
          return FoldSpread(
            laptopVolets: true,
            padding: EdgeInsets.fromLTRB(
              24,
              padding.top + 16,
              24,
              padding.bottom + 24,
            ),
            start: _start(today, compact),
            end: _end(today, compact),
          );
        },
      ),
    );
  }

  List<Widget> _start(CoupleToday today, bool compact) {
    final question = today.question;
    return [
      TodayHeader(
        days: today.days,
        partnerName: today.partnerName,
        memberName: _memberFirstName,
        memberPhotoUrl: AuthService().currentUser?.photoUrl,
        partnerPhotoUrl: today.partnerPicture,
        compact: compact,
      ),
      if (question != null) ...[
        SizedBox(height: compact ? 12 : 20),
        TodayQuestionCard(
          text: question.text,
          partnerName: today.partnerName,
          myAnswered: question.myAnswered,
          partnerAnswered: question.partnerAnswered,
          onOpen: () => _open(RoutePaths.coupleQuestion),
        ),
      ],
      if (!compact) ...[const SizedBox(height: 20), _shabbatCard()],
    ];
  }

  Widget _shabbatCard() => TodayShabbatCard(
    shabbat: _shabbat,
    isFriday: _now.weekday == DateTime.friday,
    onOpenAgenda: () => context.go(RoutePaths.coupleAgenda),
  );

  List<Widget> _end(CoupleToday today, bool compact) {
    final outing = today.outing;
    return [
      if (compact) ...[_shabbatCard(), const SizedBox(height: 20)],
      TodayUpcoming(items: today.upcoming, now: _now, onOpen: _openUpcoming),
      if (outing != null) ...[
        const SizedBox(height: 18),
        TodayOutingCard(outing: outing, onOpen: () => _openOuting(outing)),
      ],
      const SizedBox(height: 24),
      TodayMood(
        selected: _mood,
        partnerName: today.partnerName,
        onSelect: _setMood,
      ),
      if (today.checkinDue) ...[
        const SizedBox(height: 16),
        TodayLinkRow(
          icon: LucideIcons.clipboardCheck,
          label: context.l10n.coupleTodayCheckinDue(
            _checkinMonth(today.checkinPeriod),
          ),
          onTap: () => _open(RoutePaths.coupleCheckin),
        ),
      ],
      if (!today.premium.active) ...[
        const SizedBox(height: 16),
        TodayLinkRow(
          icon: LucideIcons.sparkles,
          label: context.l10n.coupleTodayPremiumLine,
          onTap: () => _open(RoutePaths.couplePremium),
        ),
      ],
    ];
  }

  /// « 2026-11 » → « novembre » (the current month when the period is not a
  /// month the server wrote).
  String _checkinMonth(String? period) {
    final parts = period?.split('-');
    final month = parts != null && parts.length == 2
        ? int.tryParse(parts[1])
        : null;
    final date = DateTime(
      _now.year,
      month != null && month >= 1 && month <= 12 ? month : _now.month,
    );
    return DateFormat.MMMM(context.l10n.localeName).format(date);
  }
}
