import { periodOf, previousPeriod, summarize, THEMES, type CheckinSummary, type Ratings } from "../domain/checkin";
import { dayKey, localParts, DEFAULT_TIME_ZONE, daysBetween } from "../domain/local-time";
import type { Mood } from "../domain/mood";
import { matchesFilter, pickFeatured, pickOfTheDay, publicOuting, type Outing, type OutingFilter } from "../domain/outings";
import type { CouplePremium } from "../domain/premium";
import type { QuestionLanguage } from "../domain/question-bank";
import { buildUpcoming, type UpcomingItem } from "../domain/upcoming";
import type { CandleLighting, CoupleContext, DailyQuestionPort, MoodPush, OutingReader, PremiumReader, RitualReader, SpaceStore } from "./space-ports";

export interface SpaceDeps {
  readonly store: SpaceStore;
  readonly rituals: RitualReader;
  readonly outings: OutingReader;
  readonly questions: DailyQuestionPort;
  readonly premium: PremiumReader;
  readonly moodPush: MoodPush;
  readonly candleLighting: CandleLighting;
}

export interface TodayView {
  readonly days: number;
  readonly partner: { readonly id: number; readonly name: string; readonly picture: string | null };
  readonly question: { readonly id: number; readonly text: string; readonly myAnswered: boolean; readonly partnerAnswered: boolean };
  readonly upcoming: UpcomingItem[];
  readonly outing: Outing | null;
  readonly mood: { readonly mine: Mood | null; readonly partner: Mood | null };
  readonly checkin: { readonly due: boolean; readonly period: string };
  readonly premium: CouplePremium;
}

export interface CheckinView {
  readonly period: string;
  readonly mine: Ratings | null;
  readonly partnerDone: boolean;
  readonly summary: CheckinSummary | null;
}

export class CheckinAlreadyDoneError extends Error {
  constructor() {
    super("checkin already done");
    this.name = "CheckinAlreadyDoneError";
  }
}

const TIME_ZONE = DEFAULT_TIME_ZONE;

function today(now: Date): { day: string; year: number; month: number; dayNumber: number } {
  const local = localParts(now, TIME_ZONE);
  return { day: dayKey(local), year: local.year, month: local.month, dayNumber: Math.floor(Date.UTC(local.year, local.month - 1, local.day) / 86_400_000) };
}

export class SpaceService {
  constructor(private readonly deps: SpaceDeps) {}

  async today(ctx: CoupleContext, language: QuestionLanguage, now: Date): Promise<TodayView> {
    const t = today(now);
    const [question, moods, dates, rituals, events, candidates, premium, checkin] = await Promise.all([
      this.deps.questions.today(ctx.coupleId, ctx.userId, language),
      this.deps.store.moods(ctx.coupleId, ctx.userId, ctx.partnerId, t.day),
      this.deps.store.dates(ctx.coupleId),
      this.deps.rituals.enabled(ctx.coupleId),
      this.deps.store.registeredEvents(ctx.coupleId, t.day),
      this.deps.outings.candidates(ctx.coupleId, t.day, TIME_ZONE),
      this.deps.premium.of(ctx.userId, ctx.coupleId, now),
      this.checkin(ctx, now),
    ]);
    const featured = pickOfTheDay(candidates, ctx.coupleId, t.dayNumber);
    return {
      days: ctx.startedAt === null ? 0 : Math.max(0, daysBetween(dayOf(ctx.startedAt), { year: localParts(now, TIME_ZONE).year, month: localParts(now, TIME_ZONE).month, day: localParts(now, TIME_ZONE).day })),
      partner: { id: ctx.partnerId, name: ctx.partnerName, picture: ctx.partnerPicture },
      question: { id: question.id, text: question.text, myAnswered: question.myAnswer !== null, partnerAnswered: question.partnerAnswered },
      upcoming: buildUpcoming({ now, timeZone: TIME_ZONE, dates, rituals, events, candleLighting: this.deps.candleLighting }),
      outing: featured === null ? null : publicOuting(featured),
      mood: moods,
      checkin: { due: checkin.mine === null, period: checkin.period },
      premium,
    };
  }

  async setMood(ctx: CoupleContext, mood: Mood, now: Date): Promise<{ mine: Mood; partner: Mood | null }> {
    const t = today(now);
    const before = await this.deps.store.setMood(ctx.coupleId, ctx.userId, t.day, mood);
    if (mood === "talk" && before !== "talk") await this.deps.moodPush.talkRequested(ctx.partnerId);
    const moods = await this.deps.store.moods(ctx.coupleId, ctx.userId, ctx.partnerId, t.day);
    return { mine: mood, partner: moods.partner };
  }

  async checkin(ctx: CoupleContext, now: Date): Promise<CheckinView> {
    const t = today(now);
    const period = periodOf(t.year, t.month);
    const rows = await this.deps.store.checkins(ctx.coupleId, period);
    const mine = rows.find((row) => row.userId === ctx.userId)?.ratings ?? null;
    const theirs = rows.find((row) => row.userId === ctx.partnerId)?.ratings ?? null;
    let summary: CheckinSummary | null = null;
    if (mine !== null && theirs !== null) summary = summarize([mine, theirs], await this.previousComplete(ctx, t.year, t.month));
    return { period, mine, partnerDone: theirs !== null, summary };
  }

  private async previousComplete(ctx: CoupleContext, year: number, month: number): Promise<readonly [Ratings, Ratings] | null> {
    const rows = await this.deps.store.checkins(ctx.coupleId, previousPeriod(year, month));
    const mine = rows.find((row) => row.userId === ctx.userId)?.ratings;
    const theirs = rows.find((row) => row.userId === ctx.partnerId)?.ratings;
    return mine !== undefined && theirs !== undefined ? [mine, theirs] : null;
  }

  async submitCheckin(ctx: CoupleContext, ratings: Ratings, now: Date): Promise<CheckinView> {
    const t = today(now);
    const saved = await this.deps.store.saveCheckin(ctx.coupleId, ctx.userId, periodOf(t.year, t.month), Object.fromEntries(THEMES.map((theme) => [theme, ratings[theme]])) as unknown as Ratings);
    if (!saved) throw new CheckinAlreadyDoneError();
    return this.checkin(ctx, now);
  }

  async outings(ctx: CoupleContext, filter: OutingFilter | undefined, now: Date): Promise<{ featured: Outing | null; items: Outing[] }> {
    const t = today(now);
    const filtered = (await this.deps.outings.candidates(ctx.coupleId, t.day, TIME_ZONE)).filter((candidate) => matchesFilter(candidate, filter, now, TIME_ZONE));
    const featured = pickFeatured(filtered);
    return { featured: featured === null ? null : publicOuting(featured), items: filtered.filter((candidate) => candidate !== featured).map(publicOuting) };
  }
}

function dayOf(value: string): { year: number; month: number; day: number } {
  const [year, month, day] = value.slice(0, 10).split("-").map(Number);
  return { year: year ?? 1970, month: month ?? 1, day: day ?? 1 };
}

