import { describe, expect, test } from "bun:test";
import { createSlidingWindow } from "../../src/features/chat/application/sliding-window";

describe("sliding window", () => {
  test("allows `max` hits in the window, refuses the next with a retry delay", () => {
    let now = 0;
    const window = createSlidingWindow({ max: 3, windowMs: 10_000, now: () => now });
    for (let i = 0; i < 3; i++) expect(window.attempt(1)).toEqual({ allowed: true });
    now = 4_000;
    expect(window.attempt(1)).toEqual({ allowed: false, retryAfterSeconds: 6 });
  });

  test("refused hits are not recorded, so waiting is enough to get back in", () => {
    let now = 0;
    const window = createSlidingWindow({ max: 1, windowMs: 1_000, now: () => now });
    window.attempt(1);
    for (let i = 0; i < 50; i++) window.attempt(1);
    now = 1_001;
    expect(window.attempt(1).allowed).toBe(true);
  });

  test("users are independent", () => {
    const window = createSlidingWindow({ max: 1, windowMs: 1_000, now: () => 0 });
    expect(window.attempt(1).allowed).toBe(true);
    expect(window.attempt(2).allowed).toBe(true);
    expect(window.attempt(1).allowed).toBe(false);
  });

  test("a hit exactly one window old no longer counts", () => {
    let now = 0;
    const window = createSlidingWindow({ max: 1, windowMs: 1_000, now: () => now });
    window.attempt(1);
    now = 1_000;
    expect(window.attempt(1).allowed).toBe(true);
  });

  test("idle users are forgotten once the table is large", () => {
    let now = 0;
    const window = createSlidingWindow({ max: 1, windowMs: 1_000, now: () => now });
    for (let user = 1; user <= 6_000; user++) window.attempt(user);
    now = 5_000;
    window.attempt(999_999);
    expect(window.size()).toBeLessThan(10);
  });
});
