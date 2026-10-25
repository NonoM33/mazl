import type { Sql } from "postgres";

// Where the Apple refresh token of a member is kept: ENCRYPTED (see
// apple-sign-in.ts), one per member, erased with the member.

export interface AppleTokenStore {
  save(userId: number, sealed: Uint8Array): Promise<void>;
  find(userId: number): Promise<Uint8Array | null>;
}

export async function ensureAppleSignInSchema(sql: Sql): Promise<void> {
  await sql`
    CREATE TABLE IF NOT EXISTS apple_sign_in_tokens (
      user_id INTEGER PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
      refresh_token BYTEA NOT NULL,
      created_at TIMESTAMP NOT NULL DEFAULT NOW(),
      updated_at TIMESTAMP NOT NULL DEFAULT NOW()
    )
  `;
}

export class PgAppleTokenStore implements AppleTokenStore {
  constructor(private readonly sql: Sql) {}

  async save(userId: number, sealed: Uint8Array): Promise<void> {
    await this.sql`
      INSERT INTO apple_sign_in_tokens (user_id, refresh_token)
      VALUES (${userId}, ${Buffer.from(sealed)})
      ON CONFLICT (user_id) DO UPDATE SET refresh_token = EXCLUDED.refresh_token, updated_at = NOW()
    `;
  }

  async find(userId: number): Promise<Uint8Array | null> {
    const rows = await this.sql<{ refresh_token: Buffer }[]>`SELECT refresh_token FROM apple_sign_in_tokens WHERE user_id = ${userId}`;
    return rows[0]?.refresh_token ?? null;
  }
}
