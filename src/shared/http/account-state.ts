import { sql } from "../../db";

// A signed token is not enough: the account behind it must still exist and be
// active. Deleting an account removes its row and a ban sets is_active to
// false, so both end every session at once instead of when the 30-day token
// expires. One primary-key lookup per request.
export async function isAccountActive(userId: number): Promise<boolean> {
  const rows = await sql<{ is_active: boolean | null }[]>`SELECT is_active FROM users WHERE id = ${userId}`;
  const row = rows[0];
  return row !== undefined && row.is_active !== false;
}
