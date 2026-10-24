import { createHash } from "node:crypto";
import type { AuditEntry, AuditEntryInput, ChainVerification } from "../application/ports";
import { assertSafeDetails } from "./details";

// Hash chain of the audit journal (docs/backoffice/CADRAGE.md §5):
//   hash = SHA-256(previousHash + "\n" + canonical JSON of the entry)
// The first entry chains on GENESIS_HASH.

export const GENESIS_HASH = "0".repeat(64);

export interface HashedFields {
  readonly actor: string;
  readonly action: string;
  readonly targetType: string;
  readonly targetId: string | null;
  readonly justification?: string | null;
  readonly details?: Readonly<Record<string, unknown>> | null;
  // ISO 8601, millisecond precision.
  readonly createdAt: string;
}

function sortKeysDeep(value: unknown): unknown {
  if (Array.isArray(value)) return value.map(sortKeysDeep);
  if (typeof value === "object" && value !== null) {
    const record = value as Record<string, unknown>;
    return Object.fromEntries(
      Object.keys(record)
        .sort()
        .map((key) => [key, sortKeysDeep(record[key])]),
    );
  }
  return value;
}

export function canonicalEntry(entry: HashedFields): string {
  return JSON.stringify(
    sortKeysDeep({
      actor: entry.actor,
      action: entry.action,
      targetType: entry.targetType,
      targetId: entry.targetId,
      justification: entry.justification ?? null,
      details: entry.details ?? null,
      createdAt: entry.createdAt,
    }),
  );
}

export function entryHash(previousHash: string, canonical: string): string {
  return createHash("sha256").update(`${previousHash}\n${canonical}`).digest("hex");
}

// What is hashed must be what is stored: details go through a JSON round trip
// (drops undefined, normalises numbers) before hashing, and are validated.
function normalisedDetails(details: AuditEntryInput["details"]): Readonly<Record<string, unknown>> | null {
  if (details === undefined) return null;
  assertSafeDetails(details);
  const parsed: unknown = JSON.parse(JSON.stringify(details));
  return parsed as Record<string, unknown>;
}

export interface NewEntryParts {
  readonly input: AuditEntryInput;
  readonly previousHash: string;
  readonly createdAt: Date;
  readonly id: number;
}

export function buildEntry({ input, previousHash, createdAt, id }: NewEntryParts): AuditEntry {
  const details = normalisedDetails(input.details);
  const stamp = createdAt.toISOString();
  const fields: HashedFields = {
    actor: input.actor,
    action: input.action,
    targetType: input.targetType,
    targetId: input.targetId,
    justification: input.justification ?? null,
    details,
    createdAt: stamp,
  };
  return {
    id,
    createdAt: stamp,
    actor: input.actor,
    action: input.action,
    targetType: input.targetType,
    targetId: input.targetId,
    ...(input.justification === undefined ? {} : { justification: input.justification }),
    ...(details === null ? {} : { details }),
    previousHash,
    hash: entryHash(previousHash, canonicalEntry(fields)),
  };
}

// Incremental verifier: feed entries in id order, it stops at the first break.
export class ChainVerifier {
  private expectedPrevious = GENESIS_HASH;
  private count = 0;
  private broken: number | null = null;

  // Returns false at (and after) the first entry that does not fit the chain.
  accept(entry: AuditEntry): boolean {
    if (this.broken !== null) return false;
    this.count += 1;
    const fits =
      entry.previousHash === this.expectedPrevious &&
      entry.hash === entryHash(entry.previousHash, canonicalEntry(entry));
    if (!fits) {
      this.broken = entry.id;
      return false;
    }
    this.expectedPrevious = entry.hash;
    return true;
  }

  result(): ChainVerification {
    return this.broken === null
      ? { ok: true, entries: this.count, headHash: this.expectedPrevious }
      : { ok: false, brokenAtId: this.broken, entries: this.count };
  }
}
