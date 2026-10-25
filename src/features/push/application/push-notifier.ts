import { newMatchText, newMessageText } from "../domain/push-texts";
import type { ConnectionRegistry, PushDirectory, PushLog, PushMessage, PushTransport } from "./ports";

// Who is told what, and when (V1-CONTRAT section 1). Every method resolves, even
// when the database or the provider fails: a push must never fail, nor slow
// down, the request that triggered it. A member who is blocked, banned or
// inactive triggers nothing.

export interface PushNotifierDeps {
  readonly transport: PushTransport;
  readonly directory: PushDirectory;
  readonly connections: ConnectionRegistry;
  readonly log: PushLog;
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

export interface PushNotifier {
  // Both members, each with the other's id.
  matchFormed(match: MatchFormed): Promise<void>;
  // The recipient only, and only when none of their sockets is open.
  messageReceived(message: MessageReceived): Promise<void>;
}

export function createPushNotifier(deps: PushNotifierDeps): PushNotifier {
  const { transport, directory, connections, log } = deps;

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

  return { matchFormed, messageReceived };
}
