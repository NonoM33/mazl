import { expect, test } from "bun:test";
import { emptyFeedReport } from "../../src/features/matching/application/discover";

test("an empty Discover is reported in counts, by reason", () => {
  const line = emptyFeedReport(44, { limit: 20, offset: 0 }, 3, [{ reason: "age" }, { reason: "age" }, { reason: "filters" }]);
  expect(line).toBe("Empty Discover for user 44 (offset 0): 3 candidate(s) from the database, set aside: age=2 filters=1");
});

test("no candidate at all says so", () => {
  expect(emptyFeedReport(7, { limit: 20, offset: 0 }, 0, [])).toBe("Empty Discover for user 7 (offset 0): 0 candidate(s) from the database");
});
