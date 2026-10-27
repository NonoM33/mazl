import type { MessageRecord, RequestRecord } from "../application/concierge-ports";
import { stepOf } from "../domain/concierge";
import type { Ritual } from "../domain/rituals";

// Domain records to wire formats.

export function ritualDto(ritual: Ritual) {
  return {
    id: ritual.id,
    couple_id: ritual.coupleId,
    kind: ritual.kind,
    title: ritual.title,
    weekday: ritual.weekday,
    time: ritual.time,
    enabled: ritual.enabled,
    remind_minutes: ritual.remindMinutes,
  };
}

export function conciergeListItem(request: RequestRecord) {
  return { id: request.id, title: request.title, status: request.status, wantedAt: request.wantedAt, updatedAt: request.updatedAt, step: stepOf(request.status) };
}

// What the couple sees of a request: never the internal note nor the assignee.
export function memberRequestDto(request: RequestRecord) {
  return {
    id: request.id,
    title: request.title,
    brief: request.brief,
    kind: request.kind,
    status: request.status,
    step: stepOf(request.status),
    wantedAt: request.wantedAt,
    city: request.city,
    constraints: request.constraints,
    options: request.options,
    chosenIndex: request.chosenIndex,
    createdAt: request.createdAt,
    updatedAt: request.updatedAt,
  };
}

export function memberMessageDto(message: MessageRecord, viewerId: number) {
  return { id: message.id, role: message.role, text: message.text, createdAt: message.createdAt, mine: message.role === "member" && message.authorId === viewerId };
}

export function staffRequestDto(request: RequestRecord) {
  return {
    id: request.id,
    title: request.title,
    brief: request.brief,
    status: request.status,
    wantedAt: request.wantedAt,
    city: request.city,
    constraints: request.constraints,
    options: request.options,
    chosenIndex: request.chosenIndex,
    staffNote: request.staffNote,
    assignedTo: request.assignedTo,
    createdAt: request.createdAt,
    updatedAt: request.updatedAt,
  };
}

export function staffMessageDto(message: MessageRecord) {
  return { id: message.id, role: message.role, authorId: message.authorId, text: message.text, createdAt: message.createdAt };
}
