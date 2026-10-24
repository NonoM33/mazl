// STAFF_MFA_REQUIRED ("true" / "false"); by default required in production only.
export function isMfaRequired(env: Readonly<Record<string, string | undefined>>): boolean {
  const configured = env.STAFF_MFA_REQUIRED?.trim().toLowerCase();
  if (configured === "true") return true;
  if (configured === "false") return false;
  return env.NODE_ENV === "production";
}
