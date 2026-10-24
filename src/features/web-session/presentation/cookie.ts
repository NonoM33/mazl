export const COOKIE_NAME = "__Host-mazl_web";
// Set by the bridge only; routes read it to know which web session calls them.
export const SESSION_HEADER = "x-mazl-web-session";
export const WEB_CLIENT_HEADER = "x-mazl-web";

export function readCookie(header: string | null | undefined, name: string): string | undefined {
  if (!header) return undefined;
  for (const part of header.split(";")) {
    const separator = part.indexOf("=");
    if (separator > 0 && part.slice(0, separator).trim() === name) return part.slice(separator + 1).trim();
  }
  return undefined;
}

// `__Host-` requires Secure, Path=/ and no Domain: the cookie is bound to the
// exact host that set it.
export function sessionCookie(value: string, maxAgeSeconds: number): string {
  return `${COOKIE_NAME}=${value}; Max-Age=${maxAgeSeconds}; Path=/; HttpOnly; Secure; SameSite=Strict`;
}

export function clearedCookie(): string {
  return sessionCookie("", 0);
}
