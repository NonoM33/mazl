import type { WebPricing } from "../../application/ports";
import { readStripeApiBase } from "../../../billing-web/infra/config";
import { createStripeClient } from "../../../billing-web/infra/stripe-sdk-gateway";
import { WebPricingError } from "./errors";
import { StripeWebPricing } from "./stripe-web-pricing";

export { WebPricingError } from "./errors";
export { StripeWebPricing } from "./stripe-web-pricing";

type Env = Readonly<Record<string, string | undefined>>;

const KEY_SHAPE = /^(sk|rk)_(test|live)_[A-Za-z0-9_]+$/;

// Same Stripe host as billing-web: STRIPE_API_BASE (a local fake in tests, refused in production).
// null when STRIPE_SECRET_KEY is absent (same variable as billing-web): the server answers `store_not_configured`.
export function createWebPricing(env: Env): WebPricing | null {
  const key = env.STRIPE_SECRET_KEY?.trim();
  if (key === undefined || key === "") return null;
  if (!KEY_SHAPE.test(key)) throw new WebPricingError("STRIPE_SECRET_KEY is not a Stripe secret key");
  return new StripeWebPricing(createStripeClient({ secretKey: key, apiBase: readStripeApiBase(env) }));
}
