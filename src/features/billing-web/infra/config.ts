import { z } from "zod";
import type { BillingSettings } from "../application/settings";
import { OFFERS, type OfferId } from "../domain/offers";

export class BillingConfigError extends Error {
  constructor(message: string) {
    super(message);
    this.name = "BillingConfigError";
  }
}

export interface AvailableBillingConfig {
  readonly available: true;
  readonly secretKey: string;
  readonly webhookSecret: string;
  // A fake Stripe server for tests; never accepted in production.
  readonly apiBase: URL | undefined;
  readonly settings: BillingSettings;
}

export type BillingConfig = { readonly available: false } | AvailableBillingConfig;

type Env = Readonly<Record<string, string | undefined>>;

const keySchema = z.string().regex(/^(sk|rk)_(test|live)_[A-Za-z0-9_]+$/, "STRIPE_SECRET_KEY is not a Stripe secret key");
const webhookSecretSchema = z.string().regex(/^whsec_\S+$/, "STRIPE_WEBHOOK_SECRET must start with whsec_");

function required<T>(schema: z.ZodType<T>, value: string | undefined, name: string): T {
  const parsed = schema.safeParse(value);
  if (parsed.success) return parsed.data;
  throw new BillingConfigError(`${name}: ${parsed.error.issues[0]?.message ?? "invalid"}`);
}

function origin(env: Env): string {
  const raw = env.WEB_ORIGIN?.trim() || env.APP_URL?.trim();
  if (raw === undefined || raw === "") throw new BillingConfigError("WEB_ORIGIN or APP_URL is required to build the Stripe return URLs");
  try {
    return new URL(raw).origin;
  } catch {
    throw new BillingConfigError("WEB_ORIGIN / APP_URL is not a valid URL");
  }
}

function apiBase(env: Env): URL | undefined {
  const raw = env.STRIPE_API_BASE?.trim();
  if (raw === undefined || raw === "") return undefined;
  if (env.NODE_ENV === "production") throw new BillingConfigError("STRIPE_API_BASE is refused in production");
  try {
    return new URL(raw);
  } catch {
    throw new BillingConfigError("STRIPE_API_BASE is not a valid URL");
  }
}

function prices(env: Env): Partial<Record<OfferId, string>> {
  const found: Partial<Record<OfferId, string>> = {};
  for (const offer of OFFERS) {
    const value = env[offer.priceEnv]?.trim();
    if (value !== undefined && value !== "") found[offer.id] = value;
  }
  return found;
}

export function readBillingConfig(env: Env = process.env): BillingConfig {
  const rawKey = env.STRIPE_SECRET_KEY?.trim();
  if (rawKey === undefined || rawKey === "") return { available: false };
  const secretKey = required(keySchema, rawKey, "STRIPE_SECRET_KEY");
  if (secretKey.includes("_live_") && env.STRIPE_ALLOW_LIVE !== "true") {
    throw new BillingConfigError("a live Stripe key is refused unless STRIPE_ALLOW_LIVE=true");
  }
  const webhookSecret = required(webhookSecretSchema, env.STRIPE_WEBHOOK_SECRET?.trim(), "STRIPE_WEBHOOK_SECRET");
  const base = origin(env);
  return {
    available: true,
    secretKey,
    webhookSecret,
    apiBase: apiBase(env),
    settings: {
      prices: prices(env),
      successUrl: `${base}/app/premium?checkout=success`,
      cancelUrl: `${base}/app/premium?checkout=cancel`,
      returnUrl: `${base}/app/premium`,
    },
  };
}
