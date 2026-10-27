import type { Sql } from "postgres";
import { DEFAULT_RITUALS, type NewRitual, type Ritual, type RitualKind } from "../domain/rituals";

interface RitualRow {
  id: number;
  couple_id: number;
  kind: RitualKind;
  title: string;
  weekday: number | null;
  time: string | null;
  enabled: boolean;
  remind_minutes: number;
}

const toRitual = (row: RitualRow): Ritual => ({
  id: Number(row.id),
  coupleId: Number(row.couple_id),
  kind: row.kind,
  title: row.title,
  weekday: row.weekday === null ? null : Number(row.weekday),
  time: row.time,
  enabled: row.enabled,
  remindMinutes: Number(row.remind_minutes),
});

// Gives a couple its three default rituals, once (couples.rituals_seeded_at is
// the gate): a couple that deleted them does not get them back.
export async function seedDefaultRituals(sql: Sql, coupleId: number): Promise<void> {
  const claimed = await sql`UPDATE couples SET rituals_seeded_at = NOW() WHERE id = ${coupleId} AND rituals_seeded_at IS NULL RETURNING id`;
  if (claimed.length === 0) return;
  for (const ritual of DEFAULT_RITUALS) {
    await sql`
      INSERT INTO couple_rituals (couple_id, kind, title, weekday, time, enabled, remind_minutes)
      VALUES (${coupleId}, ${ritual.kind}, ${ritual.title}, ${ritual.weekday}, ${ritual.time}, ${ritual.enabled}, ${ritual.remindMinutes})`;
  }
}

export async function seedDefaultRitualsForAllCouples(sql: Sql): Promise<void> {
  const couples = await sql<{ id: number }[]>`SELECT id FROM couples WHERE status = 'active' AND rituals_seeded_at IS NULL`;
  for (const couple of couples) await seedDefaultRituals(sql, couple.id);
}

export class PgRituals {
  constructor(private readonly sql: Sql) {}

  async list(coupleId: number): Promise<Ritual[]> {
    const rows = await this.sql<RitualRow[]>`SELECT * FROM couple_rituals WHERE couple_id = ${coupleId} ORDER BY id`;
    return rows.map(toRitual);
  }

  async enabled(coupleId: number): Promise<Ritual[]> {
    return (await this.list(coupleId)).filter((ritual) => ritual.enabled);
  }

  async create(coupleId: number, ritual: NewRitual): Promise<Ritual> {
    const [row] = await this.sql<RitualRow[]>`
      INSERT INTO couple_rituals (couple_id, kind, title, weekday, time, enabled, remind_minutes)
      VALUES (${coupleId}, ${ritual.kind}, ${ritual.title}, ${ritual.weekday}, ${ritual.time}, ${ritual.enabled}, ${ritual.remindMinutes})
      RETURNING *`;
    if (row === undefined) throw new Error("ritual not written");
    return toRitual(row);
  }

  // Only the fields present change. null is a value for weekday and time.
  async update(coupleId: number, id: number, patch: Partial<Omit<NewRitual, "kind">>): Promise<Ritual | null> {
    const current = (await this.list(coupleId)).find((ritual) => ritual.id === id);
    if (current === undefined) return null;
    const next = {
      title: patch.title ?? current.title,
      weekday: patch.weekday === undefined ? current.weekday : patch.weekday,
      time: current.kind === "shabbat" ? null : patch.time === undefined ? current.time : patch.time,
      enabled: patch.enabled ?? current.enabled,
      remindMinutes: patch.remindMinutes ?? current.remindMinutes,
    };
    const [row] = await this.sql<RitualRow[]>`
      UPDATE couple_rituals SET title = ${next.title}, weekday = ${next.weekday}, time = ${next.time},
        enabled = ${next.enabled}, remind_minutes = ${next.remindMinutes}
      WHERE id = ${id} AND couple_id = ${coupleId} RETURNING *`;
    return row === undefined ? null : toRitual(row);
  }

  async remove(coupleId: number, id: number): Promise<boolean> {
    const rows = await this.sql`DELETE FROM couple_rituals WHERE id = ${id} AND couple_id = ${coupleId} RETURNING id`;
    return rows.length > 0;
  }
}
