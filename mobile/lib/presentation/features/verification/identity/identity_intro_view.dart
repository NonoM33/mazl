import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../l10n/l10n.dart';
import 'identity_layout.dart';
import 'identity_parts.dart';

/// Opening screen: what will happen, in three lines, and the privacy promise.
class IdentityIntroView extends StatelessWidget {
  const IdentityIntroView({super.key, required this.onStart, required this.onClose});

  final VoidCallback onStart;
  final VoidCallback onClose;

  /// The three steps and their details, in the member's language.
  static List<NumberedStep> steps(AppLocalizations l10n) => [
    NumberedStep(l10n.verificationIntroStep1, detail: l10n.verificationIntroStep1Detail),
    NumberedStep(l10n.verificationIntroStep2, detail: l10n.verificationIntroStep2Detail),
    NumberedStep(l10n.verificationIntroStep3, detail: l10n.verificationIntroStep3Detail),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return IdentityPage(
      onClose: onClose,
      lead: const IconDisc(icon: LucideIcons.shieldCheck, filled: true),
      title: l10n.verificationIntroTitle,
      titleSize: 40,
      subtitle: l10n.verificationIntroSubtitle,
      note: PrivacyLine(l10n.verificationIntroPrivacy),
      actions: [IdentityPrimaryButton(l10n.verificationIntroStart, onPressed: onStart)],
      child: NumberedSteps(steps: steps(l10n)),
    );
  }
}
