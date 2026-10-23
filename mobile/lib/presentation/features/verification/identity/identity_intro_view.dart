import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'identity_layout.dart';
import 'identity_parts.dart';

/// Opening screen: what will happen, in three lines, and the privacy promise.
class IdentityIntroView extends StatelessWidget {
  const IdentityIntroView({super.key, required this.onStart, required this.onClose});

  final VoidCallback onStart;
  final VoidCallback onClose;

  static const steps = ['Photographier la page photo', 'Poser le téléphone sur la puce', 'Un selfie en mouvement'];
  static const _details = [
    'Pour lire les deux lignes du bas.',
    'La puce signée par l\'État fait foi.',
    'Comparé à la photo de la puce.',
  ];
  static const subtitle =
      'Le badge « Identité vérifiée » dit aux autres que vous êtes bien la personne des photos. '
      'Il faut un passeport ou une carte d\'identité biométrique, deux minutes et un peu de lumière.';
  static const privacyNote = 'Rien n\'est conservé : nous ne gardons que le résultat.';

  @override
  Widget build(BuildContext context) => IdentityPage(
    onClose: onClose,
    lead: const IconDisc(icon: LucideIcons.shieldCheck, filled: true),
    title: 'Vérifiez votre identité.',
    titleSize: 40,
    subtitle: subtitle,
    note: const PrivacyLine(privacyNote),
    actions: [IdentityPrimaryButton('Commencer', onPressed: onStart)],
    child: NumberedSteps(steps: [for (var i = 0; i < steps.length; i++) NumberedStep(steps[i], detail: _details[i])]),
  );
}
