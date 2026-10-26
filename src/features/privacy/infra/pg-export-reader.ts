import type { Sql } from "postgres";
import type { ExportReader } from "../application/ports";
import type { ExportCredits, ExportSections, JsonRecord } from "../domain/export-document";

type Rows = Promise<JsonRecord[]>;

// Tables owned by other branches: read only when they exist (and have the owner column).
const WEB_SESSIONS_TABLE = "web_sessions";
const WITHDRAWAL_WAIVERS_TABLE = "billing_withdrawal_waivers";
const DISCOVER_FILTERS_TABLE = "discover_filters";

export class PgExportReader implements ExportReader {
  constructor(private readonly sql: Sql) {}

  async read(userId: number): Promise<ExportSections> {
    const [account, profile, subscription, couple] = await Promise.all([
      this.account(userId), this.profile(userId), this.subscription(userId), this.couple(userId),
    ]);
    const [photos, prompts, swipesGiven, matches, messagesSent, blocks, reportsMade] = await Promise.all([
      this.photos(userId), this.prompts(userId), this.swipesGiven(userId), this.matches(userId),
      this.messagesSent(userId), this.blocks(userId), this.reportsMade(userId),
    ]);
    const [credits, eventRsvps, eventAlerts, consents, consentHistory, webSessions, withdrawalWaivers, discoverFilters] = await Promise.all([
      this.credits(userId), this.eventRsvps(userId), this.eventAlerts(userId), this.consents(userId), this.consentHistory(userId),
      this.optionalTable(WEB_SESSIONS_TABLE, userId), this.optionalTable(WITHDRAWAL_WAIVERS_TABLE, userId),
      this.optionalTable(DISCOVER_FILTERS_TABLE, userId),
    ]);
    const [bans, sanctions, faceSessions, identity, faceReference, verificationAttempts] = await Promise.all([
      this.optionalTable("user_bans", userId), this.optionalTable("member_sanctions", userId),
      this.optionalTable("face_verification_sessions", userId), this.optionalTable("identity_verifications", userId),
      this.optionalTable("face_references", userId), this.optionalTable("verification_attempts", userId),
    ]);
    const [moderationActions, application, pushDevices] = await Promise.all([
      this.moderationActions(userId), this.waitlistOf(account), this.optionalTable("push_devices", userId),
    ]);
    return {
      account, profile, photos, prompts, swipesGiven, matches, messagesSent, blocks, reportsMade,
      subscription, credits, couple, eventRsvps, eventAlerts, consents, discoverFilters: discoverFilters[0] ?? null, consentHistory, webSessions, withdrawalWaivers,
      bans, sanctions, moderationActions, faceSessions, identity, faceReference, verificationAttempts,
      waitlist: application.waitlist, documents: application.documents, pushDevices,
    };
  }

  // Actions the console logged against the member's account.
  private async moderationActions(userId: number): Promise<JsonRecord[]> {
    return await this.sql<JsonRecord[]>`
      SELECT action, created_at FROM moderation_logs
      WHERE target_type = 'user' AND target_id = ${userId} ORDER BY id
    `.catch(() => []);
  }

  // The waitlist application filed with the account's e-mail, and its documents.
  private async waitlistOf(account: JsonRecord | null): Promise<{ waitlist: JsonRecord | null; documents: JsonRecord[] }> {
    const email = typeof account?.email === "string" ? account.email : null;
    if (email === null) return { waitlist: null, documents: [] };
    const rows = await this.sql<{ row: JsonRecord }[]>`SELECT to_jsonb(w) AS row FROM waitlist w WHERE LOWER(w.email) = LOWER(${email}) LIMIT 1`;
    const waitlist = rows[0]?.row ?? null;
    const id = waitlist?.id;
    if (typeof id !== "number") return { waitlist, documents: [] };
    const documents = await this.sql<{ row: JsonRecord }[]>`SELECT to_jsonb(d) AS row FROM documents d WHERE d.waitlist_id = ${id} ORDER BY d.id`;
    return { waitlist, documents: documents.map((entry) => entry.row) };
  }

  // to_jsonb keeps the read independent of columns that other branches add;
  // the export document then keeps only its allow-listed keys.
  private async account(userId: number): Promise<JsonRecord | null> {
    const rows = await this.sql<{ row: JsonRecord }[]>`SELECT to_jsonb(u) AS row FROM users u WHERE u.id = ${userId}`;
    return rows[0]?.row ?? null;
  }

  private async profile(userId: number): Promise<JsonRecord | null> {
    const rows = await this.sql<{ row: JsonRecord }[]>`SELECT to_jsonb(p) AS row FROM profiles p WHERE p.user_id = ${userId}`;
    return rows[0]?.row ?? null;
  }

  private photos(userId: number): Rows {
    return this.sql<JsonRecord[]>`
      SELECT id, position, is_primary, created_at FROM profile_photos WHERE user_id = ${userId} ORDER BY position, id
    `;
  }

  private prompts(userId: number): Rows {
    return this.sql<JsonRecord[]>`
      SELECT prompt_id, answer, position, created_at FROM profile_prompts WHERE user_id = ${userId} ORDER BY position, id
    `;
  }

  private swipesGiven(userId: number): Rows {
    return this.sql<JsonRecord[]>`
      SELECT target_user_id, action, created_at FROM swipes WHERE user_id = ${userId} ORDER BY id
    `;
  }

  private matches(userId: number): Rows {
    return this.sql<JsonRecord[]>`
      SELECT id AS match_id, CASE WHEN user1_id = ${userId} THEN user2_id ELSE user1_id END AS other_user_id, created_at
      FROM matches WHERE user1_id = ${userId} OR user2_id = ${userId} ORDER BY id
    `;
  }

  // Only what the member wrote: the other member's messages are that member's data.
  private messagesSent(userId: number): Rows {
    return this.sql<JsonRecord[]>`
      SELECT conversation_id, type, content, created_at, (unsent_at IS NOT NULL) AS unsent
      FROM messages WHERE sender_id = ${userId} ORDER BY id
    `;
  }

  private blocks(userId: number): Rows {
    return this.sql<JsonRecord[]>`
      SELECT blocked_id AS blocked_user_id, created_at FROM blocked_users WHERE blocker_id = ${userId} ORDER BY id
    `;
  }

  private reportsMade(userId: number): Rows {
    return this.sql<JsonRecord[]>`
      SELECT reported_user_id, reason, details, status, created_at FROM reports WHERE reporter_id = ${userId} ORDER BY id
    `;
  }

  private async subscription(userId: number): Promise<JsonRecord | null> {
    const rows = await this.sql<JsonRecord[]>`
      SELECT plan_type, status, store, product_id, original_transaction_id, started_at, expires_at, created_at
      FROM subscriptions WHERE user_id = ${userId}
    `;
    return rows[0] ?? null;
  }

  private async credits(userId: number): Promise<ExportCredits> {
    const [balances, purchases, spends] = await Promise.all([
      this.sql<JsonRecord[]>`SELECT kind, balance FROM credit_balances WHERE user_id = ${userId} ORDER BY kind`,
      this.sql<JsonRecord[]>`
        SELECT transaction_id, product_id, kind, quantity, environment, purchased_at, refunded_at
        FROM credit_purchases WHERE user_id = ${userId} ORDER BY purchased_at
      `,
      this.sql<JsonRecord[]>`
        SELECT kind, source, target_user_id, created_at FROM credit_spends WHERE user_id = ${userId} ORDER BY id
      `,
    ]);
    return { balances, purchases, spends };
  }

  private async couple(userId: number): Promise<JsonRecord | null> {
    const rows = await this.sql<JsonRecord[]>`
      SELECT id AS couple_id, CASE WHEN user1_id = ${userId} THEN user2_id ELSE user1_id END AS partner_user_id,
             status, relationship_status, started_at, met_on_mazl_at, created_at
      FROM couples WHERE user1_id = ${userId} OR user2_id = ${userId} ORDER BY id DESC LIMIT 1
    `;
    return rows[0] ?? null;
  }

  private eventRsvps(userId: number): Rows {
    return this.sql<JsonRecord[]>`
      SELECT event_id, status, paid, created_at FROM event_rsvps WHERE user_id = ${userId} ORDER BY id
    `;
  }

  private eventAlerts(userId: number): Rows {
    return this.sql<JsonRecord[]>`
      SELECT event_id, created_at, notified_at FROM event_open_alerts WHERE user_id = ${userId} ORDER BY created_at, event_id
    `;
  }

  private consents(userId: number): Rows {
    return this.sql<JsonRecord[]>`
      SELECT purpose, granted, version, source, decided_at FROM user_consents WHERE user_id = ${userId} ORDER BY purpose
    `;
  }

  private consentHistory(userId: number): Rows {
    return this.sql<JsonRecord[]>`
      SELECT purpose, granted, version, source, decided_at FROM user_consent_events WHERE user_id = ${userId} ORDER BY id
    `;
  }

  // `table` is always one of the constants above, never request data.
  private async optionalTable(table: string, userId: number): Promise<JsonRecord[]> {
    const present = await this.sql`
      SELECT 1 FROM information_schema.columns
      WHERE table_schema = current_schema() AND table_name = ${table} AND column_name = 'user_id'
    `;
    if (present.length === 0) return [];
    const rows = await this.sql<{ row: JsonRecord }[]>`
      SELECT to_jsonb(t) AS row FROM ${this.sql(table)} t WHERE t.user_id = ${userId}
    `;
    return rows.map((entry) => entry.row);
  }
}
