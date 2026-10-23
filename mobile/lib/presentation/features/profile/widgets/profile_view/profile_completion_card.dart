import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../common/widgets/mazl_components.dart';

/// Où mène une étape de complétion.
enum CompletionTarget { editProfile, settings, verification }

class CompletionStep {
  const CompletionStep({
    required this.target,
    required this.isComplete,
    required this.description,
  });

  final CompletionTarget target;
  final bool isComplete;
  final String description;
}

/// Les quatre étapes qui font un profil complet.
List<CompletionStep> buildCompletionSteps({
  required List<String> photos,
  required String? bio,
  required bool isVerified,
  required String location,
}) {
  final hasBio = bio != null && bio.isNotEmpty;
  final hasLocation = location != 'France' && location.isNotEmpty;
  return [
    CompletionStep(
      target: CompletionTarget.editProfile,
      isComplete: photos.length >= 2,
      description: photos.length >= 2 ? 'Photos ajoutées' : 'Ajoute au moins 2 photos',
    ),
    CompletionStep(
      target: CompletionTarget.editProfile,
      isComplete: hasBio,
      description: hasBio ? 'Bio complétée' : 'Décris-toi en quelques lignes',
    ),
    CompletionStep(
      target: CompletionTarget.settings,
      isComplete: hasLocation,
      description: hasLocation ? 'Ville renseignée' : 'Indique ta ville',
    ),
    CompletionStep(
      target: CompletionTarget.verification,
      isComplete: isVerified,
      description: isVerified ? 'Profil vérifié' : 'Fais vérifier ton profil',
    ),
  ];
}

/// Carte « Complète ton profil », absente quand tout est fait.
class ProfileCompletionCard extends StatelessWidget {
  const ProfileCompletionCard({super.key, required this.steps, required this.onStep});

  final List<CompletionStep> steps;
  final ValueChanged<CompletionTarget> onStep;

  @override
  Widget build(BuildContext context) {
    final done = steps.where((s) => s.isComplete).length;
    if (done == steps.length) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;
    final remaining = steps.length - done;
    final firstIncomplete = steps.firstWhere((s) => !s.isComplete);
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
          SectionLabel('Profil · $done/${steps.length}'),
          const SizedBox(height: 10),
          const Text(
            'Complète ton profil',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, letterSpacing: -0.6),
          ),
          const SizedBox(height: 4),
          Text(
            remaining > 1 ? '$remaining étapes restantes' : '1 étape restante',
            style: TextStyle(fontSize: 14, color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: done / steps.length,
              minHeight: 4,
              color: scheme.primary,
              backgroundColor: scheme.outline,
            ),
          ),
          const SizedBox(height: 8),
          for (final step in steps) _StepRow(step: step),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => onStep(firstIncomplete.target),
              child: const Text('Compléter maintenant'),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({required this.step});

  final CompletionStep step;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = step.isComplete ? scheme.onSurfaceVariant : scheme.onSurface;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            step.isComplete ? LucideIcons.check : LucideIcons.circle,
            size: 18,
            color: step.isComplete ? scheme.primary : scheme.onSurfaceVariant,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              step.description,
              style: TextStyle(
                fontSize: 15,
                color: color,
                decoration: step.isComplete ? TextDecoration.lineThrough : null,
                decorationColor: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
