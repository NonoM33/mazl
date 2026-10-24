import { sendToUser } from "../../../shared/realtime/connections";
import type { RealtimeEvents } from "../application/ports";

export const websocketEvents: RealtimeEvents = {
  emit(userIds, event) {
    for (const userId of new Set(userIds)) sendToUser(userId, { type: event.type, payload: event.payload });
  },
};
