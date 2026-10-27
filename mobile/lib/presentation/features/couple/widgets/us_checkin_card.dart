import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/models/couple_daily.dart';
import '../../../../l10n/l10n.dart';
import '../../../common/widgets/mazl_components.dart';
import 'couple_kit.dart';

/// The monthly check-in, on « Nous deux », in its three states: still to do,
/// waiting for the partner, and the summary once both answered.
///
/// Privacy (docs/couple/ESPACE-COUPLE.md §0.4): only the summary is drawn.
/// The model has no field for the other's notes, so none can leak here.
class UsCheckinCard extends StatelessWidget {
  const UsCheckinCard({
    super.key,
    required this.checkin,
    required this.partnerName,
    required this.onOpen,
  });

  final CoupleCheckin checkin;
  final String partnerName;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final summary = checkin.summary;
    final title = !checkin.answered
        ? l10n.coupleUsCheckinDue(_monthName(context))
        : summary != null
        ? l10n.coupleUsCheckinAligned(summary.aligned)
        : l10n.coupleUsWaitingFor(partnerName);
    return CoupleCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionLabel(l10n.coupleUsCheckinLabel),
          const SizedBox(height: 10),
          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              height: 1.25,
            ),
          ),
          if (checkin.answered && summary != null) ...[
            const SizedBox(height: 6),
            Text(
              _lowestLine(l10n, summary.lowest),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          if (!checkin.answered) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: kMinTapTarget + 4,
              child: FilledButton(
                onPressed: onOpen,
                child: Text(l10n.coupleUsCheckinStart),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// « novembre » for `2026-11`; the current month if the period is odd.
  String _monthName(BuildContext context) {
    final parts = checkin.period.split('-');
    final year = int.tryParse(parts.first);
    final month = parts.length > 1 ? int.tryParse(parts[1]) : null;
    final date = year != null && month != null && month >= 1 && month <= 12
        ? DateTime(year, month)
        : DateTime.now();
    return DateFormat.MMMM(context.l10n.localeName).format(date);
  }

  String _lowestLine(AppLocalizations l10n, CheckinTheme theme) =>
      switch (theme) {
        CheckinTheme.talk => l10n.coupleUsCheckinLowestTalk,
        CheckinTheme.time => l10n.coupleUsCheckinLowestTime,
        CheckinTheme.close => l10n.coupleUsCheckinLowestClose,
      };
}
