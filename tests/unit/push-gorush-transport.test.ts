import { describe, expect, test } from "bun:test";
import type { PushDevice, PushDeviceStore } from "../../src/features/push/application/ports";
import { createGorushTransport } from "../../src/features/push/infra/gorush-transport";

// What gorush 1.22 receives (POST /api/push, field names of its PushNotification
// struct, notify/notification.go): one notification per device, identified by
// notif_id, the app's bundle id as topic, the APNs environment the device
// declared, and `data` as the custom keys the app routes on. Its synchronous
// answer lists the failed pushes in `logs`; a token APNs refuses for good is forgotten.

class FakeDevices implements PushDeviceStore {
  forgotten: number[] = [];
  constructor(private readonly devices: Record<number, PushDevice[]>) {}
  register(): Promise<void> {
    return Promise.resolve();
  }
  unregister(): Promise<void> {
    return Promise.resolve();
  }
  devicesOf(userId: number): Promise<PushDevice[]> {
    return Promise.resolve(this.devices[userId] ?? []);
  }
  forget(deviceIds: readonly number[]): Promise<void> {
    this.forgotten.push(...deviceIds);
    return Promise.resolve();
  }
}

interface Call {
  readonly url: string;
  readonly secret: string | null;
  readonly body: { notifications: Array<Record<string, unknown>> };
}

function setup(answer: unknown = { counts: 1, logs: [], success: "ok" }, status = 200, devices: Record<number, PushDevice[]> = {
  44: [
    { id: 7, token: "a".repeat(64), environment: "production" },
    { id: 8, token: "b".repeat(64), environment: "sandbox" },
  ],
}) {
  const calls: Call[] = [];
  const store = new FakeDevices(devices);
  const fetchFake = (async (url: unknown, init?: { body?: string; headers?: Record<string, string> }) => {
    calls.push({ url: String(url), secret: init?.headers?.["X-Neo-Push-Secret"] ?? null, body: JSON.parse(String(init?.body)) as Call["body"] });
    return new Response(JSON.stringify(answer), { status });
  }) as unknown as typeof fetch;
  const transport = createGorushTransport({ url: "http://neo-gorush:8088/", secret: "s3cret", topic: "com.mazl.app", devices: store, fetch: fetchFake });
  return { calls, store, transport };
}

const message = { recipientId: 44, title: "Nouveau message", message: "Sarah vous a envoyé un message.", data: { type: "new_message", conversation_id: 41 }, collapseId: "conv-41" };

describe("what gorush receives", () => {
  test("one notification per device of the member, behind the shared secret", async () => {
    const { calls, transport } = setup();
    expect(await transport.send(message)).toEqual({ ok: true });
    expect(calls).toHaveLength(1);
    expect(calls[0]?.url).toBe("http://neo-gorush:8088/api/push");
    expect(calls[0]?.secret).toBe("s3cret");
    const [first, second] = calls[0]?.body.notifications ?? [];
    expect(first).toEqual({
      notif_id: "7",
      tokens: ["a".repeat(64)],
      platform: 1,
      topic: "com.mazl.app",
      title: "Nouveau message",
      message: "Sarah vous a envoyé un message.",
      sound: "default",
      priority: "high",
      push_type: "alert",
      production: true,
      data: { type: "new_message", conversation_id: 41 },
      collapse_id: "conv-41",
    });
    expect(second).toMatchObject({ notif_id: "8", tokens: ["b".repeat(64)], development: true });
    expect(second).not.toHaveProperty("production");
  });

  test("without a collapse id the field is absent", async () => {
    const { calls, transport } = setup();
    await transport.send({ ...message, collapseId: undefined });
    expect(calls[0]?.body.notifications[0]).not.toHaveProperty("collapse_id");
  });

  test("a member without any device: nothing is asked of gorush", async () => {
    const { calls, transport } = setup(undefined, 200, {});
    expect(await transport.send(message)).toEqual({ ok: false, reason: "no_device" });
    expect(calls).toEqual([]);
  });
});

describe("what gorush answers", () => {
  test("a token APNs refuses for good is forgotten; the push still reached another device", async () => {
    const { store, transport } = setup({ counts: 2, logs: [{ type: "failed-push", notif_id: "8", error: "Unregistered" }] });
    expect(await transport.send(message)).toEqual({ ok: true });
    expect(store.forgotten).toEqual([8]);
  });

  test("every device failing is a failure with APNs' reason; a bad key forgets no token", async () => {
    const { store, transport } = setup({
      counts: 2,
      logs: [
        { type: "failed-push", notif_id: "7", error: "InvalidProviderToken" },
        { type: "failed-push", notif_id: "8", error: "InvalidProviderToken" },
      ],
    });
    expect(await transport.send(message)).toEqual({ ok: false, reason: "InvalidProviderToken" });
    expect(store.forgotten).toEqual([]);
  });

  test("a gateway without APNs key says so", async () => {
    const { transport } = setup({ success: "ok", counts: 0, logs: [], desactive: true });
    expect(await transport.send(message)).toEqual({ ok: false, reason: "gateway_disabled" });
  });

  test("a refused secret or an unreachable gateway is a reason, never an exception", async () => {
    expect(await setup({}, 401).transport.send(message)).toEqual({ ok: false, reason: "HTTP 401" });
    const store = new FakeDevices({ 44: [{ id: 7, token: "a".repeat(64), environment: "production" }] });
    const down = createGorushTransport({
      url: "http://neo-gorush:8088",
      secret: "s3cret",
      topic: "com.mazl.app",
      devices: store,
      fetch: (() => Promise.reject(new TypeError("fetch failed"))) as unknown as typeof fetch,
    });
    expect(await down.send(message)).toEqual({ ok: false, reason: "unreachable" });
  });
});

describe("enabled", () => {
  test("only with both the address and the secret", () => {
    const store = new FakeDevices({});
    expect(createGorushTransport({ url: "http://g", secret: "s", topic: "t", devices: store }).isEnabled()).toBe(true);
    expect(createGorushTransport({ url: "", secret: "s", topic: "t", devices: store }).isEnabled()).toBe(false);
    expect(createGorushTransport({ url: "http://g", secret: "", topic: "t", devices: store }).isEnabled()).toBe(false);
  });
});
