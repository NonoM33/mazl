import type { ProductPolicy } from "../domain/transaction";

export const DEFAULT_BUNDLE_ID = "com.mazl.app";
export const DEFAULT_PRODUCT_IDS = "com.mazl.app.plus.1m,com.mazl.app.plus.3m,com.mazl.app.plus.6m,com.mazl.app.plus.12m";

// APPLE_BUNDLE_ID and APPLE_PRODUCT_IDS (comma separated).
export function readProductPolicy(env: Record<string, string | undefined> = process.env): ProductPolicy {
  const productIds = (env.APPLE_PRODUCT_IDS ?? DEFAULT_PRODUCT_IDS)
    .split(",")
    .map((id) => id.trim())
    .filter((id) => id.length > 0);
  return { bundleId: env.APPLE_BUNDLE_ID?.trim() || DEFAULT_BUNDLE_ID, productIds };
}
