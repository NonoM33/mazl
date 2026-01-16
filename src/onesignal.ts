// OneSignal Push Notifications Integration

const ONESIGNAL_APP_ID = process.env.ONESIGNAL_APP_ID || "0bad7c7f-4a93-4a6d-84e7-ed77a48532cf";
const ONESIGNAL_REST_API_KEY = process.env.ONESIGNAL_REST_API_KEY || "";

const ONESIGNAL_API_URL = "https://onesignal.com/api/v1";

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
  data?: Record<string, any>;
  // Optional URL to open
  url?: string;
  // Optional image
  imageUrl?: string;
}

export async function sendPushNotification(params: PushNotificationParams): Promise<{
  success: boolean;
  id?: string;
  recipients?: number;
  error?: string;
}> {
  if (!ONESIGNAL_REST_API_KEY) {
    console.error("ONESIGNAL_REST_API_KEY is not set; push notifications will not be sent.");
    return { success: false, error: "OneSignal not configured" };
  }

  try {
    const payload: any = {
      app_id: ONESIGNAL_APP_ID,
      headings: { en: params.title, fr: params.title },
      contents: { en: params.message, fr: params.message },
    };

    // Target selection
    if (params.sendToAll) {
      payload.included_segments = ["All"];
    } else if (params.segmentName) {
      payload.included_segments = [params.segmentName];
    } else if (params.userIds && params.userIds.length > 0) {
      // Use external_id (our user IDs) - requires OneSignal to have these mapped
      payload.include_external_user_ids = params.userIds;
    } else {
      return { success: false, error: "No target specified" };
    }

    // Optional fields
    if (params.data) {
      payload.data = params.data;
    }

    if (params.url) {
      payload.url = params.url;
    }

    if (params.imageUrl) {
      payload.big_picture = params.imageUrl; // Android
      payload.ios_attachments = { id: params.imageUrl }; // iOS
    }

    const response = await fetch(`${ONESIGNAL_API_URL}/notifications`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Authorization": `Basic ${ONESIGNAL_REST_API_KEY}`,
      },
      body: JSON.stringify(payload),
    });

    const result = await response.json();

    if (!response.ok) {
      console.error("OneSignal error:", result);
      return { success: false, error: result.errors?.[0] || "Failed to send notification" };
    }

    console.log(`Push notification sent: ${result.id}, recipients: ${result.recipients}`);

    return {
      success: true,
      id: result.id,
      recipients: result.recipients,
    };
  } catch (error: any) {
    console.error("OneSignal error:", error);
    return { success: false, error: error.message };
  }
}

// Send push to specific users by their IDs
export async function sendPushToUsers(
  userIds: number[],
  title: string,
  message: string,
  data?: Record<string, any>
) {
  return sendPushNotification({
    userIds: userIds.map((id) => `user_${id}`),
    title,
    message,
    data,
  });
}

// Send push to all users
export async function sendPushToAll(
  title: string,
  message: string,
  data?: Record<string, any>
) {
  return sendPushNotification({
    sendToAll: true,
    title,
    message,
    data,
  });
}

// Send push to a segment
export async function sendPushToSegment(
  segmentName: string,
  title: string,
  message: string,
  data?: Record<string, any>
) {
  return sendPushNotification({
    segmentName,
    title,
    message,
    data,
  });
}

// Notification types for MAZL app
export const NotificationTypes = {
  NEW_MATCH: "new_match",
  NEW_MESSAGE: "new_message",
  EVENT_REMINDER: "event_reminder",
  COUPLE_QUESTION: "couple_question",
  MILESTONE: "milestone",
  PROMO: "promo",
  ANNOUNCEMENT: "announcement",
} as const;

// Pre-built notification templates
export async function sendMatchNotification(userId: number, matchName: string) {
  return sendPushToUsers(
    [userId],
    "Nouveau Match ! 💝",
    `${matchName} et toi avez matché ! Commence la conversation.`,
    { type: NotificationTypes.NEW_MATCH }
  );
}

export async function sendMessageNotification(userId: number, senderName: string) {
  return sendPushToUsers(
    [userId],
    "Nouveau message 💬",
    `${senderName} t'a envoyé un message`,
    { type: NotificationTypes.NEW_MESSAGE }
  );
}

export async function sendEventReminder(userIds: number[], eventTitle: string, eventId: number) {
  return sendPushToUsers(
    userIds,
    "Rappel événement 📅",
    `N'oublie pas : ${eventTitle} arrive bientôt !`,
    { type: NotificationTypes.EVENT_REMINDER, eventId }
  );
}

export async function sendDailyQuestionNotification(userIds: number[], coupleId: number) {
  return sendPushToUsers(
    userIds,
    "Question du jour 💑",
    "Une nouvelle question vous attend ! Répondez pour mieux vous connaître.",
    { type: NotificationTypes.COUPLE_QUESTION, coupleId }
  );
}

export async function sendMilestoneNotification(userIds: number[], milestone: string) {
  return sendPushToUsers(
    userIds,
    "Félicitations ! 🎉",
    `Vous avez atteint un nouveau milestone : ${milestone}`,
    { type: NotificationTypes.MILESTONE }
  );
}
