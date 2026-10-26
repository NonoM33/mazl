import { describe, expect, test } from "bun:test";
import { HmacPseudonymizer } from "../src/features/analytics/infra/hmac-pseudonymizer";
import { BASE_URL, json, makeUser, type TestUser } from "./media-helpers";
import { sendText } from "./chat-helpers";

// Integration: consent, relay and server events against the real server, a
// throwaway Postgres and the fake OpenPanel of scripts/test-integration.ts.
// Needs TEST_API_URL, TEST_DATABASE_URL, FAKE_OPENPANEL_URL and ANALYTICS_ID_KEY.

interface Tracked {
  readonly headers: Record<string, string>;
  readonly body: { type: string; payload: { name: string; profileId: string; properties: Record<string, unknown> } };
}

const OPENPANEL = process.env.FAKE_OPENPANEL_URL ?? "";
const pseudonyms = new HmacPseudonymizer(process.env.ANALYTICS_ID_KEY ?? "");

async function trackedFor(user: TestUser): Promise<Tracked[]> {
  const all = (await (await fetch(`${OPENPANEL}/__test/requests`)).json()) as Tracked[];
  return all.filter((entry) => entry.body.payload.profileId === pseudonyms.profileIdOf(user.id));
}

// Delivery is fire and forget: wait until the expected events have arrived.
async function waitForTracked(user: TestUser, count: number): Promise<Tracked[]> {
  for (let attempt = 0; attempt < 50; attempt += 1) {
    const tracked = await trackedFor(user);
    if (tracked.length >= count) return tracked;
    await Bun.sleep(100);
  }
  return await trackedFor(user);
}

const consent = (user: TestUser, granted: boolean): Promise<Response> =>
  fetch(`${BASE_URL}/api/privacy/consents/analytics`, {
    method: "PUT",
    headers: json(user.token),
    body: JSON.stringify({ granted, version: "2026-10-26", source: "app" }),
  });

const relay = async (user: TestUser, events: unknown[]): Promise<{ status: number; accepted: number }> => {
  const response = await fetch(`${BASE_URL}/api/analytics/events`, {
    method: "POST",
    headers: json(user.token),
    body: JSON.stringify({ platform: "ios", app_version: "1.0.0+1", events }),
  });
  const body = (await response.json()) as { accepted: number };
  return { status: response.status, accepted: body.accepted };
};

const swipe = (user: TestUser, target: TestUser): Promise<Response> =>
  fetch(`${BASE_URL}/api/swipes`, { method: "POST", headers: json(user.token), body: JSON.stringify({ target_user_id: target.id, action: "like" }) });

describe("analytics relay", () => {
  test("never asked: nothing reaches OpenPanel", async () => {
    const member = await makeUser("analytics-none");
    expect(await relay(member, [{ name: "app_opened" }])).toEqual({ status: 202, accepted: 0 });
    await Bun.sleep(300);
    expect(await trackedFor(member)).toEqual([]);
  });

  test("granted: the screen reaches OpenPanel under a pseudonym, with no IP and nothing personal", async () => {
    const member = await makeUser("analytics-yes");
    expect((await consent(member, true)).status).toBe(200);
    const result = await relay(member, [
      { name: "screen_viewed", properties: { screen: "discover", email: "jeanne@example.com" } },
      { name: "religion_selected", properties: { denomination: "massorti" } },
    ]);
    expect(result).toEqual({ status: 202, accepted: 1 });

    const [tracked] = await waitForTracked(member, 1);
    expect(tracked?.headers["openpanel-client-id"]).toBe("it-client");
    expect(tracked?.body.payload.name).toBe("screen_view");
    expect(tracked?.body.payload.properties).toMatchObject({ screen: "discover", __path: "/discover", __ip: "127.0.0.1", platform: "ios", env: "test" });
    const sent = JSON.stringify(await trackedFor(member));
    expect(sent).not.toContain("jeanne@example.com");
    expect(sent).not.toContain("massorti");
    expect(sent).not.toContain(`"${member.id}"`);
  });

  test("withdrawn: the very next batch is dropped", async () => {
    const member = await makeUser("analytics-withdraw");
    await consent(member, true);
    expect((await relay(member, [{ name: "app_opened" }])).accepted).toBe(1);
    await waitForTracked(member, 1);
    expect((await consent(member, false)).status).toBe(200);
    expect((await relay(member, [{ name: "app_opened" }])).accepted).toBe(0);
    await Bun.sleep(300);
    expect(await trackedFor(member)).toHaveLength(1);
  });
});

describe("server events", () => {
  test("a match and a message: counted for the consenting member only", async () => {
    const yes = await makeUser("analytics-match-yes");
    const no = await makeUser("analytics-match-no");
    await consent(yes, true);
    expect((await swipe(no, yes)).status).toBe(200);
    expect((await swipe(yes, no)).status).toBe(200);
    const conversations = (await (await fetch(`${BASE_URL}/api/conversations`, { headers: json(yes.token) })).json()) as {
      conversations: Array<{ id: number }>;
    };
    const conversationId = conversations.conversations[0]?.id;
    if (conversationId === undefined) throw new Error("no conversation");
    await sendText(yes.token, conversationId, "Shalom, texte jamais mesuré");

    const tracked = await waitForTracked(yes, 3);
    // Delivered asynchronously: OpenPanel orders them by their time, not by arrival.
    const seen = tracked.map((entry) => `${entry.body.payload.name}:${String(entry.body.payload.properties.action ?? entry.body.payload.properties.role ?? "")}`);
    expect(seen.sort()).toEqual(["match_created:initiator", "message_sent:", "swipe:like"]);
    expect(tracked.every((entry) => entry.headers["user-agent"] === "mazl-api/1.0")).toBe(true);
    expect(JSON.stringify(tracked)).not.toContain("Shalom");
    expect(await trackedFor(no)).toEqual([]);
  });
});
