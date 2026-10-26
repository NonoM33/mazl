import type { AnalyticsService } from "../application/analytics-service";
import { serverEvents } from "../domain/events";

interface MessageCreated {
  readonly conversationId: number;
  readonly senderId: number;
  readonly recipientId: number;
}

interface MessageNotifierLike {
  messageCreated(event: MessageCreated): void;
}

// Messages go through HTTP and WebSocket alike: the chat's notifier sees them
// all once stored. Counts the sender's message, never its content or recipient.
export function withMessageAnalytics(
  notifier: MessageNotifierLike,
  analytics: Pick<AnalyticsService, "recordServerEvent">,
  clock: () => Date = () => new Date(),
): MessageNotifierLike {
  return {
    messageCreated(event: MessageCreated): void {
      notifier.messageCreated(event);
      analytics.recordServerEvent(event.senderId, serverEvents.messageSent(clock()));
    },
  };
}
