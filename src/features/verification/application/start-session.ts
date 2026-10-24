import { generateChallenges } from "../domain/challenges";
import { DAILY_SESSION_LIMIT, SESSION_TTL_SECONDS } from "../domain/thresholds";
import type { Challenge, FacePurpose } from "../domain/types";
import type { FaceSessionRepository } from "./ports";

export type StartSessionResult =
  | { readonly ok: true; readonly sessionId: string; readonly challenges: readonly Challenge[]; readonly expiresAt: Date }
  | { readonly ok: false; readonly reason: "daily_limit_reached"; readonly nextAttemptTime: Date };

export interface StartSessionDeps {
  readonly sessions: FaceSessionRepository;
  readonly random: () => number;
}

export async function startFaceSession(
  deps: StartSessionDeps,
  userId: number,
  purpose: FacePurpose,
): Promise<StartSessionResult> {
  const created = await deps.sessions.createWithinDailyQuota({
    userId,
    purpose,
    challenges: generateChallenges(deps.random),
    ttlSeconds: SESSION_TTL_SECONDS,
    dailyLimit: DAILY_SESSION_LIMIT,
  });
  if (!created.ok) return { ok: false, reason: "daily_limit_reached", nextAttemptTime: created.nextAttemptTime };
  const { session } = created;
  return { ok: true, sessionId: session.id, challenges: session.challenges, expiresAt: session.expiresAt };
}
