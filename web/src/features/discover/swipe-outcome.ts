import { ApiError } from "../../shared/api/errors";
import type { LikeAllowance, SwipeResponse } from "../../shared/api/types";

// What the swipe route answered, as one value the screens switch on.

export type SwipeOutcome =
  | { readonly kind: "ok"; readonly match: boolean }
  | { readonly kind: "likes_exhausted"; readonly allowance: LikeAllowance | null }
  | { readonly kind: "super_likes_exhausted" }
  | { readonly kind: "rate_limited"; readonly retryAfter: number | null }
  | { readonly kind: "failed"; readonly error: unknown };

export function okOutcome(response: SwipeResponse): SwipeOutcome {
  return { kind: "ok", match: response.match };
}

function readAllowance(body: Readonly<Record<string, unknown>>): LikeAllowance | null {
  const raw = body.allowance;
  if (typeof raw !== "object" || raw === null) return null;
  const { daily_allowance: daily, remaining, resets_at: resets } = raw as Record<string, unknown>;
  if (typeof resets !== "string") return null;
  return {
    daily_allowance: typeof daily === "number" ? daily : null,
    remaining: typeof remaining === "number" ? remaining : null,
    resets_at: resets,
  };
}

export function classifySwipeError(error: unknown): SwipeOutcome {
  if (!(error instanceof ApiError)) return { kind: "failed", error };
  if (error.status === 402 && error.code === "likes_exhausted") return { kind: "likes_exhausted", allowance: readAllowance(error.body) };
  if (error.status === 402 && error.code === "super_likes_exhausted") return { kind: "super_likes_exhausted" };
  if (error.isRateLimited) return { kind: "rate_limited", retryAfter: error.retryAfter };
  return { kind: "failed", error };
}
