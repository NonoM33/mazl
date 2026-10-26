import { afterEach, beforeEach, expect, test } from "bun:test";
import { oneSignalTransport } from "../../src/features/push/infra/onesignal-transport";

// The adapter between the push port and OneSignal: target format and
// enablement come from the key, as in V1-CONTRAT section 1.

const realFetch = globalThis.fetch;
const realKey = process.env.ONESIGNAL_REST_API_KEY;
let bodies: Array<Record<string, unknown>> = [];
let status = 200;

beforeEach(() => {
  bodies = [];
  status = 200;
  process.env.ONESIGNAL_REST_API_KEY = "test-key";
  globalThis.fetch = (async (_url: unknown, init?: { body?: string }) => {
    bodies.push(JSON.parse(String(init?.body)) as Record<string, unknown>);
    return new Response(JSON.stringify(status === 200 ? { id: "n1", recipients: 1 } : { errors: ["All included players are not subscribed"] }), { status });
  }) as unknown as typeof fetch;
});

afterEach(() => {
  globalThis.fetch = realFetch;
  if (realKey === undefined) delete process.env.ONESIGNAL_REST_API_KEY;
  else process.env.ONESIGNAL_REST_API_KEY = realKey;
});

test("the member is user_<id>; data and collapse_id travel as given", async () => {
  const result = await oneSignalTransport.send({ recipientId: 9, title: "T", message: "M", data: { type: "new_message", conversation_id: 3 }, collapseId: "conv-3" });
  expect(result).toEqual({ ok: true });
  expect(bodies[0]).toMatchObject({ include_aliases: { external_id: ["user_9"] }, target_channel: "push", data: { type: "new_message", conversation_id: 3 }, collapse_id: "conv-3" });
});

test("without a collapse id the field is not sent", async () => {
  await oneSignalTransport.send({ recipientId: 9, title: "T", message: "M", data: { type: "new_match", match_user_id: 4 } });
  expect(bodies[0]).not.toHaveProperty("collapse_id");
});

test("enabled only with a key, and then no request is made at all", async () => {
  expect(oneSignalTransport.isEnabled()).toBe(true);
  delete process.env.ONESIGNAL_REST_API_KEY;
  expect(oneSignalTransport.isEnabled()).toBe(false);
  const result = await oneSignalTransport.send({ recipientId: 9, title: "T", message: "M", data: { type: "new_match" } });
  expect(result.ok).toBe(false);
  expect(bodies).toEqual([]);
});

test("a refusal of OneSignal comes back as a reason, not as an exception", async () => {
  status = 400;
  const result = await oneSignalTransport.send({ recipientId: 9, title: "T", message: "M", data: { type: "new_match" } });
  expect(result).toEqual({ ok: false, reason: "All included players are not subscribed" });
});
