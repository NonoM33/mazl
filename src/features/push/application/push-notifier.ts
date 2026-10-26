import { boostEndedText, eventAvailableText, newLikeText, newMatchText, newMessageText, superLikeText, testPushText } from "../domain/push-texts";
import type { ConnectionRegistry, PushDirectory, PushLog, PushMessage, PushResult, PushTransport } from "./ports";

// Who is told what, and when (V1-CONTRAT section 1). Every method resolves, even
// when the database or the provider fails: a push must never fail, nor slow
// down, the request that triggered it. A member who is blocked, banned or
// inactive triggers nothing.

export interface PushNotifierDeps {
  readonly transport: PushTransport;
  readonly directory: PushDirectory;
  readonly connections: ConnectionRegistry;
  readonly log: PushLog;
  // Milliseconds; the tests move it.
  readonly now?: () => number;
}

export interface MatchFormed {
  readonly userAId: number;
  readonly userBId: number;
  readonly conversationId: number | null;
}

export interface MessageReceived {
  readonly conversationId: number;
  readonly senderId: number;
  readonly recipientId: number;
}

export interface LikeReceived {
  readonly likerId: number;
  readonly recipientId: number;
  readonly superLike: boolean;
}

export interface EventAvailable {
  readonly eventId: number;
  readonly title: string;
  readonly recipientIds: readonly number[];
}

// requested = distinct members of the list; skipped = not reachable (or no key).
export interface EventAvailableOutcome {
  readonly requested: number;
  readonly sent: number;
  readonly skipped: number;
  readonly failed: number;
}

export interface PushNotifier {
  // Both members, each with the other's id.
  matchFormed(match: MatchFormed): Promise<void>;
  // The recipient only, and only when none of their sockets is open.
  messageReceived(message: MessageReceived): Promise<void>;
  // A like that formed no match. Simple likes: once every six hours per member;
  // super likes: once per sender.
  likeReceived(like: LikeReceived): Promise<void>;
  boostEnded(userId: number): Promise<void>;
  // Every reachable member of the list, a few at a time.
  eventAvailable(event: EventAvailable): Promise<EventAvailableOutcome>;
  // Sent as it is, whoever the member: the administrators check a device with it.
  testPush(userId: number): Promise<PushResult>;
}

const LIKE_QUIET_MS = 6 * 3_600_000;
const SUPER_LIKE_MEMORY_MS = 24 * 3_600_000;
const MEMORY_PRUNE_AT = 10_000;
const EVENT_SEND_CONCURRENCY = 10;

// When something was last told, forgotten after a while. In memory: a restart
// may tell a like once more, never more often than that.
class RecentlyTold {
  private readonly at = new Map<string, number>();
  constructor(private readonly forMs: number) {}
  claim(key: string, now: number): boolean {
    const last = this.at.get(key);
    if (last !== undefined && now - last < this.forMs) return false;
    if (this.at.size >= MEMORY_PRUNE_AT) this.prune(now);
    this.at.set(key, now);
    return true;
  }
  private prune(now: number): void {
    for (const [key, last] of this.at) if (now - last >= this.forMs) this.at.delete(key);
  }
}

export function createPushNotifier(deps: PushNotifierDeps): PushNotifier {
  const { transport, directory, connections, log } = deps;
  const now = deps.now ?? Date.now;
  const likesTold = new RecentlyTold(LIKE_QUIET_MS);
  const superLikesTold = new RecentlyTold(SUPER_LIKE_MEMORY_MS);

  async function deliver(recipientId: number, actorId: number, build: (actorName: string | null) => PushMessage): Promise<void> {
    try {
      const audience = await directory.audience(recipientId, actorId);
      if (!audience.deliverable) return;
      const result = await transport.send(build(audience.actorName));
      if (!result.ok) log.error(`Push not sent: ${result.reason}`);
    } catch (error: unknown) {
      log.error(`Push failed: ${error instanceof Error ? error.name : "unknown"}`);
    }
  }

  async function matchFormed(match: MatchFormed): Promise<void> {
    if (!transport.isEnabled()) return;
    const toward = (recipientId: number, otherId: number) =>
      deliver(recipientId, otherId, (otherName) => ({
        recipientId,
        ...newMatchText(otherName),
        data: {
          type: "new_match",
          match_user_id: otherId,
          ...(match.conversationId === null ? {} : { conversation_id: match.conversationId }),
        },
      }));
    await Promise.all([toward(match.userAId, match.userBId), toward(match.userBId, match.userAId)]);
  }

  async function messageReceived(message: MessageReceived): Promise<void> {
    if (!transport.isEnabled() || connections.isConnected(message.recipientId)) return;
    await deliver(message.recipientId, message.senderId, (senderName) => ({
      recipientId: message.recipientId,
      ...newMessageText(senderName),
      data: { type: "new_message", conversation_id: message.conversationId },
      collapseId: `conv-${message.conversationId}`,
    }));
  }

  async function likeReceived(like: LikeReceived): Promise<void> {
    if (!transport.isEnabled()) return;
    const fresh = like.superLike
      ? superLikesTold.claim(`${like.likerId}:${like.recipientId}`, now())
      : likesTold.claim(String(like.recipientId), now());
    if (!fresh) return;
    await deliver(like.recipientId, like.likerId, () =>
      like.superLike
        ? { recipientId: like.recipientId, ...superLikeText(), data: { type: "super_like" } }
        : { recipientId: like.recipientId, ...newLikeText(), data: { type: "new_like" }, collapseId: "likes" },
    );
  }

  // Sends to one member already known reachable; true when the provider took it.
  async function sendAlone(message: PushMessage): Promise<boolean> {
    try {
      const result = await transport.send(message);
      if (!result.ok) log.error(`Push not sent: ${result.reason}`);
      return result.ok;
    } catch (error: unknown) {
      log.error(`Push failed: ${error instanceof Error ? error.name : "unknown"}`);
      return false;
    }
  }

  async function boostEnded(userId: number): Promise<void> {
    if (!transport.isEnabled()) return;
    try {
      if (!(await directory.reachable([userId])).includes(userId)) return;
    } catch (error: unknown) {
      log.error(`Push failed: ${error instanceof Error ? error.name : "unknown"}`);
      return;
    }
    await sendAlone({ recipientId: userId, ...boostEndedText(), data: { type: "boost_ended" } });
  }

  async function eventAvailable(event: EventAvailable): Promise<EventAvailableOutcome> {
    const requested = [...new Set(event.recipientIds)];
    if (!transport.isEnabled()) return { requested: requested.length, sent: 0, skipped: requested.length, failed: 0 };
    const reachable = await directory.reachable(requested);
    const text = eventAvailableText(event.title);
    let sent = 0;
    for (let start = 0; start < reachable.length; start += EVENT_SEND_CONCURRENCY) {
      const batch = reachable.slice(start, start + EVENT_SEND_CONCURRENCY);
      const results = await Promise.all(
        batch.map((recipientId) =>
          sendAlone({ recipientId, ...text, data: { type: "event_available", event_id: event.eventId }, collapseId: `event-${event.eventId}` }),
        ),
      );
      sent += results.filter(Boolean).length;
    }
    return { requested: requested.length, sent, skipped: requested.length - reachable.length, failed: reachable.length - sent };
  }

  async function testPush(userId: number): Promise<PushResult> {
    if (!transport.isEnabled()) return { ok: false, reason: "not_configured" };
    return transport.send({ recipientId: userId, ...testPushText(), data: { type: "admin_test" } });
  }

  return { matchFormed, messageReceived, likeReceived, boostEnded, eventAvailable, testPush };
}
