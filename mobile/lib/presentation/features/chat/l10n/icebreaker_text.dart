import '../../../../core/services/icebreaker_service.dart';
import '../../../../l10n/l10n.dart';

/// The draft first message of an [Icebreaker], in the member's language.
String icebreakerText(
  AppLocalizations l10n,
  Icebreaker icebreaker,
) => switch (icebreaker.phrase) {
  IcebreakerPhrase.promptLoved => l10n.icebreakerPromptLoved(
    icebreaker.promptText ?? '',
    _followUp(l10n, icebreaker.followUp),
  ),
  IcebreakerPhrase.promptSmiled => l10n.icebreakerPromptSmiled(
    icebreaker.promptText ?? '',
  ),
  IcebreakerPhrase.promptCurious => l10n.icebreakerPromptCurious(
    icebreaker.answer ?? '',
    icebreaker.topic ?? l10n.icebreakerTopicFallback,
  ),
  IcebreakerPhrase.followUpIntrigued ||
  IcebreakerPhrase.followUpKnowMore ||
  IcebreakerPhrase.followUpTellMe ||
  IcebreakerPhrase.followUpInteresting => _followUp(l10n, icebreaker.phrase),
  IcebreakerPhrase.bioTravelRecent => l10n.icebreakerBioTravelRecent,
  IcebreakerPhrase.bioTravelDream => l10n.icebreakerBioTravelDream,
  IcebreakerPhrase.bioMusicGenre => l10n.icebreakerBioMusicGenre,
  IcebreakerPhrase.bioMusicConcert => l10n.icebreakerBioMusicConcert,
  IcebreakerPhrase.bioCookingNow => l10n.icebreakerBioCookingNow,
  IcebreakerPhrase.bioCookingSignature => l10n.icebreakerBioCookingSignature,
  IcebreakerPhrase.bioSportWhich => l10n.icebreakerBioSportWhich,
  IcebreakerPhrase.bioSportWatchOrPlay => l10n.icebreakerBioSportWatchOrPlay,
  IcebreakerPhrase.bioReadingNow => l10n.icebreakerBioReadingNow,
  IcebreakerPhrase.bioReadingLastBook => l10n.icebreakerBioReadingLastBook,
  IcebreakerPhrase.bioCinemaRecent => l10n.icebreakerBioCinemaRecent,
  IcebreakerPhrase.bioCinemaOrSeries => l10n.icebreakerBioCinemaOrSeries,
  IcebreakerPhrase.bioHikingTrails => l10n.icebreakerBioHikingTrails,
  IcebreakerPhrase.bioHikingBest => l10n.icebreakerBioHikingBest,
  IcebreakerPhrase.bioPhotoSubjects => l10n.icebreakerBioPhotoSubjects,
  IcebreakerPhrase.bioPhotoCamera => l10n.icebreakerBioPhotoCamera,
  IcebreakerPhrase.orthodoxSynagogue => l10n.icebreakerOrthodoxSynagogue,
  IcebreakerPhrase.orthodoxShabbat => l10n.icebreakerOrthodoxShabbat,
  IcebreakerPhrase.orthodoxKosherRestaurant =>
    l10n.icebreakerOrthodoxKosherRestaurant,
  IcebreakerPhrase.traditionalTraditions =>
    l10n.icebreakerTraditionalTraditions,
  IcebreakerPhrase.traditionalShabbat => l10n.icebreakerTraditionalShabbat,
  IcebreakerPhrase.traditionalHoliday => l10n.icebreakerTraditionalHoliday,
  IcebreakerPhrase.secularCulture => l10n.icebreakerSecularCulture,
  IcebreakerPhrase.secularFamilyTraditions =>
    l10n.icebreakerSecularFamilyTraditions,
  IcebreakerPhrase.secularHolidays => l10n.icebreakerSecularHolidays,
  IcebreakerPhrase.defaultHoliday => l10n.icebreakerDefaultHoliday,
  IcebreakerPhrase.defaultFamilyTraditions =>
    l10n.icebreakerDefaultFamilyTraditions,
  IcebreakerPhrase.defaultPracticingFamily =>
    l10n.icebreakerDefaultPracticingFamily,
  IcebreakerPhrase.locationKnowWell => l10n.icebreakerLocationKnowWell(
    icebreaker.location ?? '',
  ),
  IcebreakerPhrase.locationFavoriteSpot => l10n.icebreakerLocationFavoriteSpot(
    icebreaker.location ?? '',
  ),
  IcebreakerPhrase.locationOriginallyFrom =>
    l10n.icebreakerLocationOriginallyFrom(icebreaker.location ?? ''),
  IcebreakerPhrase.locationRestaurant => l10n.icebreakerLocationRestaurant(
    icebreaker.location ?? '',
  ),
  IcebreakerPhrase.genericDinnerGuest => l10n.icebreakerGenericDinnerGuest,
  IcebreakerPhrase.genericPerfectDay => l10n.icebreakerGenericPerfectDay,
  IcebreakerPhrase.genericHiddenTalent => l10n.icebreakerGenericHiddenTalent,
  IcebreakerPhrase.genericSpontaneous => l10n.icebreakerGenericSpontaneous,
  IcebreakerPhrase.genericSeaOrMountain => l10n.icebreakerGenericSeaOrMountain,
  IcebreakerPhrase.genericLottery => l10n.icebreakerGenericLottery,
  IcebreakerPhrase.genericGuiltyPleasure =>
    l10n.icebreakerGenericGuiltyPleasure,
  IcebreakerPhrase.genericDream => l10n.icebreakerGenericDream,
  IcebreakerPhrase.genericBestAdvice => l10n.icebreakerGenericBestAdvice,
  IcebreakerPhrase.genericBreakfastOrDinner =>
    l10n.icebreakerGenericBreakfastOrDinner,
};

String _followUp(AppLocalizations l10n, IcebreakerPhrase? phrase) =>
    switch (phrase) {
      IcebreakerPhrase.followUpIntrigued => l10n.icebreakerFollowUpIntrigued,
      IcebreakerPhrase.followUpKnowMore => l10n.icebreakerFollowUpKnowMore,
      IcebreakerPhrase.followUpTellMe => l10n.icebreakerFollowUpTellMe,
      _ => l10n.icebreakerFollowUpInteresting,
    };
