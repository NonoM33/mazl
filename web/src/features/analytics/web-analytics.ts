import { api } from "../../shared/api/client";
import { createWebAnalytics } from "./tracker";

// The single instance of the site, relayed by the server to OpenPanel.
export const webAnalytics = createWebAnalytics({
  post: async (batch) => {
    await api.post("/api/analytics/events", { ...batch, events: batch.events.map((event) => ({ ...event })) });
  },
  now: () => new Date(),
  appVersion: "1.0.0",
});
