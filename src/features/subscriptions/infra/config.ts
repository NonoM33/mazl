import { z } from "zod";
import type { ProductPolicy } from "../domain/transaction";

export const DEFAULT_BUNDLE_ID = "com.mazl.app";
export const DEFAULT_PRODUCT_IDS = "com.mazl.app.plus.1m,com.mazl.app.plus.3m,com.mazl.app.plus.6m,com.mazl.app.plus.12m,com.mazl.app.couple.1m";

// APPLE_ALLOW_SANDBOX: true (default) keeps accepting Apple Sandbox transactions,
// which App Review and TestFlight testers produce against the production server.
// A value that is neither true nor false is a configuration error, not a reason
// to stay open by accident: it fails at boot.
const allowSandboxSchema = z.stringbool().default(true);

function readAllowSandbox(raw: string | undefined): boolean {
  const trimmed = raw?.trim();
  return allowSandboxSchema.parse(trimmed === "" ? undefined : trimmed);
}

// APPLE_BUNDLE_ID, APPLE_PRODUCT_IDS (comma separated) and APPLE_ALLOW_SANDBOX.
export function readProductPolicy(env: Record<string, string | undefined> = process.env): ProductPolicy {
  const productIds = (env.APPLE_PRODUCT_IDS ?? DEFAULT_PRODUCT_IDS)
    .split(",")
    .map((id) => id.trim())
    .filter((id) => id.length > 0);
  return {
    bundleId: env.APPLE_BUNDLE_ID?.trim() || DEFAULT_BUNDLE_ID,
    productIds,
    allowSandbox: readAllowSandbox(env.APPLE_ALLOW_SANDBOX),
  };
}
