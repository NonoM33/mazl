import { sha256Hex } from "../domain/hashing";
import type { Clock, SessionRevocationListener, TokenSigner, WebMember } from "./ports";

// Sockets are closed with this code when their web session is revoked.
export const SESSION_REVOKED_CLOSE = 4003;
export const SESSION_REVOKED_REASON = "session_revoked";
export const SOCKET_TICKET_TTL_SECONDS = 600;

export interface ClosableSocket {
  close(code?: number, reason?: string): void;
}

interface Ticket {
  readonly sessionId: string;
  readonly expiresAt: number;
}

export interface IssuedTicket {
  readonly token: string;
  readonly expiresAt: Date;
}

// Short-lived socket tickets and the open sockets of each web session, in
// memory: a ticket is a JWT the socket upgrade already knows how to check, and
// this registry says which web session it belongs to.
export class SocketRegistry implements SessionRevocationListener {
  private readonly tickets = new Map<string, Ticket>();
  private readonly sockets = new Map<string, Set<ClosableSocket>>();
  // Revoked sessions, remembered for as long as a ticket could still be in use,
  // so a socket that finishes upgrading just after the revocation is closed too.
  private readonly revoked = new Map<string, number>();

  constructor(
    private readonly sign: TokenSigner,
    private readonly now: Clock,
  ) {}

  issue(sessionId: string, member: WebMember): IssuedTicket {
    this.forgetExpired();
    const token = this.sign(member, SOCKET_TICKET_TTL_SECONDS);
    const expiresAt = this.now().getTime() + SOCKET_TICKET_TTL_SECONDS * 1000;
    this.tickets.set(sha256Hex(token), { sessionId, expiresAt });
    return { token, expiresAt: new Date(expiresAt) };
  }

  sessionOf(token: string): string | undefined {
    const ticket = this.tickets.get(sha256Hex(token));
    return ticket && ticket.expiresAt > this.now().getTime() ? ticket.sessionId : undefined;
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
    // Tickets stay known until they expire: the token is an ordinary JWT, so
    // forgetting it would let the socket upgrade as an untracked mobile one.
    // A socket opened with it is closed on arrival (see `opened`).
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

