export interface AscConfig {
  readonly keyId: string;
  readonly issuerId: string;
  readonly privateKeyPem: string;
  readonly appId: string;
  readonly subscriptionGroupId: string;
}

type Env = Readonly<Record<string, string | undefined>>;

// App id and subscription group of mazl+ (docs/premium/APP-STORE-CONNECT.md).
const DEFAULT_APP_ID = "6758543555";
const DEFAULT_GROUP_ID = "22508803";

function value(env: Env, name: string): string | undefined {
  const raw = env[name]?.trim();
  return raw === undefined || raw === "" ? undefined : raw;
}

// The PEM often travels in one line with escaped newlines in an environment variable.
export function normalizePem(raw: string): string {
  return raw.replace(/\\n/g, "\n").trim();
}

// null = not configured; the server then answers `store_not_configured`.
export function readAscConfig(env: Env): AscConfig | null {
  const keyId = value(env, "ASC_KEY_ID");
  const issuerId = value(env, "ASC_ISSUER_ID");
  const key = value(env, "ASC_PRIVATE_KEY");
  if (keyId === undefined || issuerId === undefined || key === undefined) return null;
  return {
    keyId,
    issuerId,
    privateKeyPem: normalizePem(key),
    appId: value(env, "ASC_APP_ID") ?? DEFAULT_APP_ID,
    subscriptionGroupId: value(env, "ASC_SUBSCRIPTION_GROUP_ID") ?? DEFAULT_GROUP_ID,
  };
}
