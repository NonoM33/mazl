import { describe, expect, test } from "bun:test";
import { BASE_URL, auth, db, grantPlus, grantReligiousConsent, json, makeUser, type TestUser } from "./media-helpers";

// Integration against a running server and its Postgres (TEST_API_URL, TEST_DATABASE_URL):
// the advanced filters of Discover are mazl+, apply on the server, live apart
// from the profile and are tied to the art. 9 consent (CONTRAT v1 §2).

const CONSENT_VERSION = "2026-10-24";
const putFilters = (token: string, body: unknown) =>
  fetch(`${BASE_URL}/api/discover/filters`, { method: "PUT", headers: json(token), body: JSON.stringify(body) });
const getFilters = async (token: string) => {
  const res = await fetch(`${BASE_URL}/api/discover/filters`, { headers: auth(token) });
  return { status: res.status, body: (await res.json()) as { success: boolean; plus: boolean; filters: Record<string, unknown> } };
};
const errorOf = async (res: Response) => ((await res.json()) as { error?: string }).error;

// Candidates are born this year - 40 (+ one day), the viewer only looks at
// 38-41: the feed of the test database holds nobody else in that bracket.
const BIRTH_YEAR = new Date().getUTCFullYear() - 40;

interface Candidate { key: string; id: number }

async function profileOf(user: TestUser, gender: "male" | "female", extra: Record<string, unknown> = {}): Promise<void> {
  const res = await fetch(`${BASE_URL}/api/profile`, {
    method: "PUT",
    headers: json(user.token),
    body: JSON.stringify({ displayName: "Jeanne Exemple", birthdate: `${BIRTH_YEAR}-01-02`, gender, lookingFor: gender === "male" ? "female" : "male", ...extra }),
  });
  expect(res.status).toBe(200);
}

async function viewer(label: string): Promise<TestUser> {
  const user = await makeUser(label);
  await profileOf(user, "male", { ageMin: 38, ageMax: 41 });
  return user;
}

// A woman looking for men, with the given stored answers written straight in
// the database (the profile route would drop them without her consent).
async function candidate(
  key: string,
  answers: { denomination?: string; kashrut?: string; shabbat?: string; verification?: string; photo?: boolean },
): Promise<Candidate> {
  const user = await makeUser(`cand-${key}`);
  await profileOf(user, "female");
  await db`
    UPDATE profiles SET denomination = ${answers.denomination ?? null}, kashrut_level = ${answers.kashrut ?? null},
                        shabbat_observance = ${answers.shabbat ?? null}, verification_level = ${answers.verification ?? "none"}
    WHERE user_id = ${user.id}`;
  if (answers.photo === true) {
    await db`INSERT INTO profile_photos (user_id, url, position, is_primary) VALUES (${user.id}, ${`/uploads/${user.id}.jpg`}, 0, true)`;
  }
  return { key, id: user.id };
}

async function feedIds(token: string, path: "discover" | "daily-picks" = "discover"): Promise<number[]> {
  const res = await fetch(`${BASE_URL}/api/${path}${path === "discover" ? "?limit=50" : ""}`, { headers: auth(token) });
  expect(res.status).toBe(200);
  const body = (await res.json()) as { profiles?: { user_id: number }[]; picks?: { user_id: number }[] };
  return (body.profiles ?? body.picks ?? []).map((p) => p.user_id);
}

// Candidates of the earlier tests leave the feed: each test only meets its own.
const retired: number[] = [];

// Four candidates, each failing a different criterion.
async function population() {
  if (retired.length > 0) await db`UPDATE profiles SET is_complete = false WHERE user_id IN ${db(retired)}`;
  const pop = await createPopulation();
  retired.push(...Object.values(pop).map((c) => c.id));
  return pop;
}

async function createPopulation() {
  return {
    devout: await candidate("devout", { denomination: "Massorti", kashrut: "Strict", shabbat: "Observant", verification: "photo", photo: true }),
    secular: await candidate("secular", { denomination: "Laique", kashrut: "Non", shabbat: "Non observant" }),
    silent: await candidate("silent", { verification: "identity", photo: true }),
    bare: await candidate("bare", {}),
  };
}

async function plusViewerWithConsent(label: string): Promise<TestUser> {
  const user = await viewer(label);
  await grantPlus(user.id);
  await grantReligiousConsent(user.token);
  return user;
}

describe("GET/PUT /api/discover/filters", () => {
  test("require authentication", async () => {
    expect((await fetch(`${BASE_URL}/api/discover/filters`)).status).toBe(401);
    const res = await fetch(`${BASE_URL}/api/discover/filters`, { method: "PUT", headers: { "Content-Type": "application/json" }, body: "{}" });
    expect(res.status).toBe(401);
  });

  test("a member who never set a filter reads the empty set and the mazl+ state", async () => {
    const free = await viewer("fresh");
    const { status, body } = await getFilters(free.token);
    expect(status).toBe(200);
    expect(body).toEqual({
      success: true,
      plus: false,
      filters: { denominations: null, kashrutLevels: null, shabbatObservances: null, onlyVerified: false, onlyWithPhoto: false },
    });
  });

  test("a member without mazl+ asking for a criterion gets 402 plus_required, whatever the criterion", async () => {
    const free = await viewer("free");
    await grantReligiousConsent(free.token);
    for (const body of [{ onlyVerified: true }, { onlyWithPhoto: true }, { denominations: ["Massorti"] }, { kashrutLevels: ["Strict"] }, { shabbatObservances: ["Observant"] }]) {
      const res = await putFilters(free.token, body);
      expect([JSON.stringify(body), res.status, await errorOf(res)]).toEqual([JSON.stringify(body), 402, "plus_required"]);
    }
    expect((await getFilters(free.token)).body.filters).toEqual({ denominations: null, kashrutLevels: null, shabbatObservances: null, onlyVerified: false, onlyWithPhoto: false });
  });

  test("a religious criterion without a valid consent gets 409 religious_consent_required; a non-religious one is accepted", async () => {
    const plus = await viewer("noconsent");
    await grantPlus(plus.id);
    const refused = await putFilters(plus.token, { denominations: ["Massorti"] });
    expect(refused.status).toBe(409);
    expect(await errorOf(refused)).toBe("religious_consent_required");
    const accepted = await putFilters(plus.token, { onlyVerified: true });
    expect(accepted.status).toBe(200);
    expect(((await accepted.json()) as { filters: { onlyVerified: boolean } }).filters.onlyVerified).toBe(true);
  });

  test("a consent given to an outdated wording is not a consent: the API refuses it before, so the filter is refused too", async () => {
    const plus = await viewer("oldconsent");
    await grantPlus(plus.id);
    await db`INSERT INTO user_consents (user_id, purpose, granted, version, source) VALUES (${plus.id}, 'religious_data', true, '2025-01-01', 'app')`;
    expect((await putFilters(plus.token, { kashrutLevels: ["Strict"] })).status).toBe(409);
  });

  test("validation: unknown fields, too long answers, wrong types answer 400 with the field", async () => {
    const plus = await plusViewerWithConsent("invalid");
    for (const [body, field] of [
      [{ education: "Master" }, ""],
      [{ heightMin: 150 }, ""],
      [{ onlyOnline: true }, ""],
      [{ denominations: "Massorti" }, "denominations"],
      [{ denominations: [3] }, "denominations"],
      [{ kashrutLevels: ["x".repeat(51)] }, "kashrutLevels"],
      [{ shabbatObservances: Array.from({ length: 41 }, (_, i) => `a${i}`) }, "shabbatObservances"],
      [{ onlyVerified: "yes" }, "onlyVerified"],
    ] as const) {
      const res = await putFilters(plus.token, body);
      expect([JSON.stringify(body), res.status]).toEqual([JSON.stringify(body), 400]);
      const error = (await errorOf(res)) ?? "";
      expect(error).toContain(field);
    }
    const notJson = await fetch(`${BASE_URL}/api/discover/filters`, { method: "PUT", headers: json(plus.token), body: "{nope" });
    expect(notJson.status).toBe(400);
  });

  test("a subscriber saves, updates partially and clears criteria; the response is the stored set", async () => {
    const plus = await plusViewerWithConsent("save");
    const saved = await putFilters(plus.token, { denominations: [" Massorti", "Orthodox", "massorti"], onlyWithPhoto: true });
    expect(saved.status).toBe(200);
    expect(await saved.json()).toEqual({
      success: true,
      filters: { denominations: ["Massorti", "Orthodox"], kashrutLevels: null, shabbatObservances: null, onlyVerified: false, onlyWithPhoto: true },
    });
    const partial = await putFilters(plus.token, { kashrutLevels: ["Strict"] });
    expect(((await partial.json()) as { filters: Record<string, unknown> }).filters).toEqual({
      denominations: ["Massorti", "Orthodox"], kashrutLevels: ["Strict"], shabbatObservances: null, onlyVerified: false, onlyWithPhoto: true,
    });
    const cleared = await putFilters(plus.token, { denominations: null, kashrutLevels: [], onlyWithPhoto: false });
    expect(((await cleared.json()) as { filters: Record<string, unknown> }).filters).toEqual({
      denominations: null, kashrutLevels: null, shabbatObservances: null, onlyVerified: false, onlyWithPhoto: false,
    });
  });

  test("saving filters never touches the member's own profile, and the profile route stores no filter", async () => {
    const plus = await plusViewerWithConsent("separate");
    await db`UPDATE profiles SET denomination = 'Massorti', kashrut_level = 'Strict', shabbat_observance = 'Observant' WHERE user_id = ${plus.id}`;
    expect((await putFilters(plus.token, { denominations: ["Orthodox"], kashrutLevels: ["Glatt"], shabbatObservances: ["Tres observant"] })).status).toBe(200);
    const [own] = await db<{ denomination: string; kashrut_level: string; shabbat_observance: string }[]>`
      SELECT denomination, kashrut_level, shabbat_observance FROM profiles WHERE user_id = ${plus.id}`;
    expect(own).toEqual({ denomination: "Massorti", kashrut_level: "Strict", shabbat_observance: "Observant" });

    const other = await plusViewerWithConsent("profileroute");
    const res = await fetch(`${BASE_URL}/api/profile`, {
      method: "PUT",
      headers: json(other.token),
      body: JSON.stringify({ observances: ["Casher"], onlyVerified: true, onlyWithPhoto: true, education: "Master" }),
    });
    expect(res.status).toBe(200);
    expect(await db`SELECT 1 FROM discover_filters WHERE user_id = ${other.id}`).toHaveLength(0);
  });
});

describe("the feed applies the filters", () => {
  test("a subscriber with consent only sees the profiles that fit; whoever did not answer is left out", async () => {
    const pop = await population();
    const plus = await plusViewerWithConsent("feed");
    const before = await feedIds(plus.token);
    for (const c of Object.values(pop)) expect(before).toContain(c.id);

    expect((await putFilters(plus.token, { denominations: ["massorti", "Orthodox"] })).status).toBe(200);
    expect(await feedIds(plus.token)).toEqual([pop.devout.id]);

    expect((await putFilters(plus.token, { denominations: null, kashrutLevels: ["Non"] })).status).toBe(200);
    expect(await feedIds(plus.token)).toEqual([pop.secular.id]);

    expect((await putFilters(plus.token, { kashrutLevels: null, shabbatObservances: ["Observant", "Non observant"] })).status).toBe(200);
    expect((await feedIds(plus.token)).sort()).toEqual([pop.devout.id, pop.secular.id].sort());
  });

  test("onlyVerified keeps the selfie and identity checks, onlyWithPhoto the profiles with a photo, and both combine", async () => {
    const pop = await population();
    const plus = await plusViewerWithConsent("feedflags");
    await putFilters(plus.token, { onlyVerified: true });
    expect((await feedIds(plus.token)).sort()).toEqual([pop.devout.id, pop.silent.id].sort());
    await putFilters(plus.token, { onlyVerified: false, onlyWithPhoto: true });
    expect((await feedIds(plus.token)).sort()).toEqual([pop.devout.id, pop.silent.id].sort());
    await putFilters(plus.token, { onlyVerified: true, onlyWithPhoto: true, denominations: ["Massorti"] });
    expect(await feedIds(plus.token)).toEqual([pop.devout.id]);
  });

  test("the daily picks follow the same filters", async () => {
    const pop = await population();
    const plus = await plusViewerWithConsent("picks");
    await putFilters(plus.token, { denominations: ["Laique"] });
    expect(await feedIds(plus.token, "daily-picks")).toEqual([pop.secular.id]);
  });

  test("an expired mazl+ keeps the criteria but stops applying them", async () => {
    const pop = await population();
    const plus = await plusViewerWithConsent("expired");
    await putFilters(plus.token, { denominations: ["Massorti"], onlyVerified: true });
    expect(await feedIds(plus.token)).toEqual([pop.devout.id]);

    await db`UPDATE subscriptions SET expires_at = (NOW() AT TIME ZONE 'UTC') - INTERVAL '1 day' WHERE user_id = ${plus.id}`;
    const everyone = await feedIds(plus.token);
    for (const c of Object.values(pop)) expect(everyone).toContain(c.id);
    const stored = await getFilters(plus.token);
    expect(stored.body.plus).toBe(false);
    expect(stored.body.filters.denominations).toEqual(["Massorti"]);
    expect(stored.body.filters.onlyVerified).toBe(true);

    await grantPlus(plus.id);
    expect(await feedIds(plus.token)).toEqual([pop.devout.id]);
  });

  test("a member who subscribed, filtered then lost the right to clear criteria can still clear them", async () => {
    const plus = await plusViewerWithConsent("clear");
    await putFilters(plus.token, { onlyWithPhoto: true });
    await db`UPDATE subscriptions SET expires_at = (NOW() AT TIME ZONE 'UTC') - INTERVAL '1 day' WHERE user_id = ${plus.id}`;
    const res = await putFilters(plus.token, { onlyWithPhoto: false });
    expect(res.status).toBe(200);
  });
});

describe("art. 9 consent and the filters", () => {
  test("withdrawing the consent erases the religious criteria and keeps the others", async () => {
    const pop = await population();
    const plus = await plusViewerWithConsent("withdraw");
    await putFilters(plus.token, { denominations: ["Massorti"], kashrutLevels: ["Strict"], shabbatObservances: ["Observant"], onlyVerified: true });
    expect(await feedIds(plus.token)).toEqual([pop.devout.id]);

    const withdrawn = await fetch(`${BASE_URL}/api/privacy/consents/religious_data`, {
      method: "PUT",
      headers: json(plus.token),
      body: JSON.stringify({ granted: false, version: CONSENT_VERSION, source: "app" }),
    });
    expect(withdrawn.status).toBe(200);

    const [row] = await db<{ denominations: string[] | null; kashrut_levels: string[] | null; shabbat_observances: string[] | null; only_verified: boolean }[]>`
      SELECT denominations, kashrut_levels, shabbat_observances, only_verified FROM discover_filters WHERE user_id = ${plus.id}`;
    expect(row).toEqual({ denominations: null, kashrut_levels: null, shabbat_observances: null, only_verified: true });
    expect((await getFilters(plus.token)).body.filters).toEqual({
      denominations: null, kashrutLevels: null, shabbatObservances: null, onlyVerified: true, onlyWithPhoto: false,
    });
    // Only "verified" is left: the secular candidate is no longer filtered out by religion.
    expect(await feedIds(plus.token)).not.toContain(pop.bare.id);
    expect(await feedIds(plus.token)).toContain(pop.silent.id);
  });

  test("refusing the consent does not fail when the member never had filters", async () => {
    const member = await viewer("noconsent-refuse");
    const res = await fetch(`${BASE_URL}/api/privacy/consents/religious_data`, {
      method: "PUT",
      headers: json(member.token),
      body: JSON.stringify({ granted: false, version: CONSENT_VERSION, source: "app" }),
    });
    expect(res.status).toBe(200);
  });
});

describe("the member's data rights", () => {
  test("the export lists the filters and the erasure of the account removes them", async () => {
    const plus = await plusViewerWithConsent("rgpd");
    await putFilters(plus.token, { denominations: ["Massorti"], onlyWithPhoto: true });

    const exported = await fetch(`${BASE_URL}/api/users/me/export`, { headers: auth(plus.token) });
    expect(exported.status).toBe(200);
    const document = (await exported.json()) as { discover_filters: Record<string, unknown> | null };
    expect(document.discover_filters).toEqual({
      denominations: ["Massorti"], kashrut_levels: null, shabbat_observances: null, only_verified: false, only_with_photo: true,
      updated_at: expect.any(String),
    });

    const deleted = await fetch(`${BASE_URL}/api/users/me`, {
      method: "DELETE",
      headers: json(plus.token),
      body: JSON.stringify({ reason: "Test" }),
    });
    expect(deleted.status).toBe(200);
    expect(await db`SELECT 1 FROM discover_filters WHERE user_id = ${plus.id}`).toHaveLength(0);
  });

  test("a member without filters has a null section in the export", async () => {
    const member = await viewer("rgpd-empty");
    const document = (await (await fetch(`${BASE_URL}/api/users/me/export`, { headers: auth(member.token) })).json()) as { discover_filters: unknown };
    expect(document.discover_filters).toBeNull();
  });
});
