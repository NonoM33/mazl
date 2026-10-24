import { randomToken, sha256Hex } from "../domain/hashing";
import type { Clock, SessionRevocationListener, WebMember } from "./ports";

// Sockets are closed with this code when their web session is revoked.
export const SESSION_REVOKED_CLOSE = 4003;
export const SESSION_REVOKED_REASON = "session_revoked";
// A ticket opens one socket, within a minute (security review H1).
export const SOCKET_TICKET_TTL_SECONDS = 60;

export interface ClosableSocket {
  close(code?: number, reason?: string): void;
}

interface Ticket {
  readonly sessionId: string;
  readonly userId: number;
  readonly expiresAt: number;
}

export interface TicketHolder {
  readonly sessionId: string;
  readonly userId: number;
}

export interface IssuedTicket {
  readonly token: string;
  readonly expiresAt: Date;
}

// Socket tickets and the open sockets of each web session, in memory. A ticket
// is an opaque random value, not a JWT: it can never be used as a Bearer token
// on the API, and it opens one socket, once, within a minute.
export class SocketRegistry implements SessionRevocationListener {
  private readonly tickets = new Map<string, Ticket>();
  private readonly sockets = new Map<string, Set<ClosableSocket>>();
  // Revoked sessions, remembered for as long as a ticket could still be in use,
  // so a socket that finishes upgrading just after the revocation is closed too.
  private readonly revoked = new Map<string, number>();

  constructor(private readonly now: Clock) {}

  issue(sessionId: string, member: WebMember): IssuedTicket {
    this.forgetExpired();
    const token = randomToken();
    const expiresAt = this.now().getTime() + SOCKET_TICKET_TTL_SECONDS * 1000;
    this.tickets.set(sha256Hex(token), { sessionId, userId: member.id, expiresAt });
    return { token, expiresAt: new Date(expiresAt) };
  }

  // The holder of a ticket, which is spent by the reading.
  consume(token: string): TicketHolder | undefined {
    const key = sha256Hex(token);
    const ticket = this.tickets.get(key);
    this.tickets.delete(key);
    if (!ticket || ticket.expiresAt <= this.now().getTime()) return undefined;
    return { sessionId: ticket.sessionId, userId: ticket.userId };
  }

  opened(sessionId: string, socket: ClosableSocket): void {
    if ((this.revoked.get(sessionId) ?? 0) > this.now().getTime()) {
      this.closeQuietly(socket);
      return;
    }
    const set = this.sockets.get(sessionId) ?? new Set<ClosableSocket>();
    set.add(socket);
    this.sockets.set(sessionId, set);
  }

  closed(sessionId: string, socket: ClosableSocket): void {
    const set = this.sockets.get(sessionId);
    if (!set) return;
    set.delete(socket);
    if (set.size === 0) this.sockets.delete(sessionId);
  }

  sessionsRevoked(sessionIds: readonly string[]): void {
    const revoked = new Set(sessionIds);
    const until = this.now().getTime() + SOCKET_TICKET_TTL_SECONDS * 1000;
    for (const id of sessionIds) this.revoked.set(id, until);
    for (const [hash, ticket] of this.tickets) {
      if (revoked.has(ticket.sessionId)) this.tickets.delete(hash);
    }
    for (const id of revoked) this.closeAll(id);
  }

  private closeAll(sessionId: string): void {
    for (const socket of this.sockets.get(sessionId) ?? []) this.closeQuietly(socket);
    this.sockets.delete(sessionId);
  }

  private closeQuietly(socket: ClosableSocket): void {
    try {
      socket.close(SESSION_REVOKED_CLOSE, SESSION_REVOKED_REASON);
    } catch (error) {
      console.error("Web socket close failed:", error instanceof Error ? error.name : "unknown");
    }
  }

  private forgetExpired(): void {
    const at = this.now().getTime();
    for (const [hash, ticket] of this.tickets) {
      if (ticket.expiresAt <= at) this.tickets.delete(hash);
    }
    for (const [id, until] of this.revoked) {
      if (until <= at) this.revoked.delete(id);
    }
  }
}

