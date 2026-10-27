import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/layout/column_app_bar.dart';
import '../../../../core/layout/fold_spread.dart';
import '../../../../core/models/couple_daily.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/services/couple_call.dart';
import '../../../../core/services/couple_daily_api.dart';
import '../../../../core/services/couple_service.dart';
import '../../../../l10n/l10n.dart';
import '../../../common/widgets/fold_pages.dart';
import '../../../common/widgets/mazl_components.dart';
import '../widgets/couple_message_view.dart';
import '../widgets/question_cards.dart';
import '../widgets/question_composer.dart';

/// The question of the day (docs/couple/ESPACE-COUPLE.md §0.4 and §5): one
/// question for the couple, each answers on their own, and the other's answer
/// opens only once the member has answered.
///
/// What the screen can know before the member answers: `GET …/question` keeps
/// the partner's answer back, and says nothing about whether it exists. The
/// only source is `GET /api/couple/today` (`question.partnerAnswered`), read
/// on the side and used when it speaks of the same question. Without it the
/// locked block stays neutral. The partner's text never reaches the widget
/// tree before [CoupleQuestion.myAnswer] is set.
class CoupleQuestionScreen extends StatefulWidget {
  const CoupleQuestionScreen({super.key, this.api, this.couple});

  /// Injected by tests; the app uses the real client and service.
  final CoupleDailyApi? api;
  final CoupleService? couple;

  @override
  State<CoupleQuestionScreen> createState() => _CoupleQuestionScreenState();
}

class _CoupleQuestionScreenState extends State<CoupleQuestionScreen> {
  late final CoupleDailyApi _api = widget.api ?? CoupleDailyApi.forApp();
  late final CoupleService _couple = widget.couple ?? CoupleService();
  final TextEditingController _answer = TextEditingController();

  bool _loading = true;
  bool _sending = false;
  CoupleFailure? _failure;
  CoupleQuestion? _question;

  /// From the side read of today's page; `null` when it is not known.
  bool? _partnerAnswered;

  /// The day of the couple shown in the eyebrow; 0 hides it.
  int _day = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _answer.dispose();
    super.dispose();
  }

  int? get _coupleId => _couple.coupleData?.coupleId;

  String get _partnerName =>
      _couple.coupleData?.partnerName ??
      context.l10n.coupleQuestionPartnerFallback;

  Future<void> _load() async {
    final coupleId = _coupleId;
    setState(() {
      _loading = true;
      _failure = null;
    });
    if (coupleId == null) {
      setState(() {
        _loading = false;
        _question = null;
      });
      return;
    }
    final (question, today) = await (
      _api.getQuestion(coupleId),
      _api.getToday(),
    ).wait;
    if (!mounted) return;
    final failure = question.failureOrNull;
    if (failure != null) {
      setState(() {
        _loading = false;
        _failure = failure;
      });
      return;
    }
    final loaded = question.valueOrNull;
    final todayQuestion = today.valueOrNull?.question;
    // The server's day count comes first (it is the one the Today page
    // shows); the local count of the couple's start date is the fallback.
    final day =
        today.valueOrNull?.days ?? _couple.coupleData?.daysTogether ?? 0;
    setState(() {
      _loading = false;
      _question = loaded;
      _day = day;
      _partnerAnswered = todayQuestion != null && todayQuestion.id == loaded?.id
          ? todayQuestion.partnerAnswered
          : null;
    });
  }

  Future<void> _send() async {
    final coupleId = _coupleId;
    final question = _question;
    final text = _answer.text.trim();
    if (coupleId == null || question == null || text.isEmpty || _sending) {
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _sending = true);
    final sent = await _api.answerQuestion(
      coupleId: coupleId,
      questionId: question.id,
      answer: text,
    );
    if (!mounted) return;
    if (sent.failureOrNull != null) {
      setState(() => _sending = false);
      showCoupleError(context, context.l10n.coupleQuestionSendFailed);
      return;
    }
    final reloaded = await _api.getQuestion(coupleId);
    if (!mounted) return;
    final failure = reloaded.failureOrNull;
    final fresh = reloaded.valueOrNull;
    if (failure != null) {
      // The answer is saved; only the re-read failed: offer to retry it.
      setState(() {
        _sending = false;
        _failure = failure;
      });
      return;
    }
    if (fresh == null || !fresh.answered) {
      setState(() => _sending = false);
      showCoupleError(context, context.l10n.coupleQuestionSendFailed);
      return;
    }
    setState(() {
      _sending = false;
      _question = fresh;
      _answer.clear();
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: ColumnAppBar(
      appBar: AppBar(title: Text(context.l10n.coupleQuestionTitle)),
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
    final question = _question;
    if (question == null) {
      return CoupleMessageView(
        title: l10n.coupleQuestionEmptyTitle,
        line: l10n.coupleQuestionEmptyLine,
      );
    }
    final padding = MediaQuery.paddingOf(context);
    return FoldSpread(
      wideFrom: 560,
      laptopVolets: true,
      padding: EdgeInsets.fromLTRB(24, 16, 24, padding.bottom + 24),
      start: _lead(context, question),
      end: _action(context, question),
    );
  }

  List<Widget> _lead(BuildContext context, CoupleQuestion question) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return [
      SectionLabel(
        _day > 0 ? l10n.coupleQuestionEyebrow(_day) : l10n.coupleQuestionTitle,
      ),
      const SizedBox(height: 12),
      Text(
        question.text,
        style: theme.textTheme.displaySmall?.copyWith(
          fontSize: 30,
          fontWeight: FontWeight.w600,
          height: 1.2,
        ),
      ),
      if (!question.answered) ...[
        const SizedBox(height: 24),
        _lockedCard(l10n),
      ],
    ];
  }

  Widget _lockedCard(AppLocalizations l10n) {
    final name = _partnerName;
    return switch (_partnerAnswered) {
      true => QuestionLockedCard(
        title: l10n.coupleQuestionPartnerAnsweredTitle(name),
        line: l10n.coupleQuestionPartnerAnsweredLine,
      ),
      false => QuestionLockedCard(
        title: l10n.coupleQuestionPartnerPendingTitle(name),
        line: l10n.coupleQuestionPartnerPendingLine,
      ),
      null => QuestionLockedCard(
        title: l10n.coupleQuestionHiddenTitle,
        line: l10n.coupleQuestionHiddenLine,
      ),
    };
  }

  List<Widget> _action(BuildContext context, CoupleQuestion question) {
    final l10n = context.l10n;
    final mine = question.myAnswer;
    final name = _couple.coupleData?.partnerName;
    return [
      if (mine == null)
        QuestionComposer(
          controller: _answer,
          sendLabel: name == null
              ? l10n.coupleQuestionSend
              : l10n.coupleQuestionSendTo(name),
          sending: _sending,
          onSend: _send,
        )
      else ...[
        QuestionAnswerCard(title: l10n.coupleQuestionYourAnswer, text: mine),
        const SizedBox(height: 12),
        // Reached only with `mine` set: the partner's text is read from the
        // question here and nowhere else.
        if (question.partnerAnswer case final theirs?)
          QuestionAnswerCard(
            title: l10n.coupleQuestionPartnerAnswerTitle(_partnerName),
            text: theirs,
          )
        else
          QuestionWaitingCard(
            line: l10n.coupleQuestionPartnerWaiting(_partnerName),
          ),
      ],
      const SizedBox(height: 16),
      Align(
        alignment: AlignmentDirectional.centerStart,
        child: TextButton(
          onPressed: () => context.push(RoutePaths.coupleQuestions),
          child: Text(l10n.coupleQuestionHistory),
        ),
      ),
    ];
  }
}
