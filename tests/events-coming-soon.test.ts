import { afterAll, beforeAll, describe, expect, test } from "bun:test";
import { BASE_URL, auth, db, json, makeUser, type TestUser } from "./media-helpers";

// "Coming soon" events (the fake events of the TestFlight phase): shown, every
// registration refused with a clear code, « Me prévenir » recorded, and the
// administrator's opening that lets registrations in. Needs a running server
// (TEST_API_URL) and its database (TEST_DATABASE_URL). No push provider in the
// test server: the alerts of an opened event stay pending.

const ADMIN_EMAIL = process.env.ADMIN_EMAIL || "admin@example.com";
const ADMIN_PASSWORD = process.env.ADMIN_PASSWORD || "dev-admin-pass";
let adminToken = "";
const created: number[] = [];

beforeAll(async () => {
  const res = await fetch(`${BASE_URL}/api/admin/login`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ email: ADMIN_EMAIL, password: ADMIN_PASSWORD }),
  });
  adminToken = ((await res.json()) as { token?: string }).token ?? "";
  if (!adminToken) throw new Error("admin login failed: check ADMIN_EMAIL / ADMIN_PASSWORD");
});

afterAll(async () => {
  if (created.length > 0) await db`DELETE FROM events WHERE id IN ${db(created)}`;
});

async function makeEvent(fields: { availability?: "open" | "coming_soon"; published?: boolean } = {}): Promise<number> {
  const [row] = await db<{ id: number }[]>`
    INSERT INTO events (title, date, is_published, availability, fixture_key)
    VALUES ('Dîner de Shabbat test', CURRENT_DATE + 10, ${fields.published ?? true}, ${fields.availability ?? "coming_soon"},
            ${`it-${Date.now()}-${Math.random().toString(36).slice(2)}`})
    RETURNING id`;
  if (!row) throw new Error("event not created");
  created.push(row.id);
  return row.id;
}

const rsvp = (user: TestUser, eventId: number) =>
  fetch(`${BASE_URL}/api/events/${eventId}/rsvp`, { method: "POST", headers: json(user.token), body: JSON.stringify({ status: "going" }) });
const notify = (user: TestUser, eventId: number | string, method: "POST" | "DELETE" = "POST") =>
  fetch(`${BASE_URL}/api/events/${eventId}/notify`, { method, headers: auth(user.token) });
const openEvent = (eventId: number | string, token = adminToken) =>
  fetch(`${BASE_URL}/api/admin/events/${eventId}/open`, { method: "POST", headers: { Authorization: `Bearer ${token}` } });
const detail = async (eventId: number, user?: TestUser) =>
  (await (await fetch(`${BASE_URL}/api/events/${eventId}`, user ? { headers: auth(user.token) } : {})).json()) as { event: Record<string, unknown> };
const count = async (query: Promise<{ n: string }[]>): Promise<number> => Number((await query)[0]?.n);

describe("a coming soon event", () => {
  test("is listed and served with its availability, without its fixture key", async () => {
    const event = await makeEvent();
    const body = await detail(event);
    expect(body.event.availability).toBe("coming_soon");
    expect(body.event.notify_requested).toBe(false);
    expect("fixture_key" in body.event).toBe(false);
    const listed = (await (await fetch(`${BASE_URL}/api/events?limit=50`)).json()) as { events: Array<Record<string, unknown>> };
    expect(listed.events.some((e) => "fixture_key" in e)).toBe(false);
    expect(listed.events.find((e) => e.id === event)?.availability).toBe("coming_soon");
  });

  test("refuses every registration with 409 event_coming_soon, and records none", async () => {
    const event = await makeEvent();
    const user = await makeUser("soon-rsvp");
    const res = await rsvp(user, event);
    expect(res.status).toBe(409);
    expect(await res.json()).toEqual({ success: false, error: "Registrations for this event are not open yet", code: "event_coming_soon" });
    expect(await count(db`SELECT COUNT(*)::text AS n FROM event_rsvps WHERE event_id = ${event}`)).toBe(0);
  });
});

describe("« Me prévenir »", () => {
  test("needs a member", async () => {
    const event = await makeEvent();
    expect((await fetch(`${BASE_URL}/api/events/${event}/notify`, { method: "POST" })).status).toBe(401);
  });

  test("is recorded once, shown on the event for that member only, and withdrawn", async () => {
    const event = await makeEvent();
    const [member, other] = [await makeUser("soon-alert"), await makeUser("soon-other")];
    for (let i = 0; i < 2; i++) {
      const res = await notify(member, event);
      expect(res.status).toBe(200);
      expect(await res.json()).toEqual({ success: true, notifyRequested: true });
    }
    expect(await count(db`SELECT COUNT(*)::text AS n FROM event_open_alerts WHERE event_id = ${event}`)).toBe(1);
    expect((await detail(event, member)).event.notify_requested).toBe(true);
    expect((await detail(event, other)).event.notify_requested).toBe(false);
    expect((await detail(event)).event.notify_requested).toBe(false);

    const withdrawn = await notify(member, event, "DELETE");
    expect(await withdrawn.json()).toEqual({ success: true, notifyRequested: false });
    expect((await detail(event, member)).event.notify_requested).toBe(false);
  });

  test("is refused on an open event (409), a draft and an unknown event (404), a bad id (400)", async () => {
    const [open, draft] = [await makeEvent({ availability: "open" }), await makeEvent({ published: false })];
    const member = await makeUser("soon-refused");
    const onOpen = await notify(member, open);
    expect(onOpen.status).toBe(409);
    expect(((await onOpen.json()) as { code: string }).code).toBe("event_already_open");
    expect((await notify(member, draft)).status).toBe(404);
    expect((await notify(member, 2_000_000_000)).status).toBe(404);
    expect((await notify(member, "abc")).status).toBe(400);
    expect(await count(db`SELECT COUNT(*)::text AS n FROM event_open_alerts WHERE event_id IN (${open}, ${draft})`)).toBe(0);
  });
});

describe("opening an event", () => {
  test("is for administrators only", async () => {
    const event = await makeEvent();
    const member = await makeUser("soon-not-admin");
    expect((await openEvent(event, member.token)).status).toBe(401);
    expect((await fetch(`${BASE_URL}/api/admin/events/${event}/open`, { method: "POST" })).status).toBe(401);
    expect((await detail(event)).event.availability).toBe("coming_soon");
  });

  test("lets registrations in; the alerts wait for a push provider", async () => {
    const event = await makeEvent();
    const [member, other] = [await makeUser("soon-open"), await makeUser("soon-open-2")];
    await notify(member, event);
    await notify(other, event);

    const res = await openEvent(event);
    expect(res.status).toBe(200);
    expect(await res.json()).toEqual({ success: true, status: "opened", notified: 0, pending: 2 });
    expect((await detail(event)).event.availability).toBe("open");
    expect((await rsvp(member, event)).status).toBe(200);
    expect((await detail(event, member)).event.user_rsvp_status).toBe("going");

    const again = await openEvent(event);
    expect(await again.json()).toEqual({ success: true, status: "already_open", notified: 0, pending: 2 });
    expect(await count(db`SELECT COUNT(*)::text AS n FROM event_open_alerts WHERE event_id = ${event} AND notified_at IS NULL`)).toBe(2);
  });

  test("answers 404 for an unknown event", async () => {
    expect((await openEvent(2_000_000_000)).status).toBe(404);
    expect((await openEvent("abc")).status).toBe(404);
  });
});
