import { isPushConfigured, sendPushNotification } from "../../../onesignal";
import type { PushMessage, PushResult, PushTransport } from "../application/ports";

// OneSignal as the push transport: the member is addressed as user_<id>, the
// identifier the app gives OneSignal.login (V1-CONTRAT section 1).
export const oneSignalTransport: PushTransport = {
  isEnabled: () => isPushConfigured(),
  async send(message: PushMessage): Promise<PushResult> {
    const result = await sendPushNotification({
      userIds: [`user_${message.recipientId}`],
      title: message.title,
      message: message.message,
      data: message.data,
      ...(message.collapseId === undefined ? {} : { collapseId: message.collapseId }),
    });
    return result.success ? { ok: true } : { ok: false, reason: result.error ?? "unknown" };
  },
};
