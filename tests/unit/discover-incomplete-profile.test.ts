import { beforeEach, describe, expect, test } from "bun:test";
import { Hono } from "hono";
import { createMiddleware } from "hono/factory";
import { missingProfileFields } from "../../src/features/profile/domain/profile-completeness";
import { updateProfileBodySchema } from "../../src/shared/http/validation";
import { registerDiscoverRoutes } from "../../src/features/matching/presentation/discover.routes";
import type { ProfilePreferences } from "../../src/features/profile/domain/profile-completeness";
import type { AppVariables } from "../../src/shared/http/middleware";

// Bug reported from TestFlight: "the app never asked me if I am a man or a
// woman, and Discover only shows me men — and I am a man". The query used to
// skip the gender filter when the caller's gender / looking_for was null.

interface Candidate {
  readonly user_id: number;
  readonly gender: string;
}

const MEN: Candidate[] = [{ user_id: 1, gender: "male" }, { user_id: 2, gender: "male" }];
const WOMEN: Candidate[] = [{ user_id: 3, gender: "female" }];

let preferences: Map<number, ProfilePreferences>;
let candidateQueries: number;
let app: Hono<{ Variables: AppVariables }>;

beforeEach(() => {
  preferences = new Map();
  candidateQueries = 0;
  const authenticate = createMiddleware<{ Variables: AppVariables }>(async (c, next) => {
    const id = Number(c.req.header("x-test-user"));
    if (!Number.isInteger(id)) return c.json({ success: false, error: "Invalid token" }, 401);
    c.set("userId", id);
    await next();
  });
  const pass = createMiddleware<{ Variables: AppVariables }>(async (_c, next) => { await next(); });
  app = new Hono<{ Variables: AppVariables }>();
  registerDiscoverRoutes<Candidate>(app, {
    authenticate,
    feedLimiter: pass,
    page: { defaultLimit: 20, maxLimit: 50 },
    feed: {
      loadPreferences: async (userId) => preferences.get(userId) ?? null,
      // Stand-in for the SQL: a strict filter on the caller's looking_for.
      loadCandidates: async (userId) => {
        candidateQueries += 1;
        const wanted = preferences.get(userId)?.["looking_for"];
        return [...MEN, ...WOMEN].filter((candidate) => wanted === "all" || candidate.gender === wanted);
      },
    },
  });
});

async function get(path: string, user: number): Promise<Response> {
  return await app.request(path, { headers: { "x-test-user": String(user) } });
}

describe("GET /api/discover with an incomplete caller profile", () => {
  test("409 profile_incomplete for a man with no looking_for, not a list of men", async () => {
    preferences.set(10, { gender: "male", looking_for: null });
    const res = await get("/api/discover", 10);
    expect(res.status).toBe(409);
    expect(await res.json()).toEqual({ success: false, error: "profile_incomplete", missing: ["looking_for"] });
    expect(candidateQueries).toBe(0);
  });

  test("409 naming both fields when neither is set", async () => {
    preferences.set(11, { gender: null, looking_for: null });
    const res = await get("/api/discover", 11);
    expect(res.status).toBe(409);
    expect(((await res.json()) as { missing: string[] }).missing).toEqual(["gender", "looking_for"]);
  });

  test("409 when the caller has no profile row at all", async () => {
    const res = await get("/api/discover", 12);
    expect(res.status).toBe(409);
    expect(((await res.json()) as { missing: string[] }).missing).toEqual(["gender", "looking_for"]);
  });

  test("« Tous » is an explicit choice, not a missing answer (the web client offers it)", async () => {
    preferences.set(13, { gender: "male", looking_for: "all" });
    const res = await get("/api/discover", 13);
    expect(res.status).toBe(200);
  });

  test("the daily picks feed is guarded the same way", async () => {
    preferences.set(10, { gender: "male", looking_for: null });
    const res = await get("/api/daily-picks", 10);
    expect(res.status).toBe(409);
    expect(((await res.json()) as { error: string }).error).toBe("profile_incomplete");
    expect(candidateQueries).toBe(0);
  });
});

describe("GET /api/discover with a complete caller profile", () => {
  test("a man looking for women never receives a male candidate", async () => {
    preferences.set(20, { gender: "male", looking_for: "female" });
    const res = await get("/api/discover", 20);
    expect(res.status).toBe(200);
    const body = (await res.json()) as { success: boolean; profiles: Candidate[] };
    expect(body.success).toBe(true);
    expect(body.profiles.map((p) => p.user_id)).toEqual([3]);
    expect(body.profiles.some((p) => p.gender === "male")).toBe(false);
  });

  test("daily picks answer 200 with picks", async () => {
    preferences.set(20, { gender: "male", looking_for: "female" });
    const res = await get("/api/daily-picks", 20);
    expect(res.status).toBe(200);
    expect(((await res.json()) as { picks: Candidate[] }).picks.map((p) => p.user_id)).toEqual([3]);
  });

  test("still requires authentication", async () => {
    const res = await app.request("/api/discover");
    expect(res.status).toBe(401);
  });
});

describe("missingProfileFields", () => {
  test("empty when gender and looking_for are male / female, in any case", () => {
    expect(missingProfileFields({ gender: "male", looking_for: "female" })).toEqual([]);
    expect(missingProfileFields({ gender: "Female", looking_for: " MALE " })).toEqual([]);
  });

  test("blank, unknown and non-string values count as missing", () => {
    expect(missingProfileFields({ gender: "", looking_for: "everyone" })).toEqual(["gender", "looking_for"]);
    expect(missingProfileFields({ gender: 3, looking_for: undefined })).toEqual(["gender", "looking_for"]);
    expect(missingProfileFields(null)).toEqual(["gender", "looking_for"]);
  });
});

describe("PUT /api/profile body", () => {
  test("accepts male / female", () => {
    expect(updateProfileBodySchema.safeParse({ gender: "male", lookingFor: "female" }).success).toBe(true);
  });

  test("rejects anything else for gender and lookingFor", () => {
    for (const value of ["Male", "", "homme", "other"]) {
      expect(updateProfileBodySchema.safeParse({ gender: value }).success).toBe(false);
      expect(updateProfileBodySchema.safeParse({ lookingFor: value }).success).toBe(false);
    }
  });

  test("« all » is a looking-for answer, never a gender", () => {
    expect(updateProfileBodySchema.safeParse({ lookingFor: "all" }).success).toBe(true);
    expect(updateProfileBodySchema.safeParse({ gender: "all" }).success).toBe(false);
  });

  test("still lets other fields through untouched", () => {
    expect(updateProfileBodySchema.safeParse({ displayName: "Jeanne", bio: "x", relationshipIntention: "serious" }).success).toBe(true);
  });
});
