import 'package:flutter/material.dart';

import '../../../../core/models/couple_daily.dart';
import '../../../../l10n/l10n.dart';
import '../l10n/checkin_labels.dart';
import 'couple_kit.dart';

/// What the couple sees once both have answered: how many of the three themes
/// they agree on, and one kind sentence about the lowest. Never a note.
class CheckinSummaryCard extends StatelessWidget {
  const CheckinSummaryCard({super.key, required this.summary});

  final CheckinSummary summary;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return CoupleCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.coupleCheckinAligned(summary.aligned),
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            checkinAttentionLine(l10n, summary),
            style: theme.textTheme.bodyLarge?.copyWith(height: 1.45),
          ),
        ],
      ),
    );
  }
}
