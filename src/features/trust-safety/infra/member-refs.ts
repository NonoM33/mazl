import type { Sql } from "postgres";
import type { MemberRefDto } from "../presentation/dto";
import { memberRef, num } from "./mappers";

// Name, first photo, verification level and account state of members, in one
// query. Members that no longer exist are simply absent from the map.
export async function loadMemberRefs(sql: Sql, ids: readonly number[]): Promise<Map<number, MemberRefDto>> {
  const refs = new Map<number, MemberRefDto>();
  if (ids.length === 0) return refs;
  const rows = await sql`
    SELECT u.id, COALESCE(u.is_active, true) AS is_active, p.display_name,
      (SELECT ph.url FROM profile_photos ph WHERE ph.user_id = u.id
         ORDER BY ph.is_primary DESC, ph.position ASC, ph.id ASC LIMIT 1) AS photo_url,
      CASE
        WHEN EXISTS (SELECT 1 FROM identity_verifications iv WHERE iv.user_id = u.id) OR p.verification_level = 'identity' THEN 'identity'
        WHEN p.is_verified = true OR p.verification_level = 'photo' THEN 'selfie'
        ELSE 'none'
      END AS verification
    FROM users u
    LEFT JOIN profiles p ON p.user_id = u.id
    WHERE u.id IN ${sql(ids)}
  `;
  for (const row of rows) {
    const ref = memberRef(row);
    refs.set(num(row.id), ref);
  }
  return refs;
}
