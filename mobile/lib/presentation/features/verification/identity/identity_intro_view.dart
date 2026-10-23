import 'package:flutter/material.dart';

import 'identity_layout.dart';

/// Opening screen: what will happen, in three lines, and the privacy promise.
class IdentityIntroView extends StatelessWidget {
  const IdentityIntroView({super.key, required this.onStart, required this.onClose});

  final VoidCallback onStart;
  final VoidCallback onClose;

  static const steps = [
    'Scanne les lignes en bas de ton document.',
    'Pose-le contre le haut du téléphone.',
    'Fais un selfie en suivant les consignes.',
  ];
  static const privacyNote = 'Rien n\'est conservé : nous ne gardons que le résultat.';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return IdentityPage(
      title: 'Vérifie ton identité',
      onClose: onClose,
      actions: [FilledButton(onPressed: onStart, child: const Text('Commencer'))],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < steps.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Text('${i + 1}', style: theme.textTheme.labelLarge),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Padding(padding: const EdgeInsets.only(top: 3), child: Text(steps[i], style: theme.textTheme.bodyLarge))),
                ],
              ),
            ),
          const Spacer(),
          Text(privacyNote, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}
