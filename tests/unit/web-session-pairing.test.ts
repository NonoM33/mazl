import { beforeEach, describe, expect, test } from "bun:test";
import { PairingService } from "../../src/features/web-session/application/pairing-service";
import { SessionService } from "../../src/features/web-session/application/session-service";
import { SocketRegistry } from "../../src/features/web-session/application/socket-registry";
import { ALICE, BOB, FakeClock, InMemoryMembers, InMemoryPairings, InMemorySessions } from "./support/web-session-fakes";

let clock: FakeClock;
let members: InMemoryMembers;
let pairingRows: InMemoryPairings;
let sessionRows: InMemorySessions;
let sessions: SessionService;
let service: PairingService;

beforeEach(() => {
  clock = new FakeClock();
  members = new InMemoryMembers();
  pairingRows = new InMemoryPairings();
  sessionRows = new InMemorySessions(members);
  sessions = new SessionService(sessionRows, new SocketRegistry(clock.now), clock.now);
  service = new PairingService(pairingRows, members, (m, method, label) => sessions.open(m, method, label), clock.now);
});

describe("creating a pairing", () => {
  test("lives 120 seconds and stores only hashes", async () => {
    const created = await service.create("Chrome sur macOS");
    expect(created.expiresAt.getTime() - clock.now().getTime()).toBe(120_000);
    const stored = pairingRows.rows.get(created.id);
    expect(stored?.status).toBe("pending");
    expect(JSON.stringify(stored)).not.toContain(created.code);
    expect(JSON.stringify(stored)).not.toContain(created.browserSecret);
    expect(created.code).toMatch(/^[A-Za-z0-9_-]{43}$/);
    expect(created.browserSecret).not.toBe(created.code);
  });
});

describe("the full cycle", () => {
  test("pending, scanned, approved, then signed in exactly once", async () => {
    const created = await service.create("Firefox sur Windows");
    expect(await service.poll(created.id, created.browserSecret)).toEqual({ kind: "status", status: "pending" });

    const scanned = await service.scan(ALICE.id, created.code);
    expect(scanned?.browserLabel).toBe("Firefox sur Windows");
    expect(await service.poll(created.id, created.browserSecret)).toEqual({ kind: "status", status: "scanned" });

    expect(await service.decide(ALICE.id, created.id, "approved")).toBe("ok");
    const outcome = await service.poll(created.id, created.browserSecret);
    expect(outcome.kind).toBe("signed_in");
    if (outcome.kind === "signed_in") {
      expect(outcome.member.id).toBe(ALICE.id);
      expect(outcome.opened.session.method).toBe("qr");
      expect(outcome.opened.session.browserLabel).toBe("Firefox sur Windows");
    }
    expect(await service.poll(created.id, created.browserSecret)).toEqual({ kind: "status", status: "expired" });
    expect(sessionRows.rows.size).toBe(1);
  });

  test("a denial is visible to the browser and opens nothing", async () => {
    const created = await service.create("Chrome sur macOS");
    await service.scan(ALICE.id, created.code);
    expect(await service.decide(ALICE.id, created.id, "denied")).toBe("ok");
    expect(await service.poll(created.id, created.browserSecret)).toEqual({ kind: "status", status: "denied" });
    expect(sessionRows.rows.size).toBe(0);
  });
});

describe("guards", () => {
  test("a wrong browser secret or unknown id looks like nothing", async () => {
    const created = await service.create("Chrome sur macOS");
    expect(await service.poll(created.id, "wrong")).toEqual({ kind: "not_found" });
    expect(await service.poll(created.id, "")).toEqual({ kind: "not_found" });
    expect(await service.poll("11111111-1111-4111-8111-111111111111", created.browserSecret)).toEqual({ kind: "not_found" });
  });

  test("a code can be scanned once, and an unknown code finds nothing", async () => {
    const created = await service.create("Chrome sur macOS");
    expect(await service.scan(ALICE.id, "unknown")).toBeNull();
    expect(await service.scan(ALICE.id, created.code)).not.toBeNull();
    expect(await service.scan(BOB.id, created.code)).toBeNull();
  });

  test("only the member who scanned can decide", async () => {
    const created = await service.create("Chrome sur macOS");
    await service.scan(ALICE.id, created.code);
    expect(await service.decide(BOB.id, created.id, "approved")).toBe("not_found");
    expect(await service.decide(ALICE.id, created.id, "approved")).toBe("ok");
  });

  test("a pairing that was not scanned cannot be decided, nor decided twice", async () => {
    const created = await service.create("Chrome sur macOS");
    expect(await service.decide(ALICE.id, created.id, "approved")).toBe("not_found");
    await service.scan(ALICE.id, created.code);
    await service.decide(ALICE.id, created.id, "denied");
    expect(await service.decide(ALICE.id, created.id, "approved")).toBe("not_pending");
  });

  test("a disabled account gets no session", async () => {
    const created = await service.create("Chrome sur macOS");
    await service.scan(ALICE.id, created.code);
    await service.decide(ALICE.id, created.id, "approved");
    members.disabled.add(ALICE.id);
    expect(await service.poll(created.id, created.browserSecret)).toEqual({ kind: "account_disabled" });
    expect(sessionRows.rows.size).toBe(0);
  });
});

describe("expiry (injected clock)", () => {
  test("an open pairing reads as expired after 120 s and cannot be scanned", async () => {
    const created = await service.create("Chrome sur macOS");
    clock.advance(120_000);
    expect(await service.poll(created.id, created.browserSecret)).toEqual({ kind: "status", status: "expired" });
    expect(await service.scan(ALICE.id, created.code)).toBeNull();
  });

  test("a scanned pairing that is not decided in time cannot be approved", async () => {
    const created = await service.create("Chrome sur macOS");
    await service.scan(ALICE.id, created.code);
    clock.advance(121_000);
    expect(await service.decide(ALICE.id, created.id, "approved")).toBe("not_pending");
    expect(await service.poll(created.id, created.browserSecret)).toEqual({ kind: "status", status: "expired" });
  });

  test("an approval the browser reads too late opens no session", async () => {
    const created = await service.create("Chrome sur macOS");
    await service.scan(ALICE.id, created.code);
    await service.decide(ALICE.id, created.id, "approved");
    clock.advance(121_000);
    expect(await service.poll(created.id, created.browserSecret)).toEqual({ kind: "status", status: "expired" });
    expect(sessionRows.rows.size).toBe(0);
  });
});
