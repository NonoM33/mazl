import { DEFAULT_DIFFICULTY, MAX_DIFFICULTY } from "../domain/pow";
import { WebSessionConfigError } from "../domain/errors";

type Env = Readonly<Record<string, string | undefined>>;

export interface WebSessionConfig {
  readonly powDifficulty: number;
  // Parsed WEB_ORIGIN, or null in development and tests.
  readonly origin: URL | null;
  readonly googleClientId: string | null;
  readonly appleServicesId: string | null;
}

function nonEmpty(value: string | undefined): string | null {
  return value !== undefined && value.length > 0 ? value : null;
}

function parseDifficulty(env: Env): number {
  const raw = nonEmpty(env.WEB_POW_DIFFICULTY);
  if (raw === null) return DEFAULT_DIFFICULTY;
  const value = /^\d+$/.test(raw) ? Number(raw) : Number.NaN;
  if (!Number.isInteger(value) || value > MAX_DIFFICULTY) {
    throw new WebSessionConfigError(`WEB_POW_DIFFICULTY must be an integer between 0 and ${MAX_DIFFICULTY}`);
  }
  if (value === 0 && env.NODE_ENV === "production") {
    throw new WebSessionConfigError("WEB_POW_DIFFICULTY=0 is refused in production");
  }
  return value;
}

function parseOrigin(env: Env): URL | null {
  const raw = nonEmpty(env.WEB_ORIGIN);
  if (raw === null) return null;
  try {
    return new URL(raw);
  } catch {
    throw new WebSessionConfigError("WEB_ORIGIN must be an absolute URL");
  }
}

export function readConfig(env: Env): WebSessionConfig {
  return {
    powDifficulty: parseDifficulty(env),
    origin: parseOrigin(env),
    googleClientId: nonEmpty(env.GOOGLE_CLIENT_ID),
    appleServicesId: nonEmpty(env.APPLE_WEB_SERVICES_ID),
  };
}
