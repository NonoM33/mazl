import type { AssistantInput, AssistantTurn } from "../domain/assistant-prompt";
import {
  coupleCancel,
  coupleChoose,
  DAILY_MESSAGE_LIMIT,
  staffMove,
  teamFallbackText,
  titleFrom,
  type Constraints,
  type RequestKind,
  type RequestStatus,
} from "../domain/concierge";
import type { QuestionLanguage } from "../domain/question-bank";
import type { ConciergeAssistant, ConciergePush, ConciergeStore, CoupleSummary, MessageRecord, RequestRecord } from "./concierge-ports";

export class ConciergeNotFoundError extends Error {
  constructor() {
    super("concierge request not found");
    this.name = "ConciergeNotFoundError";
  }
}

export class ConciergeRuleError extends Error {
  constructor(readonly code: "concierge_closed" | "invalid_transition" | "concierge_rate_limited") {
    super(code);
    this.name = "ConciergeRuleError";
  }
}

export interface ConciergeDeps {
  readonly store: ConciergeStore;
  readonly assistant: ConciergeAssistant;
  readonly push: ConciergePush;
  readonly now: () => Date;
  readonly log: (line: string) => void;
}

export interface CreateInput {
  readonly text: string;
  readonly wantedAt: string | null;
  readonly city: string | null;
  readonly kind: RequestKind;
  readonly constraints: Constraints;
}

export interface RequestView {
  readonly request: RequestRecord;
  readonly messages: MessageRecord[];
}

export interface StaffRequestView extends RequestView {
  readonly couple: CoupleSummary;
}

const DAY_MS = 86_400_000;

export class ConciergeService {
  constructor(private readonly deps: ConciergeDeps) {}

  list(coupleId: number): Promise<RequestRecord[]> {
    return this.deps.store.listForCouple(coupleId);
  }

  // A request of another couple does not exist for the caller.
  private async owned(coupleId: number, id: number): Promise<RequestRecord> {
    const request = await this.deps.store.find(id);
    if (request === null || request.coupleId !== coupleId) throw new ConciergeNotFoundError();
    return request;
  }

  async get(coupleId: number, id: number): Promise<RequestView> {
    const request = await this.owned(coupleId, id);
    return { request, messages: await this.deps.store.thread(id) };
  }

  private async checkLimit(coupleId: number): Promise<void> {
    const since = new Date(this.deps.now().getTime() - DAY_MS);
    if ((await this.deps.store.memberMessagesToday(coupleId, since)) >= DAILY_MESSAGE_LIMIT) throw new ConciergeRuleError("concierge_rate_limited");
  }

  async create(coupleId: number, userId: number, input: CreateInput, language: QuestionLanguage): Promise<RequestView> {
    await this.checkLimit(coupleId);
    const request = await this.deps.store.create({
      coupleId,
      createdBy: userId,
      title: titleFrom(input.text),
      brief: input.text,
      kind: input.kind,
      wantedAt: input.wantedAt,
      city: input.city,
      constraints: input.constraints,
    });
    await this.deps.store.addMessage(request.id, "member", userId, input.text);
    await this.answer(request, language);
    return this.view(request.id);
  }

  async sendMessage(coupleId: number, userId: number, id: number, text: string, language: QuestionLanguage): Promise<RequestView> {
    const request = await this.owned(coupleId, id);
    if (request.status === "closed" || request.status === "cancelled") throw new ConciergeRuleError("concierge_closed");
    await this.checkLimit(coupleId);
    await this.deps.store.addMessage(id, "member", userId, text);
    // Once an idea is chosen or booked the team is in charge: the message waits for them.
    if (request.status === "new" || request.status === "proposed") await this.answer(request, language);
    return this.view(id);
  }

  async choose(coupleId: number, id: number, index: number): Promise<RequestView> {
    const request = await this.owned(coupleId, id);
    const move = coupleChoose(request.status, request.options.length, index);
    if (!move.ok) throw new ConciergeRuleError(move.error);
    await this.deps.store.setStatus(id, "chosen", index);
    return this.view(id);
  }

  async cancel(coupleId: number, id: number): Promise<RequestView> {
    const request = await this.owned(coupleId, id);
    const move = coupleCancel(request.status);
    if (!move.ok) throw new ConciergeRuleError(move.error);
    await this.deps.store.setStatus(id, "cancelled");
    return this.view(id);
  }

  // ---- team side ----

  listForStaff(status?: RequestStatus): Promise<RequestRecord[]> {
    return this.deps.store.listAll(status === undefined ? {} : { status });
  }

  coupleSummary(coupleId: number): Promise<CoupleSummary | null> {
    return this.deps.store.coupleSummary(coupleId);
  }

  async staffView(id: number): Promise<StaffRequestView> {
    const request = await this.deps.store.find(id);
    if (request === null) throw new ConciergeNotFoundError();
    return this.staffViewOf(request);
  }

  private async staffViewOf(request: RequestRecord): Promise<StaffRequestView> {
    const couple = (await this.deps.store.coupleSummary(request.coupleId)) ?? { firstNames: [], months: 0, memberIds: [] };
    return { request, messages: await this.deps.store.thread(request.id), couple };
  }

  async staffPatch(id: number, patch: { status?: "booked" | "closed"; staffNote?: string; assignedTo?: string | null }): Promise<StaffRequestView> {
    const request = await this.deps.store.find(id);
    if (request === null) throw new ConciergeNotFoundError();
    if (patch.status !== undefined) {
      const move = staffMove(request.status, request.chosenIndex, patch.status);
      if (!move.ok) throw new ConciergeRuleError(move.error);
    } else if (request.status === "closed" || request.status === "cancelled") {
      throw new ConciergeRuleError("concierge_closed");
    }
    const updated = await this.deps.store.patchStaff(id, patch);
    if (updated === null) throw new ConciergeNotFoundError();
    return this.staffViewOf(updated);
  }

  async staffMessage(id: number, authorId: number | null, text: string): Promise<StaffRequestView> {
    const request = await this.deps.store.find(id);
    if (request === null) throw new ConciergeNotFoundError();
    if (request.status === "closed" || request.status === "cancelled") throw new ConciergeRuleError("concierge_closed");
    await this.deps.store.addMessage(id, "staff", authorId, text);
    const view = await this.staffViewOf((await this.deps.store.find(id)) ?? request);
    await this.deps.push.teamAnswered(view.couple.memberIds);
    return view;
  }

  // ---- assistant ----

  private async view(id: number): Promise<RequestView> {
    const request = await this.deps.store.find(id);
    if (request === null) throw new ConciergeNotFoundError();
    return { request, messages: await this.deps.store.thread(id) };
  }

  // Asks the assistant. Whatever goes wrong, the couple gets a message and the
  // request waits for the team: never an error.
  private async answer(request: RequestRecord, language: QuestionLanguage): Promise<void> {
    const turns: AssistantTurn[] = (await this.deps.store.thread(request.id)).map((message) => ({ role: message.role, text: message.text }));
    const input: AssistantInput = { kind: request.kind, wantedAt: request.wantedAt, city: request.city, constraints: request.constraints, turns };
    let output = null;
    try {
      output = await this.deps.assistant.respond(input);
    } catch (error: unknown) {
      this.deps.log(`Concierge assistant failed: ${error instanceof Error ? error.name : "unknown"}`);
    }
    if (output === null) {
      await this.deps.store.addMessage(request.id, "staff", null, teamFallbackText(language));
      return;
    }
    await this.deps.store.addMessage(request.id, "assistant", null, output.reply);
    if (output.options.length > 0) await this.deps.store.setProposal(request.id, "proposed", output.options);
  }
}
