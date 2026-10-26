export type JsonRecord = Readonly<Record<string, unknown>>;

// Keys that must never leave the server, whatever table they come from:
// credentials, fingerprints, provider identifiers, biometric references.
const FORBIDDEN_KEY = /token|hash|secret|provider_id|password|embedding|face_reference|signature|fingerprint/i;

export function stripSecrets(value: unknown): unknown {
  if (Array.isArray(value)) return value.map(stripSecrets);
  if (value instanceof Date || value === null || typeof value !== "object") return value;
  const kept: Record<string, unknown> = {};
  for (const [key, inner] of Object.entries(value)) {
    if (!FORBIDDEN_KEY.test(key)) kept[key] = stripSecrets(inner);
  }
  return kept;
}

export function pick(row: JsonRecord | null, keys: readonly string[]): JsonRecord | null {
  if (row === null) return null;
  const picked: Record<string, unknown> = {};
  for (const key of keys) if (key in row) picked[key] = row[key];
  return picked;
}

// Allow-lists: a column added to a table later stays out of the export until listed here.
export const ACCOUNT_KEYS = ["id", "email", "name", "picture", "provider", "created_at", "last_login_at", "is_active"] as const;
export const PREFERENCE_KEYS = ["age_min", "age_max", "distance_max", "looking_for"] as const;
export const PROFILE_KEYS = [
  "display_name", "birthdate", "gender", "bio", "location", "latitude", "longitude",
  "denomination", "kashrut_level", "shabbat_observance", "relationship_intention",
  "is_complete", "is_verified", "verification_level", "photo_verified_at", "identity_verified_at",
  "created_at", "updated_at",
] as const;
export const DISCOVER_FILTER_KEYS = [
  "denominations", "kashrut_levels", "shabbat_observances", "only_verified", "only_with_photo", "updated_at",
] as const;
export const WEB_SESSION_KEYS = ["id", "browser_label", "method", "created_at", "last_seen_at"] as const;
// Moderation and verification (security review B7): what was decided about the
// member and what was checked, never who decided, internal notes, biometric
// templates or document fingerprints.
export const BAN_KEYS = ["reason", "banned_at", "expires_at", "is_permanent", "unbanned_at"] as const;
export const SANCTION_KEYS = ["kind", "ground", "starts_at", "ends_at", "statement", "revoked_at", "created_at"] as const;
export const MODERATION_ACTION_KEYS = ["action", "created_at"] as const;
export const FACE_SESSION_KEYS = ["purpose", "created_at", "outcome"] as const;
export const IDENTITY_KEYS = ["method", "issuing_state", "document_type", "document_expiry", "verified_at"] as const;
export const FACE_REFERENCE_KEYS = ["model", "created_at"] as const;
export const ATTEMPT_KEYS = ["status", "created_at"] as const;
export const WAITLIST_KEYS = ["status", "created_at", "confirmed_at", "verification_status", "verification_requested_at", "documents_submitted_at", "verified_at"] as const;
export const DOCUMENT_KEYS = ["type", "status", "created_at", "reviewed_at", "purged_at"] as const;

export interface ExportCredits {
  readonly balances: readonly JsonRecord[];
  readonly purchases: readonly JsonRecord[];
  readonly spends: readonly JsonRecord[];
}

export interface ExportSections {
  readonly account: JsonRecord | null;
  readonly profile: JsonRecord | null;
  readonly photos: readonly JsonRecord[];
  readonly prompts: readonly JsonRecord[];
  readonly swipesGiven: readonly JsonRecord[];
  readonly matches: readonly JsonRecord[];
  readonly messagesSent: readonly JsonRecord[];
  readonly blocks: readonly JsonRecord[];
  readonly reportsMade: readonly JsonRecord[];
  readonly subscription: JsonRecord | null;
  readonly credits: ExportCredits;
  readonly couple: JsonRecord | null;
  readonly eventRsvps: readonly JsonRecord[];
  // « Me prévenir » on coming soon events.
  readonly eventAlerts: readonly JsonRecord[];
  readonly consents: readonly JsonRecord[];
  readonly discoverFilters: JsonRecord | null;
  readonly consentHistory: readonly JsonRecord[];
  readonly webSessions: readonly JsonRecord[];
  readonly withdrawalWaivers: readonly JsonRecord[];
  readonly bans: readonly JsonRecord[];
  readonly sanctions: readonly JsonRecord[];
  readonly moderationActions: readonly JsonRecord[];
  readonly faceSessions: readonly JsonRecord[];
  readonly identity: readonly JsonRecord[];
  readonly faceReference: readonly JsonRecord[];
  readonly verificationAttempts: readonly JsonRecord[];
  readonly waitlist: JsonRecord | null;
  readonly documents: readonly JsonRecord[];
}

const pickAll = (rows: readonly JsonRecord[], keys: readonly string[]) => rows.map((row) => pick(row, keys));

export interface ExportDocument {
  readonly format: "mazl-export";
  readonly version: 1;
  readonly generated_at: string;
  readonly [section: string]: unknown;
}

export function buildExportDocument(sections: ExportSections, generatedAt: Date): ExportDocument {
  const document = {
    format: "mazl-export",
    version: 1,
    generated_at: generatedAt.toISOString(),
    account: pick(sections.account, ACCOUNT_KEYS),
    profile: pick(sections.profile, PROFILE_KEYS),
    photos: sections.photos,
    prompts: sections.prompts,
    preferences: pick(sections.profile, PREFERENCE_KEYS),
    swipes_given: sections.swipesGiven,
    matches: sections.matches,
    messages_sent: sections.messagesSent,
    blocks: sections.blocks,
    reports_made: sections.reportsMade,
    subscription: sections.subscription,
    credits: sections.credits,
    couple: sections.couple,
    event_rsvps: sections.eventRsvps,
    event_alerts: sections.eventAlerts,
    consents: { current: sections.consents, history: sections.consentHistory },
    discover_filters: pick(sections.discoverFilters, DISCOVER_FILTER_KEYS),
    web_sessions: sections.webSessions.map((row) => pick(row, WEB_SESSION_KEYS)),
    withdrawal_waivers: sections.withdrawalWaivers,
    moderation: {
      bans: pickAll(sections.bans, BAN_KEYS),
      sanctions: pickAll(sections.sanctions, SANCTION_KEYS),
      actions: pickAll(sections.moderationActions, MODERATION_ACTION_KEYS),
    },
    verification: {
      face_sessions: pickAll(sections.faceSessions, FACE_SESSION_KEYS),
      identity: pickAll(sections.identity, IDENTITY_KEYS),
      // That a face template is stored, its model and date; never the template.
      stored_face_template: pickAll(sections.faceReference, FACE_REFERENCE_KEYS),
      attempts: pickAll(sections.verificationAttempts, ATTEMPT_KEYS),
    },
    waitlist_application: {
      application: pick(sections.waitlist, WAITLIST_KEYS),
      documents: pickAll(sections.documents, DOCUMENT_KEYS),
    },
  };
  return stripSecrets(document) as ExportDocument;
}
