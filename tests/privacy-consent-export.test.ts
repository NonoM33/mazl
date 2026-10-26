import { describe, expect, test } from "bun:test";
import { BASE_URL, auth, db, json, makeUser } from "./media-helpers";
import { makeMatch, send } from "./chat-helpers";

// Integration: consent (art. 9) and export (art. 15/20) against a real server and Postgres.
// Needs TEST_API_URL and TEST_DATABASE_URL.

interface ProfileRow { denomination: string | null; kashrut_level: string | null; shabbat_observance: string | null }

const fetchConsents = (token: string) => fetch(`${BASE_URL}/api/privacy/consents`, { headers: auth(token) });
const putConsent = (token: string, body: Record<string, unknown>) =>
  fetch(`${BASE_URL}/api/privacy/consents/religious_data`, { method: "PUT", headers: json(token), body: JSON.stringify(body) });

async function profileRow(userId: number): Promise<ProfileRow> {
  const rows = await db<ProfileRow[]>`SELECT denomination, kashrut_level, shabbat_observance FROM profiles WHERE user_id = ${userId}`;
  const row = rows[0];
  if (row === undefined) throw new Error("no profile row");
  return row;
}

function keysOf(value: unknown, into: string[] = []): string[] {
  if (Array.isArray(value)) value.forEach((entry) => keysOf(entry, into));
  else if (value !== null && typeof value === "object") {
    for (const [key, inner] of Object.entries(value)) {
      into.push(key);
      keysOf(inner, into);
    }
  }
  return into;
}

describe("religious data consent", () => {
  test("never asked: granted is null, with the current version and text", async () => {
    const member = await makeUser("consent-fresh");
    const body = (await (await fetchConsents(member.token)).json()) as {
      success: boolean;
      consents: { religious_data: { granted: boolean | null; version: string | null; current_version: string; text: string } };
    };
    expect(body.success).toBe(true);
    expect(body.consents.religious_data.granted).toBeNull();
    expect(body.consents.religious_data.current_version).toBe("2026-10-24");
    expect(body.consents.religious_data.text.length).toBeGreaterThan(50);
  });

  test("requires authentication", async () => {
    expect((await fetch(`${BASE_URL}/api/privacy/consents`)).status).toBe(401);
  });

  test("granted then withdrawn: the three profile fields are cleared, the history keeps both decisions", async () => {
    const member = await makeUser("consent-withdraw");
    // Given first: without it the profile route keeps no religious data (M4).
    expect((await putConsent(member.token, { granted: true, version: "2026-10-24", source: "web" })).status).toBe(200);
    const saved = await fetch(`${BASE_URL}/api/profile`, {
      method: "PUT",
      headers: json(member.token),
      body: JSON.stringify({ displayName: "Jeanne Exemple", denomination: "Massorti", kashrutLevel: "Kasher", shabbatObservance: "Strict" }),
    });
    expect(saved.status).toBe(200);
    expect((await profileRow(member.id)).denomination).toBe("Massorti");

    const granted = await putConsent(member.token, { granted: true, version: "2026-10-24", source: "web" });
    expect(granted.status).toBe(200);
    expect(((await granted.json()) as { consent: { granted: boolean } }).consent.granted).toBe(true);
    expect((await profileRow(member.id)).denomination).toBe("Massorti");

    const withdrawn = await putConsent(member.token, { granted: false, version: "2026-10-24", source: "app" });
    expect(withdrawn.status).toBe(200);
    expect(await profileRow(member.id)).toEqual({ denomination: null, kashrut_level: null, shabbat_observance: null });

    const current = (await (await fetchConsents(member.token)).json()) as { consents: { religious_data: { granted: boolean } } };
    expect(current.consents.religious_data.granted).toBe(false);
    const events = await db<{ granted: boolean; source: string }[]>`
      SELECT granted, source FROM user_consent_events WHERE user_id = ${member.id} ORDER BY id
    `;
    expect(events.map((event) => [event.granted, event.source])).toEqual([[true, "web"], [true, "web"], [false, "app"]]);
  });

  test("an outdated version answers 409 consent_version_outdated and records nothing", async () => {
    const member = await makeUser("consent-old");
    const response = await putConsent(member.token, { granted: true, version: "2025-01-01", source: "web" });
    expect(response.status).toBe(409);
    expect(((await response.json()) as { error: string }).error).toBe("consent_version_outdated");
    const rows = await db`SELECT 1 FROM user_consents WHERE user_id = ${member.id}`;
    expect(rows).toHaveLength(0);
  });

  test("a malformed body answers 400", async () => {
    const member = await makeUser("consent-bad");
    expect((await putConsent(member.token, { granted: "yes", version: "2026-10-24", source: "web" })).status).toBe(400);
    expect((await putConsent(member.token, { granted: true, version: "2026-10-24", source: "tv" })).status).toBe(400);
  });
});

describe("analytics consent", () => {
  const putAnalytics = (token: string, body: Record<string, unknown>) =>
    fetch(`${BASE_URL}/api/privacy/consents/analytics`, { method: "PUT", headers: json(token), body: JSON.stringify(body) });

  test("is listed next to the religious one, never asked yet", async () => {
    const member = await makeUser("analytics-fresh");
    const body = (await (await fetchConsents(member.token)).json()) as {
      consents: { analytics: { granted: boolean | null; current_version: string; text: string } };
    };
    expect(body.consents.analytics.granted).toBeNull();
    expect(body.consents.analytics.current_version).toBe("2026-10-26");
    expect(body.consents.analytics.text).toContain("pseudonyme");
  });

  test("granted then withdrawn: recorded under its own purpose, the religious data untouched", async () => {
    const member = await makeUser("analytics-withdraw");
    expect((await putConsent(member.token, { granted: true, version: "2026-10-24", source: "web" })).status).toBe(200);
    await fetch(`${BASE_URL}/api/profile`, {
      method: "PUT",
      headers: json(member.token),
      body: JSON.stringify({ displayName: "Jeanne Exemple", denomination: "Massorti" }),
    });
    expect((await putAnalytics(member.token, { granted: true, version: "2026-10-26", source: "app" })).status).toBe(200);
    expect((await putAnalytics(member.token, { granted: false, version: "2026-10-26", source: "app" })).status).toBe(200);

    expect((await profileRow(member.id)).denomination).toBe("Massorti");
    const current = (await (await fetchConsents(member.token)).json()) as {
      consents: { analytics: { granted: boolean }; religious_data: { granted: boolean } };
    };
    expect(current.consents.analytics.granted).toBe(false);
    expect(current.consents.religious_data.granted).toBe(true);
    const events = await db<{ granted: boolean }[]>`
      SELECT granted FROM user_consent_events WHERE user_id = ${member.id} AND purpose = 'analytics' ORDER BY id
    `;
    expect(events.map((event) => event.granted)).toEqual([true, false]);
  });

  test("the religious version is refused for the analytics consent (409, current version given)", async () => {
    const member = await makeUser("analytics-old");
    const response = await putAnalytics(member.token, { granted: true, version: "2026-10-24", source: "app" });
    expect(response.status).toBe(409);
    expect(await response.json()).toEqual({ success: false, error: "consent_version_outdated", current_version: "2026-10-26" });
  });

  test("an unknown purpose answers 404 and records nothing", async () => {
    const member = await makeUser("analytics-unknown");
    const response = await fetch(`${BASE_URL}/api/privacy/consents/marketing`, {
      method: "PUT",
      headers: json(member.token),
      body: JSON.stringify({ granted: true, version: "2026-10-26", source: "app" }),
    });
    expect(response.status).toBe(404);
    expect(await db`SELECT 1 FROM user_consents WHERE user_id = ${member.id}`).toHaveLength(0);
  });
});

describe("personal data export", () => {
  test("contains the message SENT and not the message RECEIVED, with no secret key", async () => {
    const { a, b, conversationId } = await makeMatch("export");
    const sent = await send(a.token, conversationId, { client_id: crypto.randomUUID(), type: "text", content: "message-envoye-par-a" });
    const received = await send(b.token, conversationId, { client_id: crypto.randomUUID(), type: "text", content: "message-recu-de-b" });
    expect(sent.status).toBe(200);
    expect(received.status).toBe(200);

    const response = await fetch(`${BASE_URL}/api/users/me/export`, { headers: auth(a.token) });
    expect(response.status).toBe(200);
    const disposition = response.headers.get("content-disposition") ?? "";
    expect(disposition).toMatch(new RegExp(`^attachment; filename="mazl-export-${a.id}-\\d{4}-\\d{2}-\\d{2}\\.json"$`));
    expect(response.headers.get("cache-control")).toBe("no-store");

    const text = await response.text();
    expect(text).toContain("message-envoye-par-a");
    expect(text).not.toContain("message-recu-de-b");

    const document = JSON.parse(text) as { format: string; version: number; account: { id: number }; matches: Array<{ other_user_id: number }>; messages_sent: unknown[] };
    expect(document.format).toBe("mazl-export");
    expect(document.version).toBe(1);
    expect(document.account.id).toBe(a.id);
    expect(document.matches.map((match) => match.other_user_id)).toEqual([b.id]);
    expect(document.messages_sent).toHaveLength(1);
    expect(keysOf(document).filter((key) => /token|hash|secret|provider_id/i.test(key))).toEqual([]);
  });

  test("web sessions and withdrawal waivers are exported, never the session token hash", async () => {
    const member = await makeUser("export-optional");
    const sessionId = crypto.randomUUID();
    await db`
      INSERT INTO web_sessions (id, token_hash, user_id, browser_label, method, idle_expires_at, expires_at)
      VALUES (${sessionId}, ${`test-${sessionId}`}, ${member.id}, 'Firefox sur macOS', 'qr', NOW() + INTERVAL '4 hours', NOW() + INTERVAL '7 days')`;
    await db`
      INSERT INTO billing_withdrawal_waivers (user_id, offer, text_version, text_sha256)
      VALUES (${member.id}, 'plus_3m', '2026-10-24', ${"0".repeat(64)})`;
    const document = (await (await fetch(`${BASE_URL}/api/users/me/export`, { headers: auth(member.token) })).json()) as {
      web_sessions: Array<Record<string, unknown>>;
      withdrawal_waivers: Array<Record<string, unknown>>;
    };
    expect(document.web_sessions).toHaveLength(1);
    expect(document.web_sessions[0]?.browser_label).toBe("Firefox sur macOS");
    expect(Object.keys(document.web_sessions[0] ?? {})).not.toContain("token_hash");
    expect(JSON.stringify(document)).not.toContain(`test-${sessionId}`);
    expect(document.withdrawal_waivers).toHaveLength(1);
    expect(document.withdrawal_waivers[0]?.offer).toBe("plus_3m");
  });

  test("the 4th export of the day is refused with 429 rate_limited", async () => {
    const member = await makeUser("export-limit");
    for (let attempt = 0; attempt < 3; attempt += 1) {
      expect((await fetch(`${BASE_URL}/api/users/me/export`, { headers: auth(member.token) })).status).toBe(200);
    }
    const fourth = await fetch(`${BASE_URL}/api/users/me/export`, { headers: auth(member.token) });
    expect(fourth.status).toBe(429);
    expect(((await fourth.json()) as { error: string }).error).toBe("rate_limited");
  });

  test("the route takes no member id: another member's export is only ever their own", async () => {
    const first = await makeUser("export-own-a");
    const second = await makeUser("export-own-b");
    const response = await fetch(`${BASE_URL}/api/users/${second.id}/export`, { headers: auth(first.token) });
    expect(response.status).toBe(404);
    const own = (await (await fetch(`${BASE_URL}/api/users/me/export`, { headers: auth(first.token) })).json()) as { account: { id: number } };
    expect(own.account.id).toBe(first.id);
  });

  test("requires authentication", async () => {
    expect((await fetch(`${BASE_URL}/api/users/me/export`)).status).toBe(401);
  });
});

describe("the profile keeps no religious data without consent (security review M4)", () => {
  const putProfile = (token: string, body: Record<string, string>) =>
    fetch(`${BASE_URL}/api/profile`, { method: "PUT", headers: { ...auth(token), "Content-Type": "application/json" }, body: JSON.stringify(body) });
  const practiceOf = async (id: number) =>
    (await db<{ denomination: string | null; kashrut_level: string | null }[]>`SELECT denomination, kashrut_level FROM profiles WHERE user_id = ${id}`)[0];

  test("never asked: the fields are ignored, the update itself succeeds", async () => {
    const member = await makeUser("m4-never");
    const res = await putProfile(member.token, { bio: "Bonjour", denomination: "Massorti", kashrutLevel: "Strict" });
    expect(res.status).toBe(200);
    expect(await practiceOf(member.id)).toEqual({ denomination: null, kashrut_level: null });
    expect((await db<{ bio: string }[]>`SELECT bio FROM profiles WHERE user_id = ${member.id}`)[0]?.bio).toBe("Bonjour");
  });

  test("granted: stored; withdrawn: erased and no longer accepted", async () => {
    const member = await makeUser("m4-granted");
    const decide = (granted: boolean) =>
      fetch(`${BASE_URL}/api/privacy/consents/religious_data`, { method: "PUT", headers: { ...auth(member.token), "Content-Type": "application/json" }, body: JSON.stringify({ granted, version: "2026-10-24", source: "app" }) });
    expect((await decide(true)).status).toBe(200);
    await putProfile(member.token, { denomination: "Massorti", kashrutLevel: "Strict" });
    expect(await practiceOf(member.id)).toEqual({ denomination: "Massorti", kashrut_level: "Strict" });
    expect((await decide(false)).status).toBe(200);
    await putProfile(member.token, { denomination: "Orthodox" });
    expect(await practiceOf(member.id)).toEqual({ denomination: null, kashrut_level: null });
  });
});
