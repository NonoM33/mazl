import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/layout/column_app_bar.dart';
import '../../../../core/layout/fold_spread.dart';
import '../../../../core/models/couple_daily.dart';
import '../../../../core/services/couple_call.dart';
import '../../../../core/services/couple_daily_api.dart';
import '../../../../core/services/couple_service.dart';
import '../../../../l10n/l10n.dart';
import '../../../common/widgets/fold_pages.dart';
import '../../../common/widgets/mazl_components.dart';
import '../l10n/checkin_labels.dart';
import '../widgets/checkin_scale.dart';
import '../widgets/checkin_summary_card.dart';
import '../widgets/couple_message_view.dart';

/// The monthly check-in (docs/couple/ESPACE-COUPLE.md §0.4 and §6): three
/// notes from 1 to 5, given alone. Afterwards the screen only shows that the
/// member answered, who is awaited, and the summary once both have: the
/// notes of either are never shown again (the model does not even hold the
/// other's).
class CoupleCheckinScreen extends StatefulWidget {
  const CoupleCheckinScreen({super.key, this.api, this.couple});

  /// Injected by tests; the app uses the real client and service.
  final CoupleDailyApi? api;
  final CoupleService? couple;

  @override
  State<CoupleCheckinScreen> createState() => _CoupleCheckinScreenState();
}

class _CoupleCheckinScreenState extends State<CoupleCheckinScreen> {
  late final CoupleDailyApi _api = widget.api ?? CoupleDailyApi.forApp();
  late final CoupleService _couple = widget.couple ?? CoupleService();

  final Map<CheckinTheme, int> _scores = {};
  bool _loading = true;
  bool _sending = false;
  CoupleFailure? _failure;
  CoupleCheckin? _checkin;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _failure = null;
    });
    final result = await _api.getCheckin();
    if (!mounted) return;
    setState(() {
      _loading = false;
      _failure = result.failureOrNull;
      _checkin = result.valueOrNull;
    });
  }

  bool get _complete => _scores.length == CheckinTheme.values.length;

  Future<void> _send() async {
    if (!_complete || _sending) return;
    final scores = CheckinScores(
      talk: _scores[CheckinTheme.talk]!,
      time: _scores[CheckinTheme.time]!,
      close: _scores[CheckinTheme.close]!,
    );
    setState(() => _sending = true);
    final result = await _api.submitCheckin(scores);
    if (!mounted) return;
    final sent = result.valueOrNull;
    if (sent != null && sent.mine != null) {
      setState(() {
        _sending = false;
        _checkin = sent;
      });
      return;
    }
    // Already answered (409), or an answer the contract does not describe
    // (§6 gives the shape of the POST body, not of its reply): the server
    // knows best, read the check-in again.
    final kind = result.failureOrNull?.kind;
    if (sent != null ||
        kind == CoupleFailureKind.alreadyDone ||
        kind == CoupleFailureKind.malformed) {
      await _reloadAfterSend();
      return;
    }
    setState(() => _sending = false);
    showCoupleError(context, context.l10n.coupleCheckinSendFailed);
  }

  Future<void> _reloadAfterSend() async {
    final reloaded = await _api.getCheckin();
    if (!mounted) return;
    final fresh = reloaded.valueOrNull;
    if (reloaded.failureOrNull == null && fresh != null && fresh.answered) {
      setState(() {
        _sending = false;
        _checkin = fresh;
      });
      return;
    }
    setState(() => _sending = false);
    showCoupleError(context, context.l10n.coupleCheckinSendFailed);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: ColumnAppBar(
      appBar: AppBar(
        title: Text(context.l10n.coupleCheckinTitle),
        leading: CloseButton(onPressed: () => Navigator.maybePop(context)),
      ),
    ),
    body: _buildBody(context),
  );

  Widget _buildBody(BuildContext context) {
    final l10n = context.l10n;
    if (_loading) return const FoldSpinner();
    final failure = _failure;
    if (failure != null) {
      return CoupleMessageView.failure(failure, onRetry: _load);
    }
    final checkin = _checkin;
    if (checkin == null) {
      return CoupleMessageView(
        title: l10n.coupleCheckinEmptyTitle,
        line: l10n.coupleCheckinEmptyLine,
      );
    }
    final padding = MediaQuery.paddingOf(context);
    return FoldSpread(
      wideFrom: 560,
      laptopVolets: true,
      padding: EdgeInsets.fromLTRB(24, 16, 24, padding.bottom + 24),
      start: _lead(context, checkin),
      end: checkin.answered ? _done(context, checkin) : _form(context),
    );
  }

  String _month(BuildContext context, String period) {
    final parts = period.split('-');
    final year = parts.length == 2 ? int.tryParse(parts[0]) : null;
    final month = parts.length == 2 ? int.tryParse(parts[1]) : null;
    if (year == null || month == null || month < 1 || month > 12) {
      return period;
    }
    return DateFormat(
      'LLLL',
      context.l10n.localeName,
    ).format(DateTime(year, month));
  }

  List<Widget> _lead(BuildContext context, CoupleCheckin checkin) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return [
      SectionLabel(l10n.coupleCheckinEyebrow(_month(context, checkin.period))),
      const SizedBox(height: 8),
      Text(
        checkin.answered
            ? l10n.coupleCheckinDoneHeading
            : l10n.coupleCheckinHeading,
        style: theme.textTheme.displaySmall?.copyWith(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          height: 1.2,
        ),
      ),
      if (!checkin.answered) ...[
        const SizedBox(height: 8),
        Text(
          l10n.coupleCheckinIntro,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.45,
          ),
        ),
      ],
    ];
  }

  List<Widget> _form(BuildContext context) {
    final l10n = context.l10n;
    return [
      for (final theme in CheckinTheme.values) ...[
        CheckinScale(
          question: theme.label(l10n),
          value: _scores[theme],
          onChanged: _sending
              ? (_) {}
              : (n) => setState(() => _scores[theme] = n),
        ),
        const SizedBox(height: 8),
      ],
      const SizedBox(height: 4),
      ElevatedButton(
        onPressed: _complete && !_sending ? _send : null,
        child: _sending
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Theme.of(context).colorScheme.surface,
                ),
              )
            : Text(l10n.coupleCheckinSend),
      ),
    ];
  }

  List<Widget> _done(BuildContext context, CoupleCheckin checkin) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final summary = checkin.summary;
    if (summary != null) return [CheckinSummaryCard(summary: summary)];
    if (checkin.partnerDone) return const [];
    final name =
        _couple.coupleData?.partnerName ?? l10n.coupleQuestionPartnerFallback;
    return [
      Text(
        l10n.coupleCheckinWaiting(name),
        style: theme.textTheme.bodyLarge?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          height: 1.45,
        ),
      ),
    ];
  }
}
