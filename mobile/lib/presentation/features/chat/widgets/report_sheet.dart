import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../common/widgets/mazl_sheet.dart';

const reportReasons = [
  ('Arnaque ou demande d\'argent', LucideIcons.banknote),
  ('Harcèlement ou propos déplacés', LucideIcons.messageSquareWarning),
  ('Contenu inapproprié', LucideIcons.eyeOff),
  ('Autre', LucideIcons.flag),
];

/// Asks why a message is reported; null when the sheet is dismissed.
Future<String?> pickReportReason(BuildContext context) {
  return showMazlSheet<String>(
    context,
    padded: false,
    builder: (context) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
          child: Text('Signaler ce message', style: Theme.of(context).textTheme.titleMedium),
        ),
        for (final (label, icon) in reportReasons)
          ListTile(leading: Icon(icon), title: Text(label), onTap: () => Navigator.pop(context, label)),
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
        Text('Se protéger des arnaques', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        for (final line in const [
          "N'envoyez jamais d'argent, de carte cadeau ou de cryptomonnaie.",
          'Méfiez-vous de qui vous demande de poursuivre sur WhatsApp, Telegram ou Signal très vite.',
          'Faites un appel vidéo avant de vous engager.',
          'En cas de doute, signalez la conversation : nous l\'examinons.',
        ])
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(line, style: Theme.of(context).textTheme.bodyMedium),
          ),
      ],
    ),
  );
}
