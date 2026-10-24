import { test, expect, beforeEach, afterEach } from "bun:test";

// Push wording of the couple flow (contract §3): no name in the title, first
// name only in the body, and a silent no-op when OneSignal is not configured.
// onesignal.ts captures its key when first imported: set it before any import.
process.env.ONESIGNAL_REST_API_KEY = "test-key";
const realFetch = globalThis.fetch;
let sent: Array<{ headings: { en: string }; contents: { en: string } }> = [];

beforeEach(() => {
  sent = [];
  globalThis.fetch = (async (_url: unknown, init?: { body?: string }) => {
    sent.push(JSON.parse(String(init?.body)));
    return new Response(JSON.stringify({ id: "n1", recipients: 1 }), { status: 200 });
  }) as unknown as typeof fetch;
});
afterEach(() => {
  globalThis.fetch = realFetch;
  process.env.ONESIGNAL_REST_API_KEY = "test-key";
});

const notifier = await import("../../src/features/couple/application/couple-notifier");
const load = async () => notifier;

test("no push at all when OneSignal is not configured", async () => {
  delete process.env.ONESIGNAL_REST_API_KEY;
  const n = await load();
  n.pushCoupleAccepted(1, "Myriam Cohen");
  await new Promise((r) => setTimeout(r, 20));
  expect(sent).toHaveLength(0);
});

test("accepted push: generic title, first name only in the body", async () => {
  const n = await load();
  n.pushCoupleAccepted(1, "Myriam Cohen");
  await new Promise((r) => setTimeout(r, 50));
  expect(sent).toHaveLength(1);
  expect(sent[0]!.headings.en).toBe("Demande de couple acceptée");
  expect(sent[0]!.contents.en).toContain("Myriam");
  expect(sent[0]!.contents.en).not.toContain("Cohen");
});
