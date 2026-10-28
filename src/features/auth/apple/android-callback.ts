// Sign in with Apple on Android goes through Apple's web page: Apple posts its
// answer (form_post) to POST /api/auth/apple/android-callback, and the server
// hands it to the app through the intent link the sign_in_with_apple plugin
// listens to. The app then signs in with POST /api/auth/apple as on iOS.

const ANDROID_APP_ID = "com.mazl.app";
const FIELDS = ["code", "id_token", "state", "user", "error"] as const;
// An identity token is about a kilobyte; the first-sign-in name is short.
const FIELD_MAX_LENGTH = 4096;

export function androidCallbackRedirect(form: Readonly<Record<string, unknown>>): string | null {
  const query = new URLSearchParams();
  for (const field of FIELDS) {
    const value = form[field];
    if (value === undefined) continue;
    if (typeof value !== "string" || value.length > FIELD_MAX_LENGTH) return null;
    query.set(field, value);
  }
  if (!query.has("code") && !query.has("error")) return null;
  return `intent://callback?${query.toString()}#Intent;package=${ANDROID_APP_ID};scheme=signinwithapple;end`;
}
