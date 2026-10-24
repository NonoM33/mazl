import type { Sql } from "postgres";
import type { VerificationQueueItemDto } from "../presentation/dto";
import { isoRequired, num, text } from "./mappers";

// What waits for a manual review today: the identity documents submitted
// through the waitlist flow (waitlist.verification_status 'submitted' or
// 'pending', as listed by the existing console). The selfie flow
// (verification_attempts) and the chip-based identity check are decided by the
// server alone and have no manual queue, so they appear here only if one is
// introduced later. Entries whose e-mail has no member account yet are left out:
// the contract needs a member id.
export async function loadVerificationQueue(sql: Sql, limit: number): Promise<readonly VerificationQueueItemDto[]> {
  const rows = await sql`
    SELECT u.id AS member_id, p.display_name, w.documents_submitted_at, w.verification_status,
      (SELECT ph.url FROM profile_photos ph WHERE ph.user_id = u.id
         ORDER BY ph.is_primary DESC, ph.position ASC, ph.id ASC LIMIT 1) AS photo_url
    FROM waitlist w
    JOIN users u ON lower(u.email) = lower(w.email)
    LEFT JOIN profiles p ON p.user_id = u.id
    WHERE w.verification_status IN ('submitted', 'pending') AND w.documents_submitted_at IS NOT NULL
    ORDER BY w.documents_submitted_at ASC LIMIT ${limit}
  `;
  return rows.map((row) => ({
    memberId: num(row.member_id),
    displayName: text(row.display_name),
    submittedAt: isoRequired(row.documents_submitted_at),
    kind: "documents" as const,
    status: text(row.verification_status) ?? "pending",
    photoUrl: text(row.photo_url),
  }));
}

export async function countVerificationQueue(sql: Sql): Promise<number> {
  const rows = await sql`
    SELECT COUNT(*)::int AS total FROM waitlist w JOIN users u ON lower(u.email) = lower(w.email)
    WHERE w.verification_status IN ('submitted', 'pending') AND w.documents_submitted_at IS NOT NULL
  `;
  return num(rows[0]?.total);
}
