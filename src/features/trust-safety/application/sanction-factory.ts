import { createHash } from "node:crypto";
import { buildAppealCode, buildReference, normalizeAppealCode } from "../domain/references";
import { buildStatement, type DecisionOrigin } from "../domain/statement";
import type { SanctionInput } from "../presentation/dto";
import type { NewSanction } from "./ports";

const DAY_MS = 86_400_000;

export function hashAppealCode(code: string): string {
  return createHash("sha256").update(normalizeAppealCode(code)).digest("hex");
}

export interface PreparedSanction {
  readonly sanction: NewSanction;
  // Shown once to the staff member and handed to the notifier; never stored.
  readonly appealCode: string;
}

export interface PrepareInput {
  readonly memberId: number;
  readonly input: SanctionInput;
  readonly decidedBy: string;
  readonly reportId: number | null;
  readonly note: string | null;
  readonly origin: DecisionOrigin;
  readonly now: Date;
  readonly random: (length: number) => Uint8Array;
}

function endOf(input: SanctionInput, startsAt: Date): Date | null {
  const timed = input.kind === "restriction" || input.kind === "suspension";
  if (!timed || input.durationDays === undefined) return null;
  return new Date(startsAt.getTime() + input.durationDays * DAY_MS);
}

export function prepareSanction(prepare: PrepareInput): PreparedSanction {
  const { input, now } = prepare;
  const endsAt = endOf(input, now);
  const appealCode = buildAppealCode(prepare.random(12));
  const statement = buildStatement({
    reference: buildReference(now.getUTCFullYear(), prepare.random(6)),
    kind: input.kind,
    ground: input.ground,
    facts: input.facts,
    startsAt: now,
    endsAt,
    origin: prepare.origin,
    issuedAt: now,
  });
  return {
    appealCode,
    sanction: {
      memberId: prepare.memberId,
      kind: input.kind,
      ground: input.ground,
      startsAt: now,
      endsAt,
      decidedBy: prepare.decidedBy,
      reportId: prepare.reportId,
      statement,
      appealCodeHash: hashAppealCode(appealCode),
      note: prepare.note,
    },
  };
}
