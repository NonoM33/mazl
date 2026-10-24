// Explicit, separate consent for religious-practice data (GDPR art. 9; docs/web/adr/W06).
export const RELIGIOUS_DATA = "religious_data";
export type ConsentPurpose = typeof RELIGIOUS_DATA;

// Bump the version whenever the wording changes: older decisions are then outdated.
export const RELIGIOUS_DATA_VERSION = "2026-10-24";

export const RELIGIOUS_DATA_TEXT =
  "J'accepte que MAZL traite les informations sur ma pratique religieuse que je choisis de renseigner " +
  "(courant, cashrout, Shabbat, intention) pour me proposer des profils compatibles et les afficher sur mon profil. " +
  "Ce consentement est facultatif et je peux le retirer à tout moment dans les réglages ; " +
  "les informations sont alors effacées.";

export type ConsentSource = "web" | "app";

export interface ConsentDecision {
  readonly userId: number;
  readonly purpose: ConsentPurpose;
  readonly granted: boolean;
  readonly version: string;
  readonly source: ConsentSource;
}

export interface StoredConsent {
  readonly granted: boolean;
  readonly version: string;
  readonly decidedAt: Date;
}

export class ConsentVersionOutdatedError extends Error {
  constructor(readonly submitted: string) {
    super(`consent version ${submitted} is not the current one (${RELIGIOUS_DATA_VERSION})`);
    this.name = "ConsentVersionOutdatedError";
  }
}

export function assertCurrentVersion(submitted: string): void {
  if (submitted !== RELIGIOUS_DATA_VERSION) throw new ConsentVersionOutdatedError(submitted);
}

// Withdrawing the consent erases the data it covered; granting erases nothing.
export function mustEraseReligiousData(decision: Pick<ConsentDecision, "granted">): boolean {
  return !decision.granted;
}

export interface ConsentView {
  readonly granted: boolean | null;
  readonly version: string | null;
  readonly decided_at: string | null;
  readonly current_version: string;
  readonly text: string;
}

export function buildConsentView(stored: StoredConsent | null): ConsentView {
  return {
    granted: stored?.granted ?? null,
    version: stored?.version ?? null,
    decided_at: stored?.decidedAt.toISOString() ?? null,
    current_version: RELIGIOUS_DATA_VERSION,
    text: RELIGIOUS_DATA_TEXT,
  };
}
