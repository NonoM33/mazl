import { expect, test } from "bun:test";
import { createCouplePushes } from "../../src/features/couple/application/couple-notifier";
import type { PushMessage, PushResult, PushTransport } from "../../src/features/push/application/ports";

// Push of the couple flow (docs/couple/CONTRAT.md §3, V1-CONTRAT section 1): no
// name in the title, first name only in the body, data carries the type the
// app routes on and nothing else, and nothing is sent when pushes are not configured.

class FakeTransport implements PushTransport {
  sent: PushMessage[] = [];
  enabled = true;
  isEnabled(): boolean {
    return this.enabled;
  }
  send(message: PushMessage): Promise<PushResult> {
    this.sent.push(message);
    return Promise.resolve({ ok: true });
  }
}

const settle = () => new Promise((resolve) => setTimeout(resolve, 20));

test("no push at all when pushes are not configured", async () => {
  const transport = new FakeTransport();
  transport.enabled = false;
  createCouplePushes(transport).pushCoupleAccepted(1, "Myriam Cohen");
  await settle();
  expect(transport.sent).toHaveLength(0);
});

test("accepted push: generic title, first name only in the body, the couple type and nothing else", async () => {
  const transport = new FakeTransport();
  createCouplePushes(transport).pushCoupleAccepted(7, "Myriam Cohen");
  await settle();
  expect(transport.sent).toHaveLength(1);
  expect(transport.sent[0]?.recipientId).toBe(7);
  expect(transport.sent[0]?.title).toBe("Demande de couple acceptée");
  expect(transport.sent[0]?.message).toContain("Myriam");
  expect(transport.sent[0]?.message).not.toContain("Cohen");
  expect(transport.sent[0]?.data).toEqual({ type: "couple_accepted" });
});

test("request push goes to the target, type couple_request, vouvoiement and no emoji", async () => {
  const transport = new FakeTransport();
  const pushes = createCouplePushes(transport);
  pushes.pushCoupleRequest({ id: 3, requester_id: 5, target_id: 8, requester_name: "Daniel Lévy", status: "pending" } as unknown as Parameters<typeof pushes.pushCoupleRequest>[0]);
  await settle();
  expect(transport.sent).toHaveLength(1);
  expect(transport.sent[0]?.recipientId).toBe(8);
  expect(transport.sent[0]?.data).toEqual({ type: "couple_request" });
  expect(transport.sent[0]?.message).toContain("Daniel");
  expect(transport.sent[0]?.message).not.toContain("Lévy");
  expect(`${transport.sent[0]?.title} ${transport.sent[0]?.message}`).not.toMatch(/\p{Extended_Pictographic}/u);
});
