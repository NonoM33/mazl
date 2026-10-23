import 'package:flutter/material.dart';

import '../../../../core/verification/chip/chip_reader.dart';
import 'chip_location_illustration.dart';
import 'identity_flow_state.dart';
import 'identity_layout.dart';

/// Chip step: where to put the document, then a button, then progress.
class NfcReadView extends StatelessWidget {
  const NfcReadView({super.key, required this.state, required this.onRead, required this.onRecover, required this.onClose});

  final IdentityNfc state;
  final VoidCallback onRead;
  final VoidCallback onRecover;
  final VoidCallback onClose;

  static String stepLabel(ChipReadStep step) => switch (step) {
        ChipReadStep.waitingForDocument => 'Approche ton document…',
        ChipReadStep.authenticating => 'Connexion sécurisée…',
        ChipReadStep.readingPhoto => 'Lecture de la photo…',
        ChipReadStep.readingSignature => 'Lecture de la signature…',
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final failure = state.failure;
    final progress = state.progress;
    return IdentityPage(
      title: 'Pose ton document sur le téléphone',
      onClose: state.reading ? null : onClose,
      actions: [
        if (state.reading)
          const FilledButton(onPressed: null, child: Text('Lecture en cours…'))
        else if (failure == null)
          FilledButton(onPressed: onRead, child: const Text('Lire le document'))
        else ...[
          FilledButton(onPressed: onRecover, child: Text(failure.actionLabel)),
          if (failure.offerManualReview) const ManualReviewButton(),
        ],
      ],
      child: Column(
        children: [
          const Expanded(child: Center(child: ChipLocationIllustration())),
          if (state.reading) ...[
            LinearProgressIndicator(value: progress == null ? null : progress.percent / 100),
            const SizedBox(height: 12),
            Text(progress == null ? stepLabel(ChipReadStep.waitingForDocument) : stepLabel(progress.step), style: theme.textTheme.bodyMedium),
          ] else if (failure != null)
            Text(failure.message, textAlign: TextAlign.center, style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.error)),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
