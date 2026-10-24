import { JewishCalendar } from "kosher-zmanim";

// Upcoming Jewish holidays, computed like the app
// (mobile/lib/core/services/jewish_calendar_service.dart): diaspora, modern
// holidays on, French labels and couple ideas copied from it. Multi-day
// festivals are one entry.

export type HolidayKind = "major" | "minor" | "memorial" | "israeli";

export interface Holiday {
  readonly name: string;
  readonly hebrewName: string;
  readonly description: string;
  readonly kind: HolidayKind;
  readonly ideas: readonly string[];
  // First day of the festival, local midnight.
  readonly start: Date;
  // The evening before: Jewish days start at nightfall (Hanoucca 5787 starts the evening of 4 December 2026).
  readonly eve: Date;
  // Last day, null for a one-day festival.
  readonly end: Date | null;
}

interface Meta {
  readonly group: number;
  readonly name: string;
  readonly hebrewName: string;
  readonly description: string;
  readonly kind: HolidayKind;
  readonly ideas: readonly string[];
}

const LOOKAHEAD_DAYS = 400;
const DAY_MS = 86_400_000;

const meta = (group: number, name: string, hebrewName: string, description: string, kind: HolidayKind, ideas: readonly string[] = []): Meta => ({ group, name, hebrewName, description, kind, ideas });

const SUCCOT = meta(JewishCalendar.SUCCOS, "Souccot", "סוכות", "Fête des cabanes", "major", ["Construire la Soucca ensemble", "Inviter des amis"]);
const PURIM = meta(JewishCalendar.PURIM, "Pourim", "פורים", "Fête des sorts", "major", ["Déguisement en couple", "Mishloach Manot ensemble"]);
const PESSAH = meta(JewishCalendar.PESACH, "Pessah", "פסח", "Fête de la liberté", "major", ["Seder romantique", "Voyage en Israël"]);

const BY_INDEX = new Map<number, Meta>([
  [JewishCalendar.ROSH_HASHANA, meta(JewishCalendar.ROSH_HASHANA, "Rosh Hashana", "ראש השנה", "Nouvel an juif", "major", ["Dîner festif", "Tashlich ensemble"])],
  [JewishCalendar.YOM_KIPPUR, meta(JewishCalendar.YOM_KIPPUR, "Yom Kippour", "יום כיפור", "Jour du Grand Pardon", "major", ["Se demander pardon mutuellement"])],
  [JewishCalendar.SUCCOS, SUCCOT],
  [JewishCalendar.CHOL_HAMOED_SUCCOS, SUCCOT],
  [JewishCalendar.HOSHANA_RABBA, SUCCOT],
  [JewishCalendar.SHEMINI_ATZERES, meta(JewishCalendar.SHEMINI_ATZERES, "Shemini Atseret", "שמיני עצרת", "Huitième jour de rassemblement", "major", ["Prière pour la pluie"])],
  [JewishCalendar.SIMCHAS_TORAH, meta(JewishCalendar.SIMCHAS_TORAH, "Simhat Torah", "שמחת תורה", "Joie de la Torah", "major", ["Danser avec la Torah"])],
  [JewishCalendar.CHANUKAH, meta(JewishCalendar.CHANUKAH, "Hanoucca", "חנוכה", "Fête des lumières", "major", ["Allumer les bougies ensemble", "Soufganiot maison"])],
  [JewishCalendar.TU_BESHVAT, meta(JewishCalendar.TU_BESHVAT, "Tou Bichvat", "ט״ו בשבט", "Nouvel an des arbres", "minor")],
  [JewishCalendar.PURIM, PURIM],
  [JewishCalendar.SHUSHAN_PURIM, PURIM],
  [JewishCalendar.PESACH, PESSAH],
  [JewishCalendar.CHOL_HAMOED_PESACH, PESSAH],
  [JewishCalendar.YOM_HASHOAH, meta(JewishCalendar.YOM_HASHOAH, "Yom HaShoah", "יום השואה", "Jour du souvenir de la Shoah", "memorial")],
  [JewishCalendar.YOM_HAZIKARON, meta(JewishCalendar.YOM_HAZIKARON, "Yom HaZikaron", "יום הזיכרון", "Jour du souvenir des soldats", "memorial")],
  [JewishCalendar.YOM_HAATZMAUT, meta(JewishCalendar.YOM_HAATZMAUT, "Yom HaAtsmaout", "יום העצמאות", "Jour de l'indépendance d'Israël", "israeli", ["BBQ israélien", "Concert/soirée"])],
  [JewishCalendar.YOM_YERUSHALAYIM, meta(JewishCalendar.YOM_YERUSHALAYIM, "Yom Yeroushalayim", "יום ירושלים", "Jour de la réunification de Jérusalem", "israeli")],
  [JewishCalendar.LAG_BAOMER, meta(JewishCalendar.LAG_BAOMER, "Lag BaOmer", "ל״ג בעומר", "33e jour du Omer", "minor", ["Feu de camp", "Pique-nique"])],
  [JewishCalendar.SHAVUOS, meta(JewishCalendar.SHAVUOS, "Shavouot", "שבועות", "Don de la Torah", "major", ["Cheesecake maison", "Nuit d'étude"])],
]);

const addDays = (date: Date, days: number): Date => new Date(date.getFullYear(), date.getMonth(), date.getDate() + days);

function yomTovIndex(day: Date): number {
  const calendar = new JewishCalendar(day);
  calendar.setInIsrael(false);
  calendar.setUseModernHolidays(true);
  return calendar.getYomTovIndex();
}

interface Run { readonly meta: Meta; readonly start: Date; end: Date | null }

function collectRuns(from: Date): Run[] {
  const runs = new Map<number, Run>();
  for (let offset = 0; offset < LOOKAHEAD_DAYS; offset += 1) {
    const day = addDays(from, offset);
    const found = BY_INDEX.get(yomTovIndex(day));
    if (!found) continue;
    const run = runs.get(found.group);
    if (!run) runs.set(found.group, { meta: found, start: day, end: null });
    else if (Math.round((day.getTime() - (run.end ?? run.start).getTime()) / DAY_MS) === 1) run.end = day;
  }
  return [...runs.values()];
}

// The next `count` festivals from `from` (included), earliest first.
export function upcomingHolidays(from: Date, count = 5): readonly Holiday[] {
  const today = new Date(from.getFullYear(), from.getMonth(), from.getDate());
  return collectRuns(today)
    .sort((a, b) => a.start.getTime() - b.start.getTime())
    .slice(0, count)
    .map(({ meta: m, start, end }) => ({ name: m.name, hebrewName: m.hebrewName, description: m.description, kind: m.kind, ideas: m.ideas, start, eve: addDays(start, -1), end }));
}

// Whole days from `from` to the evening the festival begins (0: tonight).
export function daysUntil(holiday: Holiday, from: Date): number {
  const today = new Date(from.getFullYear(), from.getMonth(), from.getDate());
  return Math.max(0, Math.round((holiday.eve.getTime() - today.getTime()) / DAY_MS));
}

const SHORT = new Intl.DateTimeFormat("fr-FR", { day: "numeric", month: "short" });
const DAY = new Intl.DateTimeFormat("fr-FR", { day: "numeric" });

// « soir du 4 – 12 déc. »: the festival begins the evening before its first day.
export function holidayDates(holiday: Holiday): string {
  const last = holiday.end ?? holiday.start;
  const from = holiday.eve.getMonth() === last.getMonth() ? DAY.format(holiday.eve) : SHORT.format(holiday.eve);
  return `${from} – ${SHORT.format(last)}`;
}
