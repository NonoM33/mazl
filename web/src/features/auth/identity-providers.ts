// Google Identity Services and Sign in with Apple JS, loaded only on the
// sign-in page and only when configured (docs/web/adr/W06-rgpd-article9.md:
// no third-party script anywhere else).

interface GoogleCredential { readonly credential: string }
interface GoogleId {
  initialize(options: { client_id: string; callback: (response: GoogleCredential) => void; ux_mode: "popup"; use_fedcm_for_prompt?: boolean }): void;
  renderButton(parent: HTMLElement, options: Record<string, string | number>): void;
}
interface AppleAuth {
  init(options: { clientId: string; scope: string; redirectURI: string; usePopup: boolean }): void;
  signIn(): Promise<{ authorization: { id_token: string } }>;
}
declare global {
  interface Window {
    google?: { accounts: { id: GoogleId } };
    AppleID?: { auth: AppleAuth };
  }
}

const loaded = new Map<string, Promise<void>>();

function loadScript(src: string): Promise<void> {
  const existing = loaded.get(src);
  if (existing) return existing;
  const promise = new Promise<void>((resolve, reject) => {
    const script = document.createElement("script");
    script.src = src;
    script.async = true;
    script.onload = () => resolve();
    script.onerror = () => reject(new Error(`script ${src}`));
    document.head.append(script);
  });
  loaded.set(src, promise);
  return promise;
}

export async function renderGoogleButton(parent: HTMLElement, clientId: string, onToken: (idToken: string) => void): Promise<void> {
  await loadScript("https://accounts.google.com/gsi/client");
  const id = window.google?.accounts.id;
  if (!id) throw new Error("google identity unavailable");
  id.initialize({ client_id: clientId, callback: (response) => onToken(response.credential), ux_mode: "popup" });
  id.renderButton(parent, { theme: "outline", size: "large", shape: "pill", text: "continue_with", width: 320, locale: "fr" });
}

export async function signInWithApple(servicesId: string): Promise<string> {
  await loadScript("https://appleid.cdn-apple.com/appleauth/static/jsapi/appleid/1/fr_FR/appleid.auth.js");
  const auth = window.AppleID?.auth;
  if (!auth) throw new Error("apple sign-in unavailable");
  auth.init({ clientId: servicesId, scope: "name email", redirectURI: `${window.location.origin}/app/connexion`, usePopup: true });
  const response = await auth.signIn();
  return response.authorization.id_token;
}
