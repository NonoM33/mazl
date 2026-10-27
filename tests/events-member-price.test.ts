import { beforeAll, describe, expect, test } from "bun:test";
import { BASE_URL, db } from "./media-helpers";

// docs/premium/MONETISATION.md section 10: the reduced rate of mazl+ members,
// set from the administration of the events and shown to everybody.
// Needs TEST_API_URL, TEST_DATABASE_URL and the admin credentials of the server.

const ADMIN_EMAIL = process.env.ADMIN_EMAIL || "admin@example.com";
const ADMIN_PASSWORD = process.env.ADMIN_PASSWORD || "dev-admin-pass";
let adminToken = "";
const admin = (): Record<string, string> => ({ Authorization: `Bearer ${adminToken}`, "Content-Type": "application/json" });

beforeAll(async () => {
  const res = await fetch(`${BASE_URL}/api/admin/login`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ email: ADMIN_EMAIL, password: ADMIN_PASSWORD }),
  });
  adminToken = ((await res.json()) as { token?: string }).token ?? "";
  if (!adminToken) throw new Error("admin login failed: check ADMIN_EMAIL / ADMIN_PASSWORD");
});

interface EventBody { id: number; price: string; member_price_cents: number | null }
const createEvent = (extra: Record<string, unknown>) =>
  fetch(`${BASE_URL}/api/admin/events`, {
    method: "POST",
    headers: admin(),
    body: JSON.stringify({ title: "Shabbat Exemple", date: "2031-01-01", price: 12.5, currency: "EUR", isPublished: true, ...extra }),
  });
const updateEvent = (id: number, extra: Record<string, unknown>) =>
  fetch(`${BASE_URL}/api/admin/events/${id}`, { method: "PUT", headers: admin(), body: JSON.stringify(extra) });
const created = async (res: Response): Promise<EventBody> => ((await res.json()) as { event: EventBody }).event;

describe("member price of an event", () => {
  test("is set with the event, shown on the public list and detail, in cents", async () => {
    const event = await created(await createEvent({ memberPriceCents: 800 }));
    expect(event.member_price_cents).toBe(800);
    const detail = (await (await fetch(`${BASE_URL}/api/events/${event.id}`)).json()) as { event: EventBody };
    expect([detail.event.price, detail.event.member_price_cents]).toEqual(["12.50", 800]);
    const list = (await (await fetch(`${BASE_URL}/api/events?from=2030-12-01&limit=50`)).json()) as { events: EventBody[] };
    expect(list.events.find((e) => e.id === event.id)?.member_price_cents).toBe(800);
  });

  test("an event without one says null", async () => {
    const event = await created(await createEvent({}));
    expect(event.member_price_cents).toBeNull();
  });

  test("a rate above the price, a decimal, a negative or a text is refused: 400 member_price_invalid", async () => {
    for (const memberPriceCents of [1251, 8.5, -1, "800", 10_000_001]) {
      const res = await createEvent({ memberPriceCents });
      expect([JSON.stringify(memberPriceCents), res.status, ((await res.json()) as { error: string }).error]).toEqual([JSON.stringify(memberPriceCents), 400, "member_price_invalid"]);
    }
  });

  test("an update changes it, null removes it, leaving it out keeps it, and the price it is checked against is the new one", async () => {
    const event = await created(await createEvent({ memberPriceCents: 800 }));
    expect((await created(await updateEvent(event.id, { title: "Autre titre" }))).member_price_cents).toBe(800);
    expect((await created(await updateEvent(event.id, { memberPriceCents: 500 }))).member_price_cents).toBe(500);
    const tooHigh = await updateEvent(event.id, { memberPriceCents: 1300 });
    expect(tooHigh.status).toBe(400);
    expect((await created(await updateEvent(event.id, { price: 20, memberPriceCents: 1300 }))).member_price_cents).toBe(1300);
    expect((await created(await updateEvent(event.id, { memberPriceCents: null }))).member_price_cents).toBeNull();
    expect((await updateEvent(2_000_000_000, { memberPriceCents: 100 })).status).toBe(404);
  });

  test("the administration needs an administrator", async () => {
    const res = await fetch(`${BASE_URL}/api/admin/events`, { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ title: "x", date: "2031-01-01", memberPriceCents: 1 }) });
    expect(res.status).toBe(401);
    const rows = await db`SELECT 1 FROM events WHERE title = 'x' AND date = '2031-01-01'`;
    expect(rows.length).toBe(0);
  });

  test("a duplicate keeps the rate", async () => {
    const event = await created(await createEvent({ memberPriceCents: 800 }));
    const res = await fetch(`${BASE_URL}/api/admin/events/${event.id}/duplicate`, { method: "POST", headers: admin() });
    const copy = ((await res.json()) as { event: EventBody }).event;
    expect(copy.member_price_cents).toBe(800);
  });
});
