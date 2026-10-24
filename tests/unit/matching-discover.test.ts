import { describe, expect, test } from "bun:test";
import { createFeed, inAbTestShare, parisDay, RANKING_WINDOW } from "../../src/features/matching/application/discover";
import { DEFAULT_PARAMS } from "../../src/features/matching/domain/params";
import { syntheticPopulation } from "../../src/features/matching/domain/synthetic";
import { FakeCandidates, FakeHydrator, InMemoryParams } from "./support/matching-fakes";

// An open viewer, so that most of the population is eligible and the window is full.
const population = syntheticPopulation(7, 1000).profiles;
const viewer = { ...population[0]!, userId: 5000, age: 30, gender: "male" as const, lookingFor: "all" as const, ageMin: 18, ageMax: 99, distanceMaxKm: null, location: null };
const candidates = population.slice(1);

function setup(options: { day?: string } = {}) {
  const params = new InMemoryParams();
  const source = new FakeCandidates({ viewer, candidates, excluded: new Set() });
  const hydrator = new FakeHydrator();
  const clock = { day: options.day ?? "2026-03-10" };
  const feed = createFeed({ params, candidates: source, hydrator, clock: () => new Date(`${clock.day}T10:00:00Z`) });
  return { params, source, hydrator, clock, feed };
}

describe("daily seed", () => {
  test("same member, same day: same order", async () => {
    const { feed } = setup();
    const first = await feed.rank(viewer.userId, { limit: 50, offset: 0 });
    const second = await feed.rank(viewer.userId, { limit: 50, offset: 0 });
    expect([...second.userIds]).toEqual([...first.userIds]);
  });

  test("another day: the exploration slots change, the rest stays", async () => {
    const { feed, clock } = setup();
    const orders: number[][] = [];
    for (const day of ["2026-03-10", "2026-03-11", "2026-03-12", "2026-03-13", "2026-03-14"]) {
      clock.day = day;
      orders.push([...(await feed.rank(viewer.userId, { limit: 50, offset: 0 })).userIds]);
    }
    const distinct = new Set(orders.map((o) => o.join(",")));
    expect(distinct.size).toBeGreaterThan(1);
  });

  test("the day is the Paris day, not the UTC one", () => {
    expect(parisDay(new Date("2026-03-10T23:30:00Z"))).toBe("2026-03-11");
    expect(parisDay(new Date("2026-07-10T21:59:00Z"))).toBe("2026-07-10");
    expect(parisDay(new Date("2026-07-10T22:01:00Z"))).toBe("2026-07-11");
  });
});

describe("fixed ranking window", () => {
  test("page 1 + page 2 are the first 40 of the window, without duplicate", async () => {
    const { feed } = setup();
    const whole = await feed.rank(viewer.userId, { limit: RANKING_WINDOW, offset: 0 });
    const page1 = await feed.rank(viewer.userId, { limit: 20, offset: 0 });
    const page2 = await feed.rank(viewer.userId, { limit: 20, offset: 20 });
    const joined = [...page1.userIds, ...page2.userIds];
    expect(joined).toEqual([...whole.userIds].slice(0, 40));
    expect(new Set(joined).size).toBe(40);
  });

  test("discover hydrates exactly the ranked ids, in order", async () => {
    const { feed, hydrator } = setup();
    const ranked = await feed.rank(viewer.userId, { limit: 10, offset: 5 });
    const profiles = await feed.discover(viewer.userId, { limit: 10, offset: 5 });
    expect(hydrator.asked.at(-1)).toEqual([...ranked.userIds]);
    expect(profiles.map((p) => p.user_id)).toEqual([...ranked.userIds]);
  });

  test("daily picks are the first 5", async () => {
    const { feed } = setup();
    const top = await feed.rank(viewer.userId, { limit: 5, offset: 0 });
    expect((await feed.dailyPicks(viewer.userId)).map((p) => p.user_id)).toEqual([...top.userIds]);
    expect(top.userIds).toHaveLength(5);
  });

  test("a member without profile gets an empty feed and no hydration", async () => {
    const hydrator = new FakeHydrator();
    const feed = createFeed({ params: new InMemoryParams(), candidates: new FakeCandidates(null), hydrator });
    expect(await feed.discover(1, { limit: 20, offset: 0 })).toEqual([]);
    expect(hydrator.asked).toHaveLength(1);
    expect(hydrator.asked[0]).toEqual([]);
  });

  test("scores never reach the profiles handed to the app", async () => {
    const { feed } = setup();
    const profiles = await feed.discover(viewer.userId, { limit: 20, offset: 0 });
    for (const profile of profiles) {
      expect(Object.keys(profile).sort()).toEqual(["display_name", "user_id"]);
    }
  });
});

describe("A/B test", () => {
  test("the bucket is stable and its proportion follows the share on 10 000 ids", () => {
    for (const share of [1, 10, 25, 50]) {
      let inside = 0;
      for (let id = 1; id <= 10_000; id++) {
        const first = inAbTestShare(id, share);
        expect(inAbTestShare(id, share)).toBe(first);
        if (first) inside++;
      }
      expect(Math.abs(inside / 10_000 - share / 100)).toBeLessThan(0.02);
    }
  });

  test("a member in the share is ranked with the variant, the others with the active version", async () => {
    const { feed, params } = setup();
    const variant = await params.createVersion({ params: DEFAULT_PARAMS, note: "variante", author: "a@example.com", parentId: 1 });
    await params.startAbTest(variant.id, 50, "a@example.com");
    const seen = new Set<number>();
    for (let id = 1; id <= 200; id++) {
      const expected = inAbTestShare(id, 50) ? variant.id : 1;
      seen.add(expected);
      expect((await feed.rank(id, { limit: 5, offset: 0 })).versionId).toBe(expected);
    }
    expect(seen.size).toBe(2);
  });

  test("without A/B test everyone gets the active version, whatever its id", async () => {
    const { feed, params } = setup();
    const v2 = await params.createVersion({ params: DEFAULT_PARAMS, note: "v2", author: "a@example.com", parentId: 1 });
    await params.activate(v2.id, "a@example.com", "go");
    expect((await feed.rank(3, { limit: 5, offset: 0 })).versionId).toBe(v2.id);
  });
});
