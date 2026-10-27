import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../common/widgets/mazl_components.dart';
import 'couple_kit.dart';

/// What the member has not earned yet: the other's answer stays behind this
/// neutral block until they have answered themselves. It carries no part of
/// the answer, only a sentence about whether it exists.
class QuestionLockedCard extends StatelessWidget {
  const QuestionLockedCard({
    super.key,
    required this.title,
    required this.line,
  });

  final String title;
  final String line;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return CoupleCard(
      outlined: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            LucideIcons.lock,
            size: 20,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleSmall),
                const SizedBox(height: 4),
                Text(
                  line,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// One answer, with whose it is: the member's own, or the partner's once the
/// member has answered.
class QuestionAnswerCard extends StatelessWidget {
  const QuestionAnswerCard({
    super.key,
    required this.title,
    required this.text,
  });

  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return CoupleCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionLabel(title),
          const SizedBox(height: 8),
          Text(text, style: theme.textTheme.bodyLarge?.copyWith(height: 1.45)),
        ],
      ),
    );
  }
}

/// The partner's answer is not there yet.
class QuestionWaitingCard extends StatelessWidget {
  const QuestionWaitingCard({super.key, required this.line});

  final String line;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return CoupleCard(
      outlined: true,
      child: Text(
        line,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          height: 1.45,
        ),
      ),
    );
  }
}
