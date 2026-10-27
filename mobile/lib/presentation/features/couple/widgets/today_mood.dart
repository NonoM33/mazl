import 'package:flutter/material.dart';

import '../../../../core/models/couple_daily.dart';
import '../../../../l10n/l10n.dart';
import 'couple_kit.dart';

/// « Comment ça va entre vous ? »: four pills. Only the member's own mood is
/// shown; the partner's is never displayed here.
class TodayMood extends StatelessWidget {
  const TodayMood({
    super.key,
    required this.selected,
    required this.partnerName,
    required this.onSelect,
  });

  final CoupleMoodChoice? selected;
  final String partnerName;
  final void Function(CoupleMoodChoice mood) onSelect;

  static String label(BuildContext context, CoupleMoodChoice mood) {
    final l10n = context.l10n;
    return switch (mood) {
      CoupleMoodChoice.great => l10n.coupleTodayMoodGreat,
      CoupleMoodChoice.good => l10n.coupleTodayMoodGood,
      CoupleMoodChoice.meh => l10n.coupleTodayMoodMeh,
      CoupleMoodChoice.talk => l10n.coupleTodayMoodTalk,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.coupleTodayMoodQuestion, style: theme.textTheme.titleSmall),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final mood in CoupleMoodChoice.values)
              CouplePill(
                label: label(context, mood),
                selected: selected == mood,
                onTap: () => onSelect(mood),
              ),
          ],
        ),
        if (selected == CoupleMoodChoice.talk) ...[
          const SizedBox(height: 10),
          Text(
            l10n.coupleTodayMoodTalkNotice(partnerName),
            style: theme.textTheme.bodySmall,
          ),
        ],
      ],
    );
  }
}
