import 'package:flutter/material.dart';

import '../../../../l10n/l10n.dart';
import '../../../common/widgets/mazl_components.dart';
import 'couple_kit.dart';

/// « QUESTION DU JOUR »: the question, who answered, and the way in.
class TodayQuestionCard extends StatelessWidget {
  const TodayQuestionCard({
    super.key,
    required this.text,
    required this.partnerName,
    required this.myAnswered,
    required this.partnerAnswered,
    required this.onOpen,
  });

  final String text;
  final String partnerName;
  final bool myAnswered;
  final bool partnerAnswered;
  final VoidCallback onOpen;

  String _status(BuildContext context) {
    final l10n = context.l10n;
    if (myAnswered && partnerAnswered) return l10n.coupleTodayQuestionBoth;
    if (myAnswered) return l10n.coupleTodayQuestionMineAnswered(partnerName);
    if (partnerAnswered) {
      return l10n.coupleTodayQuestionPartnerAnswered(partnerName);
    }
    return l10n.coupleTodayQuestionWaiting(partnerName);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    return CoupleCard(
      radius: 28,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionLabel(l10n.coupleTodayQuestionLabel),
          const SizedBox(height: 12),
          Text(
            text,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(_status(context), style: theme.textTheme.bodySmall),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: onOpen,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(64, 44),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                ),
                child: Text(
                  myAnswered ? l10n.coupleTodayView : l10n.coupleTodayAnswer,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
