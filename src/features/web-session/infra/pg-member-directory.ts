import type { Sql } from "postgres";
import type { MemberDirectory, MemberLookup, WebMember } from "../application/ports";

interface UserRow {
  id: number;
  email: string;
  name: string | null;
  provider: string;
  provider_id: string;
  is_active: boolean | null;
}

export function toMember(row: Pick<UserRow, "id" | "email" | "name" | "provider" | "provider_id">): WebMember {
  return {
    id: row.id,
    email: row.email,
    name: row.name,
    provider: row.provider === "apple" ? "apple" : "google",
    providerId: row.provider_id,
  };
}

function lookupOf(rows: readonly UserRow[]): MemberLookup {
  const row = rows[0];
  if (!row) return { kind: "absent" };
  return row.is_active === false ? { kind: "disabled" } : { kind: "found", member: toMember(row) };
}

// Read-only on purpose: unlike the mobile sign-in, nothing here creates a user.
export class PgMemberDirectory implements MemberDirectory {
  constructor(private readonly sql: Sql) {}

  async findByProvider(provider: "google" | "apple", providerId: string): Promise<MemberLookup> {
    const rows = await this.sql<UserRow[]>`
      SELECT id, email, name, provider, provider_id, is_active FROM users
      WHERE provider = ${provider} AND provider_id = ${providerId}`;
    return lookupOf(rows);
  }

  async findById(userId: number): Promise<MemberLookup> {
    const rows = await this.sql<UserRow[]>`
      SELECT id, email, name, provider, provider_id, is_active FROM users WHERE id = ${userId}`;
    return lookupOf(rows);
  }
}
