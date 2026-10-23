import 'package:flutter/material.dart';

import 'identity_flow_state.dart';
import 'identity_layout.dart';
import 'identity_messages.dart';

/// Screens with a single message and at most one or two buttons.

class IdentityCheckingView extends StatelessWidget {
  const IdentityCheckingView({super.key, required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) =>
      IdentityPage(onClose: onClose, child: const Center(child: CircularProgressIndicator()));
}

class IdentityUnavailableView extends StatelessWidget {
  const IdentityUnavailableView({super.key, required this.reason, required this.onClose});

  final IdentityUnavailableReason reason;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) => switch (reason) {
        IdentityUnavailableReason.comingSoon => IdentityPage(
            onClose: onClose,
            actions: [FilledButton(onPressed: onClose, child: const Text('Fermer'))],
            child: const CenteredMessage(icon: Icons.hourglass_empty, message: 'Bientôt disponible'),
          ),
        IdentityUnavailableReason.noNfc => IdentityPage(
            onClose: onClose,
            actions: const [ManualReviewButton()],
            child: const CenteredMessage(icon: Icons.nfc, message: 'Ce téléphone n\'a pas de lecteur NFC.'),
          ),
      };
}

/// Chip read, selfie next.
class IdentityFaceView extends StatelessWidget {
  const IdentityFaceView({super.key, required this.onCapture, required this.onClose});

  final VoidCallback onCapture;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) => IdentityPage(
        onClose: onClose,
        actions: [FilledButton(onPressed: onCapture, child: const Text('Prendre le selfie'))],
        child: const CenteredMessage(icon: Icons.check_circle_outline, message: 'Document lu'),
      );
}

class IdentitySubmittingView extends StatelessWidget {
  const IdentitySubmittingView({super.key, required this.stage});

  final IdentitySubmitStage stage;

  @override
  Widget build(BuildContext context) => IdentityPage(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                stage == IdentitySubmitStage.sending ? 'Vérification en cours…' : 'Préparation…',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
      );
}

class IdentityDoneView extends StatelessWidget {
  const IdentityDoneView({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) => IdentityPage(
        actions: [FilledButton(onPressed: onDone, child: const Text('Terminer'))],
        child: const CenteredMessage(icon: Icons.verified_outlined, message: 'Identité vérifiée'),
      );
}

class IdentityFailedView extends StatelessWidget {
  const IdentityFailedView({super.key, required this.info, required this.onAction, required this.onClose});

  final IdentityFailureInfo info;
  final VoidCallback onAction;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) => IdentityPage(
        onClose: onClose,
        actions: [
          FilledButton(onPressed: onAction, child: Text(info.actionLabel)),
          if (info.offerManualReview) const ManualReviewButton(),
        ],
        child: CenteredMessage(icon: Icons.error_outline, message: info.message, color: Theme.of(context).colorScheme.error),
      );
}
