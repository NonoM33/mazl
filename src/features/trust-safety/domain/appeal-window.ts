// A member may contest a sanction free of charge for six months (DSA art. 20).
export const APPEAL_WINDOW_MONTHS = 6;

export function appealDeadline(issuedAt: Date): Date {
  const deadline = new Date(issuedAt.getTime());
  deadline.setUTCMonth(deadline.getUTCMonth() + APPEAL_WINDOW_MONTHS);
  return deadline;
}

export function isAppealWindowOpen(issuedAt: Date, now: Date): boolean {
  return now.getTime() <= appealDeadline(issuedAt).getTime();
}
