import { describe, expect, test } from "bun:test";
import { migrateExistingDocuments } from "../../src/features/documents/application/migrate-existing-documents";
import { createReadDocument } from "../../src/features/documents/application/read-document";
import { containsBytes, fakeJpeg, MemoryRepo, MemoryStore, SECRET_MARKER } from "./documents-fakes";

async function legacy(repo: MemoryRepo, store: MemoryStore, name: string, extra = {}) {
  const row = repo.seed({ filename: name, encrypted: false, ...extra });
  await store.write(name, fakeJpeg());
  return row;
}

describe("encrypt-existing-documents", () => {
  test("encrypts undecided plaintext files and removes the originals", async () => {
    const repo = new MemoryRepo();
    const store = new MemoryStore();
    const row = await legacy(repo, store, "1-selfie_id-aaa.jpg");

    const report = await migrateExistingDocuments({ repo, store, dryRun: false });

    expect(report.encrypted).toBe(1);
    expect(store.files.has("1-selfie_id-aaa.jpg")).toBe(false);
    const updated = repo.rows.get(row.id)!;
    expect(updated.encrypted).toBe(true);
    expect(updated.filename).toMatch(/^documents\/[0-9a-f-]{36}\.enc$/);
    expect(containsBytes(store.files.get(updated.filename!)!, SECRET_MARKER)).toBe(false);

    const read = await createReadDocument({ repo, store })(row.id);
    expect(read.kind).toBe("ok");
  });

  test("purges documents that were already decided instead of encrypting them", async () => {
    const repo = new MemoryRepo();
    const store = new MemoryStore();
    const approved = await legacy(repo, store, "1-selfie_id-a.jpg", { status: "approved" });
    const rejected = await legacy(repo, store, "1-id_card_back-b.jpg", { status: "rejected" });

    const report = await migrateExistingDocuments({ repo, store, dryRun: false });

    expect(report).toMatchObject({ encrypted: 0, purgedDecided: 2 });
    expect(store.files.size).toBe(0);
    expect(repo.rows.get(approved.id)!.filename).toBeNull();
    expect(repo.rows.get(rejected.id)!.purgedAt).not.toBeNull();
  });

  test("is idempotent", async () => {
    const repo = new MemoryRepo();
    const store = new MemoryStore();
    await legacy(repo, store, "1-selfie_id-a.jpg");
    await legacy(repo, store, "1-id_card_front-b.jpg", { status: "approved" });
    await migrateExistingDocuments({ repo, store, dryRun: false });
    const filesAfterFirst = [...store.files.keys()].sort();

    const second = await migrateExistingDocuments({ repo, store, dryRun: false });

    expect(second).toMatchObject({ encrypted: 0, purgedDecided: 0, missingFile: 0, failed: 0 });
    expect([...store.files.keys()].sort()).toEqual(filesAfterFirst);
  });

  test("--dry-run reports the counts and changes nothing", async () => {
    const repo = new MemoryRepo();
    const store = new MemoryStore();
    await legacy(repo, store, "1-selfie_id-a.jpg");
    await legacy(repo, store, "1-id_card_front-b.jpg", { status: "rejected" });

    const report = await migrateExistingDocuments({ repo, store, dryRun: true });

    expect(report).toMatchObject({ encrypted: 1, purgedDecided: 1 });
    expect(store.files.size).toBe(2);
    expect([...repo.rows.values()].every((r) => r.encrypted === false && r.filename !== null)).toBe(true);
  });

  test("a row whose file vanished is counted, not crashed on", async () => {
    const repo = new MemoryRepo();
    const store = new MemoryStore();
    repo.seed({ filename: "1-selfie_id-ghost.jpg", encrypted: false });
    const report = await migrateExistingDocuments({ repo, store, dryRun: false });
    expect(report.missingFile).toBe(1);
  });

  test("orphan plaintext files are counted and only deleted on request", async () => {
    const repo = new MemoryRepo();
    const store = new MemoryStore();
    await store.write("9-selfie_id-orphan.jpg", fakeJpeg());

    const counted = await migrateExistingDocuments({ repo, store, dryRun: false });
    expect(counted.orphans).toBe(1);
    expect(store.files.has("9-selfie_id-orphan.jpg")).toBe(true);

    const deleted = await migrateExistingDocuments({ repo, store, dryRun: false, deleteOrphans: true });
    expect(deleted.orphansDeleted).toBe(1);
    expect(store.files.size).toBe(0);
  });

  test("a referenced file is never treated as an orphan", async () => {
    const repo = new MemoryRepo();
    const store = new MemoryStore();
    await legacy(repo, store, "1-selfie_id-a.jpg");
    const report = await migrateExistingDocuments({ repo, store, dryRun: true, deleteOrphans: true });
    expect(report.orphans).toBe(0);
  });
});
