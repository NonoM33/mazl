import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/verification/chip/chip_reader.dart';
import 'chip_location_illustration.dart';
import 'identity_flow_state.dart';
import 'identity_layout.dart';
import 'identity_messages.dart';
import 'identity_parts.dart';
import 'nfc_step_checklist.dart';

/// Chip step: where to put the document, then a button, then progress.
class NfcReadView extends StatelessWidget {
  const NfcReadView({
    super.key,
    required this.state,
    required this.onRead,
    required this.onRecover,
    required this.onRereadPhotoPage,
    required this.onClose,
  });

  final IdentityNfc state;
  final VoidCallback onRead;
  final VoidCallback onRecover;
  final VoidCallback onRereadPhotoPage;
  final VoidCallback onClose;

  static const _eyebrow = 'Étape 2 / 3';
  static const _placement =
      'Le haut du téléphone contre la couverture fermée du passeport, '
      'ou contre le dos de la carte d\'identité. Retirez la coque si besoin.';
  static const _tips = [
    'Retirez la coque du téléphone.',
    'Posez le haut du téléphone au centre de la couverture, passeport fermé.',
    'Restez immobile une dizaine de secondes.',
  ];

  /// A chip that stayed silent, as opposed to a phone setting or a wrong MRZ.
  static final _silentChipMessages = {
    for (final kind in [ChipFailureKind.timeout, ChipFailureKind.tagLost, ChipFailureKind.unknown])
      describeChipFailure(kind)!.message,
  };

  static String stepLabel(ChipReadStep step) => NfcStepChecklist.labels[step]!;

  @override
  Widget build(BuildContext context) {
    final failure = state.failure;
    if (failure != null && !state.reading) return _failureView(failure);
    return state.reading ? _readingView() : _waitingView();
  }

  Widget _waitingView() => IdentityPage(
    eyebrow: _eyebrow,
    onClose: onClose,
    title: 'Posez votre document sur le téléphone.',
    subtitle: _placement,
    actions: [IdentityPrimaryButton('Lire le document', onPressed: onRead)],
    child: const Center(child: ChipLocationIllustration()),
  );

  Widget _readingView() {
    final progress = state.progress;
    final percent = progress?.percent ?? 0;
    return IdentityPage(
      eyebrow: _eyebrow,
      title: 'Ne bougez plus.',
      subtitle: 'Gardez le document contre le haut du téléphone jusqu\'à la fin de la lecture.',
      note: Semantics(
        label: 'Lecture de la puce',
        value: '$percent %',
        child: ExcludeSemantics(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(value: percent / 100, minHeight: 4),
          ),
        ),
      ),
      child: NfcStepChecklist(current: progress?.step ?? ChipReadStep.waitingForDocument),
    );
  }

  Widget _failureView(IdentityFailureInfo failure) {
    final silent = _silentChipMessages.contains(failure.message);
    return IdentityNotice(
      eyebrow: _eyebrow,
      icon: LucideIcons.circleAlert,
      title: failure.message,
      body: switch (failure.recovery) {
        IdentityRecovery.retryChip => silent ? 'Cela arrive souvent au premier essai. Rien n\'a été envoyé.' : null,
        IdentityRecovery.rescanMrz =>
          'Rien n\'a été envoyé. Relisez la page photo pour repartir sur de bonnes données.',
        IdentityRecovery.retryFace || IdentityRecovery.close => null,
      },
      tips: silent && failure.recovery == IdentityRecovery.retryChip ? _tips : const [],
      onClose: onClose,
      actions: [
        IdentityPrimaryButton(failure.actionLabel, onPressed: onRecover),
        // The chip answered nothing or badly: the photo page may have been misread.
        if (silent) IdentityLinkButton('Relire la page photo', onPressed: onRereadPhotoPage),
        if (failure.offerManualReview) const ManualReviewButton(),
      ],
    );
  }
}
