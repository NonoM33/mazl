// Typed business errors of the chat feature. The presentation layer maps each
// kind to an HTTP status; none carries message text, URLs or names.

export type ChatErrorKind =
  | "not_found" // not a member, or the thing does not exist: always the same answer
  | "blocked"
  | "invalid" // the request is well-formed JSON but breaks a rule (detail says which)
  | "too_large"
  | "not_author"
  | "too_late"
  | "too_many_pending";

export class ChatError extends Error {
  readonly kind: ChatErrorKind;
  readonly detail: string;

  constructor(kind: ChatErrorKind, detail: string = kind) {
    super(`chat: ${kind}: ${detail}`);
    this.name = "ChatError";
    this.kind = kind;
    this.detail = detail;
  }
}

export const notFound = (): ChatError => new ChatError("not_found");
export const invalid = (detail: string): ChatError => new ChatError("invalid", detail);
