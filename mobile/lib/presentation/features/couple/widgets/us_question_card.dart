import 'package:flutter/material.dart';

import '../../../../core/models/couple_daily.dart';
import '../../../../l10n/l10n.dart';
import '../../../common/widgets/mazl_components.dart';
import 'couple_kit.dart';

/// The question of the day, on « Nous deux »: the question, where the two
/// stand, and the way into it.
///
/// Privacy (docs/couple/ESPACE-COUPLE.md §0.4): the partner's answer is drawn
/// only when the server sent it, which it does only once the member answered.
/// Nothing here guesses it, hides it behind a tap, or keeps it in the tree
/// otherwise.
class UsQuestionCard extends StatelessWidget {
  const UsQuestionCard({
    super.key,
    required this.question,
    required this.partnerName,
    required this.partnerAnswered,
    required this.onOpen,
  });

  final CoupleQuestion question;
  final String partnerName;

  /// Whether the partner already answered, when it is known (read from the
  /// day's summary, which carries only the fact, never the words).
  final bool? partnerAnswered;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final partnerAnswer = question.partnerAnswer;
    final state = !question.answered
        ? (partnerAnswered == true
              ? l10n.coupleUsQuestionPartnerAnswered(partnerName)
              : l10n.coupleUsQuestionYourTurn)
        : partnerAnswer != null
        ? l10n.coupleUsQuestionYouAnswered
        : l10n.coupleUsWaitingFor(partnerName);
    return CoupleCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionLabel(l10n.coupleUsQuestionLabel),
          const SizedBox(height: 10),
          Text(
            question.text,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            state,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (question.myAnswer != null && partnerAnswer != null) ...[
            const SizedBox(height: 14),
            _Answer(label: l10n.coupleUsYouLabel, text: question.myAnswer!),
            const SizedBox(height: 10),
            _Answer(label: partnerName, text: partnerAnswer),
          ],
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: kMinTapTarget + 4,
            child: FilledButton(
              onPressed: onOpen,
              child: Text(
                question.answered
                    ? l10n.coupleUsSeeButton
                    : l10n.coupleUsAnswerButton,
              ),
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
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionLabel(label),
        const SizedBox(height: 2),
        Text(
          text,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: scheme.onSurface),
        ),
      ],
    );
  }
}
