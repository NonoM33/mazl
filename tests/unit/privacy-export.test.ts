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
  consents: [{ purpose: "religious_data", granted: true }],
  consentHistory: [{ purpose: "religious_data", granted: true }],
  webSessions: [{ id: "s1", browser_label: "Firefox", method: "password", created_at: "2026-01-05", last_seen_at: "2026-01-06", token_hash: "deadbeef" }],
  withdrawalWaivers: [{ id: 1, accepted_at: "2026-01-07", signature_hash: "cafe" }],
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
      "reports_made", "subscription", "credits", "couple", "event_rsvps", "consents", "web_sessions", "withdrawal_waivers",
    ]) {
      expect(key in document).toBe(true);
    }
    expect(document.preferences).toEqual({ age_min: 25, age_max: 40, distance_max: 50, looking_for: "relationship" });
    expect(document.messages_sent).toEqual(sections.messagesSent);
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

  test("profile and account are cut to their allow-list", async () => {
    const { document } = await new ExportService(reader, fixedNow).export(7);
    expect(Object.keys(document.profile as object)).toEqual(["display_name", "denomination"]);
    expect(document.account).toEqual({ id: 7, email: "jeanne@example.com", name: "Jeanne Exemple", provider: "google", created_at: "2026-01-01" });
  });
});
