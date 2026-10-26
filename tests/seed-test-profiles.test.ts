import { afterAll, beforeAll, describe, expect, test } from "bun:test";
import postgres from "postgres";
import { createScratchDatabase, runBun, startServer, type RunningServer, type ScratchDatabase } from "./support/scratch-database";
import { THROWAWAY_CREDENTIAL } from "./throwaway-credential";

// scripts/seed-test-profiles.ts: the fake members of the TestFlight phase and the
// conversations of the administrator's account. Runs ONLY against a database created
// here, inside the throwaway Postgres; the API runs on it too (NODE_ENV=test, so the
// old development seed is there first: its members must be taken over, not duplicated).
// The administrator is whoever isAdminEmail accepts: the ADMIN_EMAIL given to the script.

const SEED = "scripts/seed-test-profiles.ts";
const PURGE = "scripts/purge-seed-data.ts";
const ADMIN_EMAIL = "seed-admin@example.com";

let scratch: ScratchDatabase;
let server: RunningServer;
let sql: postgres.Sql;
const run = (script: string, ...flags: string[]) => runBun([script, ...flags], { DATABASE_URL: scratch.url, ADMIN_EMAIL, NODE_ENV: "production" });
const one = async <T extends object>(rows: Promise<T[]>): Promise<T> => {
  const [row] = await rows;
  if (row === undefined) throw new Error("no row");
  return row;
};
const count = async (query: Promise<{ n: string }[]>): Promise<number> => Number((await one(query)).n);

async function insertReal(email: string, name: string, gender: "male" | "female", lookingFor: "male" | "female"): Promise<number> {
  const user = await one(sql<{ id: number }[]>`INSERT INTO users (email, name, provider, provider_id) VALUES (${email}, ${name}, 'apple', ${email}) RETURNING id`);
  await sql`INSERT INTO profiles (user_id, display_name, birthdate, gender, looking_for, is_complete) VALUES (${user.id}, ${name}, '1992-03-04', ${gender}, ${lookingFor}, true)`;
  return user.id;
}

// Every table the script may touch, as one fingerprint each: a dry-run must leave all of them as they were.
async function fingerprint(): Promise<Record<string, string>> {
  const tables = ["users", "profiles", "profile_photos", "swipes", "matches", "conversations", "messages"];
  const result: Record<string, string> = {};
  for (const table of tables) {
    result[table] = (await one(sql<{ h: string }[]>`SELECT COALESCE(md5(string_agg(t::text, ',' ORDER BY t.id)), '') AS h FROM ${sql(table)} t`)).h;
  }
  return result;
}

const seedRows = () => sql<{ id: number; provider_id: string; is_active: boolean }[]>`SELECT id, provider_id, is_active FROM users WHERE provider = 'seed' ORDER BY id`;
const messagesOf = (userId: number) => count(sql`SELECT COUNT(*)::text AS n FROM messages x JOIN conversations c ON c.id = x.conversation_id WHERE ${userId} IN (c.user1_id, c.user2_id)`);

let admin: number;
let reader: number;
let bystander: number;
let legacyIds: Map<string, number>;

beforeAll(async () => {
  scratch = await createScratchDatabase();
  server = await startServer(scratch.url, "test");
  sql = postgres(scratch.url, { max: 2, onnotice: () => undefined });
  [admin, reader, bystander] = [
    await insertReal(ADMIN_EMAIL, "Renaud Exemple", "male", "female"),
    await insertReal("lookalike-seed-admin@example.com", "Alice Exemple", "female", "male"),
    await insertReal("bruno@example.com", "Bruno Exemple", "male", "female"),
  ];
  legacyIds = new Map((await seedRows()).map((row) => [row.provider_id, row.id]));
}, 120_000);

afterAll(async () => {
  await sql?.end({ timeout: 2 });
  await server?.stop();
  await scratch?.drop();
});

describe("scripts/seed-test-profiles.ts", () => {
  test("starts from the old development seed: twenty members with the old pictures", async () => {
    expect(legacyIds.size).toBe(20);
    expect(await count(sql`SELECT COUNT(*)::text AS n FROM profile_photos WHERE url LIKE '%pravatar%'`)).toBe(20);
  });

  test("refuses to run without DATABASE_URL, and on a flag it does not know", async () => {
    const noDatabase = await runBun([SEED], { DATABASE_URL: "" });
    expect(noDatabase.code).toBe(2);
    expect(noDatabase.out).toContain("DATABASE_URL");
    const unknown = await run(SEED, "--force");
    expect(unknown.code).toBe(2);
    const both = await run(SEED, "--apply", "--dry-run");
    expect(both.code).toBe(2);
  });

  test("a dry-run (the default) shows the target and the plan, never a password or an address, and changes nothing", async () => {
    const before = await fingerprint();
    for (const flags of [[], ["--dry-run"]]) {
      const result = await run(SEED, ...flags);
      expect(result.code).toBe(0);
      expect(result.out).toContain("Database:");
      expect(result.out).toContain("/scratch_");
      expect(result.out).not.toMatch(/postgres:\/\/|:it@/);
      expect(result.out).not.toContain("@example.com");
      expect(result.out.toLowerCase()).toContain("dry-run");
      expect(result.out).toContain("seed-female-13");
      expect(result.out).toContain(`#${admin} `);
      expect(result.out).not.toContain(`#${reader} `);
      expect(await fingerprint()).toEqual(before);
    }
  }, 60_000);

  test("--apply takes over the old members, creates the others, with two photos each", async () => {
    const result = await run(SEED, "--apply");
    expect([result.code, result.code === 0 ? "" : result.out]).toEqual([0, ""]);

    const rows = await seedRows();
    // 20 old members + 3 new women; each old key kept its row.
    expect(rows).toHaveLength(23);
    for (const [providerId, id] of legacyIds) expect(rows.find((row) => row.provider_id === providerId)?.id).toBe(id);
    const active = rows.filter((row) => row.is_active);
    expect(active).toHaveLength(16);
    expect(rows.filter((row) => !row.is_active).every((row) => /^seed-male-(4|5|6|7|8|9|10)$/.test(row.provider_id))).toBe(true);

    const members = await sql<{ id: number; gender: string; looking_for: string; age: number; bio: string; location: string; is_complete: boolean; verified: boolean; picture: string }[]>`
      SELECT u.id, p.gender, p.looking_for, DATE_PART('year', AGE(p.birthdate))::int AS age, p.bio, p.location, p.is_complete,
             (p.photo_verified_at IS NOT NULL AND EXISTS (SELECT 1 FROM profile_photos v WHERE v.user_id = u.id AND v.is_primary AND v.face_match)) AS verified, u.picture
      FROM users u JOIN profiles p ON p.user_id = u.id WHERE u.provider = 'seed' AND u.is_active ORDER BY u.id`;
    expect(members.filter((member) => member.gender === "female")).toHaveLength(13);
    expect(members.filter((member) => member.gender === "male")).toHaveLength(3);
    expect(members.every((member) => member.is_complete && member.age >= 23 && member.age <= 34 && member.bio.length > 80)).toBe(true);
    expect(members.every((member) => member.looking_for === (member.gender === "female" ? "male" : "female"))).toBe(true);
    expect(members.filter((member) => member.verified)).toHaveLength(8);
    expect(new Set(members.map((member) => member.location))).toEqual(new Set(["Paris", "Neuilly-sur-Seine", "Boulogne-Billancourt", "Lyon", "Marseille", "Strasbourg", "Nice"]));

    const primaries = new Set<string>();
    for (const member of members) {
      const photos = await sql<{ url: string; position: number; is_primary: boolean }[]>`SELECT url, position, is_primary FROM profile_photos WHERE user_id = ${member.id} ORDER BY position`;
      expect(photos.map((photo) => [photo.position, photo.is_primary])).toEqual([[0, true], [1, false]]);
      for (const photo of photos) expect(photo.url).toMatch(/^https:\/\/images\.unsplash\.com\/photo-\d+-[0-9a-f]+\?w=800&h=1000&fit=crop&crop=(faces|entropy)&q=80$/);
      expect(photos[0]?.url).toMatch(/crop=faces/);
      primaries.add(photos[0]?.url ?? "");
      expect(member.picture).toMatch(/^https:\/\/images\.unsplash\.com\/photo-\d+-[0-9a-f]+\?w=200&h=200&fit=crop&crop=faces&q=80$/);
    }
    expect(primaries.size).toBe(16);
    expect(await count(sql`SELECT COUNT(*)::text AS n FROM profile_photos ph JOIN users u ON u.id = ph.user_id WHERE u.is_active AND ph.url NOT LIKE 'https://images.unsplash.com/%'`)).toBe(0);
  }, 60_000);

  test("only the administrator gets matches and conversations, with the sex they look for", async () => {
    const matches = await sql<{ id: number; other: number; gender: string; provider: string }[]>`
      SELECT m.id, o.id AS other, p.gender, o.provider FROM matches m
      JOIN users o ON o.id = CASE WHEN m.user1_id = ${admin} THEN m.user2_id ELSE m.user1_id END
      JOIN profiles p ON p.user_id = o.id WHERE ${admin} IN (m.user1_id, m.user2_id)`;
    expect(matches).toHaveLength(5);
    expect(matches.every((match) => match.provider === "seed" && match.gender === "female")).toBe(true);

    const conversations = await sql<{ id: number; messages: string; unread: string; last: Date | null }[]>`
      SELECT c.id, (SELECT COUNT(*) FROM messages x WHERE x.conversation_id = c.id)::text AS messages,
        (SELECT COUNT(*) FROM messages x WHERE x.conversation_id = c.id AND x.sender_id <> ${admin} AND NOT x.is_read)::text AS unread,
        c.last_message_at AS last
      FROM conversations c WHERE ${admin} IN (c.user1_id, c.user2_id) ORDER BY c.id`;
    expect(conversations).toHaveLength(5);
    const written = conversations.filter((conversation) => Number(conversation.messages) > 0);
    expect(written).toHaveLength(4);
    expect(written.every((conversation) => Number(conversation.messages) >= 3 && Number(conversation.messages) <= 6)).toBe(true);
    expect(written.every((conversation) => conversation.last !== null)).toBe(true);
    expect(written.reduce((total, conversation) => total + Number(conversation.unread), 0)).toBeGreaterThanOrEqual(2);

    const recent = await count(sql`SELECT COUNT(*)::text AS n FROM messages WHERE created_at > NOW() - INTERVAL '7 days' AND created_at <= NOW()`);
    expect(recent).toBe(await count(sql`SELECT COUNT(*)::text AS n FROM messages`));

    // Nobody else: no match, conversation, message or swipe, not even the account whose address resembles the administrator's.
    for (const other of [reader, bystander]) {
      expect(await count(sql`SELECT COUNT(*)::text AS n FROM matches WHERE ${other} IN (user1_id, user2_id)`)).toBe(0);
      expect(await count(sql`SELECT COUNT(*)::text AS n FROM conversations WHERE ${other} IN (user1_id, user2_id)`)).toBe(0);
      expect(await messagesOf(other)).toBe(0);
      expect(await count(sql`SELECT COUNT(*)::text AS n FROM swipes WHERE ${other} IN (user_id, target_user_id)`)).toBe(0);
    }
    // A test member never likes anybody, and no match involves a member other than the administrator.
    expect(await count(sql`SELECT COUNT(*)::text AS n FROM swipes s JOIN users u ON u.id = s.user_id WHERE u.provider = 'seed'`)).toBe(0);
    expect(await count(sql`SELECT COUNT(*)::text AS n FROM matches`)).toBe(5);
  });

  test("a second --apply writes nothing twice", async () => {
    const tables = async () => ({
      users: await count(sql`SELECT COUNT(*)::text AS n FROM users`),
      photoIds: (await sql<{ id: number }[]>`SELECT id FROM profile_photos ORDER BY id`).map((row) => row.id),
      matchIds: (await sql<{ id: number }[]>`SELECT id FROM matches ORDER BY id`).map((row) => row.id),
      messageIds: (await sql<{ id: number }[]>`SELECT id FROM messages ORDER BY id`).map((row) => row.id),
      conversations: await count(sql`SELECT COUNT(*)::text AS n FROM conversations`),
      swipes: await count(sql`SELECT COUNT(*)::text AS n FROM swipes`),
    });
    const before = await tables();
    const second = await run(SEED, "--apply");
    expect([second.code, second.code === 0 ? "" : second.out]).toEqual([0, ""]);
    expect(second.out).toContain("0 match(es)");
    expect(await tables()).toEqual(before);
  }, 60_000);

  test("the administrator's earlier swipes on test members are forgotten, matches kept", async () => {
    const matched = new Set(
      (await sql<{ other: number }[]>`
        SELECT CASE WHEN user1_id = ${admin} THEN user2_id ELSE user1_id END AS other FROM matches WHERE ${admin} IN (user1_id, user2_id)`).map((row) => row.other),
    );
    const passed = (await seedRows()).find((row) => row.is_active && !matched.has(row.id));
    if (passed === undefined) throw new Error("no unmatched test member");
    await sql`INSERT INTO swipes (user_id, target_user_id, action) VALUES (${admin}, ${passed.id}, 'pass') ON CONFLICT DO NOTHING`;
    const again = await run(SEED, "--apply");
    expect(again.code).toBe(0);
    expect(await count(sql`SELECT COUNT(*)::text AS n FROM swipes WHERE user_id = ${admin} AND target_user_id = ${passed.id}`)).toBe(0);
    expect(await count(sql`SELECT COUNT(*)::text AS n FROM swipes WHERE user_id = ${admin}`)).toBe(matched.size);
  }, 60_000);

  test("test members accept every age and every distance", async () => {
    const rows = await sql<{ age_min: number; age_max: number; distance_max: number | null }[]>`
      SELECT p.age_min, p.age_max, p.distance_max FROM profiles p JOIN users u ON u.id = p.user_id
      WHERE u.provider = 'seed' AND u.is_active = true`;
    expect(rows).toHaveLength(16);
    for (const row of rows) expect([row.age_min, row.age_max, row.distance_max]).toEqual([18, 99, null]);
  });

  test("a real member sees the test members in Discover, with their photos", async () => {
    const made = await fetch(`${server.baseUrl}/api/dev/test-user`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ email: "decouverte@example.com", password: THROWAWAY_CREDENTIAL, name: "Camille Exemple" }),
    });
    const user = (await made.json()) as { user: { id: number }; token: string };
    const headers = { Authorization: `Bearer ${user.token}`, "Content-Type": "application/json" };
    const saved = await fetch(`${server.baseUrl}/api/profile`, {
      method: "PUT",
      headers,
      body: JSON.stringify({ displayName: "Camille", birthdate: "1992-05-06", gender: "male", lookingFor: "female" }),
    });
    expect(saved.status).toBe(200);

    const feed = await fetch(`${server.baseUrl}/api/discover?limit=50`, { headers });
    expect(feed.status).toBe(200);
    const body = (await feed.json()) as { profiles: { user_id: number; photos: string[]; picture: string | null; display_name: string }[] };
    const rows = await seedRows();
    const active = new Map(rows.filter((row) => row.is_active).map((row) => [row.id, row.provider_id]));
    const inactive = new Set(rows.filter((row) => !row.is_active).map((row) => row.id));
    const shown = body.profiles.filter((profile) => active.has(profile.user_id));
    expect(shown.map((profile) => active.get(profile.user_id)).sort()).toEqual(Array.from({ length: 13 }, (_, index) => `seed-female-${index + 1}`).sort());
    expect(body.profiles.some((profile) => inactive.has(profile.user_id))).toBe(false);
    for (const profile of shown) {
      expect(profile.photos).toHaveLength(2);
      expect(profile.photos.every((url) => url.startsWith("https://images.unsplash.com/photo-"))).toBe(true);
      expect(profile.picture ?? null).toBe(profile.photos[0] ?? null);
    }

    // The engine never matches on its own: a member who likes every test member gets no match.
    // (A free member has a daily allowance of likes: the refused ones, 402, are not part of the check.)
    let liked = 0;
    for (const profile of shown) {
      const swipe = await fetch(`${server.baseUrl}/api/swipes`, { method: "POST", headers, body: JSON.stringify({ target_user_id: profile.user_id, action: "like" }) });
      expect([200, 402]).toContain(swipe.status);
      if (swipe.status !== 200) continue;
      liked += 1;
      expect(((await swipe.json()) as { match?: boolean }).match ?? false).toBe(false);
    }
    expect(liked).toBeGreaterThan(0);
    expect(await count(sql`SELECT COUNT(*)::text AS n FROM matches WHERE ${user.user.id} IN (user1_id, user2_id)`)).toBe(0);
    expect(await count(sql`SELECT COUNT(*)::text AS n FROM matches`)).toBe(5);
  }, 60_000);

  test("test members stay out of the figures and of the e-mail campaigns", async () => {
    const script = `
      import { getAdminStats, getCampaignRecipients, sql } from "./src/db";
      import { PgFiguresRepository } from "./src/features/trust-safety/infra/pg-figures";
      const stats = await getAdminStats();
      const recipients = await getCampaignRecipients(null);
      const figures = await new PgFiguresRepository(sql).dashboard(new Date());
      console.log("RESULT " + JSON.stringify({ users: stats.users.total, matches: stats.matches, messages: stats.messages, recipients: recipients.length, members: figures.members.total, matches7d: figures.members.matches7d }));
      await sql.end();`;
    const result = await runBun(["-e", script], { DATABASE_URL: scratch.url, NODE_ENV: "production" });
    const line = result.out.split("\n").find((entry) => entry.startsWith("RESULT "));
    expect(line).toBeDefined();
    const real = await count(sql`SELECT COUNT(*)::text AS n FROM users WHERE provider <> 'seed'`);
    expect(JSON.parse((line ?? "").slice(7))).toEqual({ users: real, matches: 0, messages: 0, recipients: real, members: real, matches7d: 0 });
  }, 60_000);

  test("scripts/purge-seed-data.ts removes the test members and every fake conversation, and nothing else", async () => {
    const realBefore = await count(sql`SELECT COUNT(*)::text AS n FROM users WHERE provider <> 'seed'`);
    const dry = await run(PURGE);
    expect(dry.code).toBe(0);
    expect(dry.out).toContain("real member(s) concerned");

    const purged = await run(PURGE, "--apply");
    expect([purged.code, purged.code === 0 ? "" : purged.out]).toEqual([0, ""]);
    expect(await count(sql`SELECT COUNT(*)::text AS n FROM users WHERE provider = 'seed'`)).toBe(0);
    expect(await count(sql`SELECT COUNT(*)::text AS n FROM users WHERE provider <> 'seed'`)).toBe(realBefore);
    for (const table of ["matches", "conversations", "messages"]) expect(await count(sql`SELECT COUNT(*)::text AS n FROM ${sql(table)}`)).toBe(0);
    expect(await count(sql`SELECT COUNT(*)::text AS n FROM profile_photos`)).toBe(0);
    // The swipes the administrator gave to the test members went with them; those of the real member towards them too.
    expect(await count(sql`SELECT COUNT(*)::text AS n FROM swipes`)).toBe(0);
  }, 60_000);
});
