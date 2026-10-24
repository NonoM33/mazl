import { afterAll, beforeAll, describe, expect, test } from "bun:test";
import postgres from "postgres";
import { CorruptVersionError, NoAbTestError, VariantIsActiveError } from "../src/features/matching/application/errors";
import { createFeed } from "../src/features/matching/application/discover";
import { DEFAULT_PARAMS } from "../src/features/matching/domain/params";
import { rankCandidates } from "../src/features/matching/domain/engine";
import { setParam } from "../src/features/matching/domain/validate-params";
import { PgCandidateSource } from "../src/features/matching/infra/pg-candidate-source";
import { PgFeedHydrator } from "../src/features/matching/infra/pg-feed-hydrator";
import { PgParamsRepository, STATE_CACHE_TTL_MS } from "../src/features/matching/infra/pg-params-repository";
import { ensureMatchingSchema } from "../src/features/matching/infra/schema";

// Needs a throwaway database whose base schema was created by the real server
// (see the task notes): TEST_DATABASE_URL. Skipped otherwise.
const url = process.env.TEST_DATABASE_URL;

describe.skipIf(url === undefined)("matching on Postgres", () => {
  const sql = postgres(url ?? "postgres://unused", { onnotice: () => undefined });
  const ids: Record<string, number> = {};
  const PREFIX = "mpg-";

  async function member(key: string, profile: { gender: string | null; lookingFor: string | null; birthdate?: string; lat?: number; lon?: number; verification?: string; bio?: string | null }) {
    const [user] = await sql<{ id: number }[]>`
      INSERT INTO users (email, name, provider, provider_id, last_login_at)
      VALUES (${`${PREFIX}${key}@example.test`}, ${key}, 'test', ${`${PREFIX}${key}`}, now() - interval '1 day')
      RETURNING id`;
    const id = user!.id;
    ids[key] = id;
    await sql`
      INSERT INTO profiles (user_id, display_name, birthdate, gender, looking_for, bio, is_complete, latitude, longitude,
                            denomination, kashrut_level, age_min, age_max, verification_level, relationship_intention)
      VALUES (${id}, ${key}, ${profile.birthdate ?? "1993-05-05"}, ${profile.gender}, ${profile.lookingFor}, ${profile.bio ?? "Bonjour"}, true,
              ${profile.lat ?? 48.85}, ${profile.lon ?? 2.35}, 'Massorti', 'Strict', 18, 60, ${profile.verification ?? "none"}, 'serious')`;
    return id;
  }

  const feedFor = (params = new PgParamsRepository(sql)) =>
    createFeed({ params, candidates: new PgCandidateSource(sql), hydrator: new PgFeedHydrator(sql) });

  beforeAll(async () => {
    await sql`CREATE TABLE IF NOT EXISTS member_sanctions (
      id SERIAL PRIMARY KEY, user_id INT, kind TEXT, starts_at TIMESTAMPTZ DEFAULT now(), ends_at TIMESTAMPTZ, revoked_at TIMESTAMPTZ)`;
    await sql`DELETE FROM member_sanctions`;
    await sql`DELETE FROM users WHERE email LIKE ${`${PREFIX}%@example.test`}`;
    await sql`TRUNCATE matching_activations, matching_state, matching_param_versions RESTART IDENTITY CASCADE`.catch(() => undefined);
    await ensureMatchingSchema(sql);

    await member("viewer", { gender: "male", lookingFor: "female" });
    await member("ok1", { gender: "female", lookingFor: "male" });
    await member("ok2", { gender: "female", lookingFor: "all", verification: "photo" });
    await member("blocked", { gender: "female", lookingFor: "male", verification: "identity" });
    await member("blocker", { gender: "female", lookingFor: "male" });
    await member("swiped", { gender: "female", lookingFor: "male" });
    await member("sanctioned", { gender: "female", lookingFor: "male" });
    await member("male", { gender: "male", lookingFor: "female" });
    await member("wantsFemale", { gender: "female", lookingFor: "female" });
    const viewer = ids.viewer!;
    await sql`INSERT INTO blocked_users (blocker_id, blocked_id) VALUES (${viewer}, ${ids.blocked!})`;
    await sql`INSERT INTO blocked_users (blocker_id, blocked_id) VALUES (${ids.blocker!}, ${viewer})`;
    await sql`INSERT INTO swipes (user_id, target_user_id, action) VALUES (${viewer}, ${ids.swiped!}, 'pass')`;
    await sql`INSERT INTO member_sanctions (user_id, kind) VALUES (${ids.sanctioned!}, 'restriction')`;
  });

  afterAll(async () => {
    await sql`DELETE FROM member_sanctions`;
    await sql`DELETE FROM users WHERE email LIKE ${`${PREFIX}%@example.test`}`;
    await sql.end();
  });

  const mine = (list: readonly number[]) => list.filter((id) => Object.values(ids).includes(id));
  const name = (id: number) => Object.entries(ids).find(([, v]) => v === id)?.[0];

  describe("feed", () => {
    test("blocked (either way), swiped, sanctioned, wrong gender and one-way orientation are never proposed", async () => {
      const { userIds } = await feedFor().rank(ids.viewer!, { limit: 50, offset: 0 });
      expect(mine(userIds).map(name).sort()).toEqual(["ok1", "ok2"]);
    });

    test("a revoked sanction lifts the exclusion, an expired one too", async () => {
      await sql`UPDATE member_sanctions SET revoked_at = now() WHERE user_id = ${ids.sanctioned!}`;
      const { userIds } = await feedFor().rank(ids.viewer!, { limit: 50, offset: 0 });
      expect(mine(userIds).map(name).sort()).toEqual(["ok1", "ok2", "sanctioned"]);
      await sql`UPDATE member_sanctions SET revoked_at = NULL, ends_at = now() - interval '1 hour'`;
      expect(mine((await feedFor().rank(ids.viewer!, { limit: 50, offset: 0 })).userIds)).toContain(ids.sanctioned!);
      await sql`UPDATE member_sanctions SET ends_at = NULL`;
      expect(mine((await feedFor().rank(ids.viewer!, { limit: 50, offset: 0 })).userIds)).not.toContain(ids.sanctioned!);
    });

    test("an ended-in-the-future suspension and a ban exclude; a 'warning' does not", async () => {
      await sql`DELETE FROM member_sanctions`;
      await sql`INSERT INTO member_sanctions (user_id, kind, ends_at) VALUES (${ids.ok1!}, 'suspension', now() + interval '1 day')`;
      await sql`INSERT INTO member_sanctions (user_id, kind) VALUES (${ids.ok2!}, 'warning')`;
      const got = mine((await feedFor().rank(ids.viewer!, { limit: 50, offset: 0 })).userIds).map(name);
      expect(got).toContain("ok2");
      expect(got).not.toContain("ok1");
      await sql`DELETE FROM member_sanctions`;
    });

    test("the order is exactly the engine's on the loaded candidates", async () => {
      const source = new PgCandidateSource(sql);
      const set = await source.load(ids.viewer!);
      expect(set).not.toBeNull();
      const now = new Date();
      const day = new Intl.DateTimeFormat("en-CA", { timeZone: "Europe/Paris" }).format(now);
      const params = new PgParamsRepository(sql);
      const version = (await params.getState()).active;
      const { seedFrom } = await import("../src/features/matching/domain/random");
      const expected = rankCandidates(set!.viewer, set!.candidates, { now: now.toISOString(), excluded: set!.excluded }, version.params, seedFrom(ids.viewer!, day, version.id), 50);
      const feed = createFeed({ params, candidates: source, hydrator: new PgFeedHydrator(sql), clock: () => now });
      const got = await feed.rank(ids.viewer!, { limit: 50, offset: 0 });
      expect([...got.userIds]).toEqual(expected.ranked.map((c) => c.userId));
    });

    test("the excluded set holds swiped and blocked members in both directions", async () => {
      const set = await new PgCandidateSource(sql).load(ids.viewer!);
      expect([...set!.excluded].sort()).toEqual([ids.blocked!, ids.blocker!, ids.swiped!].sort());
    });

    test("a member without profile gets nothing", async () => {
      expect(await new PgCandidateSource(sql).load(2_000_000_000)).toBeNull();
    });
  });

  describe("candidate mapping", () => {
    test("signals are read from swipes, reports, boosts, photos, prompts and the login date", async () => {
      const target = ids.ok2!;
      await sql`INSERT INTO swipes (user_id, target_user_id, action) VALUES (${ids.male!}, ${target}, 'like'), (${ids.blocker!}, ${target}, 'super_like'), (${ids.wantsFemale!}, ${target}, 'pass')`;
      await sql`INSERT INTO swipes (user_id, target_user_id, action, created_at) VALUES (${ids.swiped!}, ${target}, 'like', now() - interval '10 days')`;
      await sql`INSERT INTO reports (reporter_id, reported_user_id, reason, status) VALUES (${ids.male!}, ${target}, 'spam', 'pending'), (${ids.male!}, ${target}, 'spam', 'dismissed')`;
      await sql`INSERT INTO reports (reporter_id, reported_user_id, reason, status, created_at) VALUES (${ids.male!}, ${target}, 'spam', 'pending', now() - interval '120 days')`;
      await sql`INSERT INTO boosts (user_id, expires_at) VALUES (${target}, now() + interval '1 hour')`;
      await sql`INSERT INTO profile_photos (user_id, url, position) VALUES (${target}, '/uploads/a.jpg', 0), (${target}, '/uploads/b.jpg', 1), (${target}, 'https://x.example.com/c.jpg', 2)`;
      await sql`INSERT INTO profile_prompts (user_id, prompt_id, answer) VALUES (${target}, 'p1', 'réponse')`;
      const set = await new PgCandidateSource(sql).load(ids.viewer!);
      const c = set!.candidates.find((p) => p.userId === target)!;
      expect(c.likesReceived7d).toBe(2);
      expect(c.openReports90d).toBe(1);
      expect(c.boostedUntil).not.toBeNull();
      expect(c.photoCount).toBe(2);
      expect(c.promptCount).toBe(1);
      expect(c.hasBio).toBe(true);
      expect(c.verification).toBe("selfie");
      expect(c.intention).toBe("serious");
      expect(c.age).toBe(Math.floor((Date.now() - Date.parse("1993-05-05")) / 31_557_600_000));
      expect(c.location).toEqual({ latitude: 48.85, longitude: 2.35 });
      expect(c.lastActiveAt).not.toBeNull();
      expect(c.gender).toBe("female");
      expect(c.lookingFor).toBe("all");
      expect(set!.viewer.verification).toBe("none");
    });
  });

  describe("hydration", () => {
    test("same columns as getDiscoverProfiles, in the requested order, no score", async () => {
      const wanted = [ids.ok2!, ids.ok1!];
      const profiles = await new PgFeedHydrator(sql).profilesForFeed(wanted);
      expect(profiles.map((p) => p.user_id)).toEqual(wanted);
      const expectedKeys = ["age", "bio", "denomination", "display_name", "gender", "id", "identity_verified", "is_verified", "kashrut_level", "location", "photo_verified", "photos", "picture", "shabbat_observance", "user_id", "verification_level"];
      expect(Object.keys(profiles[0]!).sort()).toEqual(expectedKeys);
      expect(await new PgFeedHydrator(sql).profilesForFeed([])).toEqual([]);
    });

    test("same content as the legacy query for the same member", async () => {
      const { getDiscoverProfiles } = await import("../src/db");
      // db.ts opens its own connection from DATABASE_URL; compare only if it is the same database.
      if (process.env.DATABASE_URL !== url) return;
      const legacy = await getDiscoverProfiles(ids.viewer!, 50, 0);
      const wanted = (legacy as unknown as Array<{ user_id: number }>).map((p) => p.user_id);
      const hydrated = await new PgFeedHydrator(sql).profilesForFeed(wanted);
      expect(JSON.parse(JSON.stringify(hydrated))).toEqual(JSON.parse(JSON.stringify(legacy)));
    });
  });

  describe("parameter versions", () => {
    test("schema is idempotent and seeds version 1 as the active default", async () => {
      await ensureMatchingSchema(sql);
      await ensureMatchingSchema(sql);
      const repo = new PgParamsRepository(sql);
      const state = await repo.getState();
      expect(state.active.id).toBe(1);
      expect(state.active.params).toEqual(DEFAULT_PARAMS);
      expect(state.active.author).toBe("system");
      expect(state.active.note).toBe("Paramètres initiaux");
      expect(state.abTest).toBeNull();
      const [counts] = await sql<{ v: number; s: number; a: number }[]>`
        SELECT (SELECT count(*)::int FROM matching_param_versions WHERE id = 1) AS v,
               (SELECT count(*)::int FROM matching_state) AS s,
               (SELECT count(*)::int FROM matching_activations WHERE version_id = 1) AS a`;
      expect(counts).toEqual({ v: 1, s: 1, a: 1 });
    });

    test("create, activate, roll back, with history", async () => {
      const repo = new PgParamsRepository(sql);
      const v2 = await repo.createVersion({ params: setParam(DEFAULT_PARAMS, "boost.factor", 1.5), note: "boost", author: "a@example.com", parentId: 1 });
      expect(v2.parentId).toBe(1);
      expect((await repo.getState()).active.id).toBe(1);
      expect(await repo.activate(v2.id, "a@example.com", "go")).toEqual({ previousVersionId: 1, abTestEnded: false });
      expect((await repo.getState()).active.params.boost.factor).toBe(1.5);
      expect(await repo.activate(1, "a@example.com", "retour")).toEqual({ previousVersionId: v2.id, abTestEnded: false });
      expect((await repo.getState()).active.id).toBe(1);
      const page = await repo.listVersions({ limit: 10, offset: 0 });
      expect(page.total).toBeGreaterThanOrEqual(2);
      expect(page.versions[0]!.id).toBe(v2.id);
      expect(page.versions[0]!.activatedAt).not.toBeNull();
      const [history] = await sql<{ n: number }[]>`SELECT count(*)::int AS n FROM matching_activations`;
      expect(history!.n).toBe(3);
      await expect(repo.activate(9999, "a@example.com", "x")).rejects.toThrow();
    });

    test("A/B test start, stop, and refusal of the active version", async () => {
      const repo = new PgParamsRepository(sql);
      const v = await repo.createVersion({ params: DEFAULT_PARAMS, note: "variante", author: "a@example.com", parentId: 1 });
      await expect(repo.startAbTest(1, 10, "a@example.com")).rejects.toBeInstanceOf(VariantIsActiveError);
      await repo.startAbTest(v.id, 20, "a@example.com");
      const state = await repo.getState();
      expect(state.abTest).toMatchObject({ sharePercent: 20, startedBy: "a@example.com", variant: { id: v.id } });
      await expect(sql`UPDATE matching_state SET ab_share_percent = 80`).rejects.toThrow();
      await repo.stopAbTest();
      expect((await repo.getState()).abTest).toBeNull();
      await expect(repo.stopAbTest()).rejects.toBeInstanceOf(NoAbTestError);
      await repo.startAbTest(v.id, 5, "a@example.com");
      expect(await repo.activate(v.id, "a@example.com", "gagnante")).toMatchObject({ abTestEnded: true });
      expect((await repo.getState()).abTest).toBeNull();
      await repo.activate(1, "a@example.com", "retour");
    });

    test("writes invalidate the cache of the instance; another instance waits for the TTL", async () => {
      let now = 1_000_000;
      const a = new PgParamsRepository(sql, () => now);
      const b = new PgParamsRepository(sql, () => now);
      const v = await a.createVersion({ params: DEFAULT_PARAMS, note: "cache", author: "a@example.com", parentId: 1 });
      expect((await b.getState()).active.id).toBe(1);
      await a.activate(v.id, "a@example.com", "go");
      expect((await a.getState()).active.id).toBe(v.id);
      expect((await b.getState()).active.id).toBe(1);
      now += STATE_CACHE_TTL_MS + 1;
      expect((await b.getState()).active.id).toBe(v.id);
      await a.activate(1, "a@example.com", "retour");
    });

    test("a stored version outside the bounds is an explicit error, never returned", async () => {
      const bad = JSON.parse(JSON.stringify(DEFAULT_PARAMS));
      bad.boost.factor = 99;
      const [row] = await sql<{ id: number }[]>`INSERT INTO matching_param_versions (params, note, author) VALUES (${sql.json(bad)}, 'corrompue', 'test') RETURNING id`;
      const repo = new PgParamsRepository(sql);
      await expect(repo.getVersion(row!.id)).rejects.toBeInstanceOf(CorruptVersionError);
      await expect(repo.listVersions({ limit: 100, offset: 0 })).rejects.toBeInstanceOf(CorruptVersionError);
      await sql`UPDATE matching_state SET active_version_id = ${row!.id}`;
      await expect(new PgParamsRepository(sql).getState()).rejects.toBeInstanceOf(CorruptVersionError);
      await sql`UPDATE matching_state SET active_version_id = 1`;
      await sql`DELETE FROM matching_param_versions WHERE id = ${row!.id}`;
    });
  });
});
