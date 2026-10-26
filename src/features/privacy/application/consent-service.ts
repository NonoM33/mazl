import {
  ANALYTICS,
  assertCurrentVersion,
  buildConsentView,
  isCurrentGrant,
  mustEraseReligiousData,
  RELIGIOUS_DATA,
  type ConsentDecision,
  type ConsentPurpose,
  type ConsentSource,
  type ConsentView,
  type StoredConsent,
} from "../domain/consent";
import type { ConsentRepository } from "./ports";

export interface ConsentChange {
  readonly granted: boolean;
  readonly version: string;
  readonly source: ConsentSource;
}

// Told after every recorded decision, e.g. so a cache of the consents forgets it.
export type ConsentDecisionListener = (userId: number, purpose: ConsentPurpose) => void;

export class ConsentService {
  constructor(
    private readonly repository: ConsentRepository,
    private readonly onDecision: ConsentDecisionListener = () => undefined,
  ) {}

  async list(userId: number): Promise<{ readonly religious_data: ConsentView; readonly analytics: ConsentView }> {
    const [religious, analytics] = await Promise.all([
      this.repository.current(userId, RELIGIOUS_DATA),
      this.repository.current(userId, ANALYTICS),
    ]);
    return { religious_data: buildConsentView(RELIGIOUS_DATA, religious), analytics: buildConsentView(ANALYTICS, analytics) };
  }

  async allowsReligiousData(userId: number): Promise<boolean> {
    return isCurrentGrant(RELIGIOUS_DATA, await this.repository.current(userId, RELIGIOUS_DATA));
  }

  async allowsAnalytics(userId: number): Promise<boolean> {
    return isCurrentGrant(ANALYTICS, await this.repository.current(userId, ANALYTICS));
  }

  // Throws ConsentVersionOutdatedError when the member answered an old wording.
  async decide(userId: number, purpose: ConsentPurpose, change: ConsentChange): Promise<StoredConsent> {
    assertCurrentVersion(purpose, change.version);
    const decision: ConsentDecision = { userId, purpose, ...change };
    const stored = await this.repository.record(decision, mustEraseReligiousData(decision));
    this.onDecision(userId, purpose);
    return stored;
  }
}
