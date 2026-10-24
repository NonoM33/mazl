import { describe, expect, test } from "bun:test";
import type { BillingStatus, ReceivedLike, SubscriptionRow } from "../../web/src/shared/api/types";
import { firstName, hasPlus, likeCaption } from "../../web/src/features/likes/likes-model";

const like: ReceivedLike = { user_id: 3, display_name: "Jonas Exemple", picture: null, age: 34.7, is_verified: false, liked_at: "2026-10-23T10:00:00Z" };
const billing = (active: boolean): BillingStatus => ({ success: true, plus: { active, source: "stripe", plan_type: null, expires_at: null, status: null }, stripe: { subscription: null, has_customer: false }, conflict: null, can_subscribe: !active, blocked_reason: null });
const row = (status: string, expires: string | null): SubscriptionRow => ({ plan_type: "three_month", status, store: "apple", expires_at: expires });
const now = new Date("2026-10-24T12:00:00Z");

describe("mazl+ detection", () => {
  test("the billing status wins", () => {
    expect(hasPlus(billing(true), row("expired", null), now)).toBe(true);
    expect(hasPlus(billing(false), row("active", "2027-01-01T00:00:00Z"), now)).toBe(false);
  });
  test("without billing, an active unexpired subscription counts", () => {
    expect(hasPlus(null, row("active", "2027-01-01T00:00:00Z"), now)).toBe(true);
  });
  test("an expired or inactive subscription does not", () => {
    expect(hasPlus(null, row("active", "2026-10-01T00:00:00Z"), now)).toBe(false);
    expect(hasPlus(null, row("cancelled", "2027-01-01T00:00:00Z"), now)).toBe(false);
    expect(hasPlus(null, null, now)).toBe(false);
  });
});

describe("captions", () => {
  test("without mazl+: first name only, no age", () => {
    expect(firstName(like)).toBe("Jonas");
    expect(likeCaption(like, false)).toBe("Jonas");
  });
  test("with mazl+: name and age", () => {
    expect(likeCaption(like, true)).toBe("Jonas Exemple, 34");
  });
});
