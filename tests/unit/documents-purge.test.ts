import { describe, expect, test } from "bun:test";
import { createPurger } from "../../src/features/documents/application/purge-documents";
import { createReviewDocuments } from "../../src/features/documents/application/review-documents";
import { PurgeFailedError, type DocumentRecord } from "../../src/features/documents/domain/types";
import { MemoryRepo, MemoryStore } from "./documents-fakes";

const DAY = 86_400_000;

async function seedFile(repo: MemoryRepo, store: MemoryStore, name: string, extra: Partial<DocumentRecord> = {}) {
  const row = repo.seed({ filename: name, encrypted: true, ...extra });
  await store.write(name, new Uint8Array([1, 2, 3]));
  return row;
}

function setup() {
  const repo = new MemoryRepo();
  const store = new MemoryStore();
  const purger = createPurger({ repo, store });
  return { repo, store, purger, review: createReviewDocuments({ repo, purger }) };
}

describe("review decisions purge the files", () => {
  test("approving a document deletes its file and clears the pointer", async () => {
    const { repo, store, review } = setup();
    const doc = await seedFile(repo, store, "documents/a.enc");
    await review.approveDocument(doc.id);

    expect(store.files.has("documents/a.enc")).toBe(false);
    expect(repo.rows.get(doc.id)).toMatchObject({ status: "approved", filename: null });
    expect(repo.rows.get(doc.id)!.purgedAt).not.toBeNull();
  });

  test("rejecting a document deletes its file too", async () => {
    const { repo, store, review } = setup();
    const doc = await seedFile(repo, store, "documents/a.enc");
    await review.rejectDocument(doc.id, "photo floue");
    expect(store.files.size).toBe(0);
    expect(repo.rows.get(doc.id)).toMatchObject({ status: "rejected", filename: null });
  });

  test("approving a profile purges every document of that member and no other", async () => {
    const { repo, store, review } = setup();
    const mine = await Promise.all(
      ["a", "b", "c"].map((n) => seedFile(repo, store, `documents/${n}.enc`, { waitlistId: 5 })),
    );
    const other = await seedFile(repo, store, "documents/other.enc", { waitlistId: 6 });

    await review.approveAllForWaitlist(5);

    expect([...store.files.keys()]).toEqual(["documents/other.enc"]);
    expect(mine.every((d) => repo.rows.get(d.id)!.filename === null)).toBe(true);
    expect(repo.rows.get(other.id)!.status).toBe("pending");
  });

  test("a reupload request rejects and purges every document", async () => {
    const { repo, store, review } = setup();
    await seedFile(repo, store, "documents/a.enc", { waitlistId: 5 });
    await seedFile(repo, store, "documents/b.enc", { waitlistId: 5, type: "id_card_front" });
    await review.rejectAllForWaitlist(5, "reupload requested");
    expect(store.files.size).toBe(0);
  });

  test("bulk review: approved and rejected ids are purged, untouched ones are kept", async () => {
    const { repo, store, review } = setup();
    const a = await seedFile(repo, store, "documents/a.enc", { waitlistId: 5 });
    const b = await seedFile(repo, store, "documents/b.enc", { waitlistId: 5, type: "id_card_front" });
    const c = await seedFile(repo, store, "documents/c.enc", { waitlistId: 5, type: "id_card_back" });

    await review.reviewBulk({ waitlistId: 5, documentIds: [a.id], status: "approved" });
    await review.reviewBulk({ waitlistId: 5, documentIds: [b.id], status: "rejected", notes: "flou" });

    expect([...store.files.keys()]).toEqual(["documents/c.enc"]);
    expect(repo.rows.get(c.id)!.filename).toBe("documents/c.enc");
  });

  test("a bulk review scoped to another member decides nothing", async () => {
    const { repo, store, review } = setup();
    const a = await seedFile(repo, store, "documents/a.enc", { waitlistId: 5 });
    await review.reviewBulk({ waitlistId: 99, documentIds: [a.id], status: "approved" });
    expect(store.files.has("documents/a.enc")).toBe(true);
  });

  test("a file already gone does not break the purge", async () => {
    const { repo, review } = setup();
    const doc = repo.seed({ filename: "documents/ghost.enc", encrypted: true });
    await review.approveDocument(doc.id);
    expect(repo.rows.get(doc.id)!.filename).toBeNull();
  });

  test("a file that cannot be deleted is not marked purged, the others are", async () => {
    const { repo, store, purger } = setup();
    const bad = await seedFile(repo, store, "documents/bad.enc", { status: "approved" });
    const good = await seedFile(repo, store, "documents/good.enc", { status: "approved" });
    store.failRemoveFor.add("documents/bad.enc");

    await expect(purger.purgeDecided("all")).rejects.toBeInstanceOf(PurgeFailedError);
    expect(repo.rows.get(bad.id)!.filename).toBe("documents/bad.enc");
    expect(repo.rows.get(good.id)!.filename).toBeNull();

    store.failRemoveFor.clear();
    expect(await purger.purgeDecided("all")).toBe(1); // the retry finishes the job
  });
});

describe("background purge", () => {
  test("undecided documents older than 30 days are purged, younger ones are not", async () => {
    const { repo, store, purger } = setup();
    const old = await seedFile(repo, store, "documents/old.enc", { createdAt: new Date(Date.now() - 31 * DAY) });
    const young = await seedFile(repo, store, "documents/young.enc", { createdAt: new Date(Date.now() - 29 * DAY) });

    const summary = await purger.sweep();

    expect(summary.stale).toBe(1);
    expect(repo.rows.get(old.id)!.filename).toBeNull();
    expect(repo.rows.get(old.id)!.purgedAt).not.toBeNull();
    expect(store.files.has("documents/old.enc")).toBe(false);
    expect(repo.rows.get(young.id)!.filename).toBe("documents/young.enc");
  });

  test("the sweep also finishes decided documents left behind by an earlier failure", async () => {
    const { repo, store, purger } = setup();
    await seedFile(repo, store, "documents/left.enc", { status: "approved" });
    const summary = await purger.sweep();
    expect(summary.decided).toBe(1);
    expect(store.files.size).toBe(0);
  });

  test("running the sweep twice purges nothing the second time", async () => {
    const { repo, store, purger } = setup();
    await seedFile(repo, store, "documents/old.enc", { createdAt: new Date(Date.now() - 40 * DAY) });
    await purger.sweep();
    expect(await purger.sweep()).toEqual({ decided: 0, stale: 0 });
  });
});
