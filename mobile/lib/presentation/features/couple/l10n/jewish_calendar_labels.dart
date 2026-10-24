import 'package:kosher_dart/kosher_dart.dart' show Parsha;

import '../../../../core/services/jewish_calendar_service.dart';
import '../../../../l10n/l10n.dart';

/// The words of the Jewish calendar, in the member's language. The core names
/// a holiday, an idea or a parasha by an identifier; these write it.
extension JewishHolidayLabel on JewishHolidayId {
  String title(AppLocalizations l10n) => switch (this) {
    JewishHolidayId.roshHashana => l10n.jewishCalendarHolidayRoshHashanaName,
    JewishHolidayId.yomKippur => l10n.jewishCalendarHolidayYomKippurName,
    JewishHolidayId.sukkot => l10n.jewishCalendarHolidaySukkotName,
    JewishHolidayId.sheminiAtzeret =>
      l10n.jewishCalendarHolidaySheminiAtzeretName,
    JewishHolidayId.simchatTorah => l10n.jewishCalendarHolidaySimchatTorahName,
    JewishHolidayId.hanukkah => l10n.jewishCalendarHolidayHanukkahName,
    JewishHolidayId.tuBishvat => l10n.jewishCalendarHolidayTuBishvatName,
    JewishHolidayId.purim => l10n.jewishCalendarHolidayPurimName,
    JewishHolidayId.pesach => l10n.jewishCalendarHolidayPesachName,
    JewishHolidayId.yomHashoah => l10n.jewishCalendarHolidayYomHashoahName,
    JewishHolidayId.yomHazikaron => l10n.jewishCalendarHolidayYomHazikaronName,
    JewishHolidayId.yomHaatzmaut => l10n.jewishCalendarHolidayYomHaatzmautName,
    JewishHolidayId.yomYerushalayim =>
      l10n.jewishCalendarHolidayYomYerushalayimName,
    JewishHolidayId.lagBaomer => l10n.jewishCalendarHolidayLagBaomerName,
    JewishHolidayId.shavuot => l10n.jewishCalendarHolidayShavuotName,
  };

  String description(AppLocalizations l10n) => switch (this) {
    JewishHolidayId.roshHashana =>
      l10n.jewishCalendarHolidayRoshHashanaDescription,
    JewishHolidayId.yomKippur => l10n.jewishCalendarHolidayYomKippurDescription,
    JewishHolidayId.sukkot => l10n.jewishCalendarHolidaySukkotDescription,
    JewishHolidayId.sheminiAtzeret =>
      l10n.jewishCalendarHolidaySheminiAtzeretDescription,
    JewishHolidayId.simchatTorah =>
      l10n.jewishCalendarHolidaySimchatTorahDescription,
    JewishHolidayId.hanukkah => l10n.jewishCalendarHolidayHanukkahDescription,
    JewishHolidayId.tuBishvat => l10n.jewishCalendarHolidayTuBishvatDescription,
    JewishHolidayId.purim => l10n.jewishCalendarHolidayPurimDescription,
    JewishHolidayId.pesach => l10n.jewishCalendarHolidayPesachDescription,
    JewishHolidayId.yomHashoah =>
      l10n.jewishCalendarHolidayYomHashoahDescription,
    JewishHolidayId.yomHazikaron =>
      l10n.jewishCalendarHolidayYomHazikaronDescription,
    JewishHolidayId.yomHaatzmaut =>
      l10n.jewishCalendarHolidayYomHaatzmautDescription,
    JewishHolidayId.yomYerushalayim =>
      l10n.jewishCalendarHolidayYomYerushalayimDescription,
    JewishHolidayId.lagBaomer => l10n.jewishCalendarHolidayLagBaomerDescription,
    JewishHolidayId.shavuot => l10n.jewishCalendarHolidayShavuotDescription,
  };
}

extension HolidayIdeaLabel on HolidayIdea {
  String label(AppLocalizations l10n) => switch (this) {
    HolidayIdea.festiveDinner => l10n.jewishCalendarIdeaFestiveDinner,
    HolidayIdea.tashlich => l10n.jewishCalendarIdeaTashlich,
    HolidayIdea.mutualForgiveness => l10n.jewishCalendarIdeaMutualForgiveness,
    HolidayIdea.buildSukkah => l10n.jewishCalendarIdeaBuildSukkah,
    HolidayIdea.inviteFriends => l10n.jewishCalendarIdeaInviteFriends,
    HolidayIdea.prayerForRain => l10n.jewishCalendarIdeaPrayerForRain,
    HolidayIdea.danceWithTorah => l10n.jewishCalendarIdeaDanceWithTorah,
    HolidayIdea.lightCandlesTogether =>
      l10n.jewishCalendarIdeaLightCandlesTogether,
    HolidayIdea.homemadeSufganiyot => l10n.jewishCalendarIdeaHomemadeSufganiyot,
    HolidayIdea.coupleCostumes => l10n.jewishCalendarIdeaCoupleCostumes,
    HolidayIdea.mishloachManot => l10n.jewishCalendarIdeaMishloachManot,
    HolidayIdea.romanticSeder => l10n.jewishCalendarIdeaRomanticSeder,
    HolidayIdea.tripToIsrael => l10n.jewishCalendarIdeaTripToIsrael,
    HolidayIdea.israeliBarbecue => l10n.jewishCalendarIdeaIsraeliBarbecue,
    HolidayIdea.concertOrParty => l10n.jewishCalendarIdeaConcertOrParty,
    HolidayIdea.campfire => l10n.jewishCalendarIdeaCampfire,
    HolidayIdea.picnic => l10n.jewishCalendarIdeaPicnic,
    HolidayIdea.homemadeCheesecake => l10n.jewishCalendarIdeaHomemadeCheesecake,
    HolidayIdea.studyNight => l10n.jewishCalendarIdeaStudyNight,
  };
}

extension OccasionActivityLabel on OccasionActivityId {
  String title(AppLocalizations l10n) => switch (this) {
    OccasionActivityId.shabbatDinner =>
      l10n.jewishCalendarActivityShabbatDinnerTitle,
    OccasionActivityId.shabbatCandles =>
      l10n.jewishCalendarActivityShabbatCandlesTitle,
    OccasionActivityId.shabbatWalk =>
      l10n.jewishCalendarActivityShabbatWalkTitle,
    OccasionActivityId.shabbatParasha =>
      l10n.jewishCalendarActivityShabbatParashaTitle,
    OccasionActivityId.pesachSeder =>
      l10n.jewishCalendarActivityPesachSederTitle,
    OccasionActivityId.pesachCleaning =>
      l10n.jewishCalendarActivityPesachCleaningTitle,
  };

  String body(AppLocalizations l10n) => switch (this) {
    OccasionActivityId.shabbatDinner =>
      l10n.jewishCalendarActivityShabbatDinnerBody,
    OccasionActivityId.shabbatCandles =>
      l10n.jewishCalendarActivityShabbatCandlesBody,
    OccasionActivityId.shabbatWalk =>
      l10n.jewishCalendarActivityShabbatWalkBody,
    OccasionActivityId.shabbatParasha =>
      l10n.jewishCalendarActivityShabbatParashaBody,
    OccasionActivityId.pesachSeder =>
      l10n.jewishCalendarActivityPesachSederBody,
    OccasionActivityId.pesachCleaning =>
      l10n.jewishCalendarActivityPesachCleaningBody,
  };
}

extension OccasionActivityCategoryLabel on OccasionActivityCategory {
  String label(AppLocalizations l10n) => switch (this) {
    OccasionActivityCategory.preparation =>
      l10n.jewishCalendarCategoryPreparation,
    OccasionActivityCategory.spiritual => l10n.jewishCalendarCategorySpiritual,
    OccasionActivityCategory.relaxation =>
      l10n.jewishCalendarCategoryRelaxation,
  };
}

extension ParshaLabel on Parsha {
  /// The name of the parasha, empty when there is none to show. Two parashot
  /// read together (Vayakhel-Pekudei) are written from their two names.
  String title(AppLocalizations l10n) => switch (this) {
    Parsha.BERESHIS => l10n.jewishCalendarParshaBereshis,
    Parsha.NOACH => l10n.jewishCalendarParshaNoach,
    Parsha.LECH_LECHA => l10n.jewishCalendarParshaLechLecha,
    Parsha.VAYERA => l10n.jewishCalendarParshaVayera,
    Parsha.CHAYEI_SARA => l10n.jewishCalendarParshaChayeiSara,
    Parsha.TOLDOS => l10n.jewishCalendarParshaToldos,
    Parsha.VAYETZEI => l10n.jewishCalendarParshaVayetzei,
    Parsha.VAYISHLACH => l10n.jewishCalendarParshaVayishlach,
    Parsha.VAYESHEV => l10n.jewishCalendarParshaVayeshev,
    Parsha.MIKETZ => l10n.jewishCalendarParshaMiketz,
    Parsha.VAYIGASH => l10n.jewishCalendarParshaVayigash,
    Parsha.VAYECHI => l10n.jewishCalendarParshaVayechi,
    Parsha.SHEMOS => l10n.jewishCalendarParshaShemos,
    Parsha.VAERA => l10n.jewishCalendarParshaVaera,
    Parsha.BO => l10n.jewishCalendarParshaBo,
    Parsha.BESHALACH => l10n.jewishCalendarParshaBeshalach,
    Parsha.YISRO => l10n.jewishCalendarParshaYisro,
    Parsha.MISHPATIM => l10n.jewishCalendarParshaMishpatim,
    Parsha.TERUMAH => l10n.jewishCalendarParshaTerumah,
    Parsha.TETZAVEH => l10n.jewishCalendarParshaTetzaveh,
    Parsha.KI_SISA => l10n.jewishCalendarParshaKiSisa,
    Parsha.VAYAKHEL => l10n.jewishCalendarParshaVayakhel,
    Parsha.PEKUDEI => l10n.jewishCalendarParshaPekudei,
    Parsha.VAYIKRA => l10n.jewishCalendarParshaVayikra,
    Parsha.TZAV => l10n.jewishCalendarParshaTzav,
    Parsha.SHMINI => l10n.jewishCalendarParshaShmini,
    Parsha.TAZRIA => l10n.jewishCalendarParshaTazria,
    Parsha.METZORA => l10n.jewishCalendarParshaMetzora,
    Parsha.ACHREI_MOS => l10n.jewishCalendarParshaAchreiMos,
    Parsha.KEDOSHIM => l10n.jewishCalendarParshaKedoshim,
    Parsha.EMOR => l10n.jewishCalendarParshaEmor,
    Parsha.BEHAR => l10n.jewishCalendarParshaBehar,
    Parsha.BECHUKOSAI => l10n.jewishCalendarParshaBechukosai,
    Parsha.BAMIDBAR => l10n.jewishCalendarParshaBamidbar,
    Parsha.NASSO => l10n.jewishCalendarParshaNasso,
    Parsha.BEHAALOSCHA => l10n.jewishCalendarParshaBehaaloscha,
    Parsha.SHLACH => l10n.jewishCalendarParshaShlach,
    Parsha.KORACH => l10n.jewishCalendarParshaKorach,
    Parsha.CHUKAS => l10n.jewishCalendarParshaChukas,
    Parsha.BALAK => l10n.jewishCalendarParshaBalak,
    Parsha.PINCHAS => l10n.jewishCalendarParshaPinchas,
    Parsha.MATOS => l10n.jewishCalendarParshaMatos,
    Parsha.MASEI => l10n.jewishCalendarParshaMasei,
    Parsha.DEVARIM => l10n.jewishCalendarParshaDevarim,
    Parsha.VAESCHANAN => l10n.jewishCalendarParshaVaeschanan,
    Parsha.EIKEV => l10n.jewishCalendarParshaEikev,
    Parsha.REEH => l10n.jewishCalendarParshaReeh,
    Parsha.SHOFTIM => l10n.jewishCalendarParshaShoftim,
    Parsha.KI_SEITZEI => l10n.jewishCalendarParshaKiSeitzei,
    Parsha.KI_SAVO => l10n.jewishCalendarParshaKiSavo,
    Parsha.NITZAVIM => l10n.jewishCalendarParshaNitzavim,
    Parsha.VAYEILECH => l10n.jewishCalendarParshaVayeilech,
    Parsha.HAAZINU => l10n.jewishCalendarParshaHaazinu,
    Parsha.VZOS_HABERACHA => l10n.jewishCalendarParshaVzosHaberacha,
    Parsha.VAYAKHEL_PEKUDEI => l10n.jewishCalendarParshaPair(
      Parsha.VAYAKHEL.title(l10n),
      Parsha.PEKUDEI.title(l10n),
    ),
    Parsha.TAZRIA_METZORA => l10n.jewishCalendarParshaPair(
      Parsha.TAZRIA.title(l10n),
      Parsha.METZORA.title(l10n),
    ),
    Parsha.ACHREI_MOS_KEDOSHIM => l10n.jewishCalendarParshaPair(
      Parsha.ACHREI_MOS.title(l10n),
      Parsha.KEDOSHIM.title(l10n),
    ),
    Parsha.BEHAR_BECHUKOSAI => l10n.jewishCalendarParshaPair(
      Parsha.BEHAR.title(l10n),
      Parsha.BECHUKOSAI.title(l10n),
    ),
    Parsha.CHUKAS_BALAK => l10n.jewishCalendarParshaPair(
      Parsha.CHUKAS.title(l10n),
      Parsha.BALAK.title(l10n),
    ),
    Parsha.MATOS_MASEI => l10n.jewishCalendarParshaPair(
      Parsha.MATOS.title(l10n),
      Parsha.MASEI.title(l10n),
    ),
    Parsha.NITZAVIM_VAYEILECH => l10n.jewishCalendarParshaPair(
      Parsha.NITZAVIM.title(l10n),
      Parsha.VAYEILECH.title(l10n),
    ),
    Parsha.NONE ||
    Parsha.SHKALIM ||
    Parsha.ZACHOR ||
    Parsha.PARA ||
    Parsha.HACHODESH => '',
  };
}
