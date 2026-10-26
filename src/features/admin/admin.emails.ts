// Who is an administrator. No secret is read here, so a maintenance script can
// import it without the admin JWT configuration.

export const normalizeEmail = (email: string): string => email.trim().toLowerCase();

export const ADMIN_EMAILS: readonly string[] = ["renaudlemagicien@gmail.com", process.env.ADMIN_EMAIL]
  .filter((email): email is string => Boolean(email))
  .map(normalizeEmail);

export const isAdminEmail = (email: string): boolean => ADMIN_EMAILS.includes(normalizeEmail(email));
