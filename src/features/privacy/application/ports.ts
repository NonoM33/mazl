import type { ConsentDecision, ConsentPurpose, StoredConsent } from "../domain/consent";
import type { ExportSections } from "../domain/export-document";

export interface ConsentRepository {
  // The latest decision of the member for this purpose, or null when never asked.
  current(userId: number, purpose: ConsentPurpose): Promise<StoredConsent | null>;
  // Appends the decision to the history and replaces the current one. When
  // `eraseReligiousData` is set, the profile columns it covers are cleared in
  // the SAME transaction, so a withdrawal never leaves data behind.
  record(decision: ConsentDecision, eraseReligiousData: boolean): Promise<StoredConsent>;
}

// One read per section of the export, each scoped to the member.
export interface ExportReader {
  read(userId: number): Promise<ExportSections>;
}
