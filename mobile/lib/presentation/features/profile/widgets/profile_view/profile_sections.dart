import 'package:flutter/material.dart';

import '../../../../../l10n/l10n.dart';
import '../../../../common/widgets/mazl_components.dart';
import 'profile_view_data.dart';

/// Une étiquette de section au-dessus de son contenu.
class ProfileSection extends StatelessWidget {
  const ProfileSection({super.key, required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionLabel(label),
        const SizedBox(height: 12),
        child,
      ],
    );
  }
}

/// Paragraphe libre : « À propos », « Ce que je recherche ».
class ProfileTextSection extends StatelessWidget {
  const ProfileTextSection({super.key, required this.label, required this.text});

  final String label;
  final String text;

  @override
  Widget build(BuildContext context) {
    return ProfileSection(
      label: label,
      child: Text(
        text,
        style: const TextStyle(fontSize: 17, height: 1.5, letterSpacing: -0.2),
      ),
    );
  }
}

/// « L'essentiel » : une rangée par champ renseigné, filet entre chaque.
class ProfileFactsSection extends StatelessWidget {
  const ProfileFactsSection({super.key, required this.facts});

  final List<ProfileFact> facts;

  @override
  Widget build(BuildContext context) {
    if (facts.isEmpty) return const SizedBox.shrink();
    return ProfileSection(
      label: context.l10n.profileEssentials,
      child: Column(
        children: [
          for (var i = 0; i < facts.length; i++)
            FactRow(
              label: facts[i].label,
              value: facts[i].value,
              last: i == facts.length - 1,
            ),
        ],
      ),
    );
  }
}

/// Question et réponse d'un prompt, sur une carte brume.
class ProfilePromptCard extends StatelessWidget {
  const ProfilePromptCard({super.key, required this.question, required this.answer});

  final String question;
  final String answer;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            answer,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w500,
              letterSpacing: -0.5,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }
}

/// Les prompts d'un profil, une carte chacun.
class ProfilePromptCards extends StatelessWidget {
  const ProfilePromptCards({super.key, required this.prompts});

  /// Paires (question, réponse), dans l'ordre d'affichage.
  final List<({String question, String answer})> prompts;

  @override
  Widget build(BuildContext context) {
    if (prompts.isEmpty) return const SizedBox.shrink();
    return ProfileSection(
      label: context.l10n.profileInAFewWords,
      child: Column(
        children: [
          for (var i = 0; i < prompts.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            ProfilePromptCard(
              question: prompts[i].question,
              answer: prompts[i].answer,
            ),
          ],
        ],
      ),
    );
  }
}
