import type { Sql } from "postgres";
import { isAdminTestAccount } from "../admin/admin.emails";
import {
  CONVERSATIONS_PER_ADMIN,
  CONVERSATION_SCRIPTS,
  MATCHES_PER_ADMIN,
  MATCH_LEAD_MINUTES,
  NEW_MATCH_MINUTES_AGO,
  SWIPE_MINUTES_AGO,
  TEST_MEMBERS,
  stockPhoto,
  type TestMember,
} from "./test-profile-roster";

// The test members of the TestFlight phase (provider 'seed'), created by
// scripts/seed-test-profiles.ts, and the conversations that ONLY the administrator
// finds in their own account. scripts/purge-seed-data.ts removes all of it.
//
// Nothing here likes anybody for a test member: the matches of the administrator are
// written directly (the like of the administrator is recorded, never one of a seed
// member), and the swipe engine only matches on a mutual like.

type Db = Sql;

export interface MemberChange {
  readonly providerId: string;
  readonly displayName: string;
  readonly action: "create" | "update";
}

export interface AdminChange {
  readonly userId: number;
  readonly seeking: string;
  readonly matchesToCreate: number;
  readonly conversationsToFill: number;
  readonly messagesToCreate: number;
}

export interface TestProfilesPlan {
  readonly members: readonly MemberChange[];
  // Members of the old development seed that the roster does not reuse: switched off.
  readonly retired: readonly string[];
  readonly admins: readonly AdminChange[];
}

interface AdminAccount {
  readonly id: number;
  readonly lookingFor: string | null;
}

interface Partnership {
  readonly member: TestMember;
  readonly existing: boolean;
  readonly messages: number;
}

const MEMBER_IDS = TEST_MEMBERS.map((member) => member.providerId);

// A year of birth that gives the stated age today and keeps it for the rest of the year.
function birthdateOf(member: TestMember, index: number, today: Date): string {
  const month = (index % 12) + 1;
  const day = (index % 28) + 1;
  const passed = today.getUTCMonth() + 1 > month || (today.getUTCMonth() + 1 === month && today.getUTCDate() >= day);
  const year = today.getUTCFullYear() - member.age - (passed ? 0 : 1);
  return `${year}-${String(month).padStart(2, "0")}-${String(day).padStart(2, "0")}`;
}

// The seed members this account is offered, in a stable order: the sex it looks for.
function poolFor(lookingFor: string | null): readonly TestMember[] {
  const wanted = lookingFor?.toLowerCase();
  if (wanted === "male" || wanted === "female") return TEST_MEMBERS.filter((member) => member.gender === wanted);
  return TEST_MEMBERS;
}

async function adminAccounts(db: Db): Promise<AdminAccount[]> {
  const rows = await db<{ id: number; email: string; looking_for: string | null }[]>`
    SELECT u.id, u.email, p.looking_for
    FROM users u LEFT JOIN profiles p ON p.user_id = u.id
    WHERE u.provider <> 'seed' AND u.is_active IS NOT FALSE
    ORDER BY u.id`;
  return rows.filter((row) => isAdminTestAccount(row)).map((row) => ({ id: row.id, lookingFor: row.looking_for }));
}

async function partnerships(db: Db, admin: AdminAccount): Promise<Partnership[]> {
  const rows = await db<{ provider_id: string; messages: string }[]>`
    SELECT s.provider_id,
      (SELECT COUNT(*) FROM messages x JOIN conversations c ON c.id = x.conversation_id
        WHERE c.user1_id IN (${admin.id}, s.id) AND c.user2_id IN (${admin.id}, s.id))::text AS messages
    FROM matches m JOIN users s ON s.id IN (m.user1_id, m.user2_id) AND s.provider = 'seed'
    WHERE ${admin.id} IN (m.user1_id, m.user2_id)`;
  const known = new Map(rows.map((row) => [row.provider_id, Number(row.messages)]));
  const wanted = poolFor(admin.lookingFor);
  const fresh = wanted.filter((member) => !known.has(member.providerId)).slice(0, Math.max(0, MATCHES_PER_ADMIN - known.size));
  const chosen = wanted.filter((member) => known.has(member.providerId) || fresh.includes(member)).slice(0, MATCHES_PER_ADMIN);
  return chosen.map((member) => ({ member, existing: known.has(member.providerId), messages: known.get(member.providerId) ?? 0 }));
}

function adminChange(admin: AdminAccount, chosen: readonly Partnership[]): AdminChange {
  const toFill = chosen.map((partner, slot) => ({ partner, slot })).filter(({ partner, slot }) => slot < CONVERSATIONS_PER_ADMIN && partner.messages === 0);
  return {
    userId: admin.id,
    seeking: admin.lookingFor ?? "not stated",
    matchesToCreate: chosen.filter((partner) => !partner.existing).length,
    conversationsToFill: toFill.length,
    messagesToCreate: toFill.reduce((total, { slot }) => total + (CONVERSATION_SCRIPTS[slot]?.length ?? 0), 0),
  };
}

export async function planTestProfiles(db: Db): Promise<TestProfilesPlan> {
  const present = new Set((await db<{ provider_id: string }[]>`SELECT provider_id FROM users WHERE provider = 'seed'`).map((row) => row.provider_id));
  const admins = await adminAccounts(db);
  return {
    members: TEST_MEMBERS.map((member) => ({ providerId: member.providerId, displayName: member.displayName, action: present.has(member.providerId) ? "update" : "create" })),
    retired: [...present].filter((providerId) => !MEMBER_IDS.includes(providerId)).sort(),
    admins: await Promise.all(admins.map(async (admin) => adminChange(admin, await partnerships(db, admin)))),
  };
}

// A test member accepts every age and every distance: Discover filters both ways
// (mutual age and distance), and a tester of any age, anywhere, must see them.
const OPEN_AGE_MIN = 18;
const OPEN_AGE_MAX = 99;

// The administrator's earlier passes and likes on test members, matches apart, are
// forgotten: the members taken over from the old development seed were often swiped
// already, and would never show in the administrator's Discover again.
async function forgetAdminSwipes(db: Db, adminId: number): Promise<void> {
  await db`
    DELETE FROM swipes s USING users u
    WHERE s.user_id = ${adminId} AND s.target_user_id = u.id AND u.provider = 'seed'
      AND NOT EXISTS (
        SELECT 1 FROM matches m
        WHERE (m.user1_id = s.user_id AND m.user2_id = s.target_user_id)
           OR (m.user2_id = s.user_id AND m.user1_id = s.target_user_id))`;
}

async function upsertMember(db: Db, member: TestMember, index: number, today: Date): Promise<number> {
  const [user] = await db<{ id: number }[]>`
    INSERT INTO users (email, name, picture, provider, provider_id, is_active, last_login_at)
    VALUES (${member.email}, ${member.name}, ${stockPhoto(member.photoId, "thumbnail")}, 'seed', ${member.providerId}, true, NOW())
    ON CONFLICT (provider, provider_id) DO UPDATE
      SET email = EXCLUDED.email, name = EXCLUDED.name, picture = EXCLUDED.picture, is_active = true, last_login_at = NOW(), updated_at = NOW()
    RETURNING id`;
  if (user === undefined) throw new Error(`no row for ${member.providerId}`);
  await db`
    INSERT INTO profiles (user_id, display_name, birthdate, gender, bio, location, denomination, kashrut_level, shabbat_observance,
                          relationship_intention, looking_for, is_complete, is_verified, verification_level, photo_verified_at,
                          age_min, age_max, distance_max)
    VALUES (${user.id}, ${member.displayName}, ${birthdateOf(member, index, today)}, ${member.gender}, ${member.bio}, ${member.city},
            ${member.denomination}, ${member.kashrut}, ${member.shabbat}, ${member.intention},
            ${member.gender === "female" ? "male" : "female"}, true, ${member.photoVerified}, ${member.photoVerified ? "photo" : "none"},
            ${member.photoVerified ? db`NOW()` : null}, ${OPEN_AGE_MIN}, ${OPEN_AGE_MAX}, NULL)
    ON CONFLICT (user_id) DO UPDATE SET
      display_name = EXCLUDED.display_name, birthdate = EXCLUDED.birthdate, gender = EXCLUDED.gender, bio = EXCLUDED.bio,
      location = EXCLUDED.location, denomination = EXCLUDED.denomination, kashrut_level = EXCLUDED.kashrut_level,
      shabbat_observance = EXCLUDED.shabbat_observance, relationship_intention = EXCLUDED.relationship_intention,
      looking_for = EXCLUDED.looking_for, is_complete = true, is_verified = EXCLUDED.is_verified,
      verification_level = EXCLUDED.verification_level,
      age_min = EXCLUDED.age_min, age_max = EXCLUDED.age_max, distance_max = NULL,
      photo_verified_at = CASE WHEN EXCLUDED.is_verified THEN COALESCE(profiles.photo_verified_at, NOW()) ELSE NULL END,
      updated_at = NOW()`;
  await syncPhotos(db, user.id, member);
  return user.id;
}

// One photo at position 0, primary. Existing rows are updated
// in place (their ids, hence their signed URLs, stay), extra rows are removed.
async function syncPhotos(db: Db, userId: number, member: TestMember): Promise<void> {
  const wanted = [stockPhoto(member.photoId, "portrait", "faces")];
  const existing = await db<{ id: number }[]>`SELECT id FROM profile_photos WHERE user_id = ${userId} ORDER BY position ASC, id ASC`;
  for (const [position, url] of wanted.entries()) {
    const current = existing[position];
    const faceMatch = member.photoVerified ? true : null;
    if (current === undefined) {
      await db`
        INSERT INTO profile_photos (user_id, url, position, is_primary, face_match, face_checked_at)
        VALUES (${userId}, ${url}, ${position}, ${position === 0}, ${faceMatch}, ${member.photoVerified ? db`NOW()` : null})`;
    } else {
      await db`
        UPDATE profile_photos SET url = ${url}, position = ${position}, is_primary = ${position === 0}, face_match = ${faceMatch},
                                  face_checked_at = ${member.photoVerified ? db`COALESCE(face_checked_at, NOW())` : null}
        WHERE id = ${current.id}`;
    }
  }
  const surplus = existing.slice(wanted.length).map((row) => row.id);
  if (surplus.length > 0) await db`DELETE FROM profile_photos WHERE id IN ${db(surplus)}`;
}

async function memberIdsByKey(db: Db): Promise<Map<string, number>> {
  const rows = await db<{ id: number; provider_id: string }[]>`SELECT id, provider_id FROM users WHERE provider = 'seed'`;
  return new Map(rows.map((row) => [row.provider_id, row.id]));
}

// The like of the administrator is recorded (so the profile leaves Discover), long enough
// ago not to count in today's allowance nor in the "likes of the week" of the member.
async function matchWithAdmin(db: Db, adminId: number, memberId: number, minutesAgo: number): Promise<number> {
  const [low, high] = adminId < memberId ? [adminId, memberId] : [memberId, adminId];
  await db`
    INSERT INTO swipes (user_id, target_user_id, action, created_at)
    VALUES (${adminId}, ${memberId}, 'like', NOW() - make_interval(mins => ${SWIPE_MINUTES_AGO}))
    ON CONFLICT (user_id, target_user_id) DO NOTHING`;
  await db`
    INSERT INTO matches (user1_id, user2_id, created_at) VALUES (${low}, ${high}, NOW() - make_interval(mins => ${minutesAgo}))
    ON CONFLICT (user1_id, user2_id) DO NOTHING`;
  const [match] = await db<{ id: number }[]>`SELECT id FROM matches WHERE user1_id = ${low} AND user2_id = ${high}`;
  if (match === undefined) throw new Error("match not found");
  const [conversation] = await db<{ id: number }[]>`SELECT id FROM conversations WHERE match_id = ${match.id} ORDER BY id LIMIT 1`;
  if (conversation !== undefined) return conversation.id;
  const [created] = await db<{ id: number }[]>`
    INSERT INTO conversations (match_id, user1_id, user2_id, created_at) VALUES (${match.id}, ${low}, ${high}, NOW() - make_interval(mins => ${minutesAgo}))
    RETURNING id`;
  if (created === undefined) throw new Error("conversation not created");
  return created.id;
}

async function writeScript(db: Db, conversationId: number, adminId: number, memberId: number, slot: number): Promise<void> {
  for (const line of CONVERSATION_SCRIPTS[slot] ?? []) {
    const unread = line.from === "partner" && line.unread === true;
    await db`
      INSERT INTO messages (conversation_id, sender_id, content, is_read, read_at, created_at)
      VALUES (${conversationId}, ${line.from === "admin" ? adminId : memberId}, ${line.text}, ${!unread},
              ${unread ? null : db`NOW() - make_interval(mins => ${line.minutesAgo})`}, NOW() - make_interval(mins => ${line.minutesAgo}))`;
  }
  await db`UPDATE conversations SET last_message_at = (SELECT MAX(created_at) FROM messages WHERE conversation_id = ${conversationId}) WHERE id = ${conversationId}`;
}

async function seedAdmin(db: Db, admin: AdminAccount, ids: ReadonlyMap<string, number>): Promise<void> {
  const chosen = await partnerships(db, admin);
  for (const [slot, partner] of chosen.entries()) {
    const memberId = ids.get(partner.member.providerId);
    if (memberId === undefined) throw new Error(`${partner.member.providerId} is not in the database`);
    const script = CONVERSATION_SCRIPTS[slot];
    const first = script?.[0];
    const matchedMinutesAgo = first === undefined ? NEW_MATCH_MINUTES_AGO : first.minutesAgo + MATCH_LEAD_MINUTES;
    const conversationId = await matchWithAdmin(db, admin.id, memberId, matchedMinutesAgo);
    if (slot < CONVERSATIONS_PER_ADMIN && partner.messages === 0) await writeScript(db, conversationId, admin.id, memberId, slot);
  }
}

// Everything in one transaction: the plan is computed again inside it, and a failure
// leaves the database as it was.
export async function applyTestProfiles(db: Db): Promise<TestProfilesPlan> {
  return (await db.begin(async (transaction) => {
    const tx = transaction as unknown as Db;
    const plan = await planTestProfiles(tx);
    const today = new Date();
    for (const [index, member] of TEST_MEMBERS.entries()) await upsertMember(tx, member, index, today);
    if (plan.retired.length > 0) await tx`UPDATE users SET is_active = false WHERE provider = 'seed' AND provider_id IN ${tx(plan.retired)}`;
    const ids = await memberIdsByKey(tx);
    for (const admin of await adminAccounts(tx)) {
      await seedAdmin(tx, admin, ids);
      await forgetAdminSwipes(tx, admin.id);
    }
    return plan;
  })) as TestProfilesPlan;
}
