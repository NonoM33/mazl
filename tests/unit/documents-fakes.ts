import type {
  DocumentFileStore,
  DocumentRepository,
  NewDocument,
  PurgeScope,
  PurgeTarget,
} from "../../src/features/documents/application/ports";
import type { DecisionStatus, DocumentRecord } from "../../src/features/documents/domain/types";

// In-memory doubles written from the ports, not from the Postgres/fs adapters.

export class MemoryStore implements DocumentFileStore {
  readonly files = new Map<string, Uint8Array>();
  failRemoveFor = new Set<string>();
  failWrites = false;

  async write(fileName: string, bytes: Uint8Array): Promise<void> {
    if (this.failWrites) throw new Error("disk full");
    this.files.set(fileName, new Uint8Array(bytes));
  }
  async read(fileName: string): Promise<Uint8Array | null> {
    return this.files.get(fileName) ?? null;
  }
  async remove(fileName: string): Promise<void> {
    if (this.failRemoveFor.has(fileName)) throw new Error("EPERM");
    this.files.delete(fileName);
  }
  async listLegacyFiles(): Promise<string[]> {
    return [...this.files.keys()].filter((name) => !name.includes("/"));
  }
}

export class MemoryRepo implements DocumentRepository {
  readonly rows = new Map<number, DocumentRecord>();
  private nextId = 1;

  seed(partial: Partial<DocumentRecord> & { filename: string | null }): DocumentRecord {
    const row: DocumentRecord = {
      id: this.nextId++,
      waitlistId: 1,
      type: "selfie_id",
      mimeType: "image/jpeg",
      status: "pending",
      encrypted: false,
      purgedAt: null,
      createdAt: new Date(),
      ...partial,
    };
    this.rows.set(row.id, row);
    return row;
  }

  async insert(doc: NewDocument): Promise<number> {
    return this.seed({
      waitlistId: doc.waitlistId,
      type: doc.type,
      filename: doc.fileName,
      mimeType: doc.mimeType,
      encrypted: true,
    }).id;
  }
  async delete(id: number): Promise<void> {
    this.rows.delete(id);
  }
  async findById(id: number): Promise<DocumentRecord | null> {
    return this.rows.get(id) ?? null;
  }
  async latestByType(waitlistId: number): Promise<Record<string, DocumentRecord>> {
    const out: Record<string, DocumentRecord> = {};
    for (const row of [...this.rows.values()].filter((r) => r.waitlistId === waitlistId)) {
      const current = out[row.type];
      if (!current || row.id > current.id) out[row.type] = row;
    }
    return out;
  }
  async typesByIds(waitlistId: number, ids: readonly number[]): Promise<string[]> {
    return [...this.rows.values()].filter((r) => r.waitlistId === waitlistId && ids.includes(r.id)).map((r) => r.type);
  }
  async decide(params: { ids: readonly number[]; waitlistId?: number; status: DecisionStatus }): Promise<void> {
    for (const id of params.ids) {
      const row = this.rows.get(id);
      if (row && (params.waitlistId === undefined || row.waitlistId === params.waitlistId)) row.status = params.status;
    }
  }
  async approveAllNotRejected(waitlistId: number): Promise<void> {
    for (const row of this.rows.values()) {
      if (row.waitlistId === waitlistId && row.status !== "rejected") row.status = "approved";
    }
  }
  async rejectAll(waitlistId: number): Promise<void> {
    for (const row of this.rows.values()) if (row.waitlistId === waitlistId) row.status = "rejected";
  }
  async findDecidedUnpurged(scope: PurgeScope): Promise<PurgeTarget[]> {
    return [...this.rows.values()]
      .filter((r) => r.status !== "pending" && r.purgedAt === null)
      .filter((r) => {
        if (scope === "all") return true;
        if ("ids" in scope) return scope.ids.includes(r.id);
        return r.waitlistId === scope.waitlistId;
      })
      .map((r) => ({ id: r.id, filename: r.filename }));
  }
  async findStaleUndecided(maxAgeDays: number): Promise<PurgeTarget[]> {
    const cutoff = Date.now() - maxAgeDays * 86_400_000;
    return [...this.rows.values()]
      .filter((r) => r.status === "pending" && r.purgedAt === null && r.createdAt.getTime() < cutoff)
      .map((r) => ({ id: r.id, filename: r.filename }));
  }
  async markPurged(ids: readonly number[]): Promise<void> {
    for (const id of ids) {
      const row = this.rows.get(id);
      if (row) {
        row.filename = null;
        row.purgedAt = new Date();
      }
    }
  }
  async findPlaintext(): Promise<DocumentRecord[]> {
    return [...this.rows.values()].filter((r) => !r.encrypted && r.purgedAt === null && r.filename !== null);
  }
  async replaceWithEncrypted(id: number, fileName: string): Promise<void> {
    const row = this.rows.get(id);
    if (row) {
      row.filename = fileName;
      row.encrypted = true;
    }
  }
  async referencedFileNames(): Promise<Set<string>> {
    return new Set([...this.rows.values()].flatMap((r) => (r.filename ? [r.filename] : [])));
  }
}

// A recognisable JPEG: valid magic bytes followed by a marker no random
// ciphertext would contain by chance.
export const SECRET_MARKER = "PASSEPORT-JEANNE-EXEMPLE-0123456789";
export function fakeJpeg(): Uint8Array {
  return new Uint8Array([0xff, 0xd8, 0xff, 0xe0, ...new TextEncoder().encode(SECRET_MARKER), 0xff, 0xd9]);
}

export function containsBytes(haystack: Uint8Array, needle: string): boolean {
  return Buffer.from(haystack).includes(Buffer.from(needle));
}
