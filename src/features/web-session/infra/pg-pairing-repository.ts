import type { Sql } from "postgres";
import type { Pairing, PairingStatus } from "../domain/pairing";
import type { PairingRepository } from "../application/ports";

interface PairingRow {
  id: string;
  code_hash: string;
  browser_secret_hash: string;
  browser_label: string;
  status: PairingStatus;
  user_id: number | null;
  created_at: Date;
  expires_at: Date;
}

const toPairing = (row: PairingRow): Pairing => ({
  id: row.id,
  codeHash: row.code_hash,
  browserSecretHash: row.browser_secret_hash,
  browserLabel: row.browser_label,
  status: row.status,
  userId: row.user_id,
  createdAt: row.created_at,
  expiresAt: row.expires_at,
});

export class PgPairingRepository implements PairingRepository {
  constructor(private readonly sql: Sql) {}

  async insert(p: Pairing): Promise<void> {
    await this.sql`
      INSERT INTO web_pairings (id, code_hash, browser_secret_hash, browser_label, status, created_at, expires_at)
      VALUES (${p.id}, ${p.codeHash}, ${p.browserSecretHash}, ${p.browserLabel}, ${p.status}, ${p.createdAt}, ${p.expiresAt})`;
  }

  async findById(id: string): Promise<Pairing | null> {
    if (!isUuid(id)) return null;
    const rows = await this.sql<PairingRow[]>`SELECT * FROM web_pairings WHERE id = ${id}`;
    return rows[0] ? toPairing(rows[0]) : null;
  }

  async markScanned(codeHash: string, userId: number, now: Date): Promise<Pairing | null> {
    const rows = await this.sql<PairingRow[]>`
      UPDATE web_pairings SET status = 'scanned', user_id = ${userId}, scanned_at = ${now}
      WHERE code_hash = ${codeHash} AND status = 'pending' AND expires_at > ${now}
      RETURNING *`;
    return rows[0] ? toPairing(rows[0]) : null;
  }

  async decide(id: string, userId: number, status: "approved" | "denied", now: Date): Promise<boolean> {
    const rows = await this.sql`
      UPDATE web_pairings SET status = ${status}, decided_at = ${now}
      WHERE id = ${id} AND user_id = ${userId} AND status = 'scanned' AND expires_at > ${now}
      RETURNING id`;
    return rows.length > 0;
  }

  async consume(id: string, now: Date): Promise<number | null> {
    const rows = await this.sql<{ user_id: number }[]>`
      UPDATE web_pairings SET status = 'consumed'
      WHERE id = ${id} AND status = 'approved' AND expires_at > ${now}
      RETURNING user_id`;
    return rows[0]?.user_id ?? null;
  }

  async purgeExpiredBefore(limit: Date): Promise<void> {
    await this.sql`DELETE FROM web_pairings WHERE expires_at < ${limit}`;
  }
}

const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

// Postgres rejects a malformed uuid with an error; an unknown id is a 404.
export function isUuid(value: string): boolean {
  return UUID.test(value);
}
