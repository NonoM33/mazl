import '../../../../core/models/profile_labels.dart';
import '../../../../core/models/relationship_intention.dart';
import '../../../../l10n/l10n.dart';

/// Les libellés des réponses de profil. Le cœur normalise la valeur stockée
/// vers un type ; ici on le dit dans la langue du membre.

extension DenominationLabel on Denomination {
  String label(AppLocalizations l10n) => switch (this) {
    Denomination.secular => l10n.profileDenominationSecular,
    Denomination.traditional => l10n.profileDenominationTraditional,
    Denomination.masorti => l10n.profileDenominationMasorti,
    Denomination.liberal => l10n.profileDenominationLiberal,
    Denomination.modernOrthodox => l10n.profileDenominationModernOrthodox,
    Denomination.orthodox => l10n.profileDenominationOrthodox,
    Denomination.chabad => l10n.profileDenominationChabad,
    Denomination.other => l10n.profileOther,
  };
}

extension KashrutLabel on Kashrut {
  /// Sur le profil : la phrase complète (« Cacher à la maison »).
  String label(AppLocalizations l10n) => switch (this) {
    Kashrut.none => l10n.profileKashrutNone,
    Kashrut.home => l10n.profileKashrutHome,
    Kashrut.strict => l10n.profileKashrutStrict,
    Kashrut.glatt => l10n.profileKashrutGlatt,
  };

  /// Dans la modification et l'inscription : le choix court (« À la maison »).
  String optionLabel(AppLocalizations l10n) => switch (this) {
    Kashrut.none => l10n.profileKashrutNone,
    Kashrut.home => l10n.profileKashrutOptionHome,
    Kashrut.strict => l10n.profileKashrutOptionStrict,
    Kashrut.glatt => l10n.profileKashrutOptionGlatt,
  };
}

extension ShabbatObservanceLabel on ShabbatObservance {
  /// Sur le profil (« Shabbat en partie »).
  String label(AppLocalizations l10n) => switch (this) {
    ShabbatObservance.notObservant => l10n.profileShabbatNotObservant,
    ShabbatObservance.partial => l10n.profileShabbatPartial,
    ShabbatObservance.observant => l10n.profileShabbatObserved,
    ShabbatObservance.strict => l10n.profileShabbatStrict,
    ShabbatObservance.family => l10n.profileShabbatFamily,
  };

  /// Dans la modification et l'inscription (« Partiellement »).
  String optionLabel(AppLocalizations l10n) => switch (this) {
    ShabbatObservance.notObservant => l10n.profileShabbatNotObservant,
    ShabbatObservance.partial => l10n.profileShabbatOptionPartial,
    ShabbatObservance.observant => l10n.profileShabbatOptionObservant,
    ShabbatObservance.strict => l10n.profileShabbatOptionStrict,
    ShabbatObservance.family => l10n.profileShabbatFamily,
  };
}

extension SynagogueVisitsLabel on SynagogueVisits {
  String label(AppLocalizations l10n) => switch (this) {
    SynagogueVisits.daily => l10n.profileSynagogueDaily,
    SynagogueVisits.weekly => l10n.profileSynagogueWeekly,
    SynagogueVisits.holidays => l10n.profileSynagogueHolidays,
    SynagogueVisits.rarely => l10n.profileSynagogueRarely,
  };
}

extension RelationshipIntentionLabel on RelationshipIntention {
  /// Pastille de profil et choix d'inscription.
  String label(AppLocalizations l10n) => switch (this) {
    RelationshipIntention.marriage => l10n.profileIntentionMarriage,
    RelationshipIntention.serious => l10n.profileIntentionSerious,
    RelationshipIntention.open => l10n.profileIntentionOpen,
    RelationshipIntention.friendsFirst => l10n.profileIntentionFriendsFirst,
    RelationshipIntention.undecided => l10n.profileIntentionUndecided,
  };

  /// Sélecteur du profil : « Ouvert(e) à tout » s'écrit avec le « e » facultatif.
  String selectorLabel(AppLocalizations l10n) => switch (this) {
    RelationshipIntention.open => l10n.profileIntentionOpenSelector,
    _ => label(l10n),
  };

  String description(AppLocalizations l10n) => switch (this) {
    RelationshipIntention.marriage => l10n.profileIntentionMarriageDescription,
    RelationshipIntention.serious => l10n.profileIntentionSeriousDescription,
    RelationshipIntention.open => l10n.profileIntentionOpenDescription,
    RelationshipIntention.friendsFirst =>
      l10n.profileIntentionFriendsFirstDescription,
    RelationshipIntention.undecided => l10n.profileIntentionUndecided,
  };
}

/// Le texte d'une réponse stockée. `null` quand elle est vide ou, hors
/// [includeHidden], quand elle ne mérite pas de puce (« Non », « Autre »).
String? answerText<T extends Enum>(
  ProfileAnswer<T>? answer,
  String Function(T kind) label, {
  bool includeHidden = false,
}) {
  if (answer == null || (answer.isHidden && !includeHidden)) return null;
  final kind = answer.kind;
  return kind == null ? answer.custom : label(kind);
}

/// Les valeurs du profil, en puces : `null` = pas de puce.
String? denominationFact(AppLocalizations l10n, String? raw) =>
    answerText(ProfileLabels.denominationAnswer(raw), (k) => k.label(l10n));

String? kashrutFact(AppLocalizations l10n, String? raw) =>
    answerText(ProfileLabels.kashrutAnswer(raw), (k) => k.label(l10n));

String? shabbatFact(AppLocalizations l10n, String? raw) =>
    answerText(ProfileLabels.shabbatAnswer(raw), (k) => k.label(l10n));

String? intentionFact(AppLocalizations l10n, String? raw) =>
    answerText(ProfileLabels.intentionAnswer(raw), (k) => k.label(l10n));

/// Les valeurs de la modification du profil : « Non » et « Autre » comptent
/// comme des réponses ; vide = « Non renseigné ».
String denominationField(AppLocalizations l10n, String? raw) =>
    answerText(
      ProfileLabels.denominationAnswer(raw),
      (k) => k.label(l10n),
      includeHidden: true,
    ) ??
    l10n.commonNotSpecified;

String kashrutField(AppLocalizations l10n, String? raw) =>
    answerText(
      ProfileLabels.kashrutAnswer(raw),
      (k) => k.optionLabel(l10n),
      includeHidden: true,
    ) ??
    l10n.commonNotSpecified;

String shabbatField(AppLocalizations l10n, String? raw) =>
    answerText(
      ProfileLabels.shabbatAnswer(raw),
      (k) => k.optionLabel(l10n),
      includeHidden: true,
    ) ??
    l10n.commonNotSpecified;
