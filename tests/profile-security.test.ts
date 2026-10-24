import { describe, expect, test } from "bun:test";
import { BASE_URL, auth, db, json, makeUser, type TestUser } from "./media-helpers";

// Attack scenarios against the profile routes. Needs a running server
// (TEST_API_URL) and its database (TEST_DATABASE_URL). Every test builds its
// own members so that the suites can run in any order.

async function completeProfile(user: TestUser, fields: { gender?: string; lookingFor?: string } = {}): Promise<void> {
  await db`
    UPDATE profiles
    SET is_complete = true, display_name = ${`Membre ${user.id}`}, birthdate = '1995-04-12',
        gender = ${fields.gender ?? "female"}, looking_for = ${fields.lookingFor ?? "male"}
    WHERE user_id = ${user.id}
  `;
}

const getProfile = (viewer: TestUser, targetId: number) =>
  fetch(`${BASE_URL}/api/profile/${targetId}`, { headers: auth(viewer.token) });

const putProfile = (user: TestUser, body: unknown) =>
  fetch(`${BASE_URL}/api/profile`, { method: "PUT", headers: json(user.token), body: JSON.stringify(body) });

const block = (blocker: TestUser, blockedId: number) =>
  fetch(`${BASE_URL}/api/users/${blockedId}/block`, { method: "POST", headers: json(blocker.token) });

describe("GET /api/profile/:userId only shows what the viewer may see", () => {
  test("a member who blocked the viewer is indistinguishable from a missing member", async () => {
    const viewer = await makeUser("pv-viewer");
    const target = await makeUser("pv-blocker");
    await completeProfile(target);
    expect((await getProfile(viewer, target.id)).status).toBe(200);

    expect((await block(target, viewer.id)).status).toBe(200);
    const hidden = await getProfile(viewer, target.id);
    const missing = await getProfile(viewer, 2_000_000_000);
    expect(hidden.status).toBe(404);
    expect(await hidden.text()).toBe(await missing.text());
  });

  test("a member the viewer blocked is hidden as well", async () => {
    const viewer = await makeUser("pv-blocked-by-me");
    const target = await makeUser("pv-target");
    await completeProfile(target);
    await block(viewer, target.id);
    const res = await getProfile(viewer, target.id);
    expect(res.status).toBe(404);
    expect(JSON.stringify(await res.json())).not.toContain("looking_for");
  });

  test("a banned or deactivated account is not served", async () => {
    const viewer = await makeUser("pv-viewer-inactive");
    const target = await makeUser("pv-inactive");
    await completeProfile(target);
    await db`UPDATE users SET is_active = false WHERE id = ${target.id}`;
    const res = await getProfile(viewer, target.id);
    expect(res.status).toBe(404);
    expect(await res.text()).toBe(await (await getProfile(viewer, 2_000_000_000)).text());
  });

  test("a profile that is not complete is not served to others, but stays readable by its owner", async () => {
    const viewer = await makeUser("pv-viewer-incomplete");
    const target = await makeUser("pv-incomplete");
    expect((await getProfile(viewer, target.id)).status).toBe(404);

    const own = await getProfile(target, target.id);
    expect(own.status).toBe(200);
    const body = (await own.json()) as { profile: { email?: string } };
    expect(body.profile.email).toContain("@");
  });
});

// ---------------------------------------------------------------------------
// Majority and plausible ranges

function isoDate(yearsAgo: number, dayOffset = 0): string {
  const now = new Date();
  const d = new Date(Date.UTC(now.getUTCFullYear() - yearsAgo, now.getUTCMonth(), now.getUTCDate() + dayOffset));
  return d.toISOString().slice(0, 10);
}

const storedProfile = async (user: TestUser) => {
  const [row] = await db<{ birthdate: string | null; age_min: number; age_max: number; bio: string | null }[]>`
    SELECT to_char(birthdate, 'YYYY-MM-DD') AS birthdate, age_min, age_max, bio FROM profiles WHERE user_id = ${user.id}
  `;
  if (!row) throw new Error("profile row missing");
  return row;
};

describe("PUT /api/profile refuses minors and impossible dates", () => {
  test("a minor cannot register a birthdate, and nothing is stored", async () => {
    const user = await makeUser("maj-minor");
    const res = await putProfile(user, { birthdate: isoDate(15) });
    expect(res.status).toBe(400);
    expect((await storedProfile(user)).birthdate).toBeNull();
  });

  test("the 18th birthday is the limit, to the day", async () => {
    const user = await makeUser("maj-limit");
    expect((await putProfile(user, { birthdate: isoDate(18, 1) })).status).toBe(400);
    expect((await putProfile(user, { birthdate: isoDate(18) })).status).toBe(200);
    expect((await storedProfile(user)).birthdate).toBe(isoDate(18));
  });

  test.each([
    ["not a date", "hier"],
    ["month 13", "2000-13-01"],
    ["31 February", "2000-02-31"],
    ["no zero padding", "2000-1-5"],
    ["with a time", "2000-01-05T00:00:00Z"],
    ["in the future", isoDate(-2)],
    ["older than 120 years", isoDate(121)],
    ["a number", 19990101],
  ])("a birthdate that is %s is a 400, never a 500", async (_label, birthdate) => {
    const user = await makeUser("maj-bad");
    expect((await putProfile(user, { birthdate })).status).toBe(400);
  });

  test("a regular adult birthdate is still accepted", async () => {
    const user = await makeUser("maj-ok");
    expect((await putProfile(user, { birthdate: "1994-03-12" })).status).toBe(200);
  });
});

describe("PUT /api/profile bounds the preferred age range", () => {
  test.each([
    ["ageMin under 18", { ageMin: 5 }],
    ["ageMin negative", { ageMin: -3 }],
    ["ageMax over 99", { ageMax: 500 }],
    ["min above max", { ageMin: 40, ageMax: 30 }],
    ["fractional age", { ageMin: 25.5 }],
  ])("%s is refused and stored nowhere", async (_label, body) => {
    const user = await makeUser("age-bad");
    const before = await storedProfile(user);
    expect((await putProfile(user, body)).status).toBe(400);
    const after = await storedProfile(user);
    expect([after.age_min, after.age_max]).toEqual([before.age_min, before.age_max]);
  });

  test("a single bound that contradicts the stored one is refused", async () => {
    const user = await makeUser("age-half");
    expect((await putProfile(user, { ageMin: 20, ageMax: 30 })).status).toBe(200);
    expect((await putProfile(user, { ageMin: 45 })).status).toBe(400);
    expect((await putProfile(user, { ageMax: 19 })).status).toBe(400);
  });

  test("the ranges the app really sends are accepted", async () => {
    const user = await makeUser("age-ok");
    expect((await putProfile(user, { ageMin: 18, ageMax: 99, distanceMax: 100 })).status).toBe(200);
    expect((await putProfile(user, { ageMin: 22, ageMax: 35 })).status).toBe(200);
  });
});

// ---------------------------------------------------------------------------
// Content bounds

const repeat = (n: number): string => "a".repeat(n);

describe("PUT /api/profile bounds free text and closed lists", () => {
  test("bio, display name and location have a length limit", async () => {
    const user = await makeUser("len");
    expect((await putProfile(user, { bio: repeat(1001) })).status).toBe(400);
    expect((await putProfile(user, { displayName: repeat(51) })).status).toBe(400);
    expect((await putProfile(user, { location: repeat(101) })).status).toBe(400);
    expect((await storedProfile(user)).bio).toBeNull();
    expect((await putProfile(user, { bio: repeat(1000), displayName: repeat(50), location: repeat(100) })).status).toBe(200);
  });

  test("gender and lookingFor accept only the values the app offers", async () => {
    const user = await makeUser("enum");
    expect((await putProfile(user, { gender: "attack helicopter" })).status).toBe(400);
    expect((await putProfile(user, { lookingFor: "<script>alert(1)</script>" })).status).toBe(400);
    expect((await putProfile(user, { gender: "male", lookingFor: "female" })).status).toBe(200);
  });

  test("denomination, kashrut and shabbat are capped at their column width", async () => {
    const user = await makeUser("cap");
    for (const field of ["denomination", "kashrutLevel", "shabbatObservance"]) {
      expect([field, (await putProfile(user, { [field]: repeat(51) })).status]).toEqual([field, 400]);
    }
    const sent = { denomination: "Modern Orthodox", kashrutLevel: "A la maison", shabbatObservance: "Tres observant" };
    expect((await putProfile(user, sent)).status).toBe(200);
  });

  test("an explicit null (the edit screen sends one for an unset field) leaves the field alone", async () => {
    const user = await makeUser("null");
    expect((await putProfile(user, { denomination: "Massorti" })).status).toBe(200);
    expect((await putProfile(user, { denomination: null, bio: null })).status).toBe(200);
  });
});

describe("a profile becomes visible once name, birthdate and gender are known", () => {
  test("the profile setup of the app makes the member discoverable by others", async () => {
    const member = await makeUser("done");
    const viewer = await makeUser("done-viewer");
    expect((await getProfile(viewer, member.id)).status).toBe(404);

    expect((await putProfile(member, { displayName: "Noa", birthdate: "1994-03-12", gender: "female", lookingFor: "male" })).status).toBe(200);
    expect((await getProfile(viewer, member.id)).status).toBe(200);
  });

  test("a half-filled profile stays hidden", async () => {
    const member = await makeUser("half");
    const viewer = await makeUser("half-viewer");
    await putProfile(member, { displayName: "Noa", bio: "Bonjour" });
    expect((await getProfile(viewer, member.id)).status).toBe(404);
  });
});

// ---------------------------------------------------------------------------
// Profile prompts

const postPrompt = (user: TestUser, body: unknown) =>
  fetch(`${BASE_URL}/api/profile/prompts`, { method: "POST", headers: json(user.token), body: JSON.stringify(body) });

const promptCount = async (user: TestUser): Promise<number> => {
  const [row] = await db<{ n: string }[]>`SELECT COUNT(*) AS n FROM profile_prompts WHERE user_id = ${user.id}`;
  return Number(row?.n);
};

const catalogIds = async (): Promise<string[]> => {
  const res = await fetch(`${BASE_URL}/api/prompts`);
  return ((await res.json()) as { prompts: Array<{ id: string }> }).prompts.map((p) => p.id);
};

describe("profile prompts", () => {
  test("a prompt id outside the catalogue is refused", async () => {
    const user = await makeUser("pr-unknown");
    expect((await postPrompt(user, { prompt_id: "nothing_like_it", answer: "Salut", position: 1 })).status).toBe(400);
    expect((await postPrompt(user, { prompt_id: "x".repeat(5000), answer: "Salut", position: 1 })).status).toBe(400);
    expect(await promptCount(user)).toBe(0);
  });

  test("an answer is 300 characters at most, on creation and on update", async () => {
    const user = await makeUser("pr-long");
    const [first] = await catalogIds();
    expect((await postPrompt(user, { prompt_id: first, answer: repeat(301), position: 1 })).status).toBe(400);
    expect((await postPrompt(user, { prompt_id: first, answer: "   ", position: 1 })).status).toBe(400);
    const created = await postPrompt(user, { prompt_id: first, answer: repeat(300), position: 1 });
    expect(created.status).toBe(201);
    const { prompt } = (await created.json()) as { prompt: { id: number } };
    const update = (answer: string) =>
      fetch(`${BASE_URL}/api/profile/prompts/${prompt.id}`, { method: "PUT", headers: json(user.token), body: JSON.stringify({ answer }) });
    expect((await update(repeat(301))).status).toBe(400);
    expect((await update("Plus court")).status).toBe(200);
  });

  test("eight simultaneous additions still leave three prompts at most", async () => {
    const user = await makeUser("pr-race");
    const ids = await catalogIds();
    const results = await Promise.all(
      ids.slice(0, 8).map((id, i) => postPrompt(user, { prompt_id: id, answer: `Réponse ${i}`, position: i })),
    );
    expect(results.filter((r) => r.status === 201)).toHaveLength(3);
    expect(await promptCount(user)).toBe(3);
  });
});
