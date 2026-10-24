import type { Browser } from "playwright";
import { signedIn, type SignedIn } from "./browser";
import type { Member } from "./seed";

// bun's `expect` has no poll: wait until a read gives the wanted answer.
export async function until<T>(read: () => Promise<T>, wanted: (value: T) => boolean, timeoutMs = 6000): Promise<T> {
  const deadline = Date.now() + timeoutMs;
  for (;;) {
    const value = await read();
    if (wanted(value)) return value;
    if (Date.now() > deadline) throw new Error(`condition not met, last value: ${JSON.stringify(value)}`);
    await new Promise((resolve) => setTimeout(resolve, 100));
  }
}

// Sign-in is rate limited: one browser session per member and theme, reused
// by every scenario of a file.
export function sessionCache(browser: () => Browser, member: () => Member) {
  const sessions = new Map<string, SignedIn>();
  return async (theme: "light" | "dark"): Promise<SignedIn> => {
    const cached = sessions.get(theme);
    if (cached) return cached;
    const created = await signedIn(browser(), member(), { theme });
    sessions.set(theme, created);
    return created;
  };
}
