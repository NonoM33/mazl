import { describe, expect, test } from "bun:test";
import { readdirSync, readFileSync, statSync } from "node:fs";
import { join } from "node:path";
import { BASE_URL, db, json, makeUser, type TestUser } from "./media-helpers";

// Security regressions of the couple mode. Every test replays what an attacker
// (or a careless client) sends and asserts what the contract allows, so none of
// them reads the implementation. Needs a running server (TEST_API_URL) and the
// database it uses (TEST_DATABASE_URL).

// ---------- helpers ----------

async function api(token: string, method: string, path: string, body?: unknown): Promise<Response> {
  return fetch(`${BASE_URL}${path}`, {
    method,
    headers: json(token),
    body: body === undefined ? undefined : JSON.stringify(body),
  });
}

async function bodyOf<T>(res: Response): Promise<T> {
  return (await res.json()) as T;
}

async function match(a: TestUser, b: TestUser): Promise<void> {
  for (const [from, to] of [[a, b], [b, a]] as const) {
    await api(from.token, "POST", "/api/swipes", { target_user_id: to.id, action: "like" });
  }
}

async function sendRequest(from: TestUser, to: TestUser): Promise<Response> {
  return api(from.token, "POST", "/api/couple/request", { target_user_id: to.id });
}

async function requestId(from: TestUser, to: TestUser): Promise<number> {
  const res = await sendRequest(from, to);
  expect(res.status).toBe(200);
  return (await bodyOf<{ request: { id: number } }>(res)).request.id;
}

const respond = (who: TestUser, id: number, action: "accept" | "reject") =>
  api(who.token, "PUT", `/api/couple/request/${id}`, { action });

interface Couple { a: TestUser; b: TestUser; id: number }

// A real couple, created through the consent flow (match, request, accept).
async function makeCouple(label: string): Promise<Couple> {
  const a = await makeUser(`${label}a`);
  const b = await makeUser(`${label}b`);
  await match(a, b);
  const id = await requestId(a, b);
  expect((await respond(b, id, "accept")).status).toBe(200);
  const mine = await bodyOf<{ couple: { id: number } }>(await api(a.token, "GET", "/api/couple"));
  return { a, b, id: mine.couple.id };
}

async function activeCouplesOf(userId: number): Promise<number> {
  const rows = await db<{ n: string }[]>`
    SELECT COUNT(*)::text AS n FROM couples
    WHERE status = 'active' AND (user1_id = ${userId} OR user2_id = ${userId})
  `;
  return Number(rows[0]?.n ?? 0);
}

async function backdateRequest(id: number, days: number): Promise<void> {
  await db`
    UPDATE couple_requests
    SET created_at = NOW() - ${days} * INTERVAL '1 day', updated_at = NOW() - ${days} * INTERVAL '1 day'
    WHERE id = ${id}
  `;
}

async function block(blocker: TestUser, blocked: TestUser): Promise<void> {
  await db`INSERT INTO blocked_users (blocker_id, blocked_id) VALUES (${blocker.id}, ${blocked.id})`;
}

interface EventSpec { published?: boolean; dayOffset?: number; priceCents?: number | null; max?: number | null; current?: number }
async function makeEvent(spec: EventSpec = {}): Promise<number> {
  const rows = await db<{ id: number }[]>`
    INSERT INTO couple_events (title, event_date, price_cents, max_couples, current_couples, is_published)
    VALUES ('Soirée sécurité', CURRENT_DATE + ${spec.dayOffset ?? 30}::int, ${spec.priceCents ?? null},
            ${spec.max === undefined ? 20 : spec.max}, ${spec.current ?? 0}, ${spec.published ?? true})
    RETURNING id
  `;
  const row = rows[0];
  if (!row) throw new Error("could not create the event");
  return row.id;
}

async function eventCount(eventId: number): Promise<number> {
  const rows = await db<{ n: number }[]>`SELECT current_couples AS n FROM couple_events WHERE id = ${eventId}`;
  return Number(rows[0]?.n ?? -1);
}

async function registrationRows(eventId: number): Promise<number> {
  const rows = await db<{ n: string }[]>`
    SELECT COUNT(*)::text AS n FROM couple_event_registrations WHERE event_id = ${eventId} AND status = 'registered'
  `;
  return Number(rows[0]?.n ?? 0);
}

// ---------- 1. daily question: the answer must stay inside its couple ----------

describe("daily question isolation", () => {
  test("a member cannot overwrite the answer of another couple's question", async () => {
    const mine = await makeCouple("q1");
    const other = await makeCouple("q2");
    const q = await bodyOf<{ question: { id: number } }>(
      await api(other.a.token, "GET", `/api/couple/${other.id}/question`),
    );
    const victimQuestion = q.question.id;
    expect((await api(other.a.token, "POST", `/api/couple/${other.id}/question/${victimQuestion}/answer`, { answer: "reponse privee" })).status).toBe(200);
    const before = await db`SELECT user1_answer, user2_answer FROM couple_questions WHERE id = ${victimQuestion}`;

    const attack = await api(mine.a.token, "POST", `/api/couple/${mine.id}/question/${victimQuestion}/answer`, { answer: "ECRASE" });
    expect(attack.status).toBe(404);

    const after = await db`SELECT user1_answer, user2_answer FROM couple_questions WHERE id = ${victimQuestion}`;
    expect(after[0]).toEqual(before[0]);
  });

  test("a member still answers the question of their own couple", async () => {
    const mine = await makeCouple("q3");
    const q = await bodyOf<{ question: { id: number } }>(await api(mine.a.token, "GET", `/api/couple/${mine.id}/question`));
    const res = await api(mine.b.token, "POST", `/api/couple/${mine.id}/question/${q.question.id}/answer`, { answer: "oui" });
    expect(res.status).toBe(200);
    const row = await db<{ user1_answer: string | null; user2_answer: string | null }[]>`
      SELECT user1_answer, user2_answer FROM couple_questions WHERE id = ${q.question.id}`;
    expect([row[0]?.user1_answer, row[0]?.user2_answer]).toContain("oui");
  });
});

// ---------- 2. a member is in one active couple, never two ----------

describe("one active couple per member", () => {
  test("accepting is refused when the accepter already joined another couple", async () => {
    const mine = await makeCouple("one1");
    const stranger = await makeUser("one1c");
    await match(mine.a, stranger);
    // A request that was pending before `mine.a` coupled up (inserted directly: the
    // API already refuses to create it now).
    const inserted = await db<{ id: number }[]>`
      INSERT INTO couple_requests (requester_id, target_id, status) VALUES (${stranger.id}, ${mine.a.id}, 'pending') RETURNING id`;
    const res = await respond(mine.a, inserted[0]!.id, "accept");
    expect(res.status).toBe(409);
    expect(await activeCouplesOf(mine.a.id)).toBe(1);
  });

  test("two simultaneous acceptances cannot create two couples", async () => {
    const a = await makeUser("race-a");
    const b = await makeUser("race-b");
    const c = await makeUser("race-c");
    await match(a, b);
    await match(a, c);
    const fromB = await requestId(b, a);
    const fromC = await requestId(c, a);
    const results = await Promise.all([respond(a, fromB, "accept"), respond(a, fromC, "accept")]);
    const statuses = results.map((r) => r.status).sort();
    expect(statuses).toEqual([200, 409]);
    expect(await activeCouplesOf(a.id)).toBe(1);
  });

  test("accepting cancels the other pending requests of both people", async () => {
    const a = await makeUser("cancel-a");
    const b = await makeUser("cancel-b");
    const c = await makeUser("cancel-c");
    await match(a, b);
    await match(a, c);
    const fromB = await requestId(b, a);
    const fromC = await requestId(c, a);
    expect((await respond(a, fromB, "accept")).status).toBe(200);
    const rows = await db<{ status: string }[]>`SELECT status FROM couple_requests WHERE id = ${fromC}`;
    expect(rows[0]?.status).toBe("cancelled");
  });

  test("the database itself refuses a second active couple, whatever the id order", async () => {
    const users = [await makeUser("db1"), await makeUser("db2"), await makeUser("db3")].sort((x, y) => x.id - y.id);
    const [u1, u2, u3] = users as [TestUser, TestUser, TestUser];
    await db`INSERT INTO couples (user1_id, user2_id, status) VALUES (${u1.id}, ${u2.id}, 'active')`;
    // u2 is user2 of the first couple and would be user1 of this one.
    await expect(db`INSERT INTO couples (user1_id, user2_id, status) VALUES (${u2.id}, ${u3.id}, 'active')`).rejects.toThrow();
    // u1 is user1 of the first couple and would be user1 again.
    await expect(db`INSERT INTO couples (user1_id, user2_id, status) VALUES (${u1.id}, ${u3.id}, 'active')`).rejects.toThrow();
    // An ended couple does not count.
    await db`INSERT INTO couples (user1_id, user2_id, status) VALUES (${u2.id}, ${u3.id}, 'ended')`;
    // Reactivating it while u2 is still coupled is refused as well.
    await expect(db`UPDATE couples SET status = 'active' WHERE user1_id = ${u2.id} AND user2_id = ${u3.id}`).rejects.toThrow();
  });
});

// ---------- 3. blocking and unmatching after the request ----------

describe("request acceptance re-checks the relationship", () => {
  test("a blocked requester cannot become a couple with the person who blocked them", async () => {
    const a = await makeUser("blk-a");
    const b = await makeUser("blk-b");
    await match(a, b);
    const id = await requestId(a, b);
    await block(b, a);
    const res = await respond(b, id, "accept");
    expect(res.status).toBe(403);
    expect(await activeCouplesOf(a.id)).toBe(0);
    expect(await activeCouplesOf(b.id)).toBe(0);
  });

  test("the block also stops the acceptance when the requester is the one who blocked", async () => {
    const a = await makeUser("blk2-a");
    const b = await makeUser("blk2-b");
    await match(a, b);
    const id = await requestId(a, b);
    await block(a, b);
    expect((await respond(b, id, "accept")).status).toBe(403);
    expect(await activeCouplesOf(b.id)).toBe(0);
  });

  test("the lists of requests hide people in a block relationship", async () => {
    const a = await makeUser("lst-a");
    const b = await makeUser("lst-b");
    await match(a, b);
    const id = await requestId(a, b);
    await block(b, a);
    const received = await bodyOf<{ received: Array<{ id: number }>; sent: Array<{ id: number }> }>(
      await api(b.token, "GET", "/api/couple/requests"),
    );
    expect(received.received.some((r) => r.id === id)).toBe(false);
    const sent = await bodyOf<{ sent: Array<{ id: number }> }>(await api(a.token, "GET", "/api/couple/requests"));
    expect(sent.sent.some((r) => r.id === id)).toBe(false);
  });

  test("a request cannot be accepted once the match no longer exists", async () => {
    const a = await makeUser("unm-a");
    const b = await makeUser("unm-b");
    await match(a, b);
    const id = await requestId(a, b);
    const [low, high] = a.id < b.id ? [a.id, b.id] : [b.id, a.id];
    await db`DELETE FROM matches WHERE user1_id = ${low} AND user2_id = ${high}`;
    expect((await respond(b, id, "accept")).status).toBe(403);
    expect(await activeCouplesOf(b.id)).toBe(0);
  });
});

// ---------- 4. repeated requests are harassment ----------

describe("repeated couple requests", () => {
  test("a refused person cannot be asked again for seven days", async () => {
    const a = await makeUser("hr-a");
    const b = await makeUser("hr-b");
    await match(a, b);
    const first = await requestId(a, b);
    expect((await respond(b, first, "reject")).status).toBe(200);

    expect((await sendRequest(a, b)).status).toBe(429);

    await backdateRequest(first, 8);
    expect((await sendRequest(a, b)).status).toBe(200);
  });

  test("after three refused requests the pair is closed for good", async () => {
    const a = await makeUser("cap-a");
    const b = await makeUser("cap-b");
    await match(a, b);
    for (let i = 0; i < 3; i += 1) {
      const id = await requestId(a, b);
      expect((await respond(b, id, "reject")).status).toBe(200);
      await backdateRequest(id, 8 + i);
    }
    const fourth = await sendRequest(a, b);
    expect(fourth.status).toBe(409);
    const body = await bodyOf<{ success: boolean; error: string }>(fourth);
    expect(body.success).toBe(false);
    expect(body.error.length).toBeGreaterThan(10);
  });

  test("sending and cancelling in a loop is throttled", async () => {
    const a = await makeUser("loop-a");
    const b = await makeUser("loop-b");
    await match(a, b);
    for (let i = 0; i < 3; i += 1) {
      const id = await requestId(a, b);
      expect((await api(a.token, "DELETE", `/api/couple/request/${id}`)).status).toBe(200);
    }
    expect((await sendRequest(a, b)).status).toBe(429);
  });
});

// ---------- 5. archive-conversations ----------

describe("archive-conversations", () => {
  const archive = (who: TestUser, body: unknown) => api(who.token, "POST", "/api/couple/archive-conversations", body);
  const archivedCount = async (userId: number): Promise<number> => {
    const rows = await db<{ n: string }[]>`SELECT COUNT(*)::text AS n FROM archived_conversations WHERE user_id = ${userId}`;
    return Number(rows[0]?.n ?? 0);
  };
  const messagesFrom = async (senderId: number, otherId: number): Promise<number> => {
    const rows = await db<{ n: string }[]>`
      SELECT COUNT(*)::text AS n FROM messages m JOIN conversations c ON c.id = m.conversation_id
      WHERE m.sender_id = ${senderId} AND (c.user1_id = ${otherId} OR c.user2_id = ${otherId})`;
    return Number(rows[0]?.n ?? 0);
  };

  test("someone who is not in a couple cannot archive anything", async () => {
    const a = await makeUser("arc-a");
    const b = await makeUser("arc-b");
    await match(a, b);
    const res = await archive(a, { partner_user_id: 0, message: "bye" });
    expect(res.status).toBe(403);
    expect(await archivedCount(a.id)).toBe(0);
    expect(await messagesFrom(a.id, b.id)).toBe(0);
  });

  test("the partner is the one of the couple, a different one in the body is refused", async () => {
    const couple = await makeCouple("arc1");
    const other = await makeUser("arc1x");
    await match(couple.a, other);
    const res = await archive(couple.a, { partner_user_id: other.id, message: "bye" });
    expect(res.status).toBe(403);
    expect(await archivedCount(couple.a.id)).toBe(0);
    expect(await messagesFrom(couple.a.id, other.id)).toBe(0);
  });

  test("the message is limited to 500 characters", async () => {
    const couple = await makeCouple("arc2");
    const other = await makeUser("arc2x");
    await match(couple.a, other);
    const res = await archive(couple.a, { partner_user_id: couple.b.id, message: "x".repeat(501) });
    expect(res.status).toBe(400);
    expect(await archivedCount(couple.a.id)).toBe(0);
  });

  test("nothing is written in a conversation with a blocked person", async () => {
    const couple = await makeCouple("arc3");
    const friend = await makeUser("arc3f");
    const harasser = await makeUser("arc3h");
    await match(couple.a, friend);
    await match(couple.a, harasser);
    await block(harasser, couple.a);

    const res = await archive(couple.a, { partner_user_id: couple.b.id, message: "Je suis en couple" });
    expect(res.status).toBe(200);
    expect(await messagesFrom(couple.a.id, friend.id)).toBe(1);
    expect(await messagesFrom(couple.a.id, harasser.id)).toBe(0);
    expect(await messagesFrom(couple.a.id, couple.b.id)).toBe(0);
  });

  test("without partner in the body the couple's partner is kept", async () => {
    const couple = await makeCouple("arc4");
    const other = await makeUser("arc4x");
    await match(couple.a, other);
    const res = await archive(couple.a, { message: "bye" });
    expect(res.status).toBe(200);
    const kept = await db`
      SELECT 1 FROM archived_conversations ac JOIN conversations c ON c.id = ac.conversation_id
      WHERE ac.user_id = ${couple.a.id} AND (c.user1_id = ${couple.b.id} OR c.user2_id = ${couple.b.id})`;
    expect(kept.length).toBe(0);
    expect(await archivedCount(couple.a.id)).toBe(1);
  });
});

// ---------- 6. events and bookings ----------

describe("couple events", () => {
  test("a draft event is invisible and cannot be joined", async () => {
    const couple = await makeCouple("ev1");
    const draft = await makeEvent({ published: false });
    expect((await api(couple.a.token, "GET", `/api/couple/events/${draft}`)).status).toBe(404);
    expect((await api(couple.a.token, "POST", `/api/couple/events/${draft}/register`)).status).toBe(404);
    expect(await registrationRows(draft)).toBe(0);
    expect(await eventCount(draft)).toBe(0);
  });

  test("a past event cannot be joined", async () => {
    const couple = await makeCouple("ev2");
    const past = await makeEvent({ dayOffset: -3 });
    expect((await api(couple.a.token, "POST", `/api/couple/events/${past}/register`)).status).toBe(409);
    expect(await registrationRows(past)).toBe(0);
    expect(await eventCount(past)).toBe(0);
  });

  test("a paid event cannot be joined without paying", async () => {
    const couple = await makeCouple("ev3");
    const paid = await makeEvent({ priceCents: 8000 });
    const res = await api(couple.a.token, "POST", `/api/couple/events/${paid}/register`);
    expect(res.status).toBe(402);
    expect((await bodyOf<{ success: boolean }>(res)).success).toBe(false);
    expect(await registrationRows(paid)).toBe(0);
    expect(await eventCount(paid)).toBe(0);
  });

  test("a free event is still joinable, and zero cents counts as free", async () => {
    const couple = await makeCouple("ev4");
    const free = await makeEvent({ priceCents: 0 });
    expect((await api(couple.a.token, "POST", `/api/couple/events/${free}/register`)).status).toBe(200);
    expect(await eventCount(free)).toBe(1);
  });

  test("a full event answers a clear refusal, not a server error", async () => {
    const couple = await makeCouple("ev5");
    const full = await makeEvent({ max: 1, current: 1 });
    const res = await api(couple.a.token, "POST", `/api/couple/events/${full}/register`);
    expect(res.status).toBe(409);
    expect(await eventCount(full)).toBe(1);
  });

  test("the last place goes to one couple only", async () => {
    const couples = await Promise.all([makeCouple("ev6a"), makeCouple("ev6b"), makeCouple("ev6c")]);
    const event = await makeEvent({ max: 1, current: 0 });
    const results = await Promise.all(
      couples.map((c) => api(c.a.token, "POST", `/api/couple/events/${event}/register`)),
    );
    expect(results.filter((r) => r.status === 200).length).toBe(1);
    expect(await eventCount(event)).toBe(1);
    expect(await registrationRows(event)).toBe(1);
  });

  test("the same couple registering many times at once counts once", async () => {
    const couple = await makeCouple("ev7");
    const event = await makeEvent({ max: 5, current: 0 });
    await Promise.all(
      Array.from({ length: 8 }, () => api(couple.a.token, "POST", `/api/couple/events/${event}/register`)),
    );
    expect(await eventCount(event)).toBe(1);
    expect(await registrationRows(event)).toBe(1);
  });
});

describe("couple bookings", () => {
  const book = (who: TestUser, body: unknown) => api(who.token, "POST", "/api/couple/bookings", body);

  test("a booking on a draft, past or paid event is refused", async () => {
    const couple = await makeCouple("bk1");
    const draft = await makeEvent({ published: false });
    const past = await makeEvent({ dayOffset: -2 });
    const paid = await makeEvent({ priceCents: 5000 });
    expect((await book(couple.a, { eventId: draft, bookingDate: "2030-01-01" })).status).toBe(404);
    expect((await book(couple.a, { eventId: past, bookingDate: "2030-01-01" })).status).toBe(409);
    expect((await book(couple.a, { eventId: paid, bookingDate: "2030-01-01" })).status).toBe(402);
    const rows = await db`SELECT 1 FROM couple_bookings WHERE couple_id = ${couple.id}`;
    expect(rows.length).toBe(0);
  });

  test("a booking on an inactive activity is refused and the activity is hidden", async () => {
    const couple = await makeCouple("bk2");
    const [activity] = await db<{ id: number }[]>`
      INSERT INTO couple_activities (title, category, is_active) VALUES ('Brouillon', 'dinner', false) RETURNING id`;
    expect((await api(couple.a.token, "GET", `/api/couple/activities/${activity!.id}`)).status).toBe(404);
    expect((await book(couple.a, { activityId: activity!.id, bookingDate: "2030-01-01" })).status).toBe(404);
  });

  test("a malformed booking is a 400, never a 500", async () => {
    const couple = await makeCouple("bk3");
    expect((await book(couple.a, {})).status).toBe(400);
    expect((await book(couple.a, { bookingDate: "2030-01-01" })).status).toBe(400);
    expect((await book(couple.a, { activityId: "abc", bookingDate: "2030-01-01" })).status).toBe(400);
    expect((await book(couple.a, { activityId: 999999999, bookingDate: "pas-une-date" })).status).toBe(400);
    expect((await book(couple.a, { activityId: 999999999, bookingDate: "2030-02-31" })).status).toBe(400);
    expect((await book(couple.a, { activityId: 999999999, bookingDate: "2030-01-01" })).status).toBe(404);
  });

  test("a valid booking on a free published event succeeds", async () => {
    const couple = await makeCouple("bk4");
    const event = await makeEvent({});
    const res = await book(couple.a, { eventId: event, bookingDate: "2030-01-01", bookingTime: "19:30", notes: "table au calme" });
    expect(res.status).toBe(200);
    expect((await bodyOf<{ success: boolean }>(res)).success).toBe(true);
  });
});

// ---------- 7. validation ----------

describe("input validation", () => {
  test("the relationship status is picked in a list", async () => {
    const couple = await makeCouple("val1");
    const path = `/api/couple/${couple.id}/status`;
    expect((await api(couple.a.token, "PATCH", path, { relationshipStatus: "hacked" })).status).toBe(400);
    expect((await api(couple.a.token, "PATCH", path, {})).status).toBe(400);
    const row = await db<{ relationship_status: string }[]>`SELECT relationship_status FROM couples WHERE id = ${couple.id}`;
    expect(row[0]?.relationship_status).not.toBe("hacked");
    expect((await api(couple.a.token, "PATCH", path, { relationshipStatus: "engaged" })).status).toBe(200);
  });

  test("memories are validated", async () => {
    const couple = await makeCouple("val2");
    const add = (body: Record<string, unknown>) => api(couple.a.token, "POST", "/api/couple/memories", { type: "note", ...body });
    expect((await add({ type: "x".repeat(50) })).status).toBe(400);
    expect((await add({ title: "t".repeat(300) })).status).toBe(400);
    expect((await add({ location: "l".repeat(300) })).status).toBe(400);
    expect((await add({ memoryDate: "n'importe quoi" })).status).toBe(400);
    expect((await add({ memoryDate: "2024-02-30" })).status).toBe(400);
    expect((await add({ title: "Notre premier voyage", memoryDate: "2024-01-15" })).status).toBe(200);
  });

  test("a memory picture must be an https url", async () => {
    const couple = await makeCouple("val3");
    const add = (imageUrl: string) =>
      api(couple.a.token, "POST", "/api/couple/memories", { type: "photo", imageUrl });
    for (const bad of ["javascript:alert(1)", "http://example.com/a.jpg", "data:text/html;base64,PHNjcmlwdD4=", "//example.com/a.jpg", "https://"]) {
      expect((await add(bad)).status).toBe(400);
    }
    expect((await add("https://example.com/a.jpg")).status).toBe(200);
    const stored = await db`SELECT image_url FROM couple_memories WHERE couple_id = ${couple.id}`;
    expect(stored.map((r) => r.image_url)).toEqual(["https://example.com/a.jpg"]);
  });

  test("important dates and bucket-list items reject impossible dates", async () => {
    const couple = await makeCouple("val4");
    const date = (body: Record<string, unknown>) =>
      api(couple.a.token, "POST", "/api/couple/dates", { title: "Anniversaire", type: "anniversary", ...body });
    expect((await date({ date: "2024-13-45" })).status).toBe(400);
    expect((await date({ date: "demain" })).status).toBe(400);
    expect((await date({})).status).toBe(400);
    expect((await date({ date: "2024-06-15" })).status).toBe(200);
    const item = (body: Record<string, unknown>) => api(couple.a.token, "POST", "/api/couple/bucket-list", body);
    expect((await item({ title: "Voir l'aurore", targetDate: "2026-99-99" })).status).toBe(400);
    expect((await item({})).status).toBe(400);
    expect((await item({ title: "Voir l'aurore", targetDate: "2027-03-01" })).status).toBe(200);
  });

  test("limit and offset are bounded integers", async () => {
    const couple = await makeCouple("val5");
    for (const path of ["/api/couple/activities", "/api/couple/events"]) {
      for (const bad of ["limit=1000", "limit=0", "limit=-5", "limit=abc", "limit=1.5", "offset=-1", "offset=abc"]) {
        expect((await api(couple.a.token, "GET", `${path}?${bad}`)).status).toBe(400);
      }
      expect((await api(couple.a.token, "GET", `${path}?limit=100&offset=0`)).status).toBe(200);
      expect((await api(couple.a.token, "GET", path)).status).toBe(200);
    }
  });

  test("a broken json body is a 400 that does not leak the parser's message", async () => {
    const couple = await makeCouple("val6");
    const send = async (method: string, path: string): Promise<Response> =>
      fetch(`${BASE_URL}${path}`, { method, headers: json(couple.a.token), body: "{pas du json" });
    const q = await bodyOf<{ question: { id: number } }>(await api(couple.a.token, "GET", `/api/couple/${couple.id}/question`));
    const responses = await Promise.all([
      send("PATCH", `/api/couple/${couple.id}/status`),
      send("POST", `/api/couple/${couple.id}/question/${q.question.id}/answer`),
      send("POST", "/api/couple/memories"),
      send("POST", "/api/couple/dates"),
      send("POST", "/api/couple/bookings"),
      send("POST", "/api/couple/bucket-list"),
    ]);
    for (const res of responses) {
      expect(res.status).toBe(400);
      const text = JSON.stringify(await res.json());
      expect(text).not.toMatch(/JSON at position|Unexpected token|SyntaxError/i);
    }
  });

  test("an answer must be a non-empty string of reasonable length", async () => {
    const couple = await makeCouple("val7");
    const q = await bodyOf<{ question: { id: number } }>(await api(couple.a.token, "GET", `/api/couple/${couple.id}/question`));
    const path = `/api/couple/${couple.id}/question/${q.question.id}/answer`;
    expect((await api(couple.a.token, "POST", path, { answer: "" })).status).toBe(400);
    expect((await api(couple.a.token, "POST", path, { answer: 12 })).status).toBe(400);
    expect((await api(couple.a.token, "POST", path, { answer: "a".repeat(2001) })).status).toBe(400);
  });
});

describe("error messages", () => {
  function sourceFiles(dir: string): string[] {
    return readdirSync(dir).flatMap((name) => {
      const full = join(dir, name);
      return statSync(full).isDirectory() ? sourceFiles(full) : full.endsWith(".ts") ? [full] : [];
    });
  }

  test("no couple route sends a raw exception message to the client", () => {
    const offenders = sourceFiles(join(import.meta.dir, "..", "src", "features", "couple")).filter((file) =>
      /error as Error\)\.message|error\.message|err\.message|e\.message/.test(readFileSync(file, "utf8")),
    );
    expect(offenders).toEqual([]);
  });
});
