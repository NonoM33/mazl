import { createHash, createHmac } from "node:crypto";
import { describe, expect, test } from "bun:test";
import { chatMediaSigningMessage, signChatMediaUrl, verifyChatMediaSignature } from "../../src/features/chat/application/media-signer";
import { signPhotoUrl } from "../../src/features/media/application/photo-signer";
import { startPeriodically } from "../../src/features/chat/application/maintenance";

// CONTRAT.md §0.2 / docs/chat: HMAC-SHA256(MEDIA_SIGNING_KEY, "chat:<id>:<exp>"),
// valid one hour. The expected signature is computed here from the contract,
// with the development key derivation documented in shared/crypto/keys.ts.

const key = createHash("sha256").update("mazl-development-only:MEDIA_SIGNING_KEY").digest();
const expected = (id: number, exp: number, prefix = "chat") => createHmac("sha256", key).update(`${prefix}:${id}:${exp}`).digest("base64url");
const NOW = Date.UTC(2026, 9, 24, 12, 0, 0);

function parts(url: string) {
  const parsed = new URL(url, "http://x");
  return { path: parsed.pathname, exp: parsed.searchParams.get("exp") ?? "", sig: parsed.searchParams.get("sig") ?? "" };
}

describe("chat media signatures", () => {
  test("the message is chat:<id>:<exp>", () => expect(chatMediaSigningMessage(31, 1789000000)).toBe("chat:31:1789000000"));

  test("a URL is /media/chat/<id> with exp = now + 1 h and the contract's HMAC", () => {
    const { path, exp, sig } = parts(signChatMediaUrl(31, NOW));
    expect(path).toBe("/media/chat/31");
    expect(Number(exp)).toBe(Math.floor(NOW / 1000) + 3600);
    expect(sig).toBe(expected(31, Number(exp)));
  });

  test("verifies its own URLs until they expire", () => {
    const { exp, sig } = parts(signChatMediaUrl(31, NOW));
    expect(verifyChatMediaSignature(31, exp, sig, NOW + 3_599_000)).toBe(true);
    expect(verifyChatMediaSignature(31, exp, sig, NOW + 3_601_000)).toBe(false);
  });

  test("another id, another expiry, a truncated or empty signature, a non-numeric expiry", () => {
    const { exp, sig } = parts(signChatMediaUrl(31, NOW));
    expect(verifyChatMediaSignature(32, exp, sig, NOW)).toBe(false);
    expect(verifyChatMediaSignature(31, String(Number(exp) + 1), sig, NOW)).toBe(false);
    expect(verifyChatMediaSignature(31, exp, sig.slice(0, -1), NOW)).toBe(false);
    expect(verifyChatMediaSignature(31, exp, "", NOW)).toBe(false);
    expect(verifyChatMediaSignature(31, exp, undefined, NOW)).toBe(false);
    expect(verifyChatMediaSignature(31, "1e10", sig, NOW)).toBe(false);
    expect(verifyChatMediaSignature(31, undefined, sig, NOW)).toBe(false);
  });

  test("a profile-photo signature for the same number never opens a chat file", () => {
    const photo = parts(signPhotoUrl(31, NOW));
    expect(photo.path).toBe("/media/photos/31");
    expect(verifyChatMediaSignature(31, photo.exp, photo.sig, NOW)).toBe(false);
    expect(photo.sig).toBe(expected(31, Number(photo.exp), "photo"));
  });
});

describe("startPeriodically", () => {
  test("runs at once, then on the interval, and a failing run does not stop the schedule", async () => {
    let runs = 0;
    let tick: (() => void) | undefined;
    let interval = 0;
    const fakeSchedule = ((fn: () => void, ms: number) => { tick = fn; interval = ms; return setTimeout(() => undefined, 0); }) as unknown as typeof setInterval;
    const stop = startPeriodically(async () => { runs++; if (runs === 2) throw new Error("boom"); }, 6 * 3600_000, fakeSchedule);
    expect(runs).toBe(1);
    expect(interval).toBe(6 * 3600_000);
    tick!();
    tick!();
    await Bun.sleep(5);
    expect(runs).toBe(3);
    stop();
  });
});
