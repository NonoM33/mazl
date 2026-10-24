import type { Sql } from "postgres";
import type { ConsentDecision, ConsentPurpose, StoredConsent } from "../domain/consent";
import type { ConsentRepository } from "../application/ports";

interface ConsentRow {
  readonly granted: boolean;
  readonly version: string;
  readonly decided_at: Date;
}

function toStored(row: ConsentRow): StoredConsent {
  return { granted: row.granted, version: row.version, decidedAt: row.decided_at };
}

// postgres.js types a transaction handle as non-callable; it is the same tag.
function inTransaction<T>(sql: Sql, work: (tx: Sql) => Promise<T>): Promise<T> {
  return sql.begin((transaction) => work(transaction as unknown as Sql)) as Promise<T>;
}

// relationship_intention arrives with another branch: only touch it when it exists.
async function hasIntentionColumn(tx: Sql): Promise<boolean> {
  const rows = await tx`
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = current_schema() AND table_name = 'profiles' AND column_name = 'relationship_intention'
  `;
  return rows.length > 0;
}

async function eraseReligiousColumns(tx: Sql, userId: number): Promise<void> {
  await tx`UPDATE profiles SET denomination = NULL, kashrut_level = NULL, shabbat_observance = NULL WHERE user_id = ${userId}`;
  if (await hasIntentionColumn(tx)) {
    await tx`UPDATE profiles SET relationship_intention = NULL WHERE user_id = ${userId}`;
  }
}

export class PgConsentRepository implements ConsentRepository {
  constructor(private readonly sql: Sql) {}

  async current(userId: number, purpose: ConsentPurpose): Promise<StoredConsent | null> {
    const rows = await this.sql<ConsentRow[]>`
      SELECT granted, version, decided_at FROM user_consents WHERE user_id = ${userId} AND purpose = ${purpose}
    `;
    const row = rows[0];
    return row === undefined ? null : toStored(row);
  }

  async record(decision: ConsentDecision, eraseReligiousData: boolean): Promise<StoredConsent> {
    const { userId, purpose, granted, version, source } = decision;
    return await inTransaction(this.sql, async (tx) => {
      const rows = await tx<ConsentRow[]>`
        INSERT INTO user_consents (user_id, purpose, granted, version, source)
        VALUES (${userId}, ${purpose}, ${granted}, ${version}, ${source})
        ON CONFLICT (user_id, purpose)
        DO UPDATE SET granted = EXCLUDED.granted, version = EXCLUDED.version, source = EXCLUDED.source, decided_at = NOW()
        RETURNING granted, version, decided_at
      `;
      await tx`
        INSERT INTO user_consent_events (user_id, purpose, granted, version, source)
        VALUES (${userId}, ${purpose}, ${granted}, ${version}, ${source})
      `;
      if (eraseReligiousData) await eraseReligiousColumns(tx, userId);
      const row = rows[0];
      if (row === undefined) throw new Error("privacy: the consent was not recorded");
      return toStored(row);
    });
  }
}
