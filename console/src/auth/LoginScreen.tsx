import { useState, type FormEvent, type ReactElement } from "react";
import { useSession } from "../app/session";
import { Button } from "../shared/ui/Button";
import { TextInput, Field } from "../shared/ui/Field";
import { AuthLayout } from "./AuthLayout";
import { validateCredentials } from "./validation";

/**
 * Connexion. Google Identity Services n'est PAS chargé dans ce lot : le bouton « Continuer avec Google »
 * ouvre le champ de jeton de développement (identifiant Google collé à la main → POST /auth/google).
 * L'emplacement du futur bouton officiel est `#google-signin-slot` (voir console/README.md).
 */
export function LoginScreen({ notice }: { readonly notice: string | null }): ReactElement {
  const session = useSession();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [errors, setErrors] = useState<{ email?: string; password?: string }>({});
  const [failure, setFailure] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);
  const [devOpen, setDevOpen] = useState(false);
  const [credential, setCredential] = useState("");

  const submit = async (event: FormEvent): Promise<void> => {
    event.preventDefault();
    const found = validateCredentials(email, password);
    setErrors(found);
    if (Object.keys(found).length > 0) return;
    setBusy(true);
    setFailure(null);
    const result = await session.loginPassword(email, password);
    setBusy(false);
    if (!result.ok) setFailure(result.message);
  };

  const submitCredential = async (event: FormEvent): Promise<void> => {
    event.preventDefault();
    if (credential.trim() === "") return;
    setBusy(true);
    setFailure(null);
    const result = await session.loginGoogle(credential);
    setBusy(false);
    if (!result.ok) setFailure(result.message);
  };

  return (
    <AuthLayout title="Connexion à la console" lead="Connectez-vous avec votre compte professionnel.">
      {notice !== null ? (
        <p className="notice notice-warning" role="status">
          {notice}
        </p>
      ) : null}
      <div id="google-signin-slot">
        <Button variant="secondary" onClick={() => setDevOpen(true)}>
          <GoogleMark />
          Continuer avec Google
        </Button>
      </div>
      {devOpen ? (
        <form className="dev-credential" onSubmit={(event) => void submitCredential(event)}>
          <Field label="Jeton Google (développement)" hint="Collez l'identifiant (ID token) délivré par Google. Le bouton officiel arrivera avec Google Identity Services.">
            {({ id, describedBy }) => <textarea id={id} className="input textarea" rows={3} value={credential} aria-describedby={describedBy} onChange={(event) => setCredential(event.target.value)} />}
          </Field>
          <Button type="submit" variant="primary" loading={busy} disabled={credential.trim() === ""}>
            Valider le jeton
          </Button>
        </form>
      ) : null}
      <div className="auth-sep" role="separator">
        <span>ou</span>
      </div>
      <form className="stack" onSubmit={(event) => void submit(event)} noValidate>
        <TextInput label="Adresse e-mail" type="email" autoComplete="username" value={email} onChange={setEmail} error={errors.email} autoFocus />
        <TextInput label="Mot de passe" type="password" autoComplete="current-password" value={password} onChange={setPassword} error={errors.password} hint="Réservé au compte d'amorçage de l'administrateur." />
        {failure !== null ? (
          <p className="notice notice-error" role="alert">
            {failure}
          </p>
        ) : null}
        <Button type="submit" variant="primary" loading={busy}>
          Se connecter
        </Button>
      </form>
    </AuthLayout>
  );
}

function GoogleMark(): ReactElement {
  return (
    <svg width="16" height="16" viewBox="0 0 24 24" aria-hidden="true" focusable="false">
      <path fill="currentColor" d="M21.6 12.2c0-.7-.1-1.4-.2-2H12v3.8h5.4a4.6 4.6 0 0 1-2 3v2.5h3.3c1.9-1.8 2.9-4.4 2.9-7.3zM12 22c2.7 0 5-.9 6.6-2.4l-3.3-2.5c-.9.6-2 1-3.3 1-2.5 0-4.7-1.7-5.5-4H3.1v2.6A10 10 0 0 0 12 22zM6.5 14.1a6 6 0 0 1 0-3.8V7.7H3.1a10 10 0 0 0 0 8.9zM12 6c1.5 0 2.8.5 3.8 1.5l2.9-2.9A10 10 0 0 0 3.1 7.7l3.4 2.6C7.3 7.7 9.5 6 12 6z" />
    </svg>
  );
}
