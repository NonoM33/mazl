import type { Sql } from "postgres";
import type { MembersRepository, RiskFacts } from "../application/ports";
import type { MemberFileDto } from "../presentation/dto";
import { loadMemberRefs } from "./member-refs";
import { iso, isoRequired, num, numOrNull, text } from "./mappers";

const RECENT_MESSAGES = 300;
const MAX_ID = 2_147_483_647;

// A user-typed fragment is matched literally: % _ and \ lose their wildcard meaning.
function likePattern(query: string): string {
  return `%${query.replace(/[\\%_]/g, (character) => `\\${character}`)}%`;
}

function exactId(query: string): number | null {
  if (!/^\d{1,10}$/.test(query)) return null;
  const id = Number(query);
  return id <= MAX_ID ? id : null;
}

export class PgMembersRepository implements MembersRepository {
  constructor(private readonly sql: Sql) {}

  async search(query: string, limit: number, offset: number) {
    const pattern = likePattern(query);
    const id = exactId(query);
    const match = this.sql`(u.id = ${id}::int OR p.display_name ILIKE ${pattern} OR u.email ILIKE ${pattern})`;
    const rows = await this.sql`
      SELECT u.id FROM users u LEFT JOIN profiles p ON p.user_id = u.id
      WHERE ${match} ORDER BY u.id DESC LIMIT ${limit} OFFSET ${offset}
    `;
    const counted = await this.sql`SELECT COUNT(*)::int AS total FROM users u LEFT JOIN profiles p ON p.user_id = u.id WHERE ${match}`;
    const ids = rows.map((row) => num(row.id));
    const refs = await loadMemberRefs(this.sql, ids);
    const members = ids.map((memberId) => refs.get(memberId)).filter((ref) => ref !== undefined);
    return { members, total: num(counted[0]?.total) };
  }

  async profile(id: number): Promise<MemberFileDto["member"] | null> {
    const refs = await loadMemberRefs(this.sql, [id]);
    const ref = refs.get(id);
    if (!ref) return null;
    const rows = await this.sql`
      SELECT u.email, u.created_at, u.last_login_at, p.location, p.gender, p.denomination, p.bio,
             CASE WHEN p.birthdate IS NULL THEN NULL ELSE date_part('year', age(p.birthdate))::int END AS age
      FROM users u LEFT JOIN profiles p ON p.user_id = u.id WHERE u.id = ${id}
    `;
    const row = rows[0];
    if (!row) return null;
    const photos = await this.sql`SELECT url FROM profile_photos WHERE user_id = ${id} ORDER BY is_primary DESC, position ASC, id ASC`;
    return {
      ...ref,
      email: text(row.email) ?? "",
      createdAt: isoRequired(row.created_at),
      lastActiveAt: iso(row.last_login_at),
      age: numOrNull(row.age),
      city: text(row.location),
      gender: text(row.gender),
      denomination: text(row.denomination),
      photos: photos.map((photo) => text(photo.url) ?? ""),
      bio: text(row.bio),
    };
  }

  async stats(id: number) {
    const rows = await this.sql`
      SELECT
        (SELECT COUNT(*)::int FROM matches WHERE user1_id = ${id} OR user2_id = ${id}) AS matches,
        (SELECT COUNT(*)::int FROM blocked_users WHERE blocked_id = ${id}) AS blocks,
        (SELECT COUNT(*)::int FROM swipes WHERE target_user_id = ${id} AND action IN ('like', 'super_like')
           AND created_at >= now() - interval '7 days') AS likes,
        (SELECT COUNT(*)::int FROM reports WHERE reporter_id = ${id}) AS made
    `;
    const row = rows[0];
    return {
      matches: num(row?.matches),
      blocksReceived: num(row?.blocks),
      likesReceived7d: num(row?.likes),
      reportsMade: num(row?.made),
    };
  }

  async riskFacts(id: number): Promise<RiskFacts> {
    const [messages, facts] = await Promise.all([
      this.sql`
        SELECT content, conversation_id FROM messages
        WHERE sender_id = ${id} AND type = 'text' AND created_at >= now() - interval '30 days'
        ORDER BY id DESC LIMIT ${RECENT_MESSAGES}
      `,
      this.sql`
        SELECT GREATEST(0, floor(extract(epoch FROM (now() - u.created_at)) / 86400))::int AS age_days,
          (SELECT COUNT(*)::int FROM reports WHERE reported_user_id = ${id}) AS reports,
          (SELECT COUNT(*)::int FROM blocked_users WHERE blocked_id = ${id}) AS blocks,
          (COALESCE(p.is_verified, false) OR EXISTS (SELECT 1 FROM identity_verifications iv WHERE iv.user_id = u.id)) AS verified
        FROM users u LEFT JOIN profiles p ON p.user_id = u.id WHERE u.id = ${id}
      `,
    ]);
    const row = facts[0];
    return {
      messages: messages.map((message) => ({ text: text(message.content) ?? "", conversationId: num(message.conversation_id) })),
      accountAgeDays: num(row?.age_days),
      reportsCount: num(row?.reports),
      blocksReceived: num(row?.blocks),
      verified: row?.verified === true,
    };
  }
}
