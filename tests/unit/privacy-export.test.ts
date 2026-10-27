import { describe, expect, test } from "bun:test";
import { ExportService } from "../../src/features/privacy/application/export-service";
import type { ExportReader } from "../../src/features/privacy/application/ports";
import type { ExportSections } from "../../src/features/privacy/domain/export-document";

const sections: ExportSections = {
  account: { id: 7, email: "jeanne@example.com", name: "Jeanne Exemple", provider: "google", provider_id: "g-123", created_at: "2026-01-01" },
  profile: {
    display_name: "Jeanne", denomination: "Massorti", age_min: 25, age_max: 40, distance_max: 50, looking_for: "relationship",
    face_embedding: [0.1], embedding_hash: "abc",
  },
  photos: [{ id: 1, position: 0, is_primary: true, created_at: "2026-01-02" }],
  prompts: [{ prompt_id: "p1", answer: "Hello" }],
  swipesGiven: [{ target_user_id: 8, action: "like", created_at: "2026-01-03" }],
  matches: [{ match_id: 1, other_user_id: 8, created_at: "2026-01-03" }],
  messagesSent: [{ conversation_id: 1, type: "text", content: "Shalom", created_at: "2026-01-04", unsent: false }],
  blocks: [],
  reportsMade: [],
  subscription: { plan_type: "monthly", status: "active", session_token: "leak" },
  credits: { balances: [{ kind: "boost", balance: 2 }], purchases: [], spends: [] },
  couple: null,
  eventRsvps: [],
  eventAlerts: [{ event_id: 4, created_at: "2026-10-26", notified_at: null }],
  consents: [{ purpose: "religious_data", granted: true }],
  discoverFilters: { denominations: ["Massorti"], kashrut_levels: null, shabbat_observances: null, only_verified: true, only_with_photo: false, updated_at: "2026-10-25", internal_note: "interne" },
  consentHistory: [{ purpose: "religious_data", granted: true }],
  webSessions: [{ id: "s1", browser_label: "Firefox", method: "password", created_at: "2026-01-05", last_seen_at: "2026-01-06", token_hash: "deadbeef" }],
  withdrawalWaivers: [{ id: 1, accepted_at: "2026-01-07", signature_hash: "cafe" }],
  bans: [{ reason: "Faux profil", banned_at: "2026-02-01", expires_at: null, is_permanent: false, unbanned_at: "2026-02-08", banned_by: "staff@example.com" }],
  sanctions: [{ kind: "suspension", ground: "harassment", starts_at: "2026-02-01", ends_at: "2026-02-08", statement: "Messages insistants.", decided_by: 3, appeal_code_hash: "f00d", note: "interne", created_at: "2026-02-01" }],
  moderationActions: [{ action: "warn", created_at: "2026-02-01", admin_email: "staff@example.com", details: "interne" }],
  faceSessions: [{ purpose: "photo", created_at: "2026-03-01", outcome: "verified", challenges: ["front"] }],
  identity: [{ method: "chip", issuing_state: "FRA", document_type: "P", document_expiry: "2030-01-01", verified_at: "2026-03-02", doc_fingerprint: "secret-print" }],
  faceReference: [{ model: "sface-2021", created_at: "2026-03-01", embedding_sealed: "sealed-bytes" }],
  verificationAttempts: [{ status: "verified", created_at: "2026-03-01", gesture_id: "g1" }],
  waitlist: { status: "confirmed", created_at: "2025-12-01", verification_status: "verified", verified_at: "2025-12-05", verification_token: "tok", token: "tok2" },
  premiumSettings: { user_id: 7, passport_city: "Tel-Aviv", passport_latitude: 32.0853, passport_longitude: 34.7818, incognito: true, send_read_receipts: false, updated_at: "2026-10-27", internal_note: "interne" },
  boostSchedule: { user_id: 7, run_at: "2026-10-31T21:00:00Z", claimed_at: null, created_at: "2026-10-27" },
  pushDevices: [{ id: 3, user_id: 7, token: "a1b2".repeat(16), environment: "production", created_at: "2026-10-26", last_seen_at: "2026-10-26" }],
  documents: [{ type: "selfie_id", status: "approved", created_at: "2025-12-02", reviewed_at: "2025-12-05", purged_at: "2025-12-06", filename: "abc.enc", reviewer_notes: "interne" }],
};

const reader: ExportReader = { read: () => Promise.resolve(sections) };
const fixedNow = () => new Date("2026-10-24T09:30:00Z");

function allKeys(value: unknown, into: string[] = []): string[] {
  if (Array.isArray(value)) value.forEach((entry) => allKeys(entry, into));
  else if (value !== null && typeof value === "object") {
    for (const [key, inner] of Object.entries(value)) {
      into.push(key);
      allKeys(inner, into);
    }
  }
  return into;
}

describe("member data export", () => {
  test("names the file after the member and the day", async () => {
    const file = await new ExportService(reader, fixedNow).export(7);
    expect(file.filename).toBe("mazl-export-7-2026-10-24.json");
  });

  test("carries every section of the contract", async () => {
    const { document } = await new ExportService(reader, fixedNow).export(7);
    expect(document.format).toBe("mazl-export");
    expect(document.version).toBe(1);
    expect(document.generated_at).toBe("2026-10-24T09:30:00.000Z");
    for (const key of [
      "account", "profile", "photos", "prompts", "preferences", "swipes_given", "matches", "messages_sent", "blocks",
      "reports_made", "subscription", "credits", "couple", "event_rsvps", "event_alerts", "consents", "discover_filters", "web_sessions", "withdrawal_waivers", "push_devices",
      "moderation", "verification", "waitlist_application",
    ]) {
      expect(key in document).toBe(true);
    }
    expect(document.event_alerts).toEqual([{ event_id: 4, created_at: "2026-10-26", notified_at: null }]);
    expect(document.preferences).toEqual({ age_min: 25, age_max: 40, distance_max: 50, looking_for: "relationship" });
    expect(document.messages_sent).toEqual(sections.messagesSent);
    // That a phone receives pushes, which and since when; not its APNs token.
    expect(document.push_devices).toEqual([{ environment: "production", created_at: "2026-10-26", last_seen_at: "2026-10-26" }]);
    expect(document.couple).toBeNull();
  });

  test("keeps no secret, hash, token, provider id or biometric reference, at any depth", async () => {
    const { document } = await new ExportService(reader, fixedNow).export(7);
    const keys = allKeys(document);
    for (const forbidden of ["provider_id", "face_embedding", "embedding_hash", "session_token", "token_hash", "signature_hash"]) {
      expect(keys).not.toContain(forbidden);
    }
    expect(keys.filter((key) => /token|hash|secret|provider_id/i.test(key))).toEqual([]);
    expect(document.web_sessions).toEqual([
      { id: "s1", browser_label: "Firefox", method: "password", created_at: "2026-01-05", last_seen_at: "2026-01-06" },
    ]);
  });

  test("the Discover filters are exported with their allowed fields only, null when the member has none", async () => {
    const { document } = await new ExportService(reader, fixedNow).export(7);
    expect(document.discover_filters).toEqual({
      denominations: ["Massorti"], kashrut_levels: null, shabbat_observances: null, only_verified: true, only_with_photo: false, updated_at: "2026-10-25",
    });
    const without = await new ExportService({ read: () => Promise.resolve({ ...sections, discoverFilters: null }) }, fixedNow).export(7);
    expect(without.document.discover_filters).toBeNull();
  });

  test("the mazl+ settings and the programmed Boost are exported with their allowed fields only", async () => {
    const { document } = await new ExportService(reader, fixedNow).export(7);
    expect(document.premium_settings).toEqual({
      passport_city: "Tel-Aviv", passport_latitude: 32.0853, passport_longitude: 34.7818, incognito: true, send_read_receipts: false, updated_at: "2026-10-27",
    });
    expect(document.boost_schedule).toEqual({ run_at: "2026-10-31T21:00:00Z", created_at: "2026-10-27" });
    const without = await new ExportService({ read: () => Promise.resolve({ ...sections, premiumSettings: null, boostSchedule: null }) }, fixedNow).export(7);
    expect([without.document.premium_settings, without.document.boost_schedule]).toEqual([null, null]);
  });

  test("profile and account are cut to their allow-list", async () => {
    const { document } = await new ExportService(reader, fixedNow).export(7);
    expect(Object.keys(document.profile as object)).toEqual(["display_name", "denomination"]);
    expect(document.account).toEqual({ id: 7, email: "jeanne@example.com", name: "Jeanne Exemple", provider: "google", created_at: "2026-01-01" });
  });
});

// Security review B7: moderation decisions and verification records are the
// member's data too; staff identities, internal notes, biometric and document
// fingerprints are not exported.
describe("moderation and verification in the export", () => {
  test("decisions and records are exported with their allowed fields only", async () => {
    const { document } = await new ExportService(reader, fixedNow).export(7);
    expect(document.moderation).toEqual({
      bans: [{ reason: "Faux profil", banned_at: "2026-02-01", expires_at: null, is_permanent: false, unbanned_at: "2026-02-08" }],
      sanctions: [{ kind: "suspension", ground: "harassment", starts_at: "2026-02-01", ends_at: "2026-02-08", statement: "Messages insistants.", created_at: "2026-02-01" }],
      actions: [{ action: "warn", created_at: "2026-02-01" }],
    });
    expect(document.verification).toEqual({
      face_sessions: [{ purpose: "photo", created_at: "2026-03-01", outcome: "verified" }],
      identity: [{ method: "chip", issuing_state: "FRA", document_type: "P", document_expiry: "2030-01-01", verified_at: "2026-03-02" }],
      stored_face_template: [{ model: "sface-2021", created_at: "2026-03-01" }],
      attempts: [{ status: "verified", created_at: "2026-03-01" }],
    });
    expect(document.waitlist_application).toEqual({
      application: { status: "confirmed", created_at: "2025-12-01", verification_status: "verified", verified_at: "2025-12-05" },
      documents: [{ type: "selfie_id", status: "approved", created_at: "2025-12-02", reviewed_at: "2025-12-05", purged_at: "2025-12-06" }],
    });
    const text = JSON.stringify(document);
    for (const secret of ["staff@example.com", "f00d", "interne", "secret-print", "sealed-bytes", "abc.enc", "tok2"]) expect(text).not.toContain(secret);
  });
});

