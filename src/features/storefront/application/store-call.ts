import { StoreCallError, StorefrontError, type StoreName } from "../domain/errors";

const MAX_MESSAGE = 300;

// Runs a call to a store. A business error (store not configured…) goes through
// untouched; anything else becomes a StoreCallError carrying a short message.
export async function callStore<T>(store: StoreName, call: () => Promise<T>): Promise<T> {
  try {
    return await call();
  } catch (error: unknown) {
    if (error instanceof StorefrontError) throw error;
    const message = error instanceof Error ? error.message : "unknown error";
    throw new StoreCallError(store, message.slice(0, MAX_MESSAGE));
  }
}

export function describeFailure(error: unknown): string {
  return (error instanceof Error ? error.message : "unknown error").slice(0, MAX_MESSAGE);
}
