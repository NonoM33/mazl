import { describe, expect, test } from "bun:test";
import { ConsentService } from "../../src/features/privacy/application/consent-service";
import type { ConsentRepository } from "../../src/features/privacy/application/ports";
import {
  ConsentVersionOutdatedError,
  RELIGIOUS_DATA_TEXT,
  RELIGIOUS_DATA_VERSION,
  type ConsentDecision,
  type ConsentPurpose,
  type StoredConsent,
} from "../../src/features/privacy/domain/consent";

class InMemoryConsents implements ConsentRepository {
  readonly history: ConsentDecision[] = [];
  readonly erasures: boolean[] = [];
  private readonly latest = new Map<number, StoredConsent>();

  current(userId: number, _purpose: ConsentPurpose): Promise<StoredConsent | null> {
    return Promise.resolve(this.latest.get(userId) ?? null);
  }

  record(decision: ConsentDecision, eraseReligiousData: boolean): Promise<StoredConsent> {
    const stored = { granted: decision.granted, version: decision.version, decidedAt: new Date("2026-10-24T10:00:00Z") };
    this.latest.set(decision.userId, stored);
    this.history.push(decision);
    this.erasures.push(eraseReligiousData);
    return Promise.resolve(stored);
  }
}

describe("religious data consent", () => {
  test("a member never asked has granted = null and sees the current text", async () => {
    const view = (await new ConsentService(new InMemoryConsents()).list(1)).religious_data;
    expect(view.granted).toBeNull();
    expect(view.version).toBeNull();
    expect(view.decided_at).toBeNull();
    expect(view.current_version).toBe("2026-10-24");
    expect(view.text).toBe(RELIGIOUS_DATA_TEXT);
    expect(RELIGIOUS_DATA_VERSION).toBe("2026-10-24");
  });

  test("granting records the decision and erases nothing", async () => {
    const repository = new InMemoryConsents();
    const service = new ConsentService(repository);
    const stored = await service.decide(1, { granted: true, version: "2026-10-24", source: "web" });
    expect(stored.granted).toBe(true);
    expect(repository.erasures).toEqual([false]);
    expect((await service.list(1)).religious_data.granted).toBe(true);
  });

  test("withdrawing asks the repository to erase, and keeps the history", async () => {
    const repository = new InMemoryConsents();
    const service = new ConsentService(repository);
    await service.decide(1, { granted: true, version: "2026-10-24", source: "web" });
    await service.decide(1, { granted: false, version: "2026-10-24", source: "app" });
    expect(repository.erasures).toEqual([false, true]);
    expect(repository.history.map((entry) => [entry.granted, entry.source])).toEqual([[true, "web"], [false, "app"]]);
    expect((await service.list(1)).religious_data.granted).toBe(false);
  });

  test("an outdated version is refused and nothing is recorded", async () => {
    const repository = new InMemoryConsents();
    const attempt = new ConsentService(repository).decide(1, { granted: true, version: "2025-01-01", source: "web" });
    await expect(attempt).rejects.toBeInstanceOf(ConsentVersionOutdatedError);
    expect(repository.history).toHaveLength(0);
  });
});
