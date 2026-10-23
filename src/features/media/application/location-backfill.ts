import { fuzzCoordinates } from "../domain/geo-fuzz";
import { locationSeedFor } from "./location-seed";
import type { LocationBackfillRepository } from "./ports";

const PAGE_SIZE = 500;

// One-time (idempotent) boot task: replaces every position stored before the
// socle, when it was kept exact, by its fuzzed point. Returns how many rows
// changed. A page that changes nothing ends the run, so a repository that
// cannot flag a row can never make boot loop.
export async function fuzzStoredLocations(repository: LocationBackfillRepository): Promise<number> {
  let changed = 0;
  for (;;) {
    const page = await repository.listUnfuzzed(PAGE_SIZE);
    let progress = 0;
    for (const position of page) {
      const fuzzed = fuzzCoordinates(position, locationSeedFor(position.userId));
      if (await repository.markFuzzed(position.userId, fuzzed)) progress += 1;
    }
    changed += progress;
    if (progress === 0) return changed;
  }
}
