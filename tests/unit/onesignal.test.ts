import { afterEach, beforeEach, describe, expect, test } from "bun:test";
import { sendDailyQuestionNotification, sendEventReminder, sendMilestoneNotification, sendPushNotification, sendPushToUsers } from "../../src/onesignal";

// What OneSignal receives, from the contract of the app (V1-CONTRAT section 1):
// the target is the external id "user_<id>" the app logs in with, `data` holds
// what the app routes on, and without ONESIGNAL_REST_API_KEY nothing leaves.

interface Sent {
  readonly url: string;
  readonly authorization: string | null;
  readonly body: Record<string, unknown>;
}

const realFetch = globalThis.fetch;
const realEnv = { key: process.env.ONESIGNAL_REST_API_KEY, base: process.env.ONESIGNAL_API_BASE };
let sent: Sent[] = [];

beforeEach(() => {
  sent = [];
  process.env.ONESIGNAL_REST_API_KEY = "test-key";
  delete process.env.ONESIGNAL_API_BASE;
  globalThis.fetch = (async (url: unknown, init?: { body?: string; headers?: Record<string, string> }) => {
    sent.push({ url: String(url), authorization: init?.headers?.Authorization ?? null, body: JSON.parse(String(init?.body)) as Record<string, unknown> });
    return new Response(JSON.stringify({ id: "n1", recipients: 1 }), { status: 200 });
  }) as unknown as typeof fetch;
});

afterEach(() => {
  globalThis.fetch = realFetch;
  for (const [name, value] of [["ONESIGNAL_REST_API_KEY", realEnv.key], ["ONESIGNAL_API_BASE", realEnv.base]] as const) {
    if (value === undefined) delete process.env[name];
    else process.env[name] = value;
  }
});

const EMOJI = /\p{Extended_Pictographic}/u;
const TUTOIEMENT = /\b(tu|toi|ton|ta|tes|t'|te)\b/i;

describe("the target", () => {
  test("a member is addressed as user_<id>, with the data given", async () => {
    const result = await sendPushToUsers([42], "Titre", "Texte", { type: "new_message", conversation_id: 9 });
    expect(result.success).toBe(true);
    expect(sent).toHaveLength(1);
    expect(sent[0]?.url).toBe("https://onesignal.com/api/v1/notifications");
    expect(sent[0]?.authorization).toBe("Basic test-key");
    expect(sent[0]?.body.include_external_user_ids).toEqual(["user_42"]);
    expect(sent[0]?.body.data).toEqual({ type: "new_message", conversation_id: 9 });
    expect(sent[0]?.body).not.toHaveProperty("collapse_id");
  });

  test("notifications of one conversation replace each other through collapse_id", async () => {
    await sendPushNotification({ userIds: ["user_42"], title: "Titre", message: "Texte", collapseId: "conv-9" });
    expect(sent[0]?.body.collapse_id).toBe("conv-9");
  });

  test("nothing is sent, nor any request made, without ONESIGNAL_REST_API_KEY", async () => {
    delete process.env.ONESIGNAL_REST_API_KEY;
    const result = await sendPushToUsers([42], "Titre", "Texte");
    expect(result.success).toBe(false);
    expect(sent).toHaveLength(0);
  });

  test("a test server can stand in for OneSignal, a production one cannot", async () => {
    process.env.ONESIGNAL_API_BASE = "http://127.0.0.1:9/api/v1/";
    await sendPushToUsers([1], "Titre", "Texte");
    expect(sent[0]?.url).toBe("http://127.0.0.1:9/api/v1/notifications");
    sent = [];
    const production = process.env.NODE_ENV;
    process.env.NODE_ENV = "production";
    try {
      expect((await sendPushToUsers([1], "Titre", "Texte")).success).toBe(false);
      expect(sent).toHaveLength(0);
    } finally {
      if (production === undefined) delete process.env.NODE_ENV;
      else process.env.NODE_ENV = production;
    }
  });
});

describe("the wording of the templates", () => {
  test("vouvoiement and no emoji, and the daily question carries no couple id", async () => {
    await sendEventReminder([1], "Shabbat chez Rachel", 12);
    await sendDailyQuestionNotification([1]);
    await sendMilestoneNotification([1], "un an ensemble");
    expect(sent).toHaveLength(3);
    for (const { body } of sent) {
      const texts = [(body.headings as { fr: string }).fr, (body.contents as { fr: string }).fr];
      for (const text of texts) {
        expect(text).not.toMatch(EMOJI);
        expect(text).not.toMatch(TUTOIEMENT);
      }
    }
    expect(sent[1]?.body.data).toEqual({ type: "couple_question" });
  });
});
