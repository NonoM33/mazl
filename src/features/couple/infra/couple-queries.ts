import { sql, getCouple, type CoupleRequestView } from "../../../db";
import { publicPicturesFor } from "../../media/infra/public-pictures";

// SQL and read-model mapping for the consent-based couple flow
// (docs/couple/CONTRAT.md §1-§3). Parameterised queries only.

// §1 — a couple as seen by one of its members.
export interface CoupleView {
  id: number;
  partner_id: number;
  partner_name: string;
  partner_picture: string | null;
  started_at: string | null;
  met_on_mazl_at: string | null;
  status: string;
}

interface CoupleDbRow {
  id: number;
  partner_id: number;
  partner_name: string | null;
  partner_picture: string | null;
  started_at: Date | string | null;
  met_on_mazl_at: Date | string | null;
  relationship_status: string | null;
}

function toIso(value: Date | string | null): string | null {
  if (value === null) return null;
  return new Date(value).toISOString();
}

// `getCouple` already resolves the partner from the viewer's side and signs the
// partner picture; this only narrows the row to the contract's public shape.
export function toCoupleView(row: CoupleDbRow): CoupleView {
  return {
    id: Number(row.id),
    partner_id: Number(row.partner_id),
    partner_name: row.partner_name ?? "",
    partner_picture: row.partner_picture,
    started_at: toIso(row.started_at),
    met_on_mazl_at: toIso(row.met_on_mazl_at),
    status: row.relationship_status ?? "dating",
  };
}

// The caller's active couple in the §1 shape, or null.
export async function getCoupleViewFor(userId: number): Promise<CoupleView | null> {
  const row = await getCouple(userId);
  return row ? toCoupleView(row as unknown as CoupleDbRow) : null;
}

// §0.2 — a request is only allowed between two members who matched and who
// have not blocked each other, in either direction.
export async function canRequestCouple(userA: number, userB: number): Promise<boolean> {
  const [low, high] = userA < userB ? [userA, userB] : [userB, userA];
  const rows = await sql`
    SELECT 1
    WHERE EXISTS (
      SELECT 1 FROM matches WHERE user1_id = ${low} AND user2_id = ${high}
    )
    AND NOT EXISTS (
      SELECT 1 FROM blocked_users
      WHERE (blocker_id = ${userA} AND blocked_id = ${userB})
         OR (blocker_id = ${userB} AND blocked_id = ${userA})
    )
  `;
  return rows.length > 0;
}

// One request in the same shape as the entries of GET /api/couple/requests.
export async function getCoupleRequestView(requestId: number): Promise<CoupleRequestView | null> {
  const rows = await sql`
    SELECT
      cr.id, cr.requester_id, cr.target_id, cr.status, cr.created_at,
      rp.display_name AS requester_name,
      tp.display_name AS target_name
    FROM couple_requests cr
    LEFT JOIN profiles rp ON rp.user_id = cr.requester_id
    LEFT JOIN profiles tp ON tp.user_id = cr.target_id
    WHERE cr.id = ${requestId}
    LIMIT 1
  `;
  const raw = rows[0] as unknown as
    | Omit<CoupleRequestView, "requester_picture" | "target_picture">
    | undefined;
  if (!raw) return null;
  const pictures = await publicPicturesFor(sql, [raw.requester_id, raw.target_id]);
  return {
    ...raw,
    requester_picture: pictures.get(raw.requester_id) ?? null,
    target_picture: pictures.get(raw.target_id) ?? null,
  };
}
