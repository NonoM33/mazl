import { describe, expect, test } from "bun:test";
import { formatHms, formatMinutes, remainingMs } from "../../web/src/features/discover/clock";
import { ApiError } from "../../web/src/shared/api/errors";
import { classifySwipeError } from "../../web/src/features/discover/swipe-outcome";
import { parseMatchEvent } from "../../web/src/features/discover/match-event";
import { cardPhotos, stepPhoto } from "../../web/src/features/discover/photos";
import { card } from "./discover-fixtures";

describe("countdown", () => {
  test("formats hours, minutes, seconds", () => {
    expect(formatHms(3 * 3_600_000 + 4 * 60_000 + 5_000)).toBe("03:04:05");
    expect(formatHms(0)).toBe("00:00:00");
    expect(formatHms(-5)).toBe("00:00:00");
  });
  test("rounds up so it never shows zero early", () => expect(formatHms(900)).toBe("00:00:01"));
  test("boost clock is mm:ss", () => expect(formatMinutes(29 * 60_000 + 59_000)).toBe("29:59"));
  test("remaining time is never negative", () => {
    expect(remainingMs("2026-10-24T12:00:10Z", Date.parse("2026-10-24T12:00:00Z"))).toBe(10_000);
    expect(remainingMs("2026-10-24T12:00:00Z", Date.parse("2026-10-24T12:00:10Z"))).toBe(0);
    expect(remainingMs("not a date", 0)).toBe(0);
  });
});

describe("swipe errors", () => {
  test("402 likes_exhausted carries the allowance", () => {
    const body = { allowance: { daily_allowance: 10, remaining: 0, resets_at: "2026-10-25T00:00:00Z" } };
    expect(classifySwipeError(new ApiError(402, "likes_exhausted", null, body))).toEqual({ kind: "likes_exhausted", allowance: body.allowance });
  });
  test("402 super_likes_exhausted", () => expect(classifySwipeError(new ApiError(402, "super_likes_exhausted")).kind).toBe("super_likes_exhausted"));
  test("429 keeps the delay", () => expect(classifySwipeError(new ApiError(429, "http_429", 42))).toEqual({ kind: "rate_limited", retryAfter: 42 }));
  test("anything else is a failure", () => expect(classifySwipeError(new ApiError(500, "x")).kind).toBe("failed"));
  test("likes_exhausted without a readable body still opens the dialog", () => expect(classifySwipeError(new ApiError(402, "likes_exhausted", null, { allowance: 3 }))).toEqual({ kind: "likes_exhausted", allowance: null }));
});

describe("match event and photos", () => {
  test("reads the socket payload", () => {
    expect(parseMatchEvent({ matchId: 1, conversationId: 7, userId: 4, userName: "Noam", userPicture: "x.jpg" })).toEqual({ userId: 4, name: "Noam", picture: "x.jpg", conversationId: 7 });
    expect(parseMatchEvent({ userId: 4 })?.conversationId).toBeNull();
    expect(parseMatchEvent("nope")).toBeNull();
    expect(parseMatchEvent({ userName: "x" })).toBeNull();
  });
  test("photo stepping clamps on tap and wraps on Space", () => {
    expect(stepPhoto(0, 3, -1, false)).toBe(0);
    expect(stepPhoto(2, 3, 1, false)).toBe(2);
    expect(stepPhoto(2, 3, 1, true)).toBe(0);
    expect(stepPhoto(0, 1, 1, true)).toBe(0);
  });
  test("falls back to the picture when there is no gallery", () => {
    expect(cardPhotos(card(1, { picture: "p.jpg" }))).toEqual(["p.jpg"]);
    expect(cardPhotos(card(1))).toEqual([]);
  });
});
