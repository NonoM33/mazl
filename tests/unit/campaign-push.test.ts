import { expect, test } from "bun:test";
import type { PushMessage, PushResult, PushTransport } from "../../src/features/push/application/ports";

// A push campaign goes to each recipient through the push transport (gorush):
// only the members it reached are marked sent, the others count as errors.

// The admin routes refuse to load without a secret to sign admin tokens with.
process.env.JWT_SECRET ??= "unit-test-secret";
const { deliverPushCampaign } = await import("../../src/features/admin/admin.campaigns.routes");

class FakeTransport implements PushTransport {
  sent: PushMessage[] = [];
  constructor(private readonly unreachable: ReadonlySet<number> = new Set()) {}
  isEnabled(): boolean {
    return true;
  }
  send(message: PushMessage): Promise<PushResult> {
    this.sent.push(message);
    return Promise.resolve(this.unreachable.has(message.recipientId) ? { ok: false, reason: "no_device" } : { ok: true });
  }
}

test("each recipient gets the campaign; only those reached are marked sent", async () => {
  const transport = new FakeTransport(new Set([2]));
  const marked: number[][] = [];
  const outcome = await deliverPushCampaign(transport, { id: 9, title: "Shavouot", content: "Une soirée vous attend." }, [{ id: 1 }, { id: 2 }, { id: 3 }], async (_campaignId, ids) => {
    marked.push([...ids]);
  });
  expect(outcome).toEqual({ sent: 2, errors: 1, total: 3 });
  expect(transport.sent.map((push) => [push.recipientId, push.title, push.message, push.data])).toEqual([
    [1, "Shavouot", "Une soirée vous attend.", { type: "announcement", campaign_id: 9 }],
    [2, "Shavouot", "Une soirée vous attend.", { type: "announcement", campaign_id: 9 }],
    [3, "Shavouot", "Une soirée vous attend.", { type: "announcement", campaign_id: 9 }],
  ]);
  expect(marked.flat().sort()).toEqual([1, 3]);
});

test("pushes not configured: nothing is sent, every recipient is an error", async () => {
  const transport = new FakeTransport();
  transport.isEnabled = () => false;
  const outcome = await deliverPushCampaign(transport, { id: 9, title: "T", content: "C" }, [{ id: 1 }], async () => undefined);
  expect(outcome).toEqual({ sent: 0, errors: 1, total: 1 });
  expect(transport.sent).toEqual([]);
});
