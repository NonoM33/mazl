// Explicit, separate consents, each with its own versioned text:
// - religious-practice data (GDPR art. 9; docs/web/adr/W06);
// - the measurement of use (docs/analytics/plan-de-marquage.md).
export const RELIGIOUS_DATA = "religious_data";
export const ANALYTICS = "analytics";
export const CONSENT_PURPOSES = [RELIGIOUS_DATA, ANALYTICS] as const;
export type ConsentPurpose = (typeof CONSENT_PURPOSES)[number];

// Bump the version whenever the wording changes: older decisions are then outdated.
export const RELIGIOUS_DATA_VERSION = "2026-10-24";

export const RELIGIOUS_DATA_TEXT =
  "J'accepte que MAZL traite les informations sur ma pratique religieuse que je choisis de renseigner " +
  "(courant, cashrout, Shabbat, intention) pour me proposer des profils compatibles et les afficher sur mon profil. " +
  "Ce consentement est facultatif et je peux le retirer à tout moment dans les réglages ; " +
  "les informations sont alors effacées.";

export const ANALYTICS_VERSION = "2026-10-26";

export const ANALYTICS_TEXT =
  "J'accepte que MAZL mesure mon utilisation de l'application pour l'améliorer : écrans consultés, " +
  "étapes de l'inscription, swipes, matchs, messages envoyés, achats et vérifications, sans jamais leur contenu. " +
  "Ces mesures sont rattachées à un identifiant pseudonyme, ne contiennent ni mes messages, ni mes informations " +
  "religieuses, ni ma position, et restent sur les serveurs de MAZL, sans publicité ni partage. " +
  "Ce consentement est facultatif et je peux le retirer à tout moment dans les réglages.";

const WORDINGS: Readonly<Record<ConsentPurpose, { readonly version: string; readonly text: string }>> = {
  [RELIGIOUS_DATA]: { version: RELIGIOUS_DATA_VERSION, text: RELIGIOUS_DATA_TEXT },
  [ANALYTICS]: { version: ANALYTICS_VERSION, text: ANALYTICS_TEXT },
};

export function currentVersionOf(purpose: ConsentPurpose): string {
  return WORDINGS[purpose].version;
}

export function isConsentPurpose(value: string): value is ConsentPurpose {
  return (CONSENT_PURPOSES as readonly string[]).includes(value);
}

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
  readonly currentVersion: string;

  constructor(
    readonly purpose: ConsentPurpose,
    readonly submitted: string,
  ) {
    const currentVersion = currentVersionOf(purpose);
    super(`${purpose} consent version ${submitted} is not the current one (${currentVersion})`);
    this.name = "ConsentVersionOutdatedError";
    this.currentVersion = currentVersion;
  }
}

export function assertCurrentVersion(purpose: ConsentPurpose, submitted: string): void {
  if (submitted !== currentVersionOf(purpose)) throw new ConsentVersionOutdatedError(purpose, submitted);
}

// Withdrawing the religious consent erases the data it covered; nothing else erases.
export function mustEraseReligiousData(decision: Pick<ConsentDecision, "granted" | "purpose">): boolean {
  return decision.purpose === RELIGIOUS_DATA && !decision.granted;
}

export interface ConsentView {
  readonly granted: boolean | null;
  readonly version: string | null;
  readonly decided_at: string | null;
  readonly current_version: string;
  readonly text: string;
}

export function buildConsentView(purpose: ConsentPurpose, stored: StoredConsent | null): ConsentView {
  return {
    granted: stored?.granted ?? null,
    version: stored?.version ?? null,
    decided_at: stored?.decidedAt.toISOString() ?? null,
    current_version: WORDINGS[purpose].version,
    text: WORDINGS[purpose].text,
  };
}

// Only a consent given to the current text counts.
export function isCurrentGrant(purpose: ConsentPurpose, stored: Pick<StoredConsent, "granted" | "version"> | null): boolean {
  return stored !== null && stored.granted && stored.version === currentVersionOf(purpose);
}

// Religious data may be stored only under a consent given to the current text.
export function allowsReligiousData(stored: Pick<StoredConsent, "granted" | "version"> | null): boolean {
  return isCurrentGrant(RELIGIOUS_DATA, stored);
}
