import { beforeEach, describe, expect, test } from "bun:test";
import * as connections from "../../src/shared/realtime/connections";

// Security: one account must not be able to hold an unbounded number of
// sockets (memory, file descriptors, fan-out of every event it receives).

class FakeSocket {
  readonly sent: string[] = [];
  closed: { code: number; reason: string } | null = null;
  failOnClose = false;
  send(data: string): void {
    if (this.closed !== null) throw new Error("socket is closed");
    this.sent.push(data);
  }
  close(code: number, reason: string): void {
    if (this.failOnClose) throw new Error("already gone");
    this.closed = { code, reason };
  }
}

const asWebSocket = (socket: FakeSocket): WebSocket => socket as unknown as WebSocket;

let nextUser = 1000;
let user: number;

beforeEach(() => {
  nextUser += 1;
  user = nextUser;
});

function open(userId: number, count: number): FakeSocket[] {
  const sockets: FakeSocket[] = [];
  for (let i = 0; i < count; i++) {
    const socket = new FakeSocket();
    connections.addConnection(userId, asWebSocket(socket));
    sockets.push(socket);
  }
  return sockets;
}

const ping = { type: "chat:typing", payload: {} } as const;

describe("MAX_SOCKETS_PER_USER", () => {
  test("is 5", () => expect(connections.MAX_SOCKETS_PER_USER).toBe(5));

  test("a flood of connections never leaves more than 5 open, and the survivors are the newest", () => {
    const sockets = open(user, 50);
    const open_ = sockets.filter((socket) => socket.closed === null);
    expect(open_).toEqual(sockets.slice(-5));
  });

  test("the 6th connection closes the OLDEST one with 4008 too_many_connections", () => {
    const sockets = open(user, 6);
    expect(sockets[0]?.closed).toEqual({ code: 4008, reason: "too_many_connections" });
    for (const socket of sockets.slice(1)) expect(socket.closed).toBeNull();
  });

  test("5 connections close nothing", () => {
    for (const socket of open(user, 5)) expect(socket.closed).toBeNull();
  });

  test("the evicted socket receives nothing more, the others still do", () => {
    const sockets = open(user, 6);
    connections.sendToUser(user, ping);
    expect(sockets[0]?.sent).toEqual([]);
    for (const socket of sockets.slice(1)) expect(socket.sent).toEqual([JSON.stringify(ping)]);
  });

  test("registering the same socket twice does not evict anyone", () => {
    const sockets = open(user, 5);
    connections.addConnection(user, asWebSocket(sockets[4] as FakeSocket));
    for (const socket of sockets) expect(socket.closed).toBeNull();
  });

  test("the limit is per user: another account keeps all its sockets", () => {
    const other = user + 100_000;
    const others = open(other, 5);
    open(user, 20);
    for (const socket of others) expect(socket.closed).toBeNull();
  });

  test("a socket that fails to close does not break the registration of the new one", () => {
    const first = new FakeSocket();
    first.failOnClose = true;
    connections.addConnection(user, asWebSocket(first));
    const rest = open(user, 5);
    connections.sendToUser(user, ping);
    expect(rest.every((socket) => socket.sent.length === 1)).toBe(true);
  });

  test("a connection closed by the client frees a slot", () => {
    const sockets = open(user, 5);
    connections.removeConnection(user, asWebSocket(sockets[0] as FakeSocket));
    const [sixth] = open(user, 1);
    for (const socket of sockets.slice(1)) expect(socket.closed).toBeNull();
    expect(sixth?.closed).toBeNull();
  });
});

describe("closeUserConnections", () => {
  test("closes and forgets every socket of the user and returns how many", () => {
    const sockets = open(user, 3);
    expect(connections.closeUserConnections(user, 4001, "banned")).toBe(3);
    for (const socket of sockets) expect(socket.closed).toEqual({ code: 4001, reason: "banned" });
    connections.sendToUser(user, ping);
    for (const socket of sockets) expect(socket.sent).toEqual([]);
  });

  test("returns 0 for a user with no socket", () => {
    expect(connections.closeUserConnections(user, 4001, "banned")).toBe(0);
  });

  test("leaves other users alone", () => {
    const mine = open(user, 2);
    const theirs = open(user + 100_000, 2);
    expect(connections.closeUserConnections(user, 4001, "banned")).toBe(2);
    for (const socket of mine) expect(socket.closed).not.toBeNull();
    for (const socket of theirs) expect(socket.closed).toBeNull();
  });

  test("keeps going when one socket refuses to close, and still counts and forgets it", () => {
    const sockets = open(user, 3);
    (sockets[1] as FakeSocket).failOnClose = true;
    expect(connections.closeUserConnections(user, 4001, "banned")).toBe(3);
    expect(sockets[0]?.closed).not.toBeNull();
    expect(sockets[2]?.closed).not.toBeNull();
    connections.sendToUser(user, ping);
    expect(sockets[1]?.sent).toEqual([]);
  });

  test("the user can reconnect afterwards", () => {
    open(user, 2);
    connections.closeUserConnections(user, 4001, "banned");
    const [fresh] = open(user, 1);
    connections.sendToUser(user, ping);
    expect(fresh?.sent).toEqual([JSON.stringify(ping)]);
  });
});
