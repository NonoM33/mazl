import { test, expect, describe, beforeAll, afterAll } from "bun:test";
import postgres from "postgres";
import { backfillProfileCompleteness } from "../src/db";
import { THROWAWAY_CREDENTIAL } from "./throwaway-credential";

// Integration regression for the TestFlight report "the app never asked me if I
// am a man or a woman, and Discover only shows me men — and I am a man".
// Runs the REAL discovery SQL. Requires a running server (TEST_API_URL) with
// dev endpoints on, and DATABASE_URL pointing at the same Postgres.
const BASE_URL = process.env.TEST_API_URL || "http://localhost:3000";
const DATABASE_URL = process.env.DATABASE_URL || "postgres://postgres:postgres@localhost:5432/mazl";

interface Member { id: number; token: string }

const sql = postgres(DATABASE_URL);
const H = (t: string): Record<string, string> => ({ "Content-Type": "application/json", Authorization: `Bearer ${t}` });
const run = `${Date.now()}-${Math.floor(performance.now())}`;

async function makeMember(label: string, profile?: { gender: string; lookingFor: string }): Promise<Member> {
  const res = await fetch(`${BASE_URL}/api/dev/test-user`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ email: `dp-${label}-${run}@mazl.app`, password: THROWAWAY_CREDENTIAL, name: `DP ${label}` }),
  });
  const data = (await res.json()) as { success: boolean; user?: { id: number }; token?: string };
  if (!data.success || !data.user || !data.token) throw new Error(`makeMember(${label}): ${JSON.stringify(data)}`);
  const member = { id: data.user.id, token: data.token };
  if (profile) {
    const put = await fetch(`${BASE_URL}/api/profile`, {
      method: "PUT",
      headers: H(member.token),
      body: JSON.stringify({ displayName: label, birthdate: "1995-06-15", ...profile }),
    });
    if (put.status !== 200) throw new Error(`profile(${label}): ${put.status}`);
  }
  return member;
}

async function discover(member: Member): Promise<{ status: number; body: { profiles?: Array<{ user_id: number; gender: string }>; error?: string; missing?: string[] } }> {
  const r = await fetch(`${BASE_URL}/api/discover?limit=100`, { headers: H(member.token) });
  return { status: r.status, body: (await r.json()) as never };
}

let menSeekingWomen: Member;
let womenSeekingMen: Member;
let womenSeekingWomen: Member;
let noPreferences: Member;
let manNoLookingFor: Member;
let manSeekingWomen: Member;
let womanSeekingMen: Member;

beforeAll(async () => {
  menSeekingWomen = await makeMember("man-w", { gender: "male", lookingFor: "female" });
  womenSeekingMen = await makeMember("woman-m", { gender: "female", lookingFor: "male" });
  womenSeekingWomen = await makeMember("woman-w", { gender: "female", lookingFor: "female" });
  noPreferences = await makeMember("blank");
  manSeekingWomen = await makeMember("me-man", { gender: "male", lookingFor: "female" });
  womanSeekingMen = await makeMember("me-woman", { gender: "female", lookingFor: "male" });
  manNoLookingFor = await makeMember("man-null");
  await fetch(`${BASE_URL}/api/profile`, {
    method: "PUT",
    headers: H(manNoLookingFor.token),
    body: JSON.stringify({ displayName: "man-null", birthdate: "1995-06-15", gender: "male" }),
  });
});

afterAll(async () => {
  await sql.end();
});

async function isComplete(member: Member): Promise<boolean> {
  const rows = await sql<{ is_complete: boolean | null }[]>`SELECT is_complete FROM profiles WHERE user_id = ${member.id}`;
  return rows[0]?.is_complete === true;
}

async function put(member: Member, body: Record<string, unknown>): Promise<number> {
  const r = await fetch(`${BASE_URL}/api/profile`, { method: "PUT", headers: H(member.token), body: JSON.stringify(body) });
  return r.status;
}

describe("A member becomes visible by completing the profile through PUT /api/profile", () => {
  test("completing the setup makes the member appear in a compatible member's feed", async () => {
    const newcomer = await makeMember("newcomer");
    expect(await isComplete(newcomer)).toBe(false);
    expect((await discover(womanSeekingMen)).body.profiles?.map((p) => p.user_id)).not.toContain(newcomer.id);

    expect(await put(newcomer, {
      displayName: "Newcomer", birthdate: "1994-03-02", gender: "male", lookingFor: "female",
    })).toBe(200);

    expect(await isComplete(newcomer)).toBe(true);
    expect((await discover(womanSeekingMen)).body.profiles?.map((p) => p.user_id)).toContain(newcomer.id);
  });

  test("a member still missing a required field stays out of the feeds", async () => {
    const half = await makeMember("half");
    expect(await put(half, { displayName: "Half", birthdate: "1994-03-02", gender: "male" })).toBe(200);
    expect(await isComplete(half)).toBe(false);
    expect((await discover(womanSeekingMen)).body.profiles?.map((p) => p.user_id)).not.toContain(half.id);
  });

  // The server refuses a minor at the door (400 on PUT /api/profile, MIN_MEMBER_AGE
  // in the validation) instead of storing the profile as incomplete: a minor
  // never has a profile that could ever become visible.
  test("a minor is refused, stays incomplete and never reaches a feed", async () => {
    const minor = await makeMember("minor");
    const year = new Date().getUTCFullYear() - 16;
    expect(await put(minor, { displayName: "Minor", birthdate: `${year}-01-01`, gender: "male", lookingFor: "female" })).toBe(400);
    expect(await isComplete(minor)).toBe(false);
    expect((await discover(womanSeekingMen)).body.profiles?.map((p) => p.user_id)).not.toContain(minor.id);
  });

  test("the day before the 18th birthday is refused, the 18th birthday itself is accepted", async () => {
    const today = new Date();
    const [year, month, day] = [today.getUTCFullYear() - 18, today.getUTCMonth(), today.getUTCDate()];
    const iso = (ms: number) => new Date(ms).toISOString().slice(0, 10);
    const tomorrow18YearsAgo = iso(Date.UTC(year, month, day + 1));
    // 29 February has no 18th anniversary in a common year: the day before stands for it.
    const turns18Today = new Date(Date.UTC(year, month, day)).getUTCMonth() === month ? iso(Date.UTC(year, month, day)) : iso(Date.UTC(year, month, day - 1));

    const almost = await makeMember("almost18");
    expect(await put(almost, { displayName: "Almost", birthdate: tomorrow18YearsAgo, gender: "male", lookingFor: "female" })).toBe(400);
    expect(await isComplete(almost)).toBe(false);

    const adult = await makeMember("just18");
    expect(await put(adult, { displayName: "Adult", birthdate: turns18Today, gender: "male", lookingFor: "female" })).toBe(200);
    expect(await isComplete(adult)).toBe(true);
  });

  test("the client cannot send is_complete", async () => {
    const sneaky = await makeMember("sneaky");
    expect(await put(sneaky, { is_complete: true, isComplete: true })).toBe(200);
    expect(await isComplete(sneaky)).toBe(false);
  });

  test("clearing a required field makes the member invisible again", async () => {
    const leaver = await makeMember("leaver", { gender: "male", lookingFor: "female" });
    expect(await isComplete(leaver)).toBe(true);
    expect(await put(leaver, { displayName: "" })).toBe(200);
    expect(await isComplete(leaver)).toBe(false);
    expect((await discover(womanSeekingMen)).body.profiles?.map((p) => p.user_id)).not.toContain(leaver.id);
  });

  test("the backfill flags a complete profile left unflagged, and is idempotent", async () => {
    const old = await makeMember("old", { gender: "female", lookingFor: "male" });
    await sql`UPDATE profiles SET is_complete = false WHERE user_id = ${old.id}`;
    await backfillProfileCompleteness();
    expect(await isComplete(old)).toBe(true);
    expect(await backfillProfileCompleteness()).toBe(0);
  });

  test("the backfill leaves an incomplete profile alone", async () => {
    const blank = await makeMember("blank-backfill");
    await backfillProfileCompleteness();
    expect(await isComplete(blank)).toBe(false);
  });
});

describe("Discover with an incomplete profile", () => {
  test("a man with looking_for null gets 409 profile_incomplete, not a list of men", async () => {
    const { status, body } = await discover(manNoLookingFor);
    expect(status).toBe(409);
    expect(body.error).toBe("profile_incomplete");
    expect(body.missing).toEqual(["looking_for"]);
    expect(body.profiles).toBeUndefined();
  });

  test("a brand new account with nothing set gets 409 naming both fields", async () => {
    const { status, body } = await discover(noPreferences);
    expect(status).toBe(409);
    expect(body.missing).toEqual(["gender", "looking_for"]);
  });

  test("GET /api/auth/me reports what is missing", async () => {
    const incomplete = await (await fetch(`${BASE_URL}/api/auth/me`, { headers: H(manNoLookingFor.token) })).json() as { missing: string[] };
    expect(incomplete.missing).toEqual(["looking_for"]);
    const complete = await (await fetch(`${BASE_URL}/api/auth/me`, { headers: H(manSeekingWomen.token) })).json() as { missing: string[] };
    expect(complete.missing).toEqual([]);
  });

  test("GET /api/profile/:ownId reports what is missing, another member's does not", async () => {
    const own = await (await fetch(`${BASE_URL}/api/profile/${manNoLookingFor.id}`, { headers: H(manNoLookingFor.token) })).json() as { missing?: string[] };
    expect(own.missing).toEqual(["looking_for"]);
    const other = await (await fetch(`${BASE_URL}/api/profile/${manSeekingWomen.id}`, { headers: H(manNoLookingFor.token) })).json() as { missing?: string[] };
    expect(other.missing).toBeUndefined();
  });
});

describe("Discover with a complete profile", () => {
  test("a man looking for women never receives a male candidate", async () => {
    const { status, body } = await discover(manSeekingWomen);
    expect(status).toBe(200);
    const profiles = body.profiles ?? [];
    expect(profiles.length).toBeGreaterThan(0);
    expect(profiles.every((p) => p.gender === "female")).toBe(true);
    const ids = profiles.map((p) => p.user_id);
    expect(ids).toContain(womenSeekingMen.id);
    expect(ids).not.toContain(menSeekingWomen.id);
    // a woman who looks for women does not want this man either
    expect(ids).not.toContain(womenSeekingWomen.id);
  });

  test("a woman looking for men only receives men who look for women", async () => {
    const { status, body } = await discover(womanSeekingMen);
    expect(status).toBe(200);
    const ids = (body.profiles ?? []).map((p) => p.user_id);
    expect(ids).toContain(menSeekingWomen.id);
    expect(ids).not.toContain(womenSeekingMen.id);
    expect(ids).not.toContain(womenSeekingWomen.id);
  });
});

describe("PUT /api/profile gender / lookingFor values", () => {
  test("rejects values other than male / female with 400", async () => {
    for (const body of [{ gender: "all" }, { lookingFor: "everyone" }, { gender: "" }]) {
      const r = await fetch(`${BASE_URL}/api/profile`, { method: "PUT", headers: H(manSeekingWomen.token), body: JSON.stringify(body) });
      expect(r.status).toBe(400);
    }
  });
});
