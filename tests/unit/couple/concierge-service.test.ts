import { describe, expect, test } from "bun:test";
import { ConciergeNotFoundError, ConciergeRuleError, ConciergeService } from "../../../src/features/couple/application/concierge-service";
import type { ConciergeAssistant, ConciergePush, ConciergeStore, MessageRecord, RequestRecord } from "../../../src/features/couple/application/concierge-ports";
import type { AssistantInput } from "../../../src/features/couple/domain/assistant-prompt";
import type { AssistantOutput, ConciergeOption, MessageRole, RequestStatus } from "../../../src/features/couple/domain/concierge";

// An in-memory store with the same contract as PgConciergeStore.
class MemoryStore implements ConciergeStore {
  requests: RequestRecord[] = [];
  messagesByRequest = new Map<number, MessageRecord[]>();
  private nextId = 1;
  private nextMessageId = 1;
  memberMessageCount = 0;

  async create(request: Parameters<ConciergeStore["create"]>[0]): Promise<RequestRecord> {
    const record: RequestRecord = { id: this.nextId++, ...request, staffNote: null, assignedTo: null, status: "new", options: [], chosenIndex: null, createdAt: "2026-10-27T10:00:00.000Z", updatedAt: "2026-10-27T10:00:00.000Z" };
    this.requests.push(record);
    return record;
  }
  async find(id: number) { return this.requests.find((r) => r.id === id) ?? null; }
  async listForCouple(coupleId: number) { return this.requests.filter((r) => r.coupleId === coupleId); }
  async listAll() { return this.requests; }
  async thread(requestId: number) { return this.messagesByRequest.get(requestId) ?? []; }
  async addMessage(requestId: number, role: MessageRole, authorId: number | null, text: string) {
    const message: MessageRecord = { id: this.nextMessageId++, role, authorId, text, createdAt: "2026-10-27T10:00:00.000Z" };
    this.messagesByRequest.set(requestId, [...(this.messagesByRequest.get(requestId) ?? []), message]);
    if (role === "member") this.memberMessageCount += 1;
    return message;
  }
  async memberMessagesToday() { return this.memberMessageCount; }
  private replace(id: number, change: Partial<RequestRecord>) {
    const index = this.requests.findIndex((r) => r.id === id);
    const current = this.requests[index];
    if (current === undefined) return null;
    const next = { ...current, ...change };
    this.requests[index] = next;
    return next;
  }
  async setProposal(id: number, status: RequestStatus, options: readonly ConciergeOption[]) { this.replace(id, { status, options, chosenIndex: null }); }
  async setStatus(id: number, status: RequestStatus, chosenIndex?: number | null) { return this.replace(id, { status, ...(chosenIndex === undefined ? {} : { chosenIndex }) }); }
  async patchStaff(id: number, patch: { status?: RequestStatus; staffNote?: string; assignedTo?: string | null }) {
    return this.replace(id, { ...(patch.status === undefined ? {} : { status: patch.status }), ...(patch.staffNote === undefined ? {} : { staffNote: patch.staffNote }), ...(patch.assignedTo === undefined ? {} : { assignedTo: patch.assignedTo }) });
  }
  async coupleSummary(coupleId: number) { return { firstNames: ["Léa", "David"], months: 7, memberIds: [coupleId * 10, coupleId * 10 + 1] }; }
}

const OPTIONS: ConciergeOption[] = [{ title: "Table calme", details: "Casher", priceHint: "autour de 90 euros" }, { title: "Brunch", details: "Dimanche", priceHint: "autour de 40 euros" }];

function setup(answer: AssistantOutput | null | Error = { reply: "Voici deux idées.", options: OPTIONS }) {
  const store = new MemoryStore();
  const inputs: AssistantInput[] = [];
  const told: number[][] = [];
  const assistant: ConciergeAssistant = {
    respond: async (input) => {
      inputs.push(input);
      if (answer instanceof Error) throw answer;
      return answer;
    },
  };
  const push: ConciergePush = { teamAnswered: async (ids) => void told.push([...ids]) };
  const service = new ConciergeService({ store, assistant, push, now: () => new Date("2026-10-27T12:00:00Z"), log: () => undefined });
  return { store, inputs, told, service };
}
const BRIEF = { text: "Dîner casher pour notre anniversaire", wantedAt: "2026-11-13", city: "Paris", kind: "table" as const, constraints: { kosher: true } };

describe("a request to the concierge", () => {
  test("with the assistant: ideas are proposed and the status is proposed", async () => {
    const { service } = setup();
    const view = await service.create(1, 10, BRIEF, "fr");
    expect(view.request.status).toBe("proposed");
    expect(view.request.options).toHaveLength(2);
    expect(view.messages.map((m) => m.role)).toEqual(["member", "assistant"]);
  });

  test("the assistant only receives the texts, the date, the city, the kind and the constraints", async () => {
    const { service, inputs } = setup();
    await service.create(1, 10, BRIEF, "fr");
    expect(inputs[0]).toEqual({
      kind: "table", wantedAt: "2026-11-13", city: "Paris", constraints: { kosher: true },
      turns: [{ role: "member", text: "Dîner casher pour notre anniversaire" }],
    });
  });

  test.each([["no assistant (null)", null], ["an assistant that throws", new Error("boom")]])("%s: status new and a message from the team, never an error", async (_label, answer) => {
    const { service } = setup(answer);
    const view = await service.create(1, 10, BRIEF, "en");
    expect(view.request.status).toBe("new");
    expect(view.messages).toHaveLength(2);
    expect(view.messages[1]).toMatchObject({ role: "staff", authorId: null });
    expect(view.messages[1]?.text).toContain("MAZL team");
  });

  test("a reply without ideas keeps the status", async () => {
    const { service } = setup({ reply: "Pour quelle ville ?", options: [] });
    expect((await service.create(1, 10, BRIEF, "fr")).request.status).toBe("new");
  });

  test("the twenty-first message of the day is refused", async () => {
    const { service, store } = setup();
    store.memberMessageCount = 20;
    await expect(service.create(1, 10, BRIEF, "fr")).rejects.toMatchObject({ code: "concierge_rate_limited" });
    expect(store.requests).toHaveLength(0);
  });
});

describe("couple isolation", () => {
  test("another couple's request is not found, whatever the operation", async () => {
    const { service } = setup();
    const { request } = await service.create(1, 10, BRIEF, "fr");
    for (const call of [
      () => service.get(2, request.id),
      () => service.sendMessage(2, 20, request.id, "bonjour", "fr"),
      () => service.choose(2, request.id, 0),
      () => service.cancel(2, request.id),
    ]) await expect(call()).rejects.toBeInstanceOf(ConciergeNotFoundError);
    expect(await service.list(2)).toEqual([]);
  });

  test("both members of the couple write in the same request", async () => {
    const { service } = setup();
    const { request } = await service.create(1, 10, BRIEF, "fr");
    const view = await service.sendMessage(1, 11, request.id, "Plutôt le soir", "fr");
    expect(view.messages.filter((m) => m.role === "member").map((m) => m.authorId)).toEqual([10, 11]);
  });
});

describe("choosing, cancelling, and the team", () => {
  test("choose then the team books; the couple cannot cancel a booked request", async () => {
    const { service } = setup();
    const { request } = await service.create(1, 10, BRIEF, "fr");
    expect((await service.choose(1, request.id, 1)).request).toMatchObject({ status: "chosen", chosenIndex: 1 });
    const booked = await service.staffPatch(request.id, { status: "booked", staffNote: "Table à 20h." });
    expect(booked.request).toMatchObject({ status: "booked", staffNote: "Table à 20h." });
    await expect(service.cancel(1, request.id)).rejects.toMatchObject({ code: "invalid_transition" });
  });

  test("the team cannot book before an idea is chosen", async () => {
    const { service } = setup();
    const { request } = await service.create(1, 10, BRIEF, "fr");
    await expect(service.staffPatch(request.id, { status: "booked" })).rejects.toMatchObject({ code: "invalid_transition" });
  });

  test("an index outside the proposed ideas is refused", async () => {
    const { service } = setup();
    const { request } = await service.create(1, 10, BRIEF, "fr");
    await expect(service.choose(1, request.id, 2)).rejects.toBeInstanceOf(ConciergeRuleError);
  });

  test("a closed or cancelled request takes no more messages, from either side", async () => {
    const { service } = setup();
    const { request } = await service.create(1, 10, BRIEF, "fr");
    await service.cancel(1, request.id);
    await expect(service.sendMessage(1, 10, request.id, "encore", "fr")).rejects.toMatchObject({ code: "concierge_closed" });
    await expect(service.staffMessage(request.id, null, "bonjour")).rejects.toMatchObject({ code: "concierge_closed" });
    await expect(service.staffPatch(request.id, { staffNote: "x" })).rejects.toMatchObject({ code: "concierge_closed" });
  });

  test("a team message tells both members, and the assistant stays quiet once an idea is chosen", async () => {
    const { service, told, inputs } = setup();
    const { request } = await service.create(1, 10, BRIEF, "fr");
    await service.choose(1, request.id, 0);
    const before = inputs.length;
    await service.sendMessage(1, 10, request.id, "Merci !", "fr");
    expect(inputs).toHaveLength(before);
    const view = await service.staffMessage(request.id, null, "Nous réservons.");
    expect(told).toEqual([[10, 11]]);
    expect(view.couple).toMatchObject({ firstNames: ["Léa", "David"], months: 7 });
    expect(view.messages.at(-1)).toMatchObject({ role: "staff", text: "Nous réservons." });
  });
});
