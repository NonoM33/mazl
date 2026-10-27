import type { Ratings } from "../domain/checkin";
import type { Mood } from "../domain/mood";
import type { CandleLighting } from "../domain/reminders";
import type { CouplePremium } from "../domain/premium";
import type { OutingCandidate } from "../domain/outings";
import type { Ritual } from "../domain/rituals";
import type { UpcomingDate, UpcomingEvent } from "../domain/upcoming";
import type { QuestionLanguage } from "../domain/question-bank";

// The couple of the caller, as the space services need it.
export interface CoupleContext {
  readonly coupleId: number;
  readonly userId: number;
  readonly partnerId: number;
  readonly partnerName: string;
  readonly partnerPicture: string | null;
  readonly startedAt: string | null;
}

export interface DailyQuestionPort {
  today(coupleId: number, userId: number, language: QuestionLanguage): Promise<{ id: number; text: string; myAnswer: string | null; partnerAnswer: string | null; partnerAnswered: boolean }>;
}

export interface SpaceStore {
  moods(coupleId: number, userId: number, partnerId: number, day: string): Promise<{ mine: Mood | null; partner: Mood | null }>;
  setMood(coupleId: number, userId: number, day: string, mood: Mood): Promise<Mood | null>;
  checkins(coupleId: number, period: string): Promise<{ userId: number; ratings: Ratings }[]>;
  saveCheckin(coupleId: number, userId: number, period: string, ratings: Ratings): Promise<boolean>;
  dates(coupleId: number): Promise<UpcomingDate[]>;
  registeredEvents(coupleId: number, fromDay: string): Promise<UpcomingEvent[]>;
}

export interface RitualReader {
  enabled(coupleId: number): Promise<Ritual[]>;
}

export interface OutingReader {
  candidates(coupleId: number, today: string, timeZone: string): Promise<OutingCandidate[]>;
}

export interface PremiumReader {
  of(userId: number, coupleId: number, now: Date): Promise<CouplePremium>;
}

export interface MoodPush {
  // The partner is told, gently and without any text of the member's.
  talkRequested(partnerId: number): Promise<void>;
}

export interface QuestionPush {
  partnerAnswered(partnerId: number): Promise<void>;
}

export type { CandleLighting };
