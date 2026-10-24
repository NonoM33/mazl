import { describe, expect, test } from "bun:test";
import { BillingConfigError, readBillingConfig } from "../../src/features/billing-web/infra/config";

const base = { STRIPE_SECRET_KEY: "sk_test_abc123", STRIPE_WEBHOOK_SECRET: "whsec_test_abc", APP_URL: "https://mazl.test/some/path" };

describe("billing configuration", () => {
  test("no key: the module is unavailable", () => {
    expect(readBillingConfig({}).available).toBe(false);
    expect(readBillingConfig({ STRIPE_SECRET_KEY: "  " }).available).toBe(false);
  });

  test("a live key is refused unless STRIPE_ALLOW_LIVE=true", () => {
    const live = { ...base, STRIPE_SECRET_KEY: "sk_live_abc123" };
    expect(() => readBillingConfig(live)).toThrow(BillingConfigError);
    expect(readBillingConfig({ ...live, STRIPE_ALLOW_LIVE: "true" }).available).toBe(true);
    expect(() => readBillingConfig({ ...live, STRIPE_ALLOW_LIVE: "yes" })).toThrow(BillingConfigError);
  });

  test("the webhook secret is mandatory with a key, and must look like one", () => {
    expect(() => readBillingConfig({ ...base, STRIPE_WEBHOOK_SECRET: undefined })).toThrow(BillingConfigError);
    expect(() => readBillingConfig({ ...base, STRIPE_WEBHOOK_SECRET: "nope" })).toThrow(BillingConfigError);
  });

  test("a value that is not a Stripe key is refused", () => {
    expect(() => readBillingConfig({ ...base, STRIPE_SECRET_KEY: "pk_test_abc" })).toThrow(BillingConfigError);
  });

  test("return URLs use WEB_ORIGIN, else APP_URL, reduced to the origin", () => {
    const fromApp = readBillingConfig(base);
    if (!fromApp.available) throw new Error("expected available");
    expect(fromApp.settings.successUrl).toBe("https://mazl.test/app/premium?checkout=success");
    expect(fromApp.settings.cancelUrl).toBe("https://mazl.test/app/premium?checkout=cancel");
    const fromWeb = readBillingConfig({ ...base, WEB_ORIGIN: "https://www.mazl.test/" });
    if (!fromWeb.available) throw new Error("expected available");
    expect(fromWeb.settings.successUrl).toBe("https://www.mazl.test/app/premium?checkout=success");
    expect(() => readBillingConfig({ ...base, APP_URL: undefined })).toThrow(BillingConfigError);
  });

  test("STRIPE_API_BASE is accepted outside production only", () => {
    const withBase = { ...base, STRIPE_API_BASE: "http://127.0.0.1:12111" };
    const config = readBillingConfig(withBase);
    if (!config.available) throw new Error("expected available");
    expect(config.apiBase?.port).toBe("12111");
    expect(() => readBillingConfig({ ...withBase, NODE_ENV: "production" })).toThrow(BillingConfigError);
    expect(() => readBillingConfig({ ...base, STRIPE_API_BASE: "not a url" })).toThrow(BillingConfigError);
  });

  test("only the configured STRIPE_PRICE_* variables become prices", () => {
    const config = readBillingConfig({ ...base, STRIPE_PRICE_PLUS_3M: "price_a", STRIPE_PRICE_BOOST_1: " price_b " });
    if (!config.available) throw new Error("expected available");
    expect(config.settings.prices).toEqual({ plus_3m: "price_a", boost_1: "price_b" });
  });
});
