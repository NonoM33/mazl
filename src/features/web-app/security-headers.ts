// Headers of every web client response (docs/web/adr/W01-hebergement.md).
// No inline script, no third party except the sign-in providers the member
// chooses; frames and plugins are refused; nothing is cached but hashed files.

const CONTENT_SECURITY_POLICY = [
  "default-src 'self'",
  "script-src 'self' https://accounts.google.com/gsi/client https://appleid.cdn-apple.com",
  "style-src 'self' 'unsafe-inline' https://accounts.google.com/gsi/style",
  "img-src 'self' data: blob: https://lh3.googleusercontent.com",
  "font-src 'self'",
  "connect-src 'self' https://accounts.google.com/gsi/",
  "frame-src https://accounts.google.com/gsi/ https://appleid.apple.com",
  "media-src 'self' blob:",
  "worker-src 'self'",
  "frame-ancestors 'none'",
  "form-action 'self'",
  "base-uri 'none'",
  "object-src 'none'",
].join("; ");

export function webSecurityHeaders(secure: boolean): Record<string, string> {
  const headers: Record<string, string> = {
    "Content-Security-Policy": CONTENT_SECURITY_POLICY,
    "X-Content-Type-Options": "nosniff",
    "Referrer-Policy": "strict-origin-when-cross-origin",
    "Cross-Origin-Opener-Policy": "same-origin-allow-popups",
    "Cross-Origin-Resource-Policy": "same-origin",
    "Permissions-Policy": "camera=(), microphone=(), geolocation=(), payment=(), usb=(), interest-cohort=()",
    "X-Frame-Options": "DENY",
  };
  if (secure) headers["Strict-Transport-Security"] = "max-age=31536000; includeSubDomains";
  return headers;
}

export const NO_STORE = "no-store";
export const IMMUTABLE = "public, max-age=31536000, immutable";
