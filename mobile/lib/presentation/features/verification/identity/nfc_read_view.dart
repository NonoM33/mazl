import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/verification/chip/chip_reader.dart';
import '../../../../l10n/l10n.dart';
import '../l10n/identity_failure_text.dart';
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

  @override
  Widget build(BuildContext context) {
    final failure = state.failure;
    if (failure != null && !state.reading) return _failureView(context, failure);
    return state.reading ? _readingView(context) : _waitingView(context);
  }

  Widget _waitingView(BuildContext context) {
    final l10n = context.l10n;
    return IdentityPage(
      eyebrow: l10n.verificationStepLabel(2, 3),
      onClose: onClose,
      title: l10n.verificationNfcWaitingTitle,
      subtitle: l10n.verificationNfcPlacement,
      actions: [IdentityPrimaryButton(l10n.verificationNfcRead, onPressed: onRead)],
      child: const Center(child: ChipLocationIllustration()),
    );
  }

  Widget _readingView(BuildContext context) {
    final l10n = context.l10n;
    final progress = state.progress;
    final percent = progress?.percent ?? 0;
    return IdentityPage(
      eyebrow: l10n.verificationStepLabel(2, 3),
      title: l10n.verificationNfcReadingTitle,
      subtitle: l10n.verificationNfcReadingSubtitle,
      note: Semantics(
        label: l10n.verificationNfcProgressLabel,
        value: l10n.verificationNfcProgressValue(percent),
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

  Widget _failureView(BuildContext context, IdentityFailureInfo failure) {
    final l10n = context.l10n;
    final silent = failure.isSilentChip;
    return IdentityNotice(
      eyebrow: l10n.verificationStepLabel(2, 3),
      icon: LucideIcons.circleAlert,
      title: failure.messageText(l10n),
      body: switch (failure.recovery) {
        IdentityRecovery.retryChip => silent ? l10n.verificationNfcSilentBody : null,
        IdentityRecovery.rescanMrz => l10n.verificationNfcRescanBody,
        IdentityRecovery.retryFace || IdentityRecovery.close => null,
      },
      tips: silent && failure.recovery == IdentityRecovery.retryChip
          ? [l10n.verificationNfcTip1, l10n.verificationNfcTip2, l10n.verificationNfcTip3]
          : const [],
      onClose: onClose,
      actions: [
        IdentityPrimaryButton(failure.actionLabel(l10n), onPressed: onRecover),
        // The chip answered nothing or badly: the photo page may have been misread.
        if (silent) IdentityLinkButton(l10n.verificationNfcRereadPhotoPage, onPressed: onRereadPhotoPage),
        if (failure.offerManualReview) const ManualReviewButton(),
      ],
    );
  }
}
