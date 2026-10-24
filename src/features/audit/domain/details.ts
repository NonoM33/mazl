// Audit details are small structured facts. Contents that belong to members
// (messages, documents) or secrets never enter the journal: it is read by many
// people, kept forever and cannot be edited.

const FORBIDDEN_KEYS: readonly string[] = ["content", "message", "password", "token", "secret", "document"];

export class ForbiddenAuditDetailError extends Error {
  constructor(readonly key: string) {
    super(`audit details must not contain a "${key}" key`);
    this.name = "ForbiddenAuditDetailError";
  }
}

export function assertSafeDetails(value: unknown): void {
  if (Array.isArray(value)) {
    for (const item of value) assertSafeDetails(item);
    return;
  }
  if (typeof value !== "object" || value === null) return;
  for (const [key, nested] of Object.entries(value)) {
    if (FORBIDDEN_KEYS.includes(key.toLowerCase())) throw new ForbiddenAuditDetailError(key);
    assertSafeDetails(nested);
  }
}
