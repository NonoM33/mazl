import { afterAll, beforeAll, describe, expect, test } from "bun:test";
import type { Subprocess } from "bun";
import { join } from "node:path";
import { BASE_URL, auth, db, json, makeUser, type TestUser } from "./media-helpers";

// docs/launch/REVIEW-LOGIN-CONTRAT.md: the App Store reviewer signs in with a user
// name and a password. This boots a second server on the test database with
// the two REVIEW_LOGIN_* variables (the shared test server has none: there the
// route must not exist) and plays the real HTTP flow.

const PORT = 3000 + Math.floor(Math.random() * 900) + 6200;
const REVIEW = `http://127.0.0.1:${PORT}`;
const USERNAME = `relecteur-${Date.now()}`;
const PASSWORD = "exemple-motdepasse";
let server: Subprocess | null = null;

beforeAll(async () => {
  const env = {
    ...(process.env as Record<string, string>),
    PORT: String(PORT),
    REVIEW_LOGIN_USERNAME: USERNAME,
    REVIEW_LOGIN_PASSWORD_HASH: await Bun.password.hash(PASSWORD),
  };
  server = Bun.spawn(["bun", join(import.meta.dir, "../src/index.ts")], { env, stdout: "ignore", stderr: "ignore" });
  for (let i = 0; i < 150; i++) {
    try {
      if ((await fetch(`${REVIEW}/api/health`)).ok) return;
    } catch {
      // not listening yet
    }
    await Bun.sleep(100);
  }
  throw new Error("second server did not start");
}, 30_000);

afterAll(async () => {
  server?.kill();
  await server?.exited;
});

interface ReviewAnswer {
  readonly success?: boolean;
  readonly error?: string;
  readonly token?: string;
  readonly user?: { id: number; email: string; provider: string; isNew: boolean; hasProfile: boolean };
}

async function signIn(body: unknown, base = REVIEW): Promise<{ status: number; body: ReviewAnswer }> {
  const response = await fetch(`${base}/api/auth/review`, { method: "POST", headers: { "content-type": "application/json" }, body: JSON.stringify(body) });
  return { status: response.status, body: (await response.json()) as ReviewAnswer };
}

async function reviewer(): Promise<{ id: number; token: string }> {
  const { status, body } = await signIn({ username: USERNAME, password: PASSWORD });
  if (status !== 200 || body.token === undefined || body.user === undefined) throw new Error(`review sign-in refused: ${status}`);
  return { id: body.user.id, token: body.token };
}

describe("review sign-in", () => {
  test("does not exist on a server without the REVIEW_LOGIN_* variables", async () => {
    const { status } = await signIn({ username: USERNAME, password: PASSWORD }, BASE_URL);
    expect(status).toBe(404);
  });

  test("the right pair opens a session on a complete profile", async () => {
    const { status, body } = await signIn({ username: USERNAME, password: PASSWORD });
    expect(status).toBe(200);
    expect(body.user?.provider).toBe("review");
    expect(body.user?.hasProfile).toBe(true);

    const me = await fetch(`${REVIEW}/api/auth/me`, { headers: auth(body.token ?? "") });
    expect(me.status).toBe(200);
    const profile = (await me.json()) as { user: { id: number }; missing: string[] };
    expect(profile.user.id).toBe(body.user?.id ?? -1);
    expect(profile.missing).toEqual([]);
  });

  test("signing in again is the same account and keeps what the reviewer changed", async () => {
    const first = await reviewer();
    await db`UPDATE profiles SET bio = 'Modifié par le relecteur' WHERE user_id = ${first.id}`;
    const { body } = await signIn({ username: USERNAME, password: PASSWORD });
    expect(body.user?.id).toBe(first.id);
    expect(body.user?.isNew).toBe(false);
    const [row] = await db<{ bio: string }[]>`SELECT bio FROM profiles WHERE user_id = ${first.id}`;
    expect(row?.bio).toBe("Modifié par le relecteur");
  });

  test("a wrong password and a wrong user name get the same answer", async () => {
    const wrongPassword = await signIn({ username: USERNAME, password: "autre-motdepasse" });
    const wrongUser = await signIn({ username: "autre", password: PASSWORD });
    expect(wrongPassword).toEqual({ status: 401, body: { success: false, error: "invalid_credentials" } });
    expect(wrongUser).toEqual(wrongPassword);
  });

  test("a body without both fields is refused", async () => {
    expect(await signIn({ username: USERNAME })).toEqual({ status: 400, body: { success: false, error: "credentials_required" } });
  });
});

describe("the review account stays out of sight", () => {
  // Born 77 years ago: the test database holds nobody else at that age, so the
  // feed of a viewer looking at 76-78 only holds the members made here.
  const birthYear = new Date().getUTCFullYear() - 77;
  let viewer: TestUser;
  let control: TestUser;
  let reviewId: number;

  const putProfile = (user: TestUser, gender: "male" | "female", extra: Record<string, unknown> = {}) =>
    fetch(`${BASE_URL}/api/profile`, {
      method: "PUT",
      headers: json(user.token),
      body: JSON.stringify({ displayName: "Jeanne Exemple", birthdate: `${birthYear}-01-02`, gender, lookingFor: gender === "male" ? "female" : "male", ...extra }),
    });

  const feed = async (path: "discover" | "daily-picks"): Promise<number[]> => {
    const res = await fetch(`${BASE_URL}/api/${path}${path === "discover" ? "?limit=50" : ""}`, { headers: auth(viewer.token) });
    expect(res.status).toBe(200);
    const body = (await res.json()) as { profiles?: { user_id: number }[]; picks?: { user_id: number }[] };
    return (body.profiles ?? body.picks ?? []).map((p) => p.user_id);
  };

  beforeAll(async () => {
    reviewId = (await reviewer()).id;
    await db`UPDATE profiles SET birthdate = ${`${birthYear}-01-02`}, age_min = 18, age_max = 99, distance_max = NULL WHERE user_id = ${reviewId}`;
    control = await makeUser("review-control");
    expect((await putProfile(control, "male", { ageMin: 18, ageMax: 99 })).status).toBe(200);
    viewer = await makeUser("review-viewer");
    expect((await putProfile(viewer, "female", { ageMin: 76, ageMax: 78 })).status).toBe(200);
  });

  test("Discover offers an ordinary member of the same age, never the review account", async () => {
    const ids = await feed("discover");
    expect(ids).toContain(control.id);
    expect(ids).not.toContain(reviewId);
  });

  test("nor do the daily picks", async () => {
    expect(await feed("daily-picks")).not.toContain(reviewId);
  });
});

describe("review sign-in rate limit", () => {
  // Last: it uses up this address's tries on the second server.
  test("ten tries per quarter of an hour, then 429", async () => {
    const statuses: number[] = [];
    for (let i = 0; i < 12; i++) statuses.push((await signIn({ username: USERNAME, password: "devine" })).status);
    expect(statuses).toContain(429);
    expect(statuses.filter((status) => status === 401).length).toBeLessThanOrEqual(10);
  });
});
