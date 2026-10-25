type Env = Readonly<Record<string, string | undefined>>;

// Sample data (fake members, fictitious couple catalogue) and the /api/dev/*
// routes exist only when NODE_ENV says development or test. Any other value,
// unset or empty included, counts as a real deployment: a staging server that
// forgot NODE_ENV must not invent members, nor hand out tokens for any e-mail.
export function isDevelopmentEnvironment(env: Env = process.env): boolean {
  return env.NODE_ENV === "development" || env.NODE_ENV === "test";
}
