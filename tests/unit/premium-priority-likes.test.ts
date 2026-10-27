import { describe, expect, test } from "bun:test";
import { createFeed } from "../../src/features/matching/application/discover";
import { withPriorityLikes } from "../../src/features/matching/domain/priority";
import type { RankedCandidate } from "../../src/features/matching/domain/ranking";
import { syntheticPopulation } from "../../src/features/matching/domain/synthetic";
import { FakeCandidates, FakeHydrator, InMemoryParams } from "./support/matching-fakes";

// docs/premium/MONETISATION.md section 6: the likes of mazl+ members come first
// in the pile of the member they liked, without bending the rest of the ranking.

const ranked = (ids: readonly number[]): RankedCandidate[] =>
  ids.map((userId, index) => ({
    userId, rank: index + 1, score: 1 - index / 100, forward: { total: 0, criteria: [] }, backward: { total: 0, criteria: [] },
    reciprocal: 0, multipliers: [], explored: false,
  }));

describe("withPriorityLikes", () => {
  test("puts the priority likers first and keeps the order inside each group", () => {
    const result = withPriorityLikes(ranked([10, 11, 12, 13, 14, 15]), new Set([14, 11]));
    expect(result.map((c) => c.userId)).toEqual([11, 14, 10, 12, 13, 15]);
    expect(result.map((c) => c.rank)).toEqual([1, 2, 3, 4, 5, 6]);
  });

  test("changes nothing without a priority liker", () => {
    expect(withPriorityLikes(ranked([3, 1, 2]), new Set()).map((c) => c.userId)).toEqual([3, 1, 2]);
  });

  test("a liker the engine did not rank is not invented", () => {
    expect(withPriorityLikes(ranked([3, 1]), new Set([99])).map((c) => c.userId)).toEqual([3, 1]);
  });
});

describe("the feed", () => {
  const population = syntheticPopulation(11, 200).profiles;
  const viewer = { ...population[0]!, userId: 9000, age: 30, gender: "male" as const, lookingFor: "all" as const, ageMin: 18, ageMax: 99, distanceMaxKm: null, location: null };
  const candidates = population.slice(1);

  function feedWith(priority: ReadonlySet<number>) {
    const source = new FakeCandidates({ viewer, candidates, excluded: new Set(), priority });
    return createFeed({ params: new InMemoryParams(), candidates: source, hydrator: new FakeHydrator(), clock: () => new Date("2026-03-10T10:00:00Z") });
  }

  test("a priority liker ranked far down the pile comes first, the others keep their order", async () => {
    const plain = (await feedWith(new Set()).rank(viewer.userId, { limit: 50, offset: 0 })).userIds;
    const liker = plain[30]!;
    const boosted = (await feedWith(new Set([liker])).rank(viewer.userId, { limit: 50, offset: 0 })).userIds;
    expect(boosted[0]).toBe(liker);
    expect(boosted.slice(1)).toEqual(plain.filter((id) => id !== liker).slice(0, boosted.length - 1));
  });

  test("pages stay slices of one ordering", async () => {
    const feed = feedWith(new Set([population[40]!.userId]));
    const whole = (await feed.rank(viewer.userId, { limit: 50, offset: 0 })).userIds;
    const page1 = (await feed.rank(viewer.userId, { limit: 20, offset: 0 })).userIds;
    const page2 = (await feed.rank(viewer.userId, { limit: 20, offset: 20 })).userIds;
    expect([...page1, ...page2]).toEqual([...whole].slice(0, 40));
  });

  test("the hydrator is told the viewer", async () => {
    const hydrator = new FakeHydratorWithViewer();
    const feed = createFeed({
      params: new InMemoryParams(),
      candidates: new FakeCandidates({ viewer, candidates, excluded: new Set() }),
      hydrator,
      clock: () => new Date("2026-03-10T10:00:00Z"),
    });
    await feed.discover(viewer.userId, { limit: 5, offset: 0 });
    expect(hydrator.viewers).toEqual([viewer.userId]);
  });
});

class FakeHydratorWithViewer extends FakeHydrator {
  readonly viewers: Array<number | undefined> = [];
  override async profilesForFeed(userIds: readonly number[], viewerId?: number) {
    this.viewers.push(viewerId);
    return super.profilesForFeed(userIds);
  }
}
