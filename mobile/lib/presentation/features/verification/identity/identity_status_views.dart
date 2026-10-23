import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../common/widgets/mazl_components.dart';
import 'identity_flow_state.dart';
import 'identity_layout.dart';
import 'identity_messages.dart';
import 'identity_parts.dart';

/// Screens with a single message and at most one or two buttons.

class IdentityCheckingView extends StatelessWidget {
  const IdentityCheckingView({super.key, required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) =>
      IdentityPage(onClose: onClose, centerBody: true, child: const CircularProgressIndicator());
}

class IdentityUnavailableView extends StatelessWidget {
  const IdentityUnavailableView({super.key, required this.reason, required this.onClose});

  final IdentityUnavailableReason reason;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) => switch (reason) {
    IdentityUnavailableReason.comingSoon => IdentityNotice(
      icon: LucideIcons.clock,
      title: 'Bientôt disponible',
      onClose: onClose,
      actions: [IdentityPrimaryButton('Fermer', onPressed: onClose)],
    ),
    IdentityUnavailableReason.noNfc => IdentityNotice(
      icon: LucideIcons.smartphoneNfc,
      title: 'Ce téléphone n\'a pas de lecteur NFC.',
      onClose: onClose,
      actions: const [ManualReviewButton()],
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
    eyebrow: 'Étape 2 / 3',
    onClose: onClose,
    lead: const IconDisc(icon: LucideIcons.check, filled: true),
    title: 'Puce lue.',
    titleSize: 36,
    subtitle: 'Il reste un selfie en mouvement, comparé à la photo de la puce.',
    actions: [IdentityPrimaryButton('Prendre le selfie', onPressed: onCapture)],
  );
}

class IdentitySubmittingView extends StatelessWidget {
  const IdentitySubmittingView({super.key, required this.stage});

  final IdentitySubmitStage stage;

  @override
  Widget build(BuildContext context) => IdentityPage(
    centerBody: true,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const CircularProgressIndicator(),
        const SizedBox(height: 20),
        Text(
          stage == IdentitySubmitStage.sending ? 'Vérification en cours…' : 'Préparation…',
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ],
    ),
  );
}

/// Success: what the badge looks like for others, and what is kept.
class IdentityDoneView extends StatelessWidget {
  const IdentityDoneView({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return IdentityPage(
      lead: const IconDisc(icon: LucideIcons.check, size: 72, filled: true),
      title: 'Identité vérifiée.',
      titleSize: 48,
      subtitle: 'La puce de votre document et votre selfie correspondent. Votre profil porte maintenant le badge.',
      actions: [IdentityPrimaryButton('Terminer', onPressed: onDone)],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _BadgePreview(),
          const SizedBox(height: 14),
          Text('Ce que les autres voient sur votre profil.', style: TextStyle(fontSize: 13, color: muted)),
          const SizedBox(height: 20),
          // Must match the server (docs/verification/CONTRAT.md §0, §4): the chip
          // data and the selfie are never stored; only these facts are kept.
          const FactRow(label: 'Photos et puce', value: 'Jamais enregistrées'),
          const FactRow(label: 'Conservé', value: 'Pays, expiration, empreinte anonyme'),
          const FactRow(label: 'Profil', value: 'Date de naissance du document', last: true),
        ],
      ),
    );
  }
}

/// The profile badge as others see it, on a neutral placeholder card.
class _BadgePreview extends StatelessWidget {
  const _BadgePreview();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ExcludeSemantics(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: scheme.surfaceContainer, borderRadius: BorderRadius.circular(24)),
        child: Row(
          children: [
            const SizedBox.square(dimension: 52, child: ProfilePhoto(radius: 26, iconSize: 24)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 96,
                    height: 12,
                    decoration: BoxDecoration(color: scheme.outline, borderRadius: BorderRadius.circular(6)),
                  ),
                  const SizedBox(height: 12),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: TagPill('Identité vérifiée', icon: LucideIcons.check),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class IdentityFailedView extends StatelessWidget {
  const IdentityFailedView({super.key, required this.info, required this.onAction, required this.onClose});

  final IdentityFailureInfo info;
  final VoidCallback onAction;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) => IdentityNotice(
    icon: LucideIcons.circleAlert,
    title: info.message,
    onClose: onClose,
    actions: [
      IdentityPrimaryButton(info.actionLabel, onPressed: onAction),
      if (info.offerManualReview) const ManualReviewButton(),
    ],
  );
}
