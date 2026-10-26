import type { PushTransport } from "../../push/application/ports";
import type { EventOpenedPush } from "../application/ports";
import { eventOpenedText } from "../domain/event-opened-text";

// The opening of an event, pushed through the transport of the push feature.
// The app routes `event_available` to the page of the event; the pushes of one
// event replace each other on the device.
export function transportEventOpenedPush(transport: PushTransport, log: { error(line: string): void }): EventOpenedPush {
  return {
    isEnabled: () => transport.isEnabled(),
    async notify({ eventId, title, recipientIds }) {
      const text = eventOpenedText(title);
      const reached: number[] = [];
      for (const recipientId of recipientIds) {
        try {
          const result = await transport.send({ recipientId, ...text, data: { type: "event_available", event_id: eventId }, collapseId: `event-${eventId}` });
          if (result.ok) reached.push(recipientId);
          else log.error(`Event push not sent: ${result.reason}`);
        } catch (error: unknown) {
          log.error(`Event push failed: ${error instanceof Error ? error.name : "unknown"}`);
        }
      }
      return reached;
    },
  };
}
