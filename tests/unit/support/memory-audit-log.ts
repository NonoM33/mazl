import type { AuditEntry, AuditEntryInput, AuditFilter, AuditLog, ChainVerification } from "../../../src/features/audit/application/ports";
import { buildEntry, ChainVerifier, GENESIS_HASH } from "../../../src/features/audit/domain/chain";

export class MemoryAuditLog implements AuditLog {
  entries: AuditEntry[] = [];

  constructor(private readonly now: () => Date = () => new Date()) {}

  async record(input: AuditEntryInput): Promise<AuditEntry> {
    const previousHash = this.entries.at(-1)?.hash ?? GENESIS_HASH;
    const entry = buildEntry({ input, previousHash, createdAt: this.now(), id: this.entries.length + 1 });
    this.entries.push(entry);
    return entry;
  }

  async list(filter: AuditFilter): Promise<{ entries: readonly AuditEntry[]; total: number }> {
    const matching = [...this.entries]
      .reverse()
      .filter(
        (e) =>
          (filter.actor === undefined || e.actor === filter.actor) &&
          (filter.action === undefined || e.action === filter.action) &&
          (filter.targetType === undefined || e.targetType === filter.targetType) &&
          (filter.targetId === undefined || e.targetId === filter.targetId),
      );
    return { entries: matching.slice(filter.offset, filter.offset + filter.limit), total: matching.length };
  }

  async verify(): Promise<ChainVerification> {
    const verifier = new ChainVerifier();
    for (const entry of this.entries) if (!verifier.accept(entry)) break;
    return verifier.result();
  }

  actions(): string[] {
    return this.entries.map((e) => e.action);
  }
}
