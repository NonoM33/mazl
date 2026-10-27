import type { PushDirectory, PushTransport } from "../../push/application/ports";
import type { ReminderPush } from "../application/reminder-ports";

// Sends to one member through the shared push transport. Nothing is sent, and
// nothing is asked of the database, while push is not configured. A member who
// is banned, suspended or inactive is not reachable and gets nothing.
export function createMemberReminderPush(transport: PushTransport, directory: PushDirectory, log: (line: string) => void): ReminderPush {
  return {
    isEnabled: () => transport.isEnabled(),
    async send(userId, push) {
      if (!transport.isEnabled()) return;
      try {
        if (!(await directory.reachable([userId])).includes(userId)) return;
        const result = await transport.send({ recipientId: userId, title: push.title, message: push.message, data: push.data });
        if (!result.ok) log(`Couple reminder not sent: ${result.reason}`);
      } catch (error: unknown) {
        log(`Couple reminder push failed: ${error instanceof Error ? error.name : "unknown"}`);
      }
    },
  };
}
