import { REQUIRED_DOCUMENT_TYPES, type DocumentRecord } from "./types";

// A document counts for the submission unless it is rejected, or it was
// purged while still undecided (nobody ever looked at it, so the member has to
// send it again).
function isUsable(doc: DocumentRecord | undefined): boolean {
  if (!doc) return false;
  if (doc.status === "rejected") return false;
  if (doc.status === "pending" && doc.purgedAt !== null) return false;
  return true;
}

export function findMissingRequired(latest: Readonly<Record<string, DocumentRecord>>): string[] {
  return REQUIRED_DOCUMENT_TYPES.filter((type) => !isUsable(latest[type]));
}
