import type { WebSessionConfig } from "../application/config";

// With WEB_ORIGIN set, the cookie only exists on that host.
export function hostAllowed(config: WebSessionConfig, host: string | null | undefined): boolean {
  return config.origin === null || host === config.origin.host;
}

// CSRF defence for unsafe methods: the Origin must be the site itself.
export function originAllowed(config: WebSessionConfig, origin: string | null, host: string | null): boolean {
  if (origin === null) return false;
  if (config.origin !== null) return origin === config.origin.origin;
  try {
    return host !== null && new URL(origin).host === host;
  } catch {
    return false;
  }
}
