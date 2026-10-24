import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../l10n/l10n.dart';
import '../../../common/widgets/mazl_sheet.dart';

/// Why a message is reported. The moderation team reads [wire] in the
/// `reports` table (CONTRAT §2), so it stays the same in every language.
enum ReportReason {
  scam('Arnaque ou demande d\'argent'),
  harassment('Harcèlement ou propos déplacés'),
  inappropriate('Contenu inapproprié'),
  other('Autre');

  const ReportReason(this.wire);

  final String wire;
}

extension ReportReasonLabel on ReportReason {
  String label(AppLocalizations l10n) => switch (this) {
    ReportReason.scam => l10n.chatReportReasonScam,
    ReportReason.harassment => l10n.chatReportReasonHarassment,
    ReportReason.inappropriate => l10n.chatReportReasonInappropriate,
    ReportReason.other => l10n.chatReportReasonOther,
  };
}

const reportReasons = [
  (ReportReason.scam, LucideIcons.banknote),
  (ReportReason.harassment, LucideIcons.messageSquareWarning),
  (ReportReason.inappropriate, LucideIcons.eyeOff),
  (ReportReason.other, LucideIcons.flag),
];

/// Asks why a message is reported; null when the sheet is dismissed.
Future<ReportReason?> pickReportReason(BuildContext context) {
  return showMazlSheet<ReportReason>(
    context,
    padded: false,
    builder: (context) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
          child: Text(
            context.l10n.chatReportTitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        for (final (reason, icon) in reportReasons)
          ListTile(
            leading: Icon(icon),
            title: Text(reason.label(context.l10n)),
            onTap: () => Navigator.pop(context, reason),
          ),
      ],
    ),
  );
}

/// Advice behind the « En savoir plus » link of the scam warning.
Future<void> showScamAdviceSheet(BuildContext context) {
  return showMazlSheet<void>(
    context,
    builder: (context) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.chatScamAdviceTitle,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        for (final line in [
          context.l10n.chatScamAdviceMoney,
          context.l10n.chatScamAdviceApps,
          context.l10n.chatScamAdviceVideo,
          context.l10n.chatScamAdviceReport,
        ])
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(line, style: Theme.of(context).textTheme.bodyMedium),
          ),
      ],
    ),
  );
}
