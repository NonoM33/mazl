import type { Sql } from "postgres";
import type { IdentityRecord, IdentityRepository, IdentitySaveResult } from "../application/identity-ports";

const UNIQUE_VIOLATION = "23505";

function isUniqueViolation(error: unknown): boolean {
  return typeof error === "object" && error !== null && "code" in error && error.code === UNIQUE_VIOLATION;
}

export class PgIdentityRepository implements IdentityRepository {
  constructor(private readonly sql: Sql) {}

  async isBanned(fingerprint: string): Promise<boolean> {
    const rows = await this.sql`SELECT 1 FROM banned_document_fingerprints WHERE doc_fingerprint = ${fingerprint}`;
    return rows.length > 0;
  }

  async ownerOf(fingerprint: string): Promise<number | null> {
    const [row] = await this.sql<{ user_id: number }[]>`
      SELECT user_id FROM identity_verifications WHERE doc_fingerprint = ${fingerprint}
    `;
    return row?.user_id ?? null;
  }

  // One transaction: the identity row and the profile change land together.
  // A member re-verifying with a new document replaces their previous row.
  async save(record: IdentityRecord): Promise<IdentitySaveResult> {
    try {
      await this.sql.begin(async (transaction) => {
        // postgres.js types TransactionSql without its call signature; it is one.
        const tx = transaction as unknown as Sql;
        await tx`
          INSERT INTO identity_verifications
            (user_id, method, issuing_state, document_type, doc_fingerprint, document_expiry, verified_at)
          VALUES (${record.userId}, ${record.method}, ${record.issuingState}, ${record.documentType},
                  ${record.fingerprint}, ${record.documentExpiry}, NOW())
          ON CONFLICT (user_id) DO UPDATE SET
            method = EXCLUDED.method, issuing_state = EXCLUDED.issuing_state,
            document_type = EXCLUDED.document_type, doc_fingerprint = EXCLUDED.doc_fingerprint,
            document_expiry = EXCLUDED.document_expiry, verified_at = NOW()
        `;
        await tx`
          UPDATE profiles
          SET birthdate = ${record.birthDate}, birthdate_locked = true, identity_verified_at = NOW(), updated_at = NOW()
          WHERE user_id = ${record.userId}
        `;
      });
      return "saved";
    } catch (error: unknown) {
      if (isUniqueViolation(error)) return "fingerprint_taken";
      throw error;
    }
  }
}
