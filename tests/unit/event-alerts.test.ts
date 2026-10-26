import { describe, expect, test } from "bun:test";
import { createEventAlerts } from "../../src/features/events/application/event-alerts";
import type { EventAlertStore, EventOpenedPush, OpenedEvent } from "../../src/features/events/application/ports";
import type { EventAvailability } from "../../src/features/events/domain/event-availability";
import { eventOpenedText } from "../../src/features/events/domain/event-opened-text";

// « Me prévenir » and the opening of a "coming soon" event. In-memory store and
// push: nothing here touches a database or the network.

interface FakeEvent {
  availability: EventAvailability;
  published: boolean;
  title: string;
}

class MemoryStore implements EventAlertStore {
  readonly alerts = new Map<number, Map<number, boolean>>();
  constructor(readonly events: Map<number, FakeEvent>) {}
  availabilityOf(eventId: number): Promise<EventAvailability | null> {
    const event = this.events.get(eventId);
    return Promise.resolve(event?.published === true ? event.availability : null);
  }
  request(eventId: number, userId: number): Promise<void> {
    const alerts = this.alerts.get(eventId) ?? new Map<number, boolean>();
    if (!alerts.has(userId)) alerts.set(userId, false);
    this.alerts.set(eventId, alerts);
    return Promise.resolve();
  }
  withdraw(eventId: number, userId: number): Promise<void> {
    this.alerts.get(eventId)?.delete(userId);
    return Promise.resolve();
  }
  isRequested(eventId: number, userId: number): Promise<boolean> {
    return Promise.resolve(this.alerts.get(eventId)?.has(userId) === true);
  }
  open(eventId: number): Promise<OpenedEvent | null> {
    const event = this.events.get(eventId);
    if (event === undefined) return Promise.resolve(null);
    const alreadyOpen = event.availability === "open";
    event.availability = "open";
    return Promise.resolve({ title: event.title, published: event.published, alreadyOpen });
  }
  pendingRecipients(eventId: number): Promise<number[]> {
    return Promise.resolve([...(this.alerts.get(eventId) ?? new Map<number, boolean>())].filter(([, told]) => !told).map(([id]) => id));
  }
  markNotified(eventId: number, userIds: readonly number[]): Promise<void> {
    for (const id of userIds) this.alerts.get(eventId)?.set(id, true);
    return Promise.resolve();
  }
}

class FakePush implements EventOpenedPush {
  enabled = true;
  unreachable = new Set<number>();
  calls: Array<{ eventId: number; title: string; recipientIds: readonly number[] }> = [];
  isEnabled(): boolean {
    return this.enabled;
  }
  notify(event: { eventId: number; title: string; recipientIds: readonly number[] }): Promise<number[]> {
    this.calls.push(event);
    return Promise.resolve(event.recipientIds.filter((id) => !this.unreachable.has(id)));
  }
}

function world(events: Record<number, FakeEvent>) {
  const store = new MemoryStore(new Map(Object.entries(events).map(([id, event]) => [Number(id), { ...event }])));
  const push = new FakePush();
  return { store, push, alerts: createEventAlerts({ store, push }) };
}

const soon: FakeEvent = { availability: "coming_soon", published: true, title: "Dîner de Shabbat" };

describe("« Me prévenir »", () => {
  test("is recorded once on a coming soon event, and can be withdrawn", async () => {
    const { alerts } = world({ 1: soon });
    expect(await alerts.request(1, 7)).toBe("requested");
    expect(await alerts.request(1, 7)).toBe("requested");
    expect(await alerts.isRequested(1, 7)).toBe(true);
    expect(await alerts.isRequested(1, 8)).toBe(false);
    expect(await alerts.withdraw(1, 7)).toBe("withdrawn");
    expect(await alerts.isRequested(1, 7)).toBe(false);
  });

  test("is refused on an open event, and on a draft or an unknown id as not found", async () => {
    const { alerts } = world({ 1: { ...soon, availability: "open" }, 2: { ...soon, published: false } });
    expect(await alerts.request(1, 7)).toBe("already_open");
    expect(await alerts.request(2, 7)).toBe("not_found");
    expect(await alerts.request(3, 7)).toBe("not_found");
    expect(await alerts.withdraw(3, 7)).toBe("not_found");
  });
});

describe("opening an event", () => {
  test("tells every member who asked, once, with the title of the event", async () => {
    const { alerts, push } = world({ 1: soon });
    await alerts.request(1, 7);
    await alerts.request(1, 8);
    expect(await alerts.open(1)).toEqual({ kind: "opened", notified: 2, pending: 0 });
    expect(push.calls).toEqual([{ eventId: 1, title: "Dîner de Shabbat", recipientIds: [7, 8] }]);
    expect(await alerts.open(1)).toEqual({ kind: "already_open", notified: 0, pending: 0 });
    expect(push.calls).toHaveLength(1);
  });

  test("keeps the alerts it could not deliver, and sends them when opened again", async () => {
    const { alerts, push } = world({ 1: soon });
    await alerts.request(1, 7);
    await alerts.request(1, 8);
    push.unreachable.add(8);
    expect(await alerts.open(1)).toEqual({ kind: "opened", notified: 1, pending: 1 });
    push.unreachable.clear();
    expect(await alerts.open(1)).toEqual({ kind: "already_open", notified: 1, pending: 0 });
    expect(push.calls.map((call) => call.recipientIds)).toEqual([[7, 8], [8]]);
  });

  test("sends nothing without a push provider, and keeps every alert", async () => {
    const { alerts, push } = world({ 1: soon });
    await alerts.request(1, 7);
    push.enabled = false;
    expect(await alerts.open(1)).toEqual({ kind: "opened", notified: 0, pending: 1 });
    expect(push.calls).toHaveLength(0);
  });

  test("does not send for a draft (no page to open), and answers not found for an unknown id", async () => {
    const { alerts, push, store } = world({ 1: soon });
    await alerts.request(1, 7);
    const event = store.events.get(1);
    if (event !== undefined) event.published = false;
    expect(await alerts.open(1)).toEqual({ kind: "opened", notified: 0, pending: 1 });
    expect(push.calls).toHaveLength(0);
    expect(await alerts.open(99)).toEqual({ kind: "not_found" });
  });
});

describe("push wording", () => {
  test("names the event, in French, without emoji", () => {
    expect(eventOpenedText("Dîner de Shabbat")).toEqual({ title: "Inscriptions ouvertes", message: "« Dîner de Shabbat » est ouvert aux inscriptions." });
    expect(eventOpenedText("  ").message).toBe("Un événement que vous suivez est ouvert aux inscriptions.");
  });
});

describe("push through the transport of the push feature", () => {
  test("one push per member, routed to the event, collapsed per event; the failures are not counted", async () => {
    const { transportEventOpenedPush } = await import("../../src/features/events/infra/transport-event-opened-push");
    const sent: unknown[] = [];
    const errors: string[] = [];
    const push = transportEventOpenedPush(
      {
        isEnabled: () => true,
        send: (message) => {
          sent.push(message);
          if (message.recipientId === 9) return Promise.reject(new TypeError("network"));
          return Promise.resolve(message.recipientId === 8 ? { ok: false, reason: "invalid alias" } : { ok: true });
        },
      },
      { error: (line) => errors.push(line) },
    );
    expect(await push.notify({ eventId: 4, title: "Randonnée", recipientIds: [7, 8, 9] })).toEqual([7]);
    expect(sent[0]).toEqual({
      recipientId: 7,
      title: "Inscriptions ouvertes",
      message: "« Randonnée » est ouvert aux inscriptions.",
      data: { type: "event_available", event_id: 4 },
      collapseId: "event-4",
    });
    expect(errors).toEqual(["Event push not sent: invalid alias", "Event push failed: TypeError"]);
  });
});
