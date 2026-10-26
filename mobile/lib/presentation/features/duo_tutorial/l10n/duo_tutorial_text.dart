import '../../../../core/duo_tutorial/duo_tutorial_step.dart';
import '../../../../l10n/l10n.dart';

/// Le titre et l'explication de chaque étape, dans la langue du membre. Le
/// cœur (`lib/core`) ne parle pas : l'écran traduit.
extension DuoTutorialStepText on DuoTutorialStep {
  String title(AppLocalizations l10n) => switch (this) {
    DuoTutorialStep.welcome => l10n.duoTutorialWelcomeTitle,
    DuoTutorialStep.open => l10n.duoTutorialOpenTitle,
    DuoTutorialStep.book => l10n.duoTutorialBookTitle,
    DuoTutorialStep.table => l10n.duoTutorialTableTitle,
    DuoTutorialStep.tent => l10n.duoTutorialTentTitle,
    DuoTutorialStep.ready => l10n.duoTutorialReadyTitle,
  };

  String body(AppLocalizations l10n) => switch (this) {
    DuoTutorialStep.welcome => l10n.duoTutorialWelcomeBody,
    DuoTutorialStep.open => l10n.duoTutorialOpenBody,
    DuoTutorialStep.book => l10n.duoTutorialBookBody,
    DuoTutorialStep.table => l10n.duoTutorialTableBody,
    DuoTutorialStep.tent => l10n.duoTutorialTentBody,
    DuoTutorialStep.ready => l10n.duoTutorialReadyBody,
  };
}
