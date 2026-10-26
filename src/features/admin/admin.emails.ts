// Who is an administrator. No secret is read here, so a maintenance script can
// import it without the admin JWT configuration.

export const normalizeEmail = (email: string): string => email.trim().toLowerCase();

export const ADMIN_EMAILS: readonly string[] = ["renaudlemagicien@gmail.com", process.env.ADMIN_EMAIL]
  .filter((email): email is string => Boolean(email))
  .map(normalizeEmail);

export const isAdminEmail = (email: string): boolean => ADMIN_EMAILS.includes(normalizeEmail(email));

// Member accounts the administrators test the app with, by id
// (ADMIN_TEST_USER_IDS, comma-separated): an account signed in with Apple may
// carry a relay address instead of the administrator's e-mail. Only the test
// conveniences use it (sample conversations, lifted verification limit), never
// the back office.
export function parseTestAccountIds(raw: string | undefined): ReadonlySet<number> {
  const ids = (raw ?? "")
    .split(",")
    .map((part) => part.trim())
    .filter((part) => /^\d+$/.test(part))
    .map(Number);
  return new Set(ids);
}

export const isAdminTestAccount = (
  account: { readonly id: number; readonly email: string },
  testIds: ReadonlySet<number> = parseTestAccountIds(process.env.ADMIN_TEST_USER_IDS),
): boolean => isAdminEmail(account.email) || testIds.has(account.id);
