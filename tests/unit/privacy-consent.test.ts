import { describe, expect, test } from "bun:test";
import { ConsentService } from "../../src/features/privacy/application/consent-service";
import type { ConsentRepository } from "../../src/features/privacy/application/ports";
import {
  ANALYTICS,
  ANALYTICS_TEXT,
  ANALYTICS_VERSION,
  ConsentVersionOutdatedError,
  RELIGIOUS_DATA,
  RELIGIOUS_DATA_TEXT,
  RELIGIOUS_DATA_VERSION,
  type ConsentDecision,
  type ConsentPurpose,
  type StoredConsent,
} from "../../src/features/privacy/domain/consent";

class InMemoryConsents implements ConsentRepository {
  readonly history: ConsentDecision[] = [];
  readonly erasures: boolean[] = [];
  private readonly latest = new Map<string, StoredConsent>();

  current(userId: number, purpose: ConsentPurpose): Promise<StoredConsent | null> {
    return Promise.resolve(this.latest.get(`${userId}:${purpose}`) ?? null);
  }

  record(decision: ConsentDecision, eraseReligiousData: boolean): Promise<StoredConsent> {
    const stored = { granted: decision.granted, version: decision.version, decidedAt: new Date("2026-10-24T10:00:00Z") };
    this.latest.set(`${decision.userId}:${decision.purpose}`, stored);
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
    const stored = await service.decide(1, RELIGIOUS_DATA, { granted: true, version: "2026-10-24", source: "web" });
    expect(stored.granted).toBe(true);
    expect(repository.erasures).toEqual([false]);
    expect((await service.list(1)).religious_data.granted).toBe(true);
  });

  test("withdrawing asks the repository to erase, and keeps the history", async () => {
    const repository = new InMemoryConsents();
    const service = new ConsentService(repository);
    await service.decide(1, RELIGIOUS_DATA, { granted: true, version: "2026-10-24", source: "web" });
    await service.decide(1, RELIGIOUS_DATA, { granted: false, version: "2026-10-24", source: "app" });
    expect(repository.erasures).toEqual([false, true]);
    expect(repository.history.map((entry) => [entry.granted, entry.source])).toEqual([[true, "web"], [false, "app"]]);
    expect((await service.list(1)).religious_data.granted).toBe(false);
  });

  test("an outdated version is refused and nothing is recorded", async () => {
    const repository = new InMemoryConsents();
    const attempt = new ConsentService(repository).decide(1, RELIGIOUS_DATA, { granted: true, version: "2025-01-01", source: "web" });
    await expect(attempt).rejects.toBeInstanceOf(ConsentVersionOutdatedError);
    expect(repository.history).toHaveLength(0);
  });
});

describe("analytics consent", () => {
  test("is listed next to the religious one, never asked yet, with its own text and version", async () => {
    const consents = await new ConsentService(new InMemoryConsents()).list(1);
    expect(consents.analytics.granted).toBeNull();
    expect(consents.analytics.current_version).toBe(ANALYTICS_VERSION);
    expect(ANALYTICS_VERSION).toBe("2026-10-26");
    expect(consents.analytics.text).toBe(ANALYTICS_TEXT);
    expect(ANALYTICS_TEXT).toContain("pseudonyme");
    expect(consents.religious_data.current_version).toBe(RELIGIOUS_DATA_VERSION);
  });

  test("granting it allows the analytics and leaves the religious consent untouched", async () => {
    const repository = new InMemoryConsents();
    const service = new ConsentService(repository);
    await service.decide(1, ANALYTICS, { granted: true, version: ANALYTICS_VERSION, source: "app" });
    expect(await service.allowsAnalytics(1)).toBe(true);
    expect(await service.allowsReligiousData(1)).toBe(false);
    expect(repository.history.map((entry) => entry.purpose)).toEqual([ANALYTICS]);
  });

  test("withdrawing it never erases the religious data", async () => {
    const repository = new InMemoryConsents();
    const service = new ConsentService(repository);
    await service.decide(1, ANALYTICS, { granted: false, version: ANALYTICS_VERSION, source: "app" });
    expect(repository.erasures).toEqual([false]);
    expect(await service.allowsAnalytics(1)).toBe(false);
  });

  test("a consent given to the religious version does not count for the analytics one", async () => {
    const attempt = new ConsentService(new InMemoryConsents()).decide(1, ANALYTICS, {
      granted: true,
      version: RELIGIOUS_DATA_VERSION,
      source: "app",
    });
    await expect(attempt).rejects.toBeInstanceOf(ConsentVersionOutdatedError);
  });

  test("a member never asked is not counted as consenting", async () => {
    expect(await new ConsentService(new InMemoryConsents()).allowsAnalytics(1)).toBe(false);
  });

  test("the decision listeners hear every analytics decision, and only those", async () => {
    const heard: Array<[number, string]> = [];
    const service = new ConsentService(new InMemoryConsents(), (userId, purpose) => heard.push([userId, purpose]));
    await service.decide(7, ANALYTICS, { granted: false, version: ANALYTICS_VERSION, source: "web" });
    await service.decide(7, RELIGIOUS_DATA, { granted: true, version: RELIGIOUS_DATA_VERSION, source: "web" });
    expect(heard).toEqual([[7, ANALYTICS], [7, RELIGIOUS_DATA]]);
  });
});
