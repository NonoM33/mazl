import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/web_sessions/web_session_models.dart';
import '../../../common/widgets/mazl_components.dart';
import '../../../common/widgets/mazl_sheet.dart';
import 'web_session_format.dart';

/// Asks whether to connect the computer. Resolves true to connect, false to
/// refuse; a dismissed sheet counts as a refusal.
Future<bool> confirmPairing(BuildContext context, WebPairing pairing) async {
  final approved = await showMazlSheet<bool>(
    context,
    isDismissible: false,
    isScrollControlled: true,
    builder: (_) => _ConfirmPairingBody(pairing: pairing),
  );
  return approved ?? false;
}

class _ConfirmPairingBody extends StatelessWidget {
  const _ConfirmPairingBody({required this.pairing});

  final WebPairing pairing;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionLabel(
            'Connexion à MAZL sur ordinateur',
            color: AppColors.tekhelet,
          ),
          const SizedBox(height: 8),
          Semantics(
            header: true,
            child: Text(
              'Connecter cet ordinateur ?',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          const SizedBox(height: 16),
          FactRow(label: 'Navigateur', value: pairing.browser),
          FactRow(
            label: 'Demande faite à',
            value: clockTimeLabel(pairing.createdAt),
            last: true,
          ),
          const SizedBox(height: 16),
          Text(
            'Ne scannez que le code affiché sur votre propre ordinateur. '
            'Si quelqu\'un vous demande de scanner un code, refusez.',
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Connecter'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Refuser'),
          ),
        ],
      ),
    );
  }
}
