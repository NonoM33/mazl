import { afterAll, afterEach, beforeAll, beforeEach, describe, expect, test } from "bun:test";
import { AppleSignIn, createAppleSignIn, type AppleLog } from "../../src/features/auth/apple/apple-sign-in";
import type { AppleTokenStore } from "../../src/features/auth/apple/apple-token-store";
import { open, SealedDataError } from "../../src/shared/crypto/secret-box";
import { FakeApple, appleEnv, testSigningKey } from "../support/fake-apple";

// docs/launch/V1-CONTRAT.md §4 and App Store rule 5.1.1(v): the server keeps the
// Apple refresh token (encrypted) and revokes it when the account is deleted.
// A failure at Apple never fails the sign-in nor the deletion; it is logged.

class MemoryStore implements AppleTokenStore {
  readonly rows = new Map<number, Uint8Array>();
  failing = false;

  async save(userId: number, sealed: Uint8Array): Promise<void> {
    if (this.failing) throw new Error("database down");
    this.rows.set(userId, sealed);
  }

  async find(userId: number): Promise<Uint8Array | null> {
    if (this.failing) throw new Error("database down");
    return this.rows.get(userId) ?? null;
  }
}

class RecordingLog implements AppleLog {
  readonly warnings: string[] = [];
  readonly errors: string[] = [];
  warn(message: string): void {
    this.warnings.push(message);
  }
  error(message: string): void {
    this.errors.push(message);
  }
  get all(): string {
    return [...this.warnings, ...this.errors].join("\n");
  }
}

const key = testSigningKey();
const apple = new FakeApple();
let store: MemoryStore;
let log: RecordingLog;
let service: AppleSignIn;

beforeAll(() => {
  apple.start();
});
afterAll(() => apple.stop());
beforeEach(() => {
  store = new MemoryStore();
  log = new RecordingLog();
  service = createAppleSignIn({ env: appleEnv(key, apple.url), store, log });
});
afterEach(() => {
  apple.requests.length = 0;
  apple.tokenAnswer = null;
  apple.revokeAnswer = null;
});

describe("remembering the authorization at sign-in", () => {
  test("exchanges the code and keeps the refresh token ENCRYPTED, bound to the member", async () => {
    await service.rememberAuthorization(7, "c-1");
    const sealed = store.rows.get(7);
    expect(sealed).toBeDefined();
    expect(Buffer.from(sealed ?? []).includes("r-c-1")).toBe(false);
    expect(open(sealed ?? new Uint8Array(), "apple-refresh-token:7").toString("utf8")).toBe("r-c-1");
    // sealed for member 7, it cannot be replayed as member 8's
    expect(() => open(sealed ?? new Uint8Array(), "apple-refresh-token:8")).toThrow(SealedDataError);
  });

  test("a new sign-in replaces the token of the member", async () => {
    await service.rememberAuthorization(7, "c-1");
    await service.rememberAuthorization(7, "c-2");
    expect(open(store.rows.get(7) ?? new Uint8Array(), "apple-refresh-token:7").toString("utf8")).toBe("r-c-2");
  });

  test("Apple refusing the code: the sign-in goes on, the failure is logged without the code", async () => {
    apple.tokenAnswer = { status: 400, body: { error: "invalid_grant" } };
    await expect(service.rememberAuthorization(7, "c-secret")).resolves.toBeUndefined();
    expect(store.rows.size).toBe(0);
    expect(log.errors).toHaveLength(1);
    expect(log.all).not.toContain("c-secret");
  });

  test("a database failure: the sign-in goes on, logged", async () => {
    store.failing = true;
    await expect(service.rememberAuthorization(7, "c-1")).resolves.toBeUndefined();
    expect(log.errors).toHaveLength(1);
  });

  test("an empty or oversized code is not sent to Apple", async () => {
    await service.rememberAuthorization(7, "");
    await service.rememberAuthorization(7, "x".repeat(5000));
    expect(apple.requestsTo("/auth/token")).toHaveLength(0);
  });
});

describe("revoking when the account is deleted", () => {
  test("revokes the stored refresh token at Apple", async () => {
    await service.rememberAuthorization(7, "c-1");
    const revoke = await service.beginRevocation(7);
    await revoke();
    expect(apple.requestsTo("/auth/revoke")).toHaveLength(1);
    expect(apple.requestsTo("/auth/revoke")[0]?.form.token).toBe("r-c-1");
  });

  test("the token is read BEFORE the erasure: it still revokes once the rows are gone", async () => {
    await service.rememberAuthorization(7, "c-1");
    const revoke = await service.beginRevocation(7);
    store.rows.clear(); // the member's rows are erased (ON DELETE CASCADE)
    await revoke();
    expect(apple.requestsTo("/auth/revoke")[0]?.form.token).toBe("r-c-1");
  });

  test("nothing to revoke when the member never signed in with Apple", async () => {
    const revoke = await service.beginRevocation(99);
    await revoke();
    expect(apple.requests).toHaveLength(0);
  });

  test("Apple refusing the revocation: logged, never thrown", async () => {
    await service.rememberAuthorization(7, "c-1");
    apple.revokeAnswer = { status: 400, body: { error: "invalid_request" } };
    const revoke = await service.beginRevocation(7);
    await expect(revoke()).resolves.toBeUndefined();
    expect(log.errors).toHaveLength(1);
    expect(log.all).not.toContain("r-c-1");
  });

  test("a database failure when reading: no throw, no revocation, logged", async () => {
    await service.rememberAuthorization(7, "c-1");
    store.failing = true;
    const revoke = await service.beginRevocation(7);
    await expect(revoke()).resolves.toBeUndefined();
    expect(apple.requestsTo("/auth/revoke")).toHaveLength(0);
    expect(log.errors).toHaveLength(1);
  });

  test("a stored value that cannot be opened (rotated key): logged, never thrown", async () => {
    store.rows.set(7, Buffer.from("garbage that is not a sealed value at all"));
    const revoke = await service.beginRevocation(7);
    await expect(revoke()).resolves.toBeUndefined();
    expect(log.errors).toHaveLength(1);
  });
});

describe("without the three variables", () => {
  function unconfigured(): AppleSignIn {
    return createAppleSignIn({ env: { NODE_ENV: "test" }, store, log });
  }

  test("warns once, at creation, naming what is missing", () => {
    unconfigured();
    expect(log.warnings).toHaveLength(1);
    expect(log.warnings[0]).toContain("APPLE_SIGNIN_PRIVATE_KEY");
    expect(log.warnings[0]).toMatch(/revocation/i);
  });

  test("a configured server does not warn", () => {
    expect(log.warnings).toHaveLength(0);
  });

  test("the sign-in and the deletion do nothing at Apple, and succeed", async () => {
    const skipped = unconfigured();
    await expect(skipped.rememberAuthorization(7, "c-1")).resolves.toBeUndefined();
    const revoke = await skipped.beginRevocation(7);
    await expect(revoke()).resolves.toBeUndefined();
    expect(apple.requests).toHaveLength(0);
    expect(store.rows.size).toBe(0);
  });
});
