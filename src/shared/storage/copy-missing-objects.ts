import type { ObjectStore } from "./object-store";

export interface CopyReport {
  scanned: number;
  uploaded: number;
  alreadyPresent: number;
  skippedPartial: number;
  bytesUploaded: number;
  // Keys that could not be copied; the run goes on without them.
  failed: string[];
}

const CONCURRENCY = 4;

// Copies every object of `source` that `target` does not have yet, under the
// same key. Idempotent (what is already in the target is never overwritten) and
// one-way: the source is only read, nothing is ever deleted. Temporary
// `.partial` files left by an interrupted write are not data and are skipped.
export async function copyMissingObjects(options: {
  source: ObjectStore;
  target: ObjectStore;
  dryRun: boolean;
}): Promise<CopyReport> {
  const { source, target, dryRun } = options;
  const report: CopyReport = { scanned: 0, uploaded: 0, alreadyPresent: 0, skippedPartial: 0, bytesUploaded: 0, failed: [] };
  const keys: string[] = [];
  for (const object of await source.list("")) {
    report.scanned += 1;
    if (object.key.endsWith(".partial")) report.skippedPartial += 1;
    else keys.push(object.key);
  }

  async function copyOne(key: string): Promise<void> {
    try {
      if (await target.exists(key)) {
        report.alreadyPresent += 1;
        return;
      }
      const bytes = await source.get(key);
      // Removed between the listing and now: nothing left to copy.
      if (bytes === null) return;
      if (!dryRun) await target.put(key, bytes);
      report.uploaded += 1;
      report.bytesUploaded += bytes.byteLength;
    } catch {
      report.failed.push(key);
    }
  }

  let next = 0;
  const workers = Array.from({ length: CONCURRENCY }, async () => {
    while (next < keys.length) {
      const key = keys[next++]!;
      await copyOne(key);
    }
  });
  await Promise.all(workers);
  report.failed.sort();
  return report;
}
