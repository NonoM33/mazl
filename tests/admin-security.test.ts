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
