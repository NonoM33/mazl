import 'package:flutter/material.dart';

import '../../../../../l10n/l10n.dart';
import '../../../../common/widgets/mazl_components.dart';

/// Fenêtre « C'est un match » : sobre, sans fond coloré.
class ProfileMatchDialog extends StatelessWidget {
  const ProfileMatchDialog({
    super.key,
    required this.name,
    required this.onContinue,
    required this.onMessage,
  });

  /// Le prénom ; `null` quand il manque.
  final String? name;
  final VoidCallback onContinue;
  final VoidCallback onMessage;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final name = this.name;
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
            SectionLabel(l10n.profileMatchLabel),
            const SizedBox(height: 12),
            Text(
              l10n.profileMatchTitle,
              style: TextStyle(fontSize: 34, fontWeight: FontWeight.w600, letterSpacing: -1.3, height: 1.1),
            ),
            const SizedBox(height: 10),
            Text(
              name == null
                  ? l10n.profileMatchBodyUnnamed
                  : l10n.profileMatchBody(name),
              style: TextStyle(fontSize: 16, height: 1.45, color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(onPressed: onMessage, child: Text(l10n.profileSendMessage)),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(onPressed: onContinue, child: Text(l10n.commonContinue)),
            ),
          ],
        ),
      ),
    );
  }
}
