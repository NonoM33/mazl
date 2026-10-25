import { test, expect, beforeEach, afterEach } from "bun:test";

// Push of the couple flow: no name in the title, first name only in the body,
// the member is addressed as user_<id> (the id the app logs in to OneSignal with,
// V1-CONTRAT section 1), data carries the type the app routes on, and nothing is
// sent when OneSignal is not configured.
process.env.ONESIGNAL_REST_API_KEY = "test-key";
const realFetch = globalThis.fetch;
let sent: Array<{ headings: { en: string }; contents: { en: string }; include_external_user_ids?: string[]; data?: unknown }> = [];

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

test("accepted push goes to user_<id> with the couple type, and nothing else in data", async () => {
  const n = await load();
  n.pushCoupleAccepted(7, "Myriam Cohen");
  await new Promise((r) => setTimeout(r, 50));
  expect(sent[0]!.include_external_user_ids).toEqual(["user_7"]);
  expect(sent[0]!.data).toEqual({ type: "couple_accepted" });
});

test("request push goes to the target as user_<id>, type couple_request, vouvoiement and no emoji", async () => {
  const n = await load();
  n.pushCoupleRequest({ id: 3, requester_id: 5, target_id: 8, requester_name: "Daniel Lévy", status: "pending" } as unknown as Parameters<typeof n.pushCoupleRequest>[0]);
  await new Promise((r) => setTimeout(r, 50));
  expect(sent).toHaveLength(1);
  expect(sent[0]!.include_external_user_ids).toEqual(["user_8"]);
  expect(sent[0]!.data).toEqual({ type: "couple_request" });
  expect(sent[0]!.contents.en).toContain("Daniel");
  expect(sent[0]!.contents.en).not.toContain("Lévy");
  expect(`${sent[0]!.headings.en} ${sent[0]!.contents.en}`).not.toMatch(/\p{Extended_Pictographic}/u);
});
