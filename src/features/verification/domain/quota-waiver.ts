// The daily limit of verification attempts may be lifted for the administrators
// while they test the selfie check, until a date set in the environment
// (ADMIN_VERIFICATION_UNLIMITED_UNTIL, ISO 8601): past it, the limit is back on
// its own, with no deployment.

/** The date the waiver ends, `null` when unset or unreadable (no waiver). */
export function parseWaiverEnd(raw: string | undefined): Date | null {
  if (raw === undefined || raw.trim() === "") return null;
  const end = new Date(raw.trim());
  return Number.isNaN(end.getTime()) ? null : end;
}

export function isQuotaWaived(isAdmin: boolean, now: Date, end: Date | null): boolean {
  return isAdmin && end !== null && now.getTime() < end.getTime();
}
