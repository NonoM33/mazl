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
