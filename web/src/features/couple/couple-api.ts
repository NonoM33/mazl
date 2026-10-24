import type { Envelope } from "../../shared/api/types";

// Shapes of the couple routes (src/features/couple/couple.content.routes.ts,
// couple.core.routes.ts). Counts come from Postgres as strings.

export interface DailyQuestion {
  readonly id: number;
  readonly question: string;
  readonly category: string | null;
  readonly user1_answer: string | null;
  readonly user2_answer: string | null;
  readonly asked_at: string;
}
export interface QuestionResponse extends Envelope { readonly question: DailyQuestion }

export interface Milestone { readonly id: number; readonly milestone_type: string; readonly achieved_at: string }
export interface MilestonesResponse extends Envelope { readonly milestones: readonly Milestone[] }

export interface ImportantDate {
  readonly id: number;
  readonly title: string;
  readonly date: string;
  readonly type: string;
  readonly is_recurring: boolean | null;
  readonly notes: string | null;
}
export interface DatesResponse extends Envelope { readonly dates: readonly ImportantDate[] }

export interface Memory {
  readonly id: number;
  readonly type: string;
  readonly title: string | null;
  readonly content: string | null;
  readonly memory_date: string | null;
  readonly created_at: string;
}
export interface MemoriesResponse extends Envelope { readonly memories: readonly Memory[] }

export interface BucketItem {
  readonly id: number;
  readonly title: string;
  readonly description: string | null;
  readonly is_completed: boolean;
  readonly target_date: string | null;
}
export interface BucketResponse extends Envelope { readonly items: readonly BucketItem[] }

export interface CoupleStats {
  readonly total_bookings: string | number;
  readonly saved_activities: string | number;
  readonly events_registered: string | number;
  readonly memories_count: string | number;
  readonly bucket_completed: string | number;
  readonly bucket_total: string | number;
}
export interface Achievement { readonly id: number; readonly achievement_name: string; readonly description: string | null; readonly unlocked_at: string }
export interface StatsResponse extends Envelope { readonly stats: CoupleStats; readonly achievements: readonly Achievement[] }

export interface Activity {
  readonly id: number;
  readonly title: string;
  readonly description: string | null;
  readonly category: string;
  readonly image_url: string | null;
  readonly price_cents: number | null;
  readonly location: string | null;
  readonly city: string | null;
  readonly rating: string | number | null;
  readonly is_kosher: boolean | null;
  readonly is_partner: boolean | null;
  readonly discount_percent: number | null;
  readonly duration_minutes: number | null;
  readonly user_notes?: string | null;
}
export interface ActivitiesResponse extends Envelope { readonly activities: readonly Activity[] }

export interface CoupleEvent {
  readonly id: number;
  readonly title: string;
  readonly description: string | null;
  readonly category: string | null;
  readonly image_url: string | null;
  readonly event_date: string;
  readonly event_time: string | null;
  readonly end_time: string | null;
  readonly location: string | null;
  readonly city: string | null;
  readonly price_cents: number | null;
  readonly max_couples: number | null;
  readonly current_couples: number | null;
  readonly is_kosher: boolean | null;
  readonly dress_code: string | null;
  readonly what_included: string | null;
  readonly is_featured: boolean | null;
}
export interface CoupleEventsResponse extends Envelope { readonly events: readonly CoupleEvent[] }
