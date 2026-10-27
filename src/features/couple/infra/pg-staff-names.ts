import type { Sql } from "postgres";

// A display name for each staff address: the member account with that address
// when there is one, else the part of the address before the @.
export async function staffNames(sql: Sql, emails: readonly string[]): Promise<{ email: string; name: string }[]> {
  if (emails.length === 0) return [];
  const rows = await sql<{ email: string; name: string | null }[]>`SELECT lower(email) AS email, name FROM users WHERE lower(email) IN ${sql(emails as string[])}`;
  const names = new Map(rows.map((row) => [row.email, row.name]));
  return emails.map((email) => ({ email, name: names.get(email)?.trim() || email.split("@")[0] || email }));
}
