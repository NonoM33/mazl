import { describe, expect, test } from "bun:test";
import { PgPushDirectory } from "../src/features/push/infra/pg-push-directory";
import { db, makeUser } from "./media-helpers";

// Who may receive a push from whom, against the real tables: a block (either
// way), a deactivated or banned account, an active sanction. Expectations come
// from the contract (V1-CONTRAT section 1), not from the SQL.

const directory = new PgPushDirectory(db);
let counter = 0;

async function named(label: string, displayName: string) {
  const user = await makeUser(label);
  await db`
    INSERT INTO profiles (user_id, display_name) VALUES (${user.id}, ${displayName})
    ON CONFLICT (user_id) DO UPDATE SET display_name = EXCLUDED.display_name`;
  return user;
}

async function sanction(userId: number, kind: string, window: { startsInMinutes: number; endsInMinutes: number | null; revoked?: boolean }): Promise<void> {
  counter += 1;
  await db`
    INSERT INTO member_sanctions (user_id, kind, ground, starts_at, ends_at, decided_by, statement, appeal_code_hash, revoked_at)
    VALUES (${userId}, ${kind}, 'test', now() + (${window.startsInMinutes} * interval '1 minute'),
      ${window.endsInMinutes === null ? null : db`now() + (${window.endsInMinutes} * interval '1 minute')`},
      'test', ${db.json({ reference: `push-dir-${userId}-${counter}` })}, 'x', ${window.revoked === true ? db`now()` : null})`;
}

describe("PgPushDirectory.audience", () => {
  test("two active members: deliverable, with the display name of the actor", async () => {
    const recipient = await named("pdr", "Daniel Lévy");
    const actor = await named("pda", "Sarah Cohen");
    expect(await directory.audience(recipient.id, actor.id)).toEqual({ deliverable: true, actorName: "Sarah Cohen" });
  });

  test("an actor with no profile name is deliverable with no name", async () => {
    const recipient = await makeUser("pdnr");
    const actor = await makeUser("pdna");
    await db`DELETE FROM profiles WHERE user_id = ${actor.id}`;
    expect(await directory.audience(recipient.id, actor.id)).toEqual({ deliverable: true, actorName: null });
  });

  test("a block refuses the pair in BOTH directions", async () => {
    const x = await named("pdbx", "X");
    const y = await named("pdby", "Y");
    await db`INSERT INTO blocked_users (blocker_id, blocked_id) VALUES (${x.id}, ${y.id})`;
    expect((await directory.audience(x.id, y.id)).deliverable).toBe(false);
    expect((await directory.audience(y.id, x.id)).deliverable).toBe(false);
  });

  test("a deactivated account (a ban sets this flag) is refused whether it is the recipient or the actor", async () => {
    const off = await named("pdoff", "Off");
    const on = await named("pdon", "On");
    await db`UPDATE users SET is_active = false WHERE id = ${off.id}`;
    expect((await directory.audience(off.id, on.id)).deliverable).toBe(false);
    expect((await directory.audience(on.id, off.id)).deliverable).toBe(false);
  });

  test("an unknown account is refused", async () => {
    const real = await makeUser("pdunk");
    expect((await directory.audience(real.id, 2_000_000_000)).deliverable).toBe(false);
    expect((await directory.audience(2_000_000_000, real.id)).deliverable).toBe(false);
  });

  for (const kind of ["restriction", "suspension", "ban"]) {
    test(`an active ${kind} refuses the pair, on either side`, async () => {
      const sanctioned = await named(`pds${kind}`, "Sanctionné");
      const other = await named(`pdo${kind}`, "Autre");
      await sanction(sanctioned.id, kind, { startsInMinutes: -60, endsInMinutes: null });
      expect((await directory.audience(other.id, sanctioned.id)).deliverable).toBe(false);
      expect((await directory.audience(sanctioned.id, other.id)).deliverable).toBe(false);
    });
  }

  test("a lifted, an expired and a future sanction do not refuse anyone", async () => {
    const member = await named("pdlifted", "Libre");
    const other = await named("pdother", "Autre");
    await sanction(member.id, "ban", { startsInMinutes: -60, endsInMinutes: null, revoked: true });
    await sanction(member.id, "suspension", { startsInMinutes: -120, endsInMinutes: -60 });
    await sanction(member.id, "suspension", { startsInMinutes: 60, endsInMinutes: 120 });
    expect((await directory.audience(other.id, member.id)).deliverable).toBe(true);
  });
});
