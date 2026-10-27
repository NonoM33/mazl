import type { AssistantInput } from "../domain/assistant-prompt";
import type { AssistantOutput, ConciergeOption, Constraints, MessageRole, RequestKind, RequestStatus } from "../domain/concierge";

// The assistant: returns its validated answer, or null when it is absent, fails
// or answers something invalid (the request then goes to the team).
export interface ConciergeAssistant {
  respond(input: AssistantInput): Promise<AssistantOutput | null>;
}

export interface RequestRecord {
  readonly id: number;
  readonly coupleId: number;
  readonly createdBy: number | null;
  readonly title: string;
  readonly brief: string;
  readonly kind: RequestKind;
  readonly wantedAt: string | null;
  readonly city: string | null;
  readonly constraints: Constraints;
  readonly status: RequestStatus;
  readonly options: readonly ConciergeOption[];
  readonly chosenIndex: number | null;
  readonly staffNote: string | null;
  readonly assignedTo: string | null;
  readonly createdAt: string;
  readonly updatedAt: string;
}

export interface MessageRecord {
  readonly id: number;
  readonly role: MessageRole;
  readonly authorId: number | null;
  readonly text: string;
  readonly createdAt: string;
}

export interface NewRequest {
  readonly coupleId: number;
  readonly createdBy: number;
  readonly title: string;
  readonly brief: string;
  readonly kind: RequestKind;
  readonly wantedAt: string | null;
  readonly city: string | null;
  readonly constraints: Constraints;
}

export interface CoupleSummary {
  readonly firstNames: readonly string[];
  readonly months: number;
  readonly memberIds: readonly number[];
}

export interface StaffListFilter {
  readonly status?: RequestStatus;
}

export interface ConciergeStore {
  create(request: NewRequest): Promise<RequestRecord>;
  find(id: number): Promise<RequestRecord | null>;
  listForCouple(coupleId: number): Promise<RequestRecord[]>;
  listAll(filter: StaffListFilter): Promise<RequestRecord[]>;
  thread(requestId: number): Promise<MessageRecord[]>;
  addMessage(requestId: number, role: MessageRole, authorId: number | null, text: string): Promise<MessageRecord>;
  // Messages written by the couple's members today, for the daily limit.
  memberMessagesToday(coupleId: number, since: Date): Promise<number>;
  setProposal(id: number, status: RequestStatus, options: readonly ConciergeOption[]): Promise<void>;
  setStatus(id: number, status: RequestStatus, chosenIndex?: number | null): Promise<RequestRecord | null>;
  patchStaff(id: number, patch: { status?: RequestStatus; staffNote?: string; assignedTo?: string | null }): Promise<RequestRecord | null>;
  coupleSummary(coupleId: number): Promise<CoupleSummary | null>;
}

export interface ConciergePush {
  // Both members are told the team answered (section 7).
  teamAnswered(memberIds: readonly number[]): Promise<void>;
}
