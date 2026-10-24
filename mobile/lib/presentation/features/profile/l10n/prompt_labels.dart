import '../../../../core/models/profile_prompt.dart';
import '../../../../l10n/l10n.dart';

extension PromptQuestionLabel on PromptQuestion {
  String text(AppLocalizations l10n) => switch (this) {
    PromptQuestion.perfectSunday => l10n.profilePromptPerfectSunday,
    PromptQuestion.funFact => l10n.profilePromptFunFact,
    PromptQuestion.lifeGoal => l10n.profilePromptLifeGoal,
    PromptQuestion.petPeeve => l10n.profilePromptPetPeeve,
    PromptQuestion.proudOf => l10n.profilePromptProudOf,
    PromptQuestion.lookingFor => l10n.profilePromptLookingFor,
    PromptQuestion.idealVacation => l10n.profilePromptIdealVacation,
    PromptQuestion.favoriteFood => l10n.profilePromptFavoriteFood,
    PromptQuestion.hiddenTalent => l10n.profilePromptHiddenTalent,
    PromptQuestion.bingeWatching => l10n.profilePromptBingeWatching,
    PromptQuestion.shabbatIdeal => l10n.profilePromptShabbatIdeal,
    PromptQuestion.familyTradition => l10n.profilePromptFamilyTradition,
    PromptQuestion.favoriteHoliday => l10n.profilePromptFavoriteHoliday,
    PromptQuestion.fridayNight => l10n.profilePromptFridayNight,
    PromptQuestion.israelMemory => l10n.profilePromptIsraelMemory,
    PromptQuestion.jewishValue => l10n.profilePromptJewishValue,
    PromptQuestion.debateMe => l10n.profilePromptDebateMe,
    PromptQuestion.teachMe => l10n.profilePromptTeachMe,
    PromptQuestion.togetherWeCould => l10n.profilePromptTogetherWeCould,
    PromptQuestion.firstDate => l10n.profilePromptFirstDate,
  };
}

extension PromptCategoryLabel on PromptCategory {
  String label(AppLocalizations l10n) => switch (this) {
    PromptCategory.personality => l10n.profilePromptCategoryPersonality,
    PromptCategory.lifestyle => l10n.profilePromptCategoryLifestyle,
    PromptCategory.jewish => l10n.profilePromptCategoryJewish,
    PromptCategory.conversation => l10n.profilePromptCategoryConversation,
  };
}

/// La question d'un prompt dans la langue du membre, retrouvée par son
/// identifiant stable. [serverText] ne sert que de repli pour un identifiant
/// que cette version de l'app ne connaît pas.
String promptQuestionText(
  AppLocalizations l10n,
  String promptId,
  String serverText,
) => PromptQuestion.fromId(promptId)?.text(l10n) ?? serverText;

/// Le titre d'un groupe de questions ; un groupe inconnu se range sous « Autre ».
String promptCategoryText(AppLocalizations l10n, String? categoryId) =>
    PromptCategory.fromId(categoryId)?.label(l10n) ?? l10n.profileOther;
