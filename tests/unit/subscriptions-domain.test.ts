import { describe, expect, test } from "bun:test";
import { planTypeForProduct, type PlanType } from "../../src/features/subscriptions/domain/plan";
import { statusForNotificationType, type SubscriptionStatus } from "../../src/features/subscriptions/domain/status";

describe("planTypeForProduct (com.mazl.app.plus.<n>m means n months)", () => {
  const cases: ReadonlyArray<readonly [string, PlanType]> = [
    ["com.mazl.app.plus.1m", "monthly"],
    ["com.mazl.app.plus.2m", "two_month"],
    ["com.mazl.app.plus.3m", "three_month"],
    ["com.mazl.app.plus.6m", "six_month"],
    ["com.mazl.app.plus.12m", "yearly"],
    ["com.mazl.app.plus.4m", "unknown"],
    ["com.mazl.app.plus.m", "unknown"],
    ["com.mazl.app.plus.1m.extra", "unknown"],
    ["com.other.app.plus.1m", "unknown"],
    ["mazl_six_month", "unknown"], // former RevenueCat identifiers are gone
    ["", "unknown"],
  ];
  for (const [productId, plan] of cases) {
    test(`${productId || "(empty)"} -> ${plan}`, () => {
      expect(planTypeForProduct(productId)).toBe(plan);
    });
  }
});

describe("statusForNotificationType (App Store Server Notifications V2)", () => {
  const cases: ReadonlyArray<readonly [string, SubscriptionStatus | undefined]> = [
    ["SUBSCRIBED", "active"],
    ["DID_RENEW", "active"],
    ["DID_CHANGE_RENEWAL_STATUS", "active"],
    ["OFFER_REDEEMED", "active"],
    ["EXPIRED", "expired"],
    ["GRACE_PERIOD_EXPIRED", "expired"],
    ["REFUND", "revoked"],
    ["REVOKE", "revoked"],
    ["DID_FAIL_TO_RENEW", "billing_issue"],
    ["TEST", undefined],
    ["DID_CHANGE_RENEWAL_PREF", undefined],
    ["REFUND_DECLINED", undefined],
    ["", undefined],
  ];
  for (const [type, status] of cases) {
    test(`${type || "(empty)"} -> ${status ?? "no change"}`, () => {
      expect(statusForNotificationType(type)).toBe(status);
    });
  }
});
