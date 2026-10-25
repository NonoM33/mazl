import type { Sql } from "postgres";
import { eraseUserRows } from "../../db";
import { COUPLE_ACTIVITY_SEEDS, COUPLE_EVENT_SEEDS } from "./couple-catalogue";

// Removal of the sample data that releases before the v1 created in every
// database they started on: the twenty fake members (provider 'seed') and the
// fictitious couple catalogue. Used by scripts/purge-seed-data.ts.
//
// The catalogue is shared by all couples, so a row that a real couple saved,
// passed or booked is KEPT; a row used only by couples that include a seed
// member goes away with those couples.

type Db = Sql;

export interface SeedAccount {
  readonly id: number;
  readonly email: string;
  readonly displayName: string | null;
  readonly matches: number;
  readonly conversations: number;
  readonly messages: number;
  // Matches or conversations with a member who is not a seed account.
  readonly realMembersAffected: number;
}

export interface CatalogueEntry {
  readonly id: number;
  readonly title: string;
  // Rows of real couples that point at it (saved, passed, booked, registered).
  readonly references: number;
}

export interface SeedPurgePlan {
  readonly accounts: readonly SeedAccount[];
  readonly activitiesToRemove: readonly CatalogueEntry[];
  readonly activitiesKept: readonly CatalogueEntry[];
  readonly eventsToRemove: readonly CatalogueEntry[];
  readonly eventsKept: readonly CatalogueEntry[];
}

// Condition on a row aliased `r` that carries a couple_id: the couple has no seed
// member, so the row survives the purge and counts as a use of the catalogue.
// Couples with a seed member disappear with that member.
const usedByRealCouple = (db: Db) => db`NOT EXISTS (
  SELECT 1 FROM couples c JOIN users u ON u.id IN (c.user1_id, c.user2_id)
  WHERE c.id = r.couple_id AND u.provider = 'seed')`;

async function seedAccounts(db: Db): Promise<SeedAccount[]> {
  const rows = await db<{ id: number; email: string; display_name: string | null; matches: string; conversations: string; messages: string; real_members_affected: string }[]>`
    SELECT u.id, u.email, p.display_name,
      (SELECT COUNT(*) FROM matches m WHERE u.id IN (m.user1_id, m.user2_id))::text AS matches,
      (SELECT COUNT(*) FROM conversations c WHERE u.id IN (c.user1_id, c.user2_id))::text AS conversations,
      (SELECT COUNT(*) FROM messages x JOIN conversations c ON c.id = x.conversation_id WHERE u.id IN (c.user1_id, c.user2_id))::text AS messages,
      (SELECT COUNT(DISTINCT other.id) FROM (
          SELECT CASE WHEN m.user1_id = u.id THEN m.user2_id ELSE m.user1_id END AS id FROM matches m WHERE u.id IN (m.user1_id, m.user2_id)
          UNION
          SELECT CASE WHEN c.user1_id = u.id THEN c.user2_id ELSE c.user1_id END FROM conversations c WHERE u.id IN (c.user1_id, c.user2_id)
        ) other JOIN users ou ON ou.id = other.id WHERE ou.provider <> 'seed')::text AS real_members_affected
    FROM users u LEFT JOIN profiles p ON p.user_id = u.id
    WHERE u.provider = 'seed'
    ORDER BY u.id`;
  return rows.map((row) => ({
    id: row.id,
    email: row.email,
    displayName: row.display_name,
    matches: Number(row.matches),
    conversations: Number(row.conversations),
    messages: Number(row.messages),
    realMembersAffected: Number(row.real_members_affected),
  }));
}

const identityOf = (title: string, location: string | undefined, city: string): string => JSON.stringify([title, location ?? null, city]);

async function activities(db: Db): Promise<CatalogueEntry[]> {
  const known = new Set(COUPLE_ACTIVITY_SEEDS.map((seed) => identityOf(seed.title, seed.location, seed.city)));
  const rows = await db<{ id: number; title: string; location: string | null; city: string | null; references: string }[]>`
    SELECT a.id, a.title, a.location, a.city,
      ((SELECT COUNT(*) FROM couple_saved_activities r WHERE r.activity_id = a.id AND ${usedByRealCouple(db)})
     + (SELECT COUNT(*) FROM couple_passed_activities r WHERE r.activity_id = a.id AND ${usedByRealCouple(db)})
     + (SELECT COUNT(*) FROM couple_bookings r WHERE r.activity_id = a.id AND ${usedByRealCouple(db)}))::text AS references
    FROM couple_activities a ORDER BY a.id`;
  return rows
    .filter((row) => known.has(identityOf(row.title, row.location ?? undefined, row.city ?? "")))
    .map((row) => ({ id: row.id, title: row.title, references: Number(row.references) }));
}

async function events(db: Db): Promise<CatalogueEntry[]> {
  const known = new Set(COUPLE_EVENT_SEEDS.map((seed) => identityOf(seed.title, seed.location, seed.city)));
  const rows = await db<{ id: number; title: string; location: string | null; city: string | null; references: string }[]>`
    SELECT e.id, e.title, e.location, e.city,
      ((SELECT COUNT(*) FROM couple_event_registrations r WHERE r.event_id = e.id AND ${usedByRealCouple(db)})
     + (SELECT COUNT(*) FROM couple_bookings r WHERE r.event_id = e.id AND ${usedByRealCouple(db)}))::text AS references
    FROM couple_events e ORDER BY e.id`;
  return rows
    .filter((row) => known.has(identityOf(row.title, row.location ?? undefined, row.city ?? "")))
    .map((row) => ({ id: row.id, title: row.title, references: Number(row.references) }));
}

export async function planSeedPurge(db: Db): Promise<SeedPurgePlan> {
  const [accountList, activityList, eventList] = [await seedAccounts(db), await activities(db), await events(db)];
  return {
    accounts: accountList,
    activitiesToRemove: activityList.filter((entry) => entry.references === 0),
    activitiesKept: activityList.filter((entry) => entry.references > 0),
    eventsToRemove: eventList.filter((entry) => entry.references === 0),
    eventsKept: eventList.filter((entry) => entry.references > 0),
  };
}

// Everything in one transaction: the plan is computed again inside it, so what is
// removed is what is true at that moment, and a failure leaves the database as it was.
export async function applySeedPurge(db: Db): Promise<SeedPurgePlan> {
  return (await db.begin(async (transaction) => {
    const tx = transaction as unknown as Db;
    const plan = await planSeedPurge(tx);
    for (const account of plan.accounts) await eraseUserRows(tx, account.id);
    const activityIds = plan.activitiesToRemove.map((entry) => entry.id);
    const eventIds = plan.eventsToRemove.map((entry) => entry.id);
    if (activityIds.length > 0) await tx`DELETE FROM couple_activities WHERE id IN ${tx(activityIds)}`;
    if (eventIds.length > 0) await tx`DELETE FROM couple_events WHERE id IN ${tx(eventIds)}`;
    return plan;
  })) as SeedPurgePlan;
}
