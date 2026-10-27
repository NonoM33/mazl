import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/layout/column_app_bar.dart';
import '../../../../core/layout/content_max_width.dart';
import '../../../../core/layout/fold_spread.dart';
import '../../../../core/models/couple_daily.dart';
import '../../../../core/services/couple_api_service.dart';
import '../../../../core/services/couple_daily_api.dart';
import '../../../../core/services/couple_service.dart';
import '../../../../l10n/l10n.dart';
import '../../../common/widgets/fold_pages.dart';
import '../../../common/widgets/mazl_components.dart';
import '../widgets/couple_kit.dart';
import '../widgets/couple_message_view.dart';
import '../widgets/us_load.dart';

/// `/couple/questions`: every question the member answered, with both answers
/// (the server lists only those, so the partner's answer is never shown for a
/// question the member skipped).
class CoupleQuestionHistoryScreen extends StatefulWidget {
  const CoupleQuestionHistoryScreen({super.key, this.api, this.couple});

  /// Injected by tests; the app uses the real services.
  final CoupleDailyApi? api;
  final CoupleService? couple;

  @override
  State<CoupleQuestionHistoryScreen> createState() =>
      _CoupleQuestionHistoryScreenState();
}

class _CoupleQuestionHistoryScreenState
    extends State<CoupleQuestionHistoryScreen> {
  late final CoupleDailyApi _api = widget.api ?? CoupleDailyApi.forApp();
  late final CoupleService _couple = widget.couple ?? CoupleService();

  UsLoad<List<CoupleQuestionEntry>> _entries = const UsLoading();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final coupleId = _couple.coupleData?.coupleId;
    if (coupleId == null) {
      setState(() => _entries = const UsReady([]));
      return;
    }
    setState(() => _entries = const UsLoading());
    final result = await _api.getQuestionHistory(coupleId);
    if (!mounted) return;
    setState(
      () => _entries = switch (result) {
        CoupleOk(:final value) => UsReady(value),
        CoupleFailed(:final failure) => UsFailed(failure),
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: ColumnAppBar(
        appBar: AppBar(title: Text(l10n.coupleUsHistoryTitle)),
      ),
      body: ContentMaxWidth(child: _body(l10n)),
    );
  }

  Widget _body(AppLocalizations l10n) {
    switch (_entries) {
      case UsLoading():
        return const FoldSpinner();
      case UsFailed(:final failure):
        return CoupleMessageView.failure(failure, onRetry: _load);
      case UsReady(:final value):
        if (value.isEmpty) {
          return CoupleMessageView(
            title: l10n.coupleUsHistoryEmptyTitle,
            line: l10n.coupleUsHistoryEmptyLine,
          );
        }
        return _list(value);
    }
  }

  /// Held like a book each page holds half of the cards, whole: a card is
  /// never cut by the fold.
  Widget _list(List<CoupleQuestionEntry> entries) {
    final half = (entries.length + 1) ~/ 2;
    final partnerName =
        _couple.coupleData?.partnerName ??
        context.l10n.coupleSpacePartnerFallback;
    final bottom = MediaQuery.paddingOf(context).bottom;
    Widget card(CoupleQuestionEntry entry) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _EntryCard(entry: entry, partnerName: partnerName),
    );
    return FoldSpread(
      padding: EdgeInsets.fromLTRB(24, 16, 24, bottom + 24),
      start: [for (final e in entries.take(half)) card(e)],
      end: [for (final e in entries.skip(half)) card(e)],
    );
  }
}

class _EntryCard extends StatelessWidget {
  const _EntryCard({required this.entry, required this.partnerName});

  final CoupleQuestionEntry entry;
  final String partnerName;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final asked = entry.askedOn;
    final partnerAnswer = entry.partnerAnswer;
    return CoupleCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (asked != null) ...[
            SectionLabel(DateFormat.yMMMMd(l10n.localeName).format(asked)),
            const SizedBox(height: 8),
          ],
          Text(
            entry.text,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          _Answer(label: l10n.coupleUsYouLabel, text: entry.myAnswer),
          const SizedBox(height: 10),
          if (partnerAnswer != null)
            _Answer(label: partnerName, text: partnerAnswer)
          else
            Text(
              l10n.coupleUsHistoryNoPartnerAnswer(partnerName),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }
}

class _Answer extends StatelessWidget {
  const _Answer({required this.label, required this.text});

  final String label;
  final String text;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SectionLabel(label),
      const SizedBox(height: 2),
      Text(text, style: Theme.of(context).textTheme.bodyMedium),
    ],
  );
}
