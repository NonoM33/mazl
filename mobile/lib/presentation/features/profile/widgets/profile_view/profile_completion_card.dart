import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../l10n/l10n.dart';
import '../../../../common/widgets/mazl_components.dart';

/// Où mène une étape de complétion.
enum CompletionTarget { editProfile, settings, verification }

/// Ce que vérifie une étape de complétion.
enum CompletionStepKind { photos, bio, city, verification }

class CompletionStep {
  const CompletionStep({
    required this.kind,
    required this.target,
    required this.isComplete,
  });

  final CompletionStepKind kind;
  final CompletionTarget target;
  final bool isComplete;

  /// Ce que dit la ligne : ce qui est fait, ou ce qu'il reste à faire.
  String description(AppLocalizations l10n) => switch (kind) {
    CompletionStepKind.photos =>
      isComplete ? l10n.profileStepPhotosDone : l10n.profileStepPhotosTodo,
    CompletionStepKind.bio =>
      isComplete ? l10n.profileStepBioDone : l10n.profileStepBioTodo,
    CompletionStepKind.city =>
      isComplete ? l10n.profileStepCityDone : l10n.profileStepCityTodo,
    CompletionStepKind.verification =>
      isComplete ? l10n.profileStepVerifiedDone : l10n.profileStepVerifiedTodo,
  };
}

/// Les quatre étapes qui font un profil complet.
List<CompletionStep> buildCompletionSteps({
  required List<String> photos,
  required String? bio,
  required bool isVerified,
  required String? location,
}) {
  final hasBio = bio != null && bio.isNotEmpty;
  final hasLocation = location != null && location.isNotEmpty;
  return [
    CompletionStep(
      kind: CompletionStepKind.photos,
      target: CompletionTarget.editProfile,
      isComplete: photos.length >= 2,
    ),
    CompletionStep(
      kind: CompletionStepKind.bio,
      target: CompletionTarget.editProfile,
      isComplete: hasBio,
    ),
    CompletionStep(
      kind: CompletionStepKind.city,
      target: CompletionTarget.settings,
      isComplete: hasLocation,
    ),
    CompletionStep(
      kind: CompletionStepKind.verification,
      target: CompletionTarget.verification,
      isComplete: isVerified,
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
    final l10n = context.l10n;
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
          SectionLabel(l10n.profileCompletionEyebrow(done, steps.length)),
          const SizedBox(height: 10),
          Text(
            l10n.profileCompletionTitle,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, letterSpacing: -0.6),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.profileCompletionRemaining(remaining),
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
              child: Text(l10n.profileCompletionAction),
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
              step.description(context.l10n),
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
