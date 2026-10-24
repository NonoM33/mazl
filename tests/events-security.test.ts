import { afterAll, describe, expect, test } from "bun:test";
import { BASE_URL, auth, db, json, makeUser, type TestUser } from "./media-helpers";

// Attack scenarios against the public events routes. Needs a running server
// (TEST_API_URL) and its database (TEST_DATABASE_URL).

const created: number[] = [];

async function makeEvent(fields: { published?: boolean; daysFromNow?: number; max?: number | null; organizer?: number | null } = {}): Promise<number> {
  const [row] = await db<{ id: number }[]>`
    INSERT INTO events (title, date, is_published, max_attendees, address, organizer_id)
    VALUES ('Soirée sécurité', CURRENT_DATE + ${fields.daysFromNow ?? 7}::int, ${fields.published ?? true},
            ${fields.max ?? null}, '12 rue Exemple, Paris', ${fields.organizer ?? null})
    RETURNING id
  `;
  if (!row) throw new Error("event not created");
  created.push(row.id);
  return row.id;
}

afterAll(async () => {
  if (created.length > 0) await db`DELETE FROM events WHERE id IN ${db(created)}`;
});

const rsvp = (user: TestUser, eventId: number | string, body: unknown = { status: "going" }) =>
  fetch(`${BASE_URL}/api/events/${eventId}/rsvp`, { method: "POST", headers: json(user.token), body: JSON.stringify(body) });
const rsvpRows = async (eventId: number): Promise<number> => {
  const [row] = await db<{ n: string }[]>`SELECT COUNT(*) AS n FROM event_rsvps WHERE event_id = ${eventId}`;
  return Number(row?.n);
};

describe("a draft event does not exist for the public", () => {
  test("GET /api/events/:id is a 404 with and without a token", async () => {
    const draft = await makeEvent({ published: false });
    const user = await makeUser("ev-draft");
    expect((await fetch(`${BASE_URL}/api/events/${draft}`)).status).toBe(404);
    expect((await fetch(`${BASE_URL}/api/events/${draft}`, { headers: auth(user.token) })).status).toBe(404);
  });

  test("no RSVP can be placed on a draft", async () => {
    const draft = await makeEvent({ published: false });
    const user = await makeUser("ev-draft-rsvp");
    expect((await rsvp(user, draft)).status).toBe(404);
    expect(await rsvpRows(draft)).toBe(0);
  });

  test("a published event is served without the organiser's member id", async () => {
    const organizer = await makeUser("ev-organizer");
    const event = await makeEvent({ organizer: organizer.id });
    const res = await fetch(`${BASE_URL}/api/events/${event}`);
    expect(res.status).toBe(200);
    const body = (await res.json()) as { event: Record<string, unknown> };
    expect(body.event.title).toBe("Soirée sécurité");
    expect(body.event.address).toBe("12 rue Exemple, Paris");
    expect("organizer_id" in body.event).toBe(false);

    const listed = (await (await fetch(`${BASE_URL}/api/events`)).json()) as { events: Array<Record<string, unknown>> };
    expect(listed.events.length).toBeGreaterThan(0);
    expect(listed.events.some((e) => "organizer_id" in e)).toBe(false);
  });
});

describe("RSVP rules", () => {
  test("a past event refuses registrations, today's event accepts them", async () => {
    const past = await makeEvent({ daysFromNow: -2 });
    const today = await makeEvent({ daysFromNow: 0 });
    const user = await makeUser("ev-past");
    expect((await rsvp(user, past)).status).toBe(400);
    expect(await rsvpRows(past)).toBe(0);
    expect((await rsvp(user, today)).status).toBe(200);
  });

  test("eight simultaneous registrations on a 3-seat event seat exactly three", async () => {
    const event = await makeEvent({ max: 3 });
    const users = await Promise.all(Array.from({ length: 8 }, (_, i) => makeUser(`ev-race${i}`)));
    const results = await Promise.all(users.map((u) => rsvp(u, event)));
    expect(results.filter((r) => r.status === 200)).toHaveLength(3);
    expect(await rsvpRows(event)).toBe(3);
  });

  test("someone already registered can confirm again on a full event", async () => {
    const event = await makeEvent({ max: 1 });
    const [first, second] = await Promise.all([makeUser("ev-full1"), makeUser("ev-full2")]);
    expect((await rsvp(first!, event)).status).toBe(200);
    expect((await rsvp(second!, event)).status).toBe(400);
    expect((await rsvp(first!, event)).status).toBe(200);
  });

  test.each([["an unknown word", "hacked"], ["a huge string", "x".repeat(5000)], ["a number", 7]])(
    "a status that is %s is a 400 and stores nothing",
    async (_label, status) => {
      const event = await makeEvent();
      const user = await makeUser("ev-status");
      expect((await rsvp(user, event, { status })).status).toBe(400);
      expect(await rsvpRows(event)).toBe(0);
    },
  );

  test("a malformed event id is a 400, never a 500", async () => {
    const user = await makeUser("ev-badid");
    expect((await rsvp(user, "abc")).status).toBe(400);
    expect((await fetch(`${BASE_URL}/api/events/abc`)).status).toBe(400);
    const del = await fetch(`${BASE_URL}/api/events/abc/rsvp`, { method: "DELETE", headers: auth(user.token) });
    expect(del.status).toBe(400);
  });

  test("the app's own request still works, and cancelling it too", async () => {
    const event = await makeEvent({ max: 10 });
    const user = await makeUser("ev-ok");
    expect((await rsvp(user, event)).status).toBe(200);
    const detail = (await (await fetch(`${BASE_URL}/api/events/${event}`, { headers: auth(user.token) })).json()) as {
      userRsvp: { status: string } | null;
    };
    expect(detail.userRsvp?.status).toBe("going");
    expect((await fetch(`${BASE_URL}/api/events/${event}/rsvp`, { method: "DELETE", headers: auth(user.token) })).status).toBe(200);
    expect(await rsvpRows(event)).toBe(0);
  });
});

describe("GET /api/events bounds its page", () => {
  test("limit=100000 returns at most 50 events", async () => {
    await db`
      INSERT INTO events (title, date, is_published)
      SELECT 'Bulk ' || g, CURRENT_DATE + 30, true FROM generate_series(1, 55) g
    `;
    const res = await fetch(`${BASE_URL}/api/events?limit=100000`);
    expect(res.status).toBe(200);
    expect(((await res.json()) as { events: unknown[] }).events.length).toBe(50);
    await db`DELETE FROM events WHERE title LIKE 'Bulk %'`;
  });

  test.each(["limit=-1", "limit=abc", "offset=-9", "offset=NaN"])("%s falls back to a default", async (query) => {
    expect((await fetch(`${BASE_URL}/api/events?${query}`)).status).toBe(200);
  });

  test("a from date that is not a date is a 400, not a 500", async () => {
    expect((await fetch(`${BASE_URL}/api/events?from=yesterday`)).status).toBe(400);
    expect((await fetch(`${BASE_URL}/api/events?from=2030-02-31`)).status).toBe(400);
    expect((await fetch(`${BASE_URL}/api/events?from=2030-01-15`)).status).toBe(200);
  });
});
