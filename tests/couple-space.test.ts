import { beforeAll, describe, expect, test } from "bun:test";
import { BASE_URL, auth, db, json, makeUser, type TestUser } from "./media-helpers";

// Integration: the daily couple space (docs/couple/ESPACE-COUPLE.md) on a real
// server and database. Needs TEST_API_URL, TEST_DATABASE_URL and the fake
// Anthropic of scripts/test-integration.ts (FAKE_ANTHROPIC_URL, ANTHROPIC_API_KEY).

const FAKE_ANTHROPIC = process.env.FAKE_ANTHROPIC_URL ?? "";
const ADMIN_PASSWORD = process.env.ADMIN_PASSWORD ?? "";
const staff = (): Record<string, string> => ({ "x-admin-password": ADMIN_PASSWORD, "Content-Type": "application/json" });

interface Couple { a: TestUser; b: TestUser; id: number }

async function api<T = any>(member: TestUser, path: string, init: RequestInit = {}, headers: Record<string, string> = {}): Promise<{ status: number; body: T }> {
  const res = await fetch(`${BASE_URL}${path}`, { ...init, headers: { ...json(member.token), ...headers, ...(init.headers as Record<string, string> | undefined) } });
  return { status: res.status, body: (await res.json()) as T };
}
const post = (member: TestUser, path: string, body: unknown, headers: Record<string, string> = {}) => api(member, path, { method: "POST", body: JSON.stringify(body) }, headers);

async function nameOf(user: TestUser, displayName: string): Promise<void> {
  await db`INSERT INTO profiles (user_id, display_name) VALUES (${user.id}, ${displayName}) ON CONFLICT (user_id) DO UPDATE SET display_name = EXCLUDED.display_name`;
}

// Two members who matched, asked and accepted: a real couple through the real routes.
async function makeCouple(label: string, names: [string, string] = ["Léa", "David"]): Promise<Couple> {
  const a = await makeUser(`${label}-a`);
  const b = await makeUser(`${label}-b`);
  await nameOf(a, `${names[0]} Exemple`);
  await nameOf(b, `${names[1]} Exemple`);
  for (const [from, to] of [[a, b], [b, a]] as const) {
    await fetch(`${BASE_URL}/api/swipes`, { method: "POST", headers: json(from.token), body: JSON.stringify({ target_user_id: to.id, action: "like" }) });
  }
  const sent = await post(a, "/api/couple/request", { target_user_id: b.id });
  const accepted = await api(b, `/api/couple/request/${sent.body.request.id}`, { method: "PUT", body: JSON.stringify({ action: "accept" }) });
  if (accepted.status !== 200) throw new Error(`couple not formed: ${JSON.stringify(accepted.body)}`);
  return { a, b, id: accepted.body.couple.id };
}

async function grantCouplePlan(userId: number, days = 30): Promise<void> {
  await db`
    INSERT INTO subscriptions (user_id, plan_type, status, store, product_id, original_transaction_id, started_at, expires_at)
    VALUES (${userId}, 'couple_monthly', 'active', 'apple', 'com.mazl.app.couple.1m', ${`test-couple-${userId}`}, NOW() AT TIME ZONE 'UTC', (NOW() AT TIME ZONE 'UTC') + ${days} * INTERVAL '1 day')
    ON CONFLICT (user_id) DO UPDATE SET plan_type = 'couple_monthly', status = 'active', expires_at = EXCLUDED.expires_at`;
}

const fakeRequests = async (): Promise<{ headers: Record<string, string>; body: any }[]> => (await fetch(`${FAKE_ANTHROPIC}/__test/requests`)).json() as never;
const fakeMode = (mode: string) => fetch(`${FAKE_ANTHROPIC}/__test/mode`, { method: "POST", body: JSON.stringify({ mode }) });
const fakeReset = () => fetch(`${FAKE_ANTHROPIC}/__test/reset`, { method: "POST" });

describe("rights: one pays, both have them", () => {
  test("without MAZL Couple: not active, no mazl+ rights", async () => {
    const couple = await makeCouple("rights-none");
    const mine = await api(couple.a, "/api/couple");
    expect(mine.body.premium).toEqual({ active: false, paidBy: null, renewsAt: null });
    expect(((await api(couple.a, "/api/likes/allowance")).body as any).allowance.daily_allowance).toBe(10);
  });

  test("a single payer covers both members, who each read who pays", async () => {
    const couple = await makeCouple("rights-pay");
    await grantCouplePlan(couple.a.id);
    const payer = (await api(couple.a, "/api/couple")).body.premium;
    const partner = (await api(couple.b, "/api/couple")).body.premium;
    expect(payer).toMatchObject({ active: true, paidBy: "me" });
    expect(partner).toMatchObject({ active: true, paidBy: "partner" });
    expect(new Date(partner.renewsAt).getTime()).toBeGreaterThan(Date.now());
    for (const member of [couple.a, couple.b]) {
      expect(((await api(member, "/api/likes/allowance")).body as any).allowance.daily_allowance).toBeNull();
    }
    expect((await api(couple.b, "/api/couple/today")).body.data.premium).toMatchObject({ active: true, paidBy: "partner" });
  });

  test("when the couple ends, the partner loses the rights", async () => {
    const couple = await makeCouple("rights-end");
    await grantCouplePlan(couple.a.id);
    expect(((await api(couple.b, "/api/likes/allowance")).body as any).allowance.daily_allowance).toBeNull();
    expect((await api(couple.a, `/api/couple/${couple.id}`, { method: "DELETE" })).status).toBe(200);
    expect(((await api(couple.b, "/api/likes/allowance")).body as any).allowance.daily_allowance).toBe(10);
    expect((await api(couple.b, "/api/couple")).body.premium).toEqual({ active: false, paidBy: null, renewsAt: null });
  });

  test("an expired subscription gives nothing to anyone", async () => {
    const couple = await makeCouple("rights-expired");
    await grantCouplePlan(couple.a.id);
    await db`UPDATE subscriptions SET expires_at = (NOW() AT TIME ZONE 'UTC') - INTERVAL '1 minute' WHERE user_id = ${couple.a.id}`;
    for (const member of [couple.a, couple.b]) {
      expect((await api(member, "/api/couple")).body.premium.active).toBe(false);
      expect(((await api(member, "/api/likes/allowance")).body as any).allowance.daily_allowance).toBe(10);
    }
  });

  test("a plain mazl+ plan of the partner does not make MAZL Couple", async () => {
    const couple = await makeCouple("rights-plus");
    await db`INSERT INTO subscriptions (user_id, plan_type, status, store, product_id, original_transaction_id, started_at, expires_at)
      VALUES (${couple.a.id}, 'monthly', 'active', 'apple', 'com.mazl.app.plus.1m', ${`test-plus-only-${couple.a.id}`}, NOW() AT TIME ZONE 'UTC', (NOW() AT TIME ZONE 'UTC') + INTERVAL '30 days')`;
    expect((await api(couple.b, "/api/couple")).body.premium.active).toBe(false);
    expect(((await api(couple.b, "/api/likes/allowance")).body as any).allowance.daily_allowance).toBe(10);
  });
});

describe("Today, mood and outsiders", () => {
  test("a member without a couple is turned away; unauthenticated is 401", async () => {
    const loner = await makeUser("space-loner");
    expect((await api(loner, "/api/couple/today")).status).toBe(400);
    expect((await api(loner, "/api/couple/rituals")).status).toBe(400);
    expect((await fetch(`${BASE_URL}/api/couple/today`)).status).toBe(401);
  });

  test("Today shows the days, the partner, the question flags and the default rituals as upcoming", async () => {
    const couple = await makeCouple("today");
    const today = (await api(couple.a, "/api/couple/today", {}, { "Accept-Language": "fr" })).body.data;
    expect(today.partner).toMatchObject({ id: couple.b.id, name: "David Exemple" });
    expect(today.days).toBeGreaterThanOrEqual(0);
    expect(today.question).toMatchObject({ myAnswered: false, partnerAnswered: false });
    expect(today.checkin).toMatchObject({ due: true });
    expect(today.mood).toEqual({ mine: null, partner: null });
    expect(today.premium.active).toBe(false);
    expect(today.upcoming.some((u: { kind: string }) => u.kind === "ritual")).toBe(true);
  });

  test("the mood is validated, stored, and seen by the partner only as a mood", async () => {
    const couple = await makeCouple("mood");
    expect((await post(couple.a, "/api/couple/mood", { mood: "ecstatic" })).status).toBe(400);
    expect((await post(couple.a, "/api/couple/mood", { mood: "good", text: "libre" })).status).toBe(400);
    expect((await post(couple.a, "/api/couple/mood", { mood: "good" })).body.data).toEqual({ mine: "good", partner: null });
    expect((await post(couple.b, "/api/couple/mood", { mood: "talk" })).body.data).toEqual({ mine: "talk", partner: "good" });
    expect((await api(couple.a, "/api/couple/today")).body.data.mood).toEqual({ mine: "good", partner: "talk" });
  });
});

describe("rituals", () => {
  test("a new couple has Shabbat on, and the two weekly rituals off", async () => {
    const couple = await makeCouple("rituals");
    const { rituals } = (await api(couple.a, "/api/couple/rituals")).body.data;
    expect(rituals.map((r: any) => [r.kind, r.title, r.weekday, r.time, r.enabled, r.remind_minutes])).toEqual([
      ["shabbat", "Shabbat ensemble", 5, null, true, 60],
      ["weekly", "Soirée sans écran", 2, "20:00", false, 60],
      ["weekly", "Appeler les parents", 0, "11:00", false, 60],
    ]);
    expect(rituals.every((r: any) => r.couple_id === couple.id)).toBe(true);
  });

  test("create, update, delete; the partner sees the same list", async () => {
    const couple = await makeCouple("rituals-crud");
    const created = await post(couple.a, "/api/couple/rituals", { kind: "custom", title: "Brunch du dimanche", weekday: 0, time: "11:30", remind_minutes: 90 });
    expect(created.status).toBe(201);
    const id = created.body.data.ritual.id;
    expect((await api(couple.b, `/api/couple/rituals/${id}`, { method: "PATCH", body: JSON.stringify({ enabled: false, time: "12:00" }) })).body.data.ritual).toMatchObject({ enabled: false, time: "12:00", title: "Brunch du dimanche" });
    expect((await api(couple.a, "/api/couple/rituals")).body.data.rituals).toHaveLength(4);
    expect((await api(couple.a, `/api/couple/rituals/${id}`, { method: "DELETE" })).status).toBe(200);
    expect((await api(couple.b, "/api/couple/rituals")).body.data.rituals).toHaveLength(3);
  });

  test("bad bodies are 400; another couple's ritual is a 404 for read, change and delete", async () => {
    const mine = await makeCouple("rituals-mine");
    const other = await makeCouple("rituals-other");
    expect((await post(mine.a, "/api/couple/rituals", { kind: "custom", title: "x", time: "25:00" })).status).toBe(400);
    expect((await post(mine.a, "/api/couple/rituals", { kind: "yearly", title: "x" })).status).toBe(400);
    expect((await api(mine.a, "/api/couple/rituals/1", { method: "PATCH", body: JSON.stringify({}) })).status).toBe(400);
    const theirs = (await api(other.a, "/api/couple/rituals")).body.data.rituals[0].id;
    expect((await api(mine.a, `/api/couple/rituals/${theirs}`, { method: "PATCH", body: JSON.stringify({ enabled: false }) })).status).toBe(404);
    expect((await api(mine.a, `/api/couple/rituals/${theirs}`, { method: "DELETE" })).status).toBe(404);
    expect((await api(other.a, "/api/couple/rituals")).body.data.rituals[0].enabled).toBe(true);
    expect((await api(mine.a, "/api/couple/rituals/abc", { method: "DELETE" })).status).toBe(404);
  });
});

describe("the daily question", () => {
  test("hidden until you answer, in the language asked, same question all day", async () => {
    const couple = await makeCouple("question");
    const fr = (await api(couple.a, `/api/couple/${couple.id}/question`, {}, { "Accept-Language": "fr-FR" })).body;
    const q = fr.data;
    expect(fr.question).toEqual(q);
    expect(q).toMatchObject({ myAnswer: null, partnerAnswer: null });
    const he = (await api(couple.a, `/api/couple/${couple.id}/question`, {}, { "Accept-Language": "he-IL,he;q=0.9" })).body.data;
    expect(he.id).toBe(q.id);
    expect(he.text).not.toBe(q.text);
    expect(he.text).toMatch(/[֐-׿]/);

    expect((await post(couple.b, `/api/couple/${couple.id}/question/${q.id}/answer`, { answer: "Nos balades du dimanche." })).status).toBe(200);
    const before = (await api(couple.a, `/api/couple/${couple.id}/question`)).body.data;
    expect(before.partnerAnswer).toBeNull(); // not before A answers
    expect((await api(couple.a, "/api/couple/today")).body.data.question).toMatchObject({ myAnswered: false, partnerAnswered: true });
    expect((await api(couple.a, `/api/couple/${couple.id}/questions`)).body.data.questions).toEqual([]);

    expect((await post(couple.a, `/api/couple/${couple.id}/question/${q.id}/answer`, { answer: "Le dîner du vendredi." })).status).toBe(200);
    expect((await api(couple.a, `/api/couple/${couple.id}/question`)).body.data).toMatchObject({ myAnswer: "Le dîner du vendredi.", partnerAnswer: "Nos balades du dimanche." });
    const history = (await api(couple.b, `/api/couple/${couple.id}/questions`)).body.data.questions;
    expect(history).toHaveLength(1);
    expect(history[0]).toMatchObject({ id: q.id, myAnswer: "Nos balades du dimanche.", partnerAnswer: "Le dîner du vendredi." });
  });

  test("another couple's question is forbidden, and an empty answer is refused", async () => {
    const mine = await makeCouple("question-mine");
    const other = await makeCouple("question-other");
    expect((await api(mine.a, `/api/couple/${other.id}/question`)).status).toBe(403);
    expect((await post(mine.a, `/api/couple/${other.id}/question/1/answer`, { answer: "x" })).status).toBe(403);
    expect((await api(mine.a, `/api/couple/${other.id}/questions`)).status).toBe(403);
    const q = (await api(mine.a, `/api/couple/${mine.id}/question`)).body.data;
    expect((await post(mine.a, `/api/couple/${mine.id}/question/${q.id}/answer`, { answer: "   " })).status).toBe(400);
    // the question of another couple, by id, cannot be answered through your own couple
    const theirs = (await api(other.a, `/api/couple/${other.id}/question`)).body.data;
    expect((await post(mine.a, `/api/couple/${mine.id}/question/${theirs.id}/answer`, { answer: "intrus" })).status).toBe(404);
    expect((await api(other.a, `/api/couple/${other.id}/question`)).body.data.partnerAnswer).toBeNull();
  });

  test("no repeat until the bank is used up: with 119 asked, the 120th is drawn", async () => {
    const couple = await makeCouple("question-bank");
    for (let n = 1; n <= 119; n += 1) {
      await db`INSERT INTO couple_questions (couple_id, question, category, bank_key, asked_at)
        VALUES (${couple.id}, 'ancienne', 'daily', ${`q${String(n).padStart(3, "0")}`}, (NOW() AT TIME ZONE 'Europe/Paris')::date - ${n} * INTERVAL '1 day')`;
    }
    const q = (await api(couple.a, `/api/couple/${couple.id}/question`)).body.data;
    const [row] = await db`SELECT bank_key FROM couple_questions WHERE id = ${q.id}`;
    expect(row?.bank_key).toBe("q120");
  });

  test("an old question without a bank key keeps its stored text", async () => {
    const couple = await makeCouple("question-legacy");
    await db`INSERT INTO couple_questions (couple_id, question, category, asked_at, user1_answer, user2_answer)
      VALUES (${couple.id}, 'Une très ancienne question ?', 'Reves', (NOW() AT TIME ZONE 'Europe/Paris')::date - 40, 'oui', 'non')`;
    const history = (await api(couple.a, `/api/couple/${couple.id}/questions`)).body.data.questions;
    expect(history.map((h: any) => h.text)).toEqual(["Une très ancienne question ?"]);
  });
});

describe("monthly check-in", () => {
  test("alone, then together: a summary and never the other's notes; once a month", async () => {
    const couple = await makeCouple("checkin");
    expect((await post(couple.a, "/api/couple/checkin", { talk: 6, time: 3, close: 3 })).status).toBe(400);
    expect((await post(couple.a, "/api/couple/checkin", { talk: 4, time: 3 })).status).toBe(400);
    const first = await post(couple.a, "/api/couple/checkin", { talk: 4, time: 3, close: 5 });
    expect(first.body.data).toMatchObject({ mine: { talk: 4, time: 3, close: 5 }, partnerDone: false, summary: null });
    const second = await post(couple.a, "/api/couple/checkin", { talk: 1, time: 1, close: 1 });
    expect(second.status).toBe(409);
    expect(second.body.error).toBe("checkin_already_done");

    const seen = (await api(couple.b, "/api/couple/checkin")).body.data;
    expect(seen).toMatchObject({ mine: null, partnerDone: true, summary: null });
    expect(JSON.stringify(seen)).not.toMatch(/"talk":4|"close":5/);

    const done = (await post(couple.b, "/api/couple/checkin", { talk: 5, time: 1, close: 4 })).body.data;
    expect(done.summary).toEqual({ aligned: 2, lowest: "time", trend: null });
    expect(done.mine).toEqual({ talk: 5, time: 1, close: 4 });
    expect((await api(couple.a, "/api/couple/checkin")).body.data.summary).toEqual(done.summary);
    expect((await api(couple.a, "/api/couple/today")).body.data.checkin.due).toBe(false);
  });
});

describe("outings", () => {
  const fixtureKey = `test-outings-${Date.now()}`;
  const ids: { cheap: number; kosher: number; today: number; farEvent: number } = { cheap: 0, kosher: 0, today: 0, farEvent: 0 };

  beforeAll(async () => {
    const insert = async (title: string, price: number, kosher: boolean, partner: boolean): Promise<number> =>
      ((await db`INSERT INTO couple_activities (title, category, city, image_url, price_cents, is_kosher, is_partner, is_active, fixture_key)
        VALUES (${title}, 'diy', 'Lyon', 'https://example.com/a.jpg', ${price}, ${kosher}, ${partner}, true, ${`${fixtureKey}-${title}`}) RETURNING id`)[0] as { id: number }).id;
    ids.cheap = await insert(`${fixtureKey} pas cher`, 2500, false, false);
    ids.kosher = await insert(`${fixtureKey} casher`, 9000, true, true);
    ids.today = ((await db`INSERT INTO couple_events (title, category, city, image_url, event_date, event_time, price_cents, is_kosher, is_featured, is_published, fixture_key)
      VALUES (${`${fixtureKey} ce soir`}, 'dinner', 'Paris', 'https://example.com/e.jpg', (NOW() AT TIME ZONE 'Europe/Paris')::date, '21:00', 6500, true, true, true, ${`${fixtureKey}-today`}) RETURNING id`)[0] as { id: number }).id;
    ids.farEvent = ((await db`INSERT INTO couple_events (title, category, city, event_date, event_time, is_published, fixture_key)
      VALUES (${`${fixtureKey} lointain`}, 'dinner', 'Paris', (NOW() AT TIME ZONE 'Europe/Paris')::date + 30, '19:00', true, ${`${fixtureKey}-far`}) RETURNING id`)[0] as { id: number }).id;
  });

  const titles = (list: { title: string }[]) => list.filter((o) => o.title.startsWith(fixtureKey)).map((o) => o.title.slice(fixtureKey.length + 1)).sort();

  test("the filters of the contract, with the featured event apart", async () => {
    const couple = await makeCouple("outings");
    const all = (await api(couple.a, "/api/couple/outings")).body.data;
    expect(all.featured).toMatchObject({ kind: "event", title: `${fixtureKey} ce soir`, kosher: true, priceCents: 6500 });
    expect(new Date(all.featured.startsAt).getTime()).toBeGreaterThan(Date.now() - 86_400_000);
    expect(titles([all.featured, ...all.items])).toEqual(["casher", "ce soir", "lointain", "pas cher"]);

    const filtered = async (name: string) => {
      const r = (await api(couple.a, `/api/couple/outings?filter=${name}`)).body.data;
      return titles([...(r.featured ? [r.featured] : []), ...r.items]);
    };
    expect(await filtered("tonight")).toEqual(["ce soir"]);
    expect(await filtered("week")).toEqual(["ce soir"]);
    expect(await filtered("kosher")).toEqual(["casher", "ce soir"]);
    expect(await filtered("cheap")).toEqual(["pas cher"]);
    expect(await filtered("mazl")).toEqual(["casher", "ce soir"]);
    expect((await api(couple.a, "/api/couple/outings?filter=sometimes")).status).toBe(400);
  });

  test("the shape of an outing, and 'saved' follows the existing save route", async () => {
    const couple = await makeCouple("outings-saved");
    const find = async () => {
      const r = (await api(couple.a, "/api/couple/outings?filter=cheap")).body.data;
      return [...(r.featured ? [r.featured] : []), ...r.items].find((o: any) => o.id === ids.cheap && o.kind === "activity");
    };
    const before = await find();
    expect(Object.keys(before).sort()).toEqual(["city", "id", "imageUrl", "kind", "kosher", "priceCents", "saved", "startsAt", "subtitle", "title"]);
    expect(before.saved).toBe(false);
    expect((await post(couple.b, `/api/couple/activities/${ids.cheap}/save`, {})).status).toBe(200);
    expect((await find()).saved).toBe(true);
    // another couple did not save it
    const other = await makeCouple("outings-saved-other");
    const seen = (await api(other.a, "/api/couple/outings?filter=cheap")).body.data;
    expect([...(seen.featured ? [seen.featured] : []), ...seen.items].find((o: any) => o.id === ids.cheap && o.kind === "activity").saved).toBe(false);
  });
});

describe("the concierge", () => {
  test("without MAZL Couple every route answers 402 couple_subscription_required", async () => {
    const couple = await makeCouple("concierge-free");
    for (const [method, path, body] of [
      ["GET", "/api/couple/concierge", undefined], ["POST", "/api/couple/concierge", { text: "Un dîner" }], ["GET", "/api/couple/concierge/1", undefined],
      ["POST", "/api/couple/concierge/1/messages", { text: "x" }], ["POST", "/api/couple/concierge/1/choose", { index: 0 }], ["POST", "/api/couple/concierge/1/cancel", undefined],
    ] as const) {
      const res = await api(couple.a, path, { method, ...(body === undefined ? {} : { body: JSON.stringify(body) }) });
      expect([method, path, res.status, res.body.error]).toEqual([method, path, 402, "couple_subscription_required"]);
    }
  });

  test("end to end with the assistant: proposal, both members, choice, the team books", async () => {
    await fakeReset();
    const couple = await makeCouple("concierge-flow", ["Léa", "David"]);
    await grantCouplePlan(couple.a.id);
    const text = "Dîner casher pour notre anniversaire. Écrivez à jeanne.exemple@gmail.com ou appelez le 06 12 34 56 78.";

    // the partner who does not pay writes the request
    const created = await post(couple.b, "/api/couple/concierge", { text, wantedAt: "2026-11-13", city: "Paris", kind: "table", kosher: true, budget: "100 euros" }, { "Accept-Language": "fr" });
    expect(created.status).toBe(201);
    const { request, messages } = created.body.data;
    expect(request).toMatchObject({ status: "proposed", step: 1, wantedAt: "2026-11-13", city: "Paris", kind: "table", constraints: { kosher: true, budget: "100 euros" }, chosenIndex: null });
    expect(request.options).toHaveLength(1);
    expect(messages.map((m: any) => [m.role, m.mine])).toEqual([["member", true], ["assistant", false]]);
    expect(JSON.stringify(request)).not.toMatch(/staffNote|assignedTo/);

    // what left for the assistant
    const sent = await fakeRequests();
    expect(sent).toHaveLength(1);
    expect(sent[0]?.headers["x-api-key"]).toBeTruthy();
    expect(sent[0]?.headers["anthropic-version"]).toBe("2023-06-01");
    expect(sent[0]?.body).toMatchObject({ max_tokens: 600 });
    const wire = JSON.stringify(sent[0]?.body);
    for (const secret of ["jeanne.exemple", "gmail", "06 12 34 56 78", "Exemple", "David", "Léa", couple.a.token, couple.b.token, `media-concierge-flow`]) expect(wire).not.toContain(secret);
    for (const wanted of ["Dîner casher pour notre anniversaire", "2026-11-13", "Paris", "100 euros"]) expect(wire).toContain(wanted);

    // both members see and write in the same request
    const listed = (await api(couple.a, "/api/couple/concierge")).body.data.requests;
    expect(listed.map((r: any) => [r.id, r.status, r.step])).toEqual([[request.id, "proposed", 1]]);
    expect((await api(couple.a, `/api/couple/concierge/${request.id}`)).body.data.messages.map((m: any) => m.mine)).toEqual([false, false]);
    const more = await post(couple.a, `/api/couple/concierge/${request.id}/messages`, { text: "Plutôt vers 20h." });
    expect(more.status).toBe(201);
    expect(more.body.data.messages.filter((m: any) => m.role === "member").map((m: any) => m.mine)).toEqual([false, true]);

    // choose
    expect((await post(couple.a, `/api/couple/concierge/${request.id}/choose`, { index: 5 })).status).toBe(400);
    const chosen = await post(couple.a, `/api/couple/concierge/${request.id}/choose`, { index: 0 });
    expect(chosen.body.data.request).toMatchObject({ status: "chosen", step: 2, chosenIndex: 0 });

    // the team
    const queue = await fetch(`${BASE_URL}/api/backoffice/concierge/requests?status=chosen`, { headers: staff() });
    expect(queue.status).toBe(200);
    const entry = ((await queue.json()) as any).data.requests.find((r: any) => r.id === request.id);
    expect(entry).toMatchObject({ title: "Dîner casher pour notre anniversaire. Écrivez à jeanne.exemple@gmail.com ou appelez le 06 12 34 56 78.".slice(0, 59).trimEnd() + "…", status: "chosen", step: 2, assignedTo: null, couple: { firstNames: ["Léa", "David"] } });
    expect(entry.couple.months).toBeGreaterThanOrEqual(0);

    const detail = ((await (await fetch(`${BASE_URL}/api/backoffice/concierge/requests/${request.id}`, { headers: staff() })).json()) as any).data;
    expect(detail.request).toMatchObject({ id: request.id, brief: text, staffNote: null, assignedTo: null, chosenIndex: 0 });
    expect(detail.couple.firstNames).toEqual(["Léa", "David"]);
    expect(JSON.stringify(detail)).not.toMatch(/gmail\.com"?\s*,\s*"picture|"email"|"phone"/);

    const book = await fetch(`${BASE_URL}/api/backoffice/concierge/requests/${request.id}`, { method: "PATCH", headers: staff(), body: JSON.stringify({ status: "booked", staffNote: "Table confirmée à 20h." }) });
    expect(book.status).toBe(200);
    expect(((await book.json()) as any).data.request).toMatchObject({ status: "booked", staffNote: "Table confirmée à 20h." });
    const reply = await fetch(`${BASE_URL}/api/backoffice/concierge/requests/${request.id}/messages`, { method: "POST", headers: staff(), body: JSON.stringify({ text: "C'est réservé, bonne soirée !" }) });
    expect(reply.status).toBe(201);
    expect(((await reply.json()) as any).data.messages.at(-1)).toMatchObject({ role: "staff", text: "C'est réservé, bonne soirée !" });

    const final = (await api(couple.b, `/api/couple/concierge/${request.id}`)).body.data;
    expect(final.request).toMatchObject({ status: "booked", step: 3 });
    expect(final.messages.at(-1)).toMatchObject({ role: "staff", mine: false });
    expect((await post(couple.a, `/api/couple/concierge/${request.id}/cancel`, {})).status).toBe(409);

    // audited, without the content of the message
    const audit = await db`SELECT action, actor, details FROM audit_log WHERE target_type = 'concierge_request' AND target_id = ${String(request.id)} ORDER BY id`;
    expect(audit.map((row) => row.action)).toEqual(["concierge.update", "concierge.reply"]);
    expect(JSON.stringify(audit)).not.toContain("bonne soirée");
  });

  test("another couple, even with MAZL Couple, finds nothing: 404 on every operation", async () => {
    await fakeReset();
    const mine = await makeCouple("concierge-mine");
    const other = await makeCouple("concierge-other");
    await grantCouplePlan(mine.a.id);
    await grantCouplePlan(other.a.id);
    const created = await post(mine.a, "/api/couple/concierge", { text: "Un week-end surprise" });
    const id = created.body.data.request.id;
    for (const [method, path, body] of [
      ["GET", `/api/couple/concierge/${id}`, undefined], ["POST", `/api/couple/concierge/${id}/messages`, { text: "intrus" }],
      ["POST", `/api/couple/concierge/${id}/choose`, { index: 0 }], ["POST", `/api/couple/concierge/${id}/cancel`, undefined],
    ] as const) {
      const res = await api(other.b, path, { method, ...(body === undefined ? {} : { body: JSON.stringify(body) }) });
      expect([method, path, res.status, res.body.error]).toEqual([method, path, 404, "concierge_not_found"]);
    }
    expect((await api(other.a, "/api/couple/concierge")).body.data.requests).toEqual([]);
    expect((await api(mine.a, `/api/couple/concierge/${id}`)).body.data.request.status).not.toBe("cancelled");
    expect((await api(mine.a, "/api/couple/concierge/999999999")).status).toBe(404);
    expect((await api(mine.a, "/api/couple/concierge/abc")).status).toBe(404);
  });

  test("an assistant that fails or answers nonsense is no error: status new and a message from the team", async () => {
    const couple = await makeCouple("concierge-fallback");
    await grantCouplePlan(couple.a.id);
    for (const mode of ["error", "invalid"]) {
      await fakeMode(mode);
      const created = await post(couple.a, "/api/couple/concierge", { text: `Une idée (${mode}) ?` }, { "Accept-Language": "en" });
      expect(created.status).toBe(201);
      expect(created.body.data.request).toMatchObject({ status: "new", options: [] });
      expect(created.body.data.messages.at(-1)).toMatchObject({ role: "staff" });
      expect(created.body.data.messages.at(-1).text).toContain("MAZL team");
    }
    await fakeMode("ok");
  });

  test("the twenty-first message of the day is a 429, and a closed request takes no more", async () => {
    await fakeReset();
    const couple = await makeCouple("concierge-limit");
    await grantCouplePlan(couple.a.id);
    const created = await post(couple.a, "/api/couple/concierge", { text: "Un cadeau" });
    const id = created.body.data.request.id;
    for (let n = 2; n <= 20; n += 1) expect((await post(couple.b, `/api/couple/concierge/${id}/messages`, { text: `message ${String(n)}` })).status).toBe(201);
    const refused = await post(couple.a, `/api/couple/concierge/${id}/messages`, { text: "de trop" });
    expect(refused.status).toBe(429);
    expect(refused.body.error).toBe("concierge_rate_limited");
    expect((await post(couple.a, "/api/couple/concierge", { text: "une autre demande" })).status).toBe(429);

    const other = await makeCouple("concierge-closed");
    await grantCouplePlan(other.a.id);
    const closed = (await post(other.a, "/api/couple/concierge", { text: "À annuler" })).body.data.request.id;
    expect((await post(other.a, `/api/couple/concierge/${closed}/cancel`, {})).body.data.request.status).toBe("cancelled");
    const again = await post(other.b, `/api/couple/concierge/${closed}/messages`, { text: "encore" });
    expect([again.status, again.body.error]).toEqual([409, "concierge_closed"]);
  });

  test("input is validated: empty, oversized, unknown fields, bad date", async () => {
    const couple = await makeCouple("concierge-validate");
    await grantCouplePlan(couple.a.id);
    for (const body of [{}, { text: "" }, { text: "x".repeat(2001) }, { text: "ok", wantedAt: "2026-02-31" }, { text: "ok", kind: "yacht" }, { text: "ok", name: "Léa Exemple" }]) {
      expect([JSON.stringify(body).slice(0, 40), (await post(couple.a, "/api/couple/concierge", body)).status]).toEqual([JSON.stringify(body).slice(0, 40), 400]);
    }
    expect((await fetch(`${BASE_URL}/api/couple/concierge`, { method: "POST", headers: json(couple.a.token), body: "{pas du json" })).status).toBe(400);
  });
});

describe("concierge: the team side", () => {
  test("only staff with concierge.manage: a member token, no credential or a wrong one are refused", async () => {
    const member = await makeUser("staff-gate");
    for (const headers of [json(member.token), { "Content-Type": "application/json" }, { "x-admin-password": "nope", "Content-Type": "application/json" }]) {
      const res = await fetch(`${BASE_URL}/api/backoffice/concierge/requests`, { headers });
      expect([401, 403]).toContain(res.status);
    }
  });

  test("PATCH rules: booked needs a chosen idea, unknown colleague, empty body, unknown id; assignment to a colleague", async () => {
    await fakeReset();
    const couple = await makeCouple("staff-rules");
    await grantCouplePlan(couple.a.id);
    const id = (await post(couple.a, "/api/couple/concierge", { text: "Une table pour deux" })).body.data.request.id;
    const patch = (body: unknown, target: number | string = id) => fetch(`${BASE_URL}/api/backoffice/concierge/requests/${target}`, { method: "PATCH", headers: staff(), body: JSON.stringify(body) });

    const early = await patch({ status: "booked" });
    expect([early.status, ((await early.json()) as any).error]).toEqual([409, "invalid_transition"]);
    expect((await patch({})).status).toBe(400);
    expect((await patch({ status: "cancelled" })).status).toBe(400);
    expect((await patch({ assignedTo: "inconnu@example.com" })).status).toBe(400);
    expect((await patch({ staffNote: "x" }, 999999999)).status).toBe(404);

    const colleagues = ((await (await fetch(`${BASE_URL}/api/backoffice/concierge/staff`, { headers: staff() })).json()) as any).data.staff;
    expect(colleagues.map((c: any) => c.email)).toContain("admin@example.com");
    expect(colleagues.every((c: any) => typeof c.name === "string" && c.name.length > 0)).toBe(true);
    const assigned = await patch({ assignedTo: "admin@example.com", staffNote: "Je m'en occupe." });
    expect(((await assigned.json()) as any).data.request).toMatchObject({ assignedTo: "admin@example.com", staffNote: "Je m'en occupe." });
    expect(((await (await patch({ assignedTo: null })).json()) as any).data.request.assignedTo).toBeNull();

    const closed = await patch({ status: "closed" });
    expect(closed.status).toBe(200);
    const after = await patch({ staffNote: "trop tard" });
    expect([after.status, ((await after.json()) as any).error]).toEqual([409, "concierge_closed"]);
    const message = await fetch(`${BASE_URL}/api/backoffice/concierge/requests/${id}/messages`, { method: "POST", headers: staff(), body: JSON.stringify({ text: "bonjour" }) });
    expect([message.status, ((await message.json()) as any).error]).toEqual([409, "concierge_closed"]);
  });

  test("a team message is limited to 1000 characters and the queue filters by status", async () => {
    await fakeReset();
    const couple = await makeCouple("staff-limit");
    await grantCouplePlan(couple.a.id);
    const id = (await post(couple.a, "/api/couple/concierge", { text: "Une surprise" })).body.data.request.id;
    const send = (text: string) => fetch(`${BASE_URL}/api/backoffice/concierge/requests/${id}/messages`, { method: "POST", headers: staff(), body: JSON.stringify({ text }) });
    expect((await send("x".repeat(1001))).status).toBe(400);
    expect((await send("x".repeat(1000))).status).toBe(201);
    const proposed = ((await (await fetch(`${BASE_URL}/api/backoffice/concierge/requests?status=proposed`, { headers: staff() })).json()) as any).data.requests;
    expect(proposed.some((r: any) => r.id === id)).toBe(true);
    const chosen = ((await (await fetch(`${BASE_URL}/api/backoffice/concierge/requests?status=chosen`, { headers: staff() })).json()) as any).data.requests;
    expect(chosen.some((r: any) => r.id === id)).toBe(false);
    expect((await fetch(`${BASE_URL}/api/backoffice/concierge/requests?status=weird`, { headers: staff() })).status).toBe(400);
  });

  test("the OpenAPI document is served to staff outside production, and lists the concierge", async () => {
    const res = await fetch(`${BASE_URL}/api/backoffice/couple/openapi`, { headers: staff() });
    expect(res.status).toBe(200);
    expect(Object.keys(((await res.json()) as any).paths)).toContain("/api/couple/concierge/{id}/choose");
    expect((await fetch(`${BASE_URL}/api/backoffice/couple/openapi`)).status).toBe(401);
  });
});
