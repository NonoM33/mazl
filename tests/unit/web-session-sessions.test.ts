import { beforeEach, describe, expect, test } from "bun:test";
import { SessionService } from "../../src/features/web-session/application/session-service";
import {
  SESSION_REVOKED_CLOSE,
  SESSION_REVOKED_REASON,
  SocketRegistry,
} from "../../src/features/web-session/application/socket-registry";
import { sha256Hex } from "../../src/features/web-session/domain/hashing";
import { ALICE, BOB, FakeClock, InMemoryMembers, InMemorySessions } from "./support/web-session-fakes";

const MINUTE = 60_000;
const HOUR = 60 * MINUTE;
const DAY = 24 * HOUR;

let clock: FakeClock;
let members: InMemoryMembers;
let rows: InMemorySessions;
let registry: SocketRegistry;
let sessions: SessionService;

beforeEach(() => {
  clock = new FakeClock();
  members = new InMemoryMembers();
  rows = new InMemorySessions(members);
  registry = new SocketRegistry((m, ttl) => `jwt-${m.id}-${ttl}-${Math.random()}`, clock.now);
  sessions = new SessionService(rows, registry, clock.now);
});

describe("opening", () => {
  test("stores only the hash of the cookie value and sets the deadlines", async () => {
    const { token, session } = await sessions.open(ALICE, "qr", "Chrome sur macOS");
    expect(JSON.stringify([...rows.rows.values()])).not.toContain(token);
    expect([...rows.rows.values()][0]?.tokenHash).toBe(sha256Hex(token));
    expect(session.idleExpiresAt.getTime() - clock.now().getTime()).toBe(4 * HOUR);
    expect(session.expiresAt.getTime() - clock.now().getTime()).toBe(7 * DAY);
  });
});

describe("resolving", () => {
  test("finds a live session and refuses an unknown value", async () => {
    const { token } = await sessions.open(ALICE, "google", "Edge sur Windows");
    expect((await sessions.resolve(token))?.member.id).toBe(ALICE.id);
    expect(await sessions.resolve("nope")).toBeNull();
  });

  test("idle for 4 hours ends the session", async () => {
    const { token } = await sessions.open(ALICE, "qr", "x");
    clock.advance(4 * HOUR + 1);
    expect(await sessions.resolve(token)).toBeNull();
  });

  test("activity pushes the idle deadline, but at most once a minute", async () => {
    const { token } = await sessions.open(ALICE, "qr", "x");
    clock.advance(30_000);
    await sessions.resolve(token);
    clock.advance(20_000);
    await sessions.resolve(token);
    expect(rows.touches).toBe(0);
    clock.advance(10_000);
    await sessions.resolve(token);
    expect(rows.touches).toBe(1);
  });

  test("regular activity keeps the session alive past 4 hours, never past 7 days", async () => {
    const { token } = await sessions.open(ALICE, "qr", "x");
    for (let i = 0; i < 24; i++) {
      clock.advance(3 * HOUR);
      expect(await sessions.resolve(token)).not.toBeNull();
    }
    expect(clock.now().getTime() - new Date("2026-10-24T12:00:00.000Z").getTime()).toBe(3 * DAY);
    for (let i = 0; i < 32; i++) {
      clock.advance(3 * HOUR);
      await sessions.resolve(token);
    }
    expect(await sessions.resolve(token)).toBeNull();
  });

  test("a session ends exactly at 7 days even if used a minute before", async () => {
    const { token } = await sessions.open(ALICE, "qr", "x");
    for (let i = 0; i < 55; i++) {
      clock.advance(3 * HOUR);
      await sessions.resolve(token);
    }
    clock.advance(3 * HOUR - MINUTE);
    expect(await sessions.resolve(token)).not.toBeNull();
    clock.advance(MINUTE);
    expect(await sessions.resolve(token)).toBeNull();
  });

  test("a disabled account's session is refused", async () => {
    const { token } = await sessions.open(ALICE, "qr", "x");
    members.disabled.add(ALICE.id);
    expect(await sessions.resolve(token)).toBeNull();
  });
});

describe("revoking", () => {
  test("a revoked session no longer resolves", async () => {
    const { token, session } = await sessions.open(ALICE, "qr", "x");
    expect(await sessions.revoke(ALICE.id, session.id)).toBe(true);
    expect(await sessions.resolve(token)).toBeNull();
    expect(await sessions.revoke(ALICE.id, session.id)).toBe(false);
  });

  test("a member cannot revoke another member's session", async () => {
    const { token, session } = await sessions.open(ALICE, "qr", "x");
    expect(await sessions.revoke(BOB.id, session.id)).toBe(false);
    expect(await sessions.resolve(token)).not.toBeNull();
  });

  test("revokeAll keeps the excepted session and spares other members", async () => {
    const keep = await sessions.open(ALICE, "qr", "keep");
    const other = await sessions.open(ALICE, "google", "other");
    const bobs = await sessions.open(BOB, "qr", "bob");
    await sessions.revokeAll(ALICE.id, keep.session.id);
    expect(await sessions.resolve(keep.token)).not.toBeNull();
    expect(await sessions.resolve(other.token)).toBeNull();
    expect(await sessions.resolve(bobs.token)).not.toBeNull();
    await sessions.revokeAll(ALICE.id, null);
    expect(await sessions.resolve(keep.token)).toBeNull();
  });

  test("list returns active sessions, newest first", async () => {
    const first = await sessions.open(ALICE, "qr", "first");
    clock.advance(MINUTE);
    const second = await sessions.open(ALICE, "google", "second");
    await sessions.revoke(ALICE.id, first.session.id);
    expect((await sessions.list(ALICE.id)).map((s) => s.id)).toEqual([second.session.id]);
  });
});

describe("sockets of a revoked session", () => {
  test("are closed with 4003 session_revoked, others are left alone", async () => {
    const a = await sessions.open(ALICE, "qr", "a");
    const b = await sessions.open(ALICE, "qr", "b");
    const closes: Array<[string, number | undefined, string | undefined]> = [];
    const socket = (name: string) => ({ close: (code?: number, reason?: string) => void closes.push([name, code, reason]) });
    registry.opened(a.session.id, socket("a"));
    registry.opened(b.session.id, socket("b"));
    await sessions.revoke(ALICE.id, a.session.id);
    expect(closes).toEqual([["a", SESSION_REVOKED_CLOSE, SESSION_REVOKED_REASON]]);
    expect(SESSION_REVOKED_CLOSE).toBe(4003);
    expect(SESSION_REVOKED_REASON).toBe("session_revoked");
  });

  test("a socket that opens just after the revocation is closed at once", async () => {
    const a = await sessions.open(ALICE, "qr", "a");
    await sessions.revoke(ALICE.id, a.session.id);
    const closes: number[] = [];
    registry.opened(a.session.id, { close: (code) => void closes.push(code ?? 0) });
    expect(closes).toEqual([4003]);
  });
});

describe("socket tickets", () => {
  test("map to their session for 10 minutes, then to nothing", async () => {
    const { session } = await sessions.open(ALICE, "qr", "a");
    const ticket = registry.issue(session.id, ALICE);
    expect(ticket.expiresAt.getTime() - clock.now().getTime()).toBe(10 * MINUTE);
    expect(ticket.token).toContain("-600-");
    expect(registry.sessionOf(ticket.token)).toBe(session.id);
    expect(registry.sessionOf("another-token")).toBeUndefined();
    clock.advance(10 * MINUTE);
    expect(registry.sessionOf(ticket.token)).toBeUndefined();
  });

  test("of a revoked session still name it, so a late socket is recognised and closed", async () => {
    const { session } = await sessions.open(ALICE, "qr", "a");
    const ticket = registry.issue(session.id, ALICE);
    await sessions.revoke(ALICE.id, session.id);
    expect(registry.sessionOf(ticket.token)).toBe(session.id);
    const closes: number[] = [];
    registry.opened(session.id, { close: (code) => void closes.push(code ?? 0) });
    expect(closes).toEqual([4003]);
  });
});
