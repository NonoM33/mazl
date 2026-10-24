import { useEffect, useEffectEvent, useRef, useState } from "react";
import { Apple, Check, RefreshCw, ShieldCheck, Smartphone } from "lucide-react";
import { api } from "../../shared/api/client";
import { ApiError } from "../../shared/api/errors";
import type { WebAuthConfig } from "../../shared/api/types";
import { useResource } from "../../shared/hooks/use-resource";
import { useSession } from "../../shared/session";
import { Dialog } from "../../shared/ui/dialog";
import { APP_LINK } from "../../shared/ui/mobile-only";
import { QrCode } from "../../shared/ui/qr-code";
import { Wordmark } from "../../shared/ui/wordmark";
import { renderGoogleButton, signInWithApple } from "./identity-providers";
import { proofOfWork, useQrPairing, type QrState } from "./use-qr-pairing";
import "./login.css";

const PROVIDER_ERRORS: Readonly<Record<string, string>> = {
  account_not_found: "Aucun compte MAZL n'est lié à cet identifiant. Créez votre compte dans l'app, puis revenez.",
  account_disabled: "Ce compte est désactivé.",
  invalid_token: "La connexion n'a pas été confirmée. Réessayez.",
  rate_limited: "Trop de tentatives. Patientez quelques minutes.",
};

function QrPanel({ state, onRestart }: { readonly state: QrState; readonly onRestart: () => void }) {
  if (state.phase === "showing") {
    return (
      <div className="qr-frame" data-status={state.status}>
        <QrCode value={state.qr} size={248} label="QR code de connexion à scanner avec l'app MAZL" />
        {state.status === "scanned" && (
          <div className="qr-veil" role="status"><Smartphone size={28} aria-hidden="true" /><p className="title-m">Confirmez sur votre téléphone</p></div>
        )}
      </div>
    );
  }
  if (state.phase === "approved") {
    return <div className="qr-frame qr-placeholder" role="status"><Check size={32} aria-hidden="true" /><p className="title-m">Connexion…</p></div>;
  }
  if (state.phase === "stalled") {
    const text = state.reason === "denied" ? "La connexion a été refusée sur le téléphone." : state.reason === "expired" ? "Le code a expiré." : "Le code n'a pas pu être préparé.";
    return (
      <div className="qr-frame qr-placeholder">
        <p className="body-m">{text}</p>
        <button type="button" className="btn btn-primary btn-sm" onClick={onRestart}><RefreshCw size={18} aria-hidden="true" />Nouveau code</button>
      </div>
    );
  }
  return <div className="qr-frame qr-placeholder" role="status" aria-label="Préparation du code"><div className="skeleton" style={{ width: 248, height: 248, borderRadius: 16 }} /></div>;
}

function useProviderSignIn() {
  const { refresh } = useSession();
  const [error, setError] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);
  const signIn = async (path: "/api/web/auth/google" | "/api/web/auth/apple", body: Record<string, string>) => {
    setBusy(true);
    setError(null);
    try {
      const pow = await proofOfWork();
      await api.post(path, { ...body, pow });
      await refresh();
    } catch (cause) {
      setError(cause instanceof ApiError ? (PROVIDER_ERRORS[cause.code] ?? "La connexion a échoué. Réessayez.") : "La connexion a échoué. Réessayez.");
    } finally {
      setBusy(false);
    }
  };
  return { error, busy, signIn };
}

function ProviderButtons({ config }: { readonly config: WebAuthConfig }) {
  const google = useRef<HTMLDivElement>(null);
  const { error, busy, signIn } = useProviderSignIn();
  const onGoogleToken = useEffectEvent((idToken: string) => { void signIn("/api/web/auth/google", { idToken }); });

  useEffect(() => {
    const parent = google.current;
    if (!config.google_client_id || !parent) return;
    renderGoogleButton(parent, config.google_client_id, (idToken) => { onGoogleToken(idToken); }).catch(() => undefined);
  }, [config.google_client_id]);

  const apple = async () => {
    if (!config.apple_services_id) return;
    try {
      const identityToken = await signInWithApple(config.apple_services_id);
      await signIn("/api/web/auth/apple", { identityToken });
    } catch {
      // Popup closed by the member: nothing to say.
    }
  };

  if (!config.google_client_id && !config.apple_services_id) return null;
  return (
    <div className="stack gap-12" aria-busy={busy}>
      <div className="divider-label"><span>ou</span></div>
      {config.google_client_id && <div ref={google} className="provider-slot" />}
      {config.apple_services_id && (
        <button type="button" className="btn btn-outline btn-block" onClick={() => void apple()} disabled={busy}>
          <Apple size={20} aria-hidden="true" />Continuer avec Apple
        </button>
      )}
      {error && <p className="field-error" role="alert">{error}</p>}
    </div>
  );
}

export function LoginScreen() {
  const { refresh } = useSession();
  const { state, restart } = useQrPairing(() => void refresh());
  const config = useResource("auth-config", (signal) => api.get<WebAuthConfig>("/api/web/auth/config", signal), null);
  const [noAccount, setNoAccount] = useState(false);

  return (
    <div className="login">
      <header className="login-top"><Wordmark size={30} /></header>
      <main className="login-main">
        <section className="login-copy">
          <p className="eyebrow">MAZL sur ordinateur</p>
          <h1 className="display-s">Retrouvez vos conversations sur grand écran.</h1>
          <ol className="login-steps">
            <li><span>1</span>Ouvrez MAZL sur votre téléphone.</li>
            <li><span>2</span>Allez dans Réglages › Ordinateurs connectés › Connecter un ordinateur.</li>
            <li><span>3</span>Scannez ce code, puis confirmez.</li>
          </ol>
          <p className="body-s login-note"><ShieldCheck size={16} aria-hidden="true" />Session limitée à cet ordinateur : 4 h d'inactivité, 7 jours au plus, révocable depuis l'app.</p>
        </section>
        <section className="login-card card" aria-label="Connexion">
          <QrPanel state={state} onRestart={restart} />
          {config.state.status === "ready" && <ProviderButtons config={config.state.data} />}
          <button type="button" className="btn btn-ghost" onClick={() => setNoAccount(true)}>Pas encore de compte ?</button>
        </section>
      </main>
      {noAccount && (
        <Dialog title="Créez votre compte dans l'app" onClose={() => setNoAccount(false)}>
          <div className="inline gap-24">
            <QrCode value={APP_LINK} size={140} label="QR code vers MAZL sur l'App Store" />
            <p className="body-m">L'inscription se fait sur téléphone : profil, consentements et vérification par selfie. Scannez ce code pour télécharger MAZL, puis revenez vous connecter ici.</p>
          </div>
        </Dialog>
      )}
    </div>
  );
}
