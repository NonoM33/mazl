// Ports of level 2 (identity from the document chip). CONTRACT: CONTRAT.md §4.

// What is kept of a verified document. No name, no document number: the
// fingerprint is an HMAC of "<state>|<number>|<birth date>" under
// DOC_FINGERPRINT_KEY, which only proves "this document is already in use".
export interface IdentityRecord {
  readonly userId: number;
  readonly method: "nfc_passive_auth";
  readonly issuingState: string;
  readonly documentType: string;
  readonly fingerprint: string;
  readonly documentExpiry: string; // ISO yyyy-mm-dd
  readonly birthDate: string; // ISO yyyy-mm-dd, becomes the profile's locked birthdate
}

export type IdentitySaveResult = "saved" | "fingerprint_taken";

export interface IdentityRepository {
  isBanned(fingerprint: string): Promise<boolean>;
  // User id already holding this document, or null.
  ownerOf(fingerprint: string): Promise<number | null>;
  // Atomic: identity row, profile birthdate locked, identity_verified_at set.
  // "fingerprint_taken" when another account won a concurrent race.
  save(record: IdentityRecord): Promise<IdentitySaveResult>;
}

export type DocumentFingerprinter = (message: string) => string;
