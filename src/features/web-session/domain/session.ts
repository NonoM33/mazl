export const IDLE_TIMEOUT_MS = 4 * 60 * 60 * 1000;
export const ABSOLUTE_LIFETIME_MS = 7 * 24 * 60 * 60 * 1000;
export const TOUCH_INTERVAL_MS = 60_000;

export type SignInMethod = "qr" | "google" | "apple";

export interface WebSession {
  readonly id: string;
  readonly userId: number;
  readonly browserLabel: string;
  readonly method: SignInMethod;
  readonly createdAt: Date;
  readonly lastSeenAt: Date;
  readonly idleExpiresAt: Date;
  readonly expiresAt: Date;
  readonly revokedAt: Date | null;
}

export function isActive(session: WebSession, now: Date): boolean {
  return (
    session.revokedAt === null &&
    session.idleExpiresAt.getTime() > now.getTime() &&
    session.expiresAt.getTime() > now.getTime()
  );
}

export function idleDeadline(lastSeen: Date): Date {
  return new Date(lastSeen.getTime() + IDLE_TIMEOUT_MS);
}

export function absoluteDeadline(createdAt: Date): Date {
  return new Date(createdAt.getTime() + ABSOLUTE_LIFETIME_MS);
}

export function needsTouch(session: WebSession, now: Date): boolean {
  return now.getTime() - session.lastSeenAt.getTime() >= TOUCH_INTERVAL_MS;
}

// Cookie lifetime: what remains of the absolute duration.
export function remainingSeconds(session: WebSession, now: Date): number {
  return Math.max(0, Math.floor((session.expiresAt.getTime() - now.getTime()) / 1000));
}
