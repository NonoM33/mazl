// OneSignal Push Notifications Integration
//
// Members are targeted by external id, "user_<id>": the identifier the app gives
// OneSignal.login() (V1-CONTRAT section 1). The key and the endpoint are read at
// every call, so a server started without ONESIGNAL_REST_API_KEY sends nothing.
// Current API (https://documentation.onesignal.com/reference/push-notification):
// an App API key sent as "Key <key>", the member as the external_id alias.

const DEFAULT_ONESIGNAL_APP_ID = "0bad7c7f-4a93-4a6d-84e7-ed77a48532cf";
const DEFAULT_ONESIGNAL_API_URL = "https://api.onesignal.com";
// A push is never worth holding a request, a socket handler or a shutdown.
const ONESIGNAL_TIMEOUT_MS = 8_000;

export function isPushConfigured(env: Readonly<Record<string, string | undefined>> = process.env): boolean {
  return (env.ONESIGNAL_REST_API_KEY ?? "") !== "";
}

// Tests point the server at a fake OneSignal; a real deployment never may.
function apiUrl(env: Readonly<Record<string, string | undefined>>): string {
  const override = env.ONESIGNAL_API_BASE?.trim();
  if (override === undefined || override === "") return DEFAULT_ONESIGNAL_API_URL;
  if (env.NODE_ENV === "production") throw new Error("ONESIGNAL_API_BASE is refused in production");
  return override.replace(/\/$/, "");
}

export type PushData = Readonly<Record<string, string | number | boolean>>;

interface PushNotificationParams {
  // Target by user IDs (external_id in OneSignal)
  userIds?: string[];
  // Or target all users
  sendToAll?: boolean;
  // Or target by segment
  segmentName?: string;
  // Notification content
  title: string;
  message: string;
  // Optional data payload
  data?: PushData;
  // Notifications with the same id replace each other on the device
  collapseId?: string;
  // Optional URL to open
  url?: string;
  // Optional image
  imageUrl?: string;
}

// OneSignal answers errors as a list of sentences, or as an object of details.
function firstError(errors: unknown): string | undefined {
  return Array.isArray(errors) && typeof errors[0] === "string" ? errors[0] : undefined;
}

export async function sendPushNotification(params: PushNotificationParams): Promise<{
  success: boolean;
  id?: string;
  recipients?: number;
  error?: string;
}> {
  const apiKey = process.env.ONESIGNAL_REST_API_KEY ?? "";
  if (apiKey === "") {
    console.error("ONESIGNAL_REST_API_KEY is not set; push notifications will not be sent.");
    return { success: false, error: "OneSignal not configured" };
  }

  try {
    const payload: Record<string, unknown> = {
      app_id: process.env.ONESIGNAL_APP_ID || DEFAULT_ONESIGNAL_APP_ID,
      headings: { en: params.title, fr: params.title },
      contents: { en: params.message, fr: params.message },
    };

    // Target selection
    if (params.sendToAll) {
      payload.included_segments = ["All"];
    } else if (params.segmentName) {
      payload.included_segments = [params.segmentName];
    } else if (params.userIds && params.userIds.length > 0) {
      payload.include_aliases = { external_id: params.userIds };
      payload.target_channel = "push";
    } else {
      return { success: false, error: "No target specified" };
    }

    // Optional fields
    if (params.data) {
      payload.data = params.data;
    }

    if (params.collapseId) {
      payload.collapse_id = params.collapseId;
    }

    if (params.url) {
      payload.url = params.url;
    }

    if (params.imageUrl) {
      payload.big_picture = params.imageUrl; // Android
      payload.ios_attachments = { id: params.imageUrl }; // iOS
    }

    const response = await fetch(`${apiUrl(process.env)}/notifications`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Authorization": `Key ${apiKey}`,
      },
      body: JSON.stringify(payload),
      signal: AbortSignal.timeout(ONESIGNAL_TIMEOUT_MS),
    });

    const result = (await response.json().catch(() => ({}))) as {
      id?: string;
      recipients?: number;
      errors?: unknown;
    };

    if (!response.ok) {
      const reason = firstError(result.errors) ?? `HTTP ${response.status}`;
      console.error(`OneSignal refused the push: ${reason}`);
      return { success: false, error: reason };
    }
    // An empty id: accepted, sent to nobody (no subscribed device for the target).
    if (result.id === undefined || result.id === "") {
      const reason = firstError(result.errors) ?? "Not sent";
      console.error(`OneSignal sent nothing: ${reason}`);
      return { success: false, error: reason };
    }

    console.log(`Push notification sent: ${result.id}, recipients: ${result.recipients ?? "?"}`);

    return {
      success: true,
      id: result.id,
      ...(result.recipients === undefined ? {} : { recipients: result.recipients }),
    };
  } catch (error: unknown) {
    console.error("OneSignal error:", error instanceof Error ? error.name : "unknown");
    return { success: false, error: error instanceof Error ? error.message : "unknown" };
  }
}

// Send push to specific users by their IDs
export async function sendPushToUsers(
  userIds: readonly number[],
  title: string,
  message: string,
  data?: PushData
) {
  return sendPushNotification({
    userIds: userIds.map((id) => `user_${id}`),
    title,
    message,
    ...(data ? { data } : {}),
  });
}

// Send push to all users
export async function sendPushToAll(
  title: string,
  message: string,
  data?: PushData
) {
  return sendPushNotification({
    sendToAll: true,
    title,
    message,
    ...(data ? { data } : {}),
  });
}

// Send push to a segment
export async function sendPushToSegment(
  segmentName: string,
  title: string,
  message: string,
  data?: PushData
) {
  return sendPushNotification({
    segmentName,
    title,
    message,
    ...(data ? { data } : {}),
  });
}

// Notification types for MAZL app. The ones of the table in V1-CONTRAT section 1
// are new_match, new_message, couple_request and couple_question.
export const NotificationTypes = {
  NEW_MATCH: "new_match",
  NEW_MESSAGE: "new_message",
  COUPLE_REQUEST: "couple_request",
  COUPLE_ACCEPTED: "couple_accepted",
  COUPLE_QUESTION: "couple_question",
  EVENT_REMINDER: "event_reminder",
  MILESTONE: "milestone",
  PROMO: "promo",
  ANNOUNCEMENT: "announcement",
} as const;

// Pre-built notification templates: vouvoiement, no emoji. The match and message
// notifications are built by features/push, which also decides who receives them.
export async function sendEventReminder(userIds: readonly number[], eventTitle: string, eventId: number) {
  return sendPushToUsers(
    userIds,
    "Rappel d'événement",
    `N'oubliez pas : ${eventTitle} arrive bientôt.`,
    { type: NotificationTypes.EVENT_REMINDER, eventId }
  );
}

export async function sendDailyQuestionNotification(userIds: readonly number[]) {
  return sendPushToUsers(
    userIds,
    "Question du jour",
    "Une nouvelle question vous attend. Répondez pour mieux vous connaître.",
    { type: NotificationTypes.COUPLE_QUESTION }
  );
}

export async function sendMilestoneNotification(userIds: readonly number[], milestone: string) {
  return sendPushToUsers(
    userIds,
    "Félicitations",
    `Vous avez atteint une nouvelle étape : ${milestone}`,
    { type: NotificationTypes.MILESTONE }
  );
}
