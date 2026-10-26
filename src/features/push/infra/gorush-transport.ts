import type { PushDevice, PushDeviceStore, PushMessage, PushResult, PushTransport } from "../application/ports";

// gorush (self-hosted, Coolify `neo-gorush-prod`, shared with Neo) as the push
// transport: it hands the notifications to APNs with the team's .p8 key. It is
// reached on the internal Docker network, behind a guard that wants the shared
// secret. Field names are those of gorush 1.22 (notify/notification.go); in its
// synchronous mode the answer lists the failed pushes in `logs`.

const SECRET_HEADER = "X-Neo-Push-Secret";
const IOS = 1;
const TIMEOUT_MS = 8_000;
// APNs refused the token for good: the app was removed, or the token is not this app's.
const LOST_TOKEN_REASONS: ReadonlySet<string> = new Set(["Unregistered", "BadDeviceToken", "DeviceTokenNotForTopic"]);

export interface GorushOptions {
  readonly url: string;
  readonly secret: string;
  // The app's bundle id: one gorush serves several apps of the team.
  readonly topic: string;
  readonly devices: PushDeviceStore;
  readonly fetch?: typeof fetch;
  readonly timeoutMs?: number;
}

interface GorushAnswer {
  readonly desactive?: boolean;
  readonly logs?: ReadonlyArray<{ readonly type?: string; readonly notif_id?: string; readonly error?: string }>;
}

function notificationFor(device: PushDevice, message: PushMessage, topic: string): Record<string, unknown> {
  return {
    notif_id: String(device.id),
    tokens: [device.token],
    platform: IOS,
    topic,
    title: message.title,
    message: message.message,
    sound: "default",
    priority: "high",
    push_type: "alert",
    ...(device.environment === "production" ? { production: true } : { development: true }),
    data: message.data,
    ...(message.collapseId === undefined ? {} : { collapse_id: message.collapseId }),
  };
}

export function createGorushTransport(options: GorushOptions): PushTransport {
  const call = options.fetch ?? fetch;
  const endpoint = `${options.url.replace(/\/+$/, "")}/api/push`;

  async function post(notifications: Array<Record<string, unknown>>): Promise<{ ok: true; answer: GorushAnswer } | { ok: false; reason: string }> {
    let response: Response;
    try {
      response = await call(endpoint, {
        method: "POST",
        headers: { "Content-Type": "application/json", [SECRET_HEADER]: options.secret },
        body: JSON.stringify({ notifications }),
        signal: AbortSignal.timeout(options.timeoutMs ?? TIMEOUT_MS),
      });
    } catch {
      return { ok: false, reason: "unreachable" };
    }
    if (!response.ok) return { ok: false, reason: `HTTP ${response.status}` };
    const answer = (await response.json().catch(() => ({}))) as GorushAnswer;
    return { ok: true, answer };
  }

  return {
    isEnabled: () => options.url !== "" && options.secret !== "",
    async send(message: PushMessage): Promise<PushResult> {
      const devices = await options.devices.devicesOf(message.recipientId);
      if (devices.length === 0) return { ok: false, reason: "no_device" };
      const posted = await post(devices.map((device) => notificationFor(device, message, options.topic)));
      if (!posted.ok) return posted;
      if (posted.answer.desactive === true) return { ok: false, reason: "gateway_disabled" };

      const failed = (posted.answer.logs ?? []).filter((log) => log.type === "failed-push");
      const known = new Map(devices.map((device) => [String(device.id), device.id]));
      const lost = failed.flatMap((log) => (log.error !== undefined && LOST_TOKEN_REASONS.has(log.error) && known.has(log.notif_id ?? "") ? [known.get(log.notif_id ?? "") ?? 0] : []));
      if (lost.length > 0) await options.devices.forget(lost);
      if (failed.length < devices.length) return { ok: true };
      return { ok: false, reason: failed[0]?.error ?? "failed" };
    },
  };
}
