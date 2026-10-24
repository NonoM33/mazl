import type { ReportReason, SanctionKind } from "./types";

// The graduated scale: a suggestion for the moderator, never applied alone.

const RUNGS: readonly SanctionKind[] = ["warning", "restriction", "suspension", "ban"];

export interface PastSanction {
  readonly kind: SanctionKind;
  readonly revoked: boolean;
}

function rank(kind: SanctionKind): number {
  return RUNGS.indexOf(kind);
}

function atLeast(a: SanctionKind, b: SanctionKind): SanctionKind {
  return rank(a) >= rank(b) ? a : b;
}

function nextAfterHistory(history: readonly PastSanction[]): SanctionKind {
  const standing = history.filter((entry) => !entry.revoked);
  if (standing.length === 0) return "warning";
  const highest = Math.max(...standing.map((entry) => rank(entry.kind)));
  return RUNGS[Math.min(highest + 1, RUNGS.length - 1)] ?? "ban";
}

export function suggestSanction(reason: ReportReason, history: readonly PastSanction[]): SanctionKind {
  const hasPrior = history.some((entry) => !entry.revoked);
  const next = nextAfterHistory(history);
  switch (reason) {
    case "underage":
      // A minor is taken off the platform at once, pending an age check.
      return atLeast(next, "suspension");
    case "offline_behavior":
      // A threat or danger in person: a repeat is a ban.
      return hasPrior ? "ban" : next;
    case "scam":
      return hasPrior ? atLeast(next, "suspension") : next;
    default:
      return next;
  }
}
