import {
  assertCurrentVersion,
  buildConsentView,
  mustEraseReligiousData,
  RELIGIOUS_DATA,
  type ConsentDecision,
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

export class ConsentService {
  constructor(private readonly repository: ConsentRepository) {}

  async list(userId: number): Promise<{ readonly religious_data: ConsentView }> {
    const stored = await this.repository.current(userId, RELIGIOUS_DATA);
    return { religious_data: buildConsentView(stored) };
  }

  // Throws ConsentVersionOutdatedError when the member answered an old wording.
  async decide(userId: number, change: ConsentChange): Promise<StoredConsent> {
    assertCurrentVersion(change.version);
    const decision: ConsentDecision = { userId, purpose: RELIGIOUS_DATA, ...change };
    return await this.repository.record(decision, mustEraseReligiousData(decision));
  }
}
