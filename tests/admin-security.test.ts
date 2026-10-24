import { beforeAll, describe, expect, test } from "bun:test";
import { BASE_URL, db } from "./media-helpers";
import { THROWAWAY_CREDENTIAL } from "./throwaway-credential";

// Integration tests of the admin back-office security fixes (CSV export,
// campaigns, pagination). Needs a running server (TEST_API_URL) started with the
// non-production dev endpoints, ADMIN_EMAIL / ADMIN_PASSWORD matching the server,
// and TEST_DATABASE_URL pointing at the server's database. No e-mail or push is
// ever sent: the server must run WITHOUT RESEND_API_KEY / ONESIGNAL_REST_API_KEY.
const ADMIN_EMAIL = process.env.ADMIN_EMAIL || "admin@example.com";
const ADMIN_PASSWORD = process.env.ADMIN_PASSWORD || "dev-admin-pass";

let adminToken = "";

const admin = (): Record<string, string> => ({
  Authorization: `Bearer ${adminToken}`,
  "Content-Type": "application/json",
});

beforeAll(async () => {
  if (process.env.RESEND_API_KEY || process.env.ONESIGNAL_REST_API_KEY) {
    throw new Error("refusing to run: real e-mail/push keys are set, these tests would contact members");
  }
  const res = await fetch(`${BASE_URL}/api/admin/login`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ email: ADMIN_EMAIL, password: ADMIN_PASSWORD }),
  });
  adminToken = ((await res.json()) as { token?: string }).token ?? "";
  if (!adminToken) throw new Error("admin login failed: check ADMIN_EMAIL / ADMIN_PASSWORD");
});

async function makeNamedUser(name: string, label: string): Promise<{ id: number; email: string }> {
  const email = `adminsec-${label}-${Date.now()}-${Math.floor(performance.now() * 1000)}@example.com`;
  const res = await fetch(`${BASE_URL}/api/dev/test-user`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ email, password: THROWAWAY_CREDENTIAL, name }),
  });
  const data = (await res.json()) as { success: boolean; user?: { id: number } };
  if (!data.success || !data.user) throw new Error(`makeNamedUser failed: ${JSON.stringify(data)}`);
  return { id: data.user.id, email };
}

// Minimal RFC 4180 reader written from the spec, independent of the server code.
function parseCsv(text: string): string[][] {
  const rows: string[][] = [];
  let row: string[] = [];
  let cell = "";
  let quoted = false;
  for (let i = 0; i < text.length; i++) {
    const ch = text[i]!;
    if (quoted) {
      if (ch === '"' && text[i + 1] === '"') { cell += '"'; i++; }
      else if (ch === '"') quoted = false;
      else cell += ch;
    } else if (ch === '"') quoted = true;
    else if (ch === ",") { row.push(cell); cell = ""; }
    else if (ch === "\n") { row.push(cell); rows.push(row); row = []; cell = ""; }
    else cell += ch;
  }
  row.push(cell);
  rows.push(row);
  return rows;
}

describe("event attendee CSV export: formula injection", () => {
  const hostileNames = [
    '=HYPERLINK("http://evil.example/","x")',
    "+33123456789",
    "-2+3",
    "@SUM(A1:A2)",
    "\t=1+1",
    "\r=1+1",
  ];

  test("a member named like a formula cannot make a spreadsheet run it", async () => {
    const create = await fetch(`${BASE_URL}/api/admin/events`, {
      method: "POST",
      headers: admin(),
      body: JSON.stringify({ title: "Shabbat Exemple", date: "2031-01-01" }),
    });
    const eventId = ((await create.json()) as { event: { id: number } }).event.id;

    for (const [i, name] of hostileNames.entries()) {
      const user = await makeNamedUser(name, `csv${i}`);
      await db`INSERT INTO event_rsvps (event_id, user_id, status) VALUES (${eventId}, ${user.id}, 'going')`;
    }

    const res = await fetch(`${BASE_URL}/api/admin/events/${eventId}/export`, { headers: admin() });
    expect(res.status).toBe(200);
    const rows = parseCsv(await res.text());
    const header = rows[0]!;
    const nameCol = header.indexOf("name");
    const dataRows = rows.slice(1).filter((r) => r.length > 1);
    expect(dataRows.length).toBe(hostileNames.length);

    // What a spreadsheet would execute: any cell that still begins with a formula trigger.
    for (const r of dataRows) {
      for (const value of r) expect(value).not.toMatch(/^[=+\-@\t\r]/);
    }
    // And the real text is still there, only prefixed with a quote.
    const names = dataRows.map((r) => r[nameCol]);
    for (const hostile of hostileNames) expect(names).toContain(`'${hostile}`);
  });
});

interface CampaignRow { id: number; status: string; stats_sent: number; type: string; segment_id: number | null }

async function createCampaign(extra: Record<string, unknown> = {}): Promise<number> {
  const res = await fetch(`${BASE_URL}/api/admin/campaigns`, {
    method: "POST",
    headers: admin(),
    body: JSON.stringify({ type: "email", title: "Newsletter Exemple", subject: "Bonjour", content: "<p>Shalom</p>", ...extra }),
  });
  const body = (await res.json()) as { campaign?: CampaignRow };
  if (res.status !== 200 || !body.campaign) throw new Error(`createCampaign failed ${res.status}: ${JSON.stringify(body)}`);
  return body.campaign.id;
}

const sendCampaign = (id: number | string): Promise<Response> =>
  fetch(`${BASE_URL}/api/admin/campaigns/${id}/send`, { method: "POST", headers: admin() });

const putCampaign = (id: number, body: Record<string, unknown>): Promise<Response> =>
  fetch(`${BASE_URL}/api/admin/campaigns/${id}`, { method: "PUT", headers: admin(), body: JSON.stringify(body) });

async function campaignInDb(id: number): Promise<CampaignRow> {
  const rows = await db<CampaignRow[]>`SELECT id, status, stats_sent, type, segment_id FROM campaigns WHERE id = ${id}`;
  return rows[0]!;
}

async function recipientCount(campaignId: number, onlyDelivered = false): Promise<number> {
  const rows = await db<{ n: number }[]>`
    SELECT COUNT(*)::int AS n FROM campaign_recipients
    WHERE campaign_id = ${campaignId} AND (${!onlyDelivered} OR sent_at IS NOT NULL)`;
  return rows[0]!.n;
}

describe("campaigns: sending", () => {
  test("two simultaneous /send: only one goes out and every recipient is written once", async () => {
    await makeNamedUser("Jeanne Exemple", "camp-a");
    await makeNamedUser("Samuel Exemple", "camp-b");
    const id = await createCampaign();

    const responses = await Promise.all([sendCampaign(id), sendCampaign(id), sendCampaign(id)]);
    const statuses = responses.map((r) => r.status).sort();
    expect(statuses).toEqual([200, 409, 409]);

    const duplicates = await db`
      SELECT user_id, COUNT(*)::int AS n FROM campaign_recipients
      WHERE campaign_id = ${id} GROUP BY user_id HAVING COUNT(*) > 1`;
    expect(duplicates.length).toBe(0);
    expect(await recipientCount(id)).toBeGreaterThan(0);
  });

  test("a campaign that was already sent cannot be sent again", async () => {
    const id = await createCampaign();
    expect((await sendCampaign(id)).status).toBe(200);
    expect((await sendCampaign(id)).status).toBe(409);
  });

  test.each(["email", "push"])("%s campaign without provider keys: nothing counted as sent", async (type) => {
    await makeNamedUser("Ruth Exemple", `camp-${type}`);
    const id = await createCampaign({ type });
    const res = await sendCampaign(id);
    expect(res.status).toBe(200);
    const body = (await res.json()) as { sent: number; errors: number; total: number };
    expect(body.total).toBeGreaterThan(0);
    expect(body.sent).toBe(0);
    expect(body.errors).toBe(body.total);

    const row = await campaignInDb(id);
    expect(row.stats_sent).toBe(0);
    expect(row.status).toBe("failed");
    expect(await recipientCount(id, true)).toBe(0);
    expect(await recipientCount(id)).toBeGreaterThan(0);
  });

  test("a campaign tied to a segment is refused instead of going to every member", async () => {
    await makeNamedUser("David Exemple", "camp-seg");
    const segRes = await fetch(`${BASE_URL}/api/admin/segments`, {
      method: "POST",
      headers: admin(),
      body: JSON.stringify({ name: "Paris 25-30", filters: { city: "Paris", ageMin: 25, ageMax: 30 } }),
    });
    const segmentId = ((await segRes.json()) as { segment: { id: number } }).segment.id;
    const id = await createCampaign({ segmentId });

    const res = await sendCampaign(id);
    expect(res.status).toBe(409);
    const body = (await res.json()) as { success: boolean; error: string };
    expect(body.success).toBe(false);
    expect(body.error).toMatch(/segment/i);

    expect((await campaignInDb(id)).status).toBe("draft");
    expect(await recipientCount(id)).toBe(0);
  });

  test("an unknown or malformed id is a 404, never a 500", async () => {
    expect((await sendCampaign(999999999)).status).toBe(404);
    expect((await sendCampaign("abc")).status).toBe(404);
  });
});

describe("pagination bounds on the admin lists", () => {
  const lists = ["/api/admin/campaigns", "/api/admin/events"];

  test.each(lists)("%s survives garbage limit and offset (no 500)", async (path) => {
    for (const query of ["limit=abc", "limit=-1&offset=-5", "limit=1e9", "offset=abc", "limit=%00", "offset=99999999999999999999"]) {
      const res = await fetch(`${BASE_URL}${path}?${query}`, { headers: admin() });
      expect(res.status, `${path}?${query}`).toBe(200);
    }
  });

  test.each(lists)("%s never returns more than 100 rows", async (path) => {
    const res = await fetch(`${BASE_URL}${path}?limit=100000`, { headers: admin() });
    const body = (await res.json()) as Record<string, unknown[]>;
    const rows = body.campaigns ?? body.events ?? [];
    expect(rows.length).toBeLessThanOrEqual(100);
  });

  test("limit=1 returns a single row", async () => {
    await createCampaign();
    await createCampaign();
    const res = await fetch(`${BASE_URL}/api/admin/campaigns?limit=1`, { headers: admin() });
    const body = (await res.json()) as { campaigns: unknown[] };
    expect(body.campaigns.length).toBe(1);
  });

  test("a malformed event id is a 404, never a 500", async () => {
    for (const suffix of ["abc/export", "abc/duplicate", "abc"]) {
      const method = suffix.endsWith("duplicate") ? "POST" : suffix === "abc" ? "DELETE" : "GET";
      const res = await fetch(`${BASE_URL}/api/admin/events/${suffix}`, { method, headers: admin() });
      expect(res.status, `${method} ${suffix}`).toBe(404);
    }
  });
});

describe("campaigns: editing", () => {
  test("PUT cannot put a sent campaign back to draft", async () => {
    const id = await createCampaign();
    expect((await sendCampaign(id)).status).toBe(200);
    const after = (await campaignInDb(id)).status;
    expect(after).not.toBe("draft");

    const res = await putCampaign(id, { status: "draft" });
    expect(res.status).toBe(409);
    expect((await campaignInDb(id)).status).toBe(after);
  });

  test("PUT cannot edit the content of a campaign that was already sent", async () => {
    const id = await createCampaign();
    await sendCampaign(id);
    const res = await putCampaign(id, { title: "Titre piraté" });
    expect(res.status).toBe(409);
  });

  test("PUT cannot mark a draft as sent or sending, nor invent a status", async () => {
    const id = await createCampaign();
    for (const status of ["sent", "sending", "failed", "bogus"]) {
      expect((await putCampaign(id, { status })).status).toBe(400);
    }
    expect((await campaignInDb(id)).status).toBe("draft");
    expect((await putCampaign(id, { status: "scheduled" })).status).toBe(200);
    expect((await campaignInDb(id)).status).toBe("scheduled");
  });

  test("a campaign type outside email/push is refused at creation", async () => {
    const res = await fetch(`${BASE_URL}/api/admin/campaigns`, {
      method: "POST",
      headers: admin(),
      body: JSON.stringify({ type: "sms", title: "x", content: "y" }),
    });
    expect(res.status).toBe(400);
  });
});
