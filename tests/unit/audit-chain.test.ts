import { describe, expect, test } from "bun:test";
import type { AuditEntry } from "../../src/features/audit/application/ports";
import { canonicalEntry, entryHash, GENESIS_HASH } from "../../src/features/audit/domain/chain";
import { ForbiddenAuditDetailError } from "../../src/features/audit/domain/details";
import { MemoryAuditLog } from "./support/memory-audit-log";

// Expected values below were computed outside the code under test:
//   printf '%s\n%s' "<64 zeros>" '<canonical json>' | shasum -a 256
const CANONICAL_1 =
  '{"action":"report.decide","actor":"a@example.com","createdAt":"2026-10-24T10:00:00.000Z","details":{"a":1,"z":{"b":2,"c":3}},"justification":null,"targetId":"42","targetType":"report"}';
const HASH_1 = "b0ea88c7aa5694d757ecdd045b8f29778190d5ea19035296530257bd21c22bb4";
const CANONICAL_2 =
  '{"action":"x","actor":"b@example.com","createdAt":"2026-10-24T10:00:01.000Z","details":null,"justification":"why","targetId":null,"targetType":"system"}';
const HASH_2 = "021bb838bedf00fa884da39c99d62ba70803f2c587de33232cad872e9be4c261";

describe("audit chain, from the specification", () => {
  test("genesis hash is 64 zeros", () => {
    expect(GENESIS_HASH).toBe("0".repeat(64));
  });

  test("canonical form sorts keys recursively and writes null for absent fields", () => {
    expect(
      canonicalEntry({
        targetType: "report",
        actor: "a@example.com",
        details: { z: { c: 3, b: 2 }, a: 1 },
        action: "report.decide",
        targetId: "42",
        createdAt: "2026-10-24T10:00:00.000Z",
      }),
    ).toBe(CANONICAL_1);
    expect(
      canonicalEntry({
        actor: "b@example.com",
        action: "x",
        targetType: "system",
        targetId: null,
        justification: "why",
        createdAt: "2026-10-24T10:00:01.000Z",
      }),
    ).toBe(CANONICAL_2);
  });

  test("hash is SHA-256 of previous + newline + canonical", () => {
    expect(entryHash(GENESIS_HASH, CANONICAL_1)).toBe(HASH_1);
    expect(entryHash(HASH_1, CANONICAL_2)).toBe(HASH_2);
  });

  test("recorded entries get exactly those hashes", async () => {
    const times = [new Date("2026-10-24T10:00:00.000Z"), new Date("2026-10-24T10:00:01.000Z")];
    const log = new MemoryAuditLog(() => times.shift() as Date);
    const first = await log.record({
      actor: "a@example.com",
      action: "report.decide",
      targetType: "report",
      targetId: "42",
      details: { z: { c: 3, b: 2 }, a: 1 },
    });
    const second = await log.record({ actor: "b@example.com", action: "x", targetType: "system", targetId: null, justification: "why" });
    expect(first.previousHash).toBe(GENESIS_HASH);
    expect(first.hash).toBe(HASH_1);
    expect(second.previousHash).toBe(HASH_1);
    expect(second.hash).toBe(HASH_2);
  });
});

async function filled(count: number): Promise<MemoryAuditLog> {
  const log = new MemoryAuditLog();
  for (let i = 0; i < count; i += 1) {
    await log.record({ actor: "a@example.com", action: "member.read", targetType: "member", targetId: String(i), details: { n: i } });
  }
  return log;
}

describe("verify", () => {
  test("accepts an intact chain and reports its head", async () => {
    const log = await filled(5);
    expect(await log.verify()).toEqual({ ok: true, entries: 5, headHash: log.entries[4]?.hash ?? "" });
  });

  test("an empty journal verifies, head is genesis", async () => {
    expect(await new MemoryAuditLog().verify()).toEqual({ ok: true, entries: 0, headHash: GENESIS_HASH });
  });

  test("locates a falsified field", async () => {
    const log = await filled(5);
    const victim = log.entries[2] as AuditEntry;
    log.entries[2] = { ...victim, actor: "someone-else@example.com" };
    const result = await log.verify();
    expect(result).toMatchObject({ ok: false, brokenAtId: victim.id });
  });

  test("locates a falsified detail", async () => {
    const log = await filled(4);
    const victim = log.entries[1] as AuditEntry;
    log.entries[1] = { ...victim, details: { n: 999 } };
    expect(await log.verify()).toMatchObject({ ok: false, brokenAtId: victim.id });
  });

  test("locates a removed entry at the next one", async () => {
    const log = await filled(5);
    const next = log.entries[3] as AuditEntry;
    log.entries.splice(2, 1);
    expect(await log.verify()).toMatchObject({ ok: false, brokenAtId: next.id });
  });

  test("locates a recomputed hash that does not chain", async () => {
    const log = await filled(3);
    const victim = log.entries[1] as AuditEntry;
    log.entries[1] = { ...victim, previousHash: "f".repeat(64), hash: entryHash("f".repeat(64), canonicalEntry(victim)) };
    expect(await log.verify()).toMatchObject({ ok: false, brokenAtId: victim.id });
  });
});

describe("details never carry contents or secrets", () => {
  for (const key of ["content", "message", "password", "token", "secret", "document"]) {
    test(`refuses a "${key}" key, nested too`, async () => {
      const log = new MemoryAuditLog();
      const base = { actor: "a@example.com", action: "x", targetType: "system", targetId: null } as const;
      await expect(log.record({ ...base, details: { [key]: "x" } })).rejects.toBeInstanceOf(ForbiddenAuditDetailError);
      await expect(log.record({ ...base, details: { ok: { deeper: [{ [key]: "x" }] } } })).rejects.toBeInstanceOf(ForbiddenAuditDetailError);
      expect(log.entries).toHaveLength(0);
    });
  }

  test("accepts ordinary keys", async () => {
    const log = new MemoryAuditLog();
    await log.record({ actor: "a", action: "x", targetType: "system", targetId: null, details: { method: "password", reason: "wrong" } });
    expect(log.entries).toHaveLength(1);
  });
});
