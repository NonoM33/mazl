import 'package:flutter/material.dart';

import '../../../../common/widgets/mazl_components.dart';

/// Fenêtre « C'est un match » : sobre, sans fond coloré.
class ProfileMatchDialog extends StatelessWidget {
  const ProfileMatchDialog({
    super.key,
    required this.name,
    required this.onContinue,
    required this.onMessage,
  });

  final String name;
  final VoidCallback onContinue;
  final VoidCallback onMessage;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Dialog(
      backgroundColor: scheme.surface,
      elevation: 0,
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionLabel('Match'),
            const SizedBox(height: 12),
            const Text(
              "C'est un match.",
              style: TextStyle(fontSize: 34, fontWeight: FontWeight.w600, letterSpacing: -1.3, height: 1.1),
            ),
            const SizedBox(height: 10),
            Text(
              'Vous pouvez maintenant discuter avec $name.',
              style: TextStyle(fontSize: 16, height: 1.45, color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(onPressed: onMessage, child: const Text('Envoyer un message')),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(onPressed: onContinue, child: const Text('Continuer')),
            ),
          ],
        ),
      ),
    );
  }
}
