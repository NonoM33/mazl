import { useEffect, useState, type ReactElement } from "react";
import { useSession } from "../app/session";
import { groupBy4 } from "../shared/format";
import { Button } from "../shared/ui/Button";
import { Skeleton } from "../shared/ui/Feedback";
import { useToast } from "../shared/ui/Toast";
import type { MfaEnrollmentDto } from "../shared/api/contracts";
import { AuthLayout } from "./AuthLayout";
import { CodeInput } from "./CodeInput";
import { isCompleteCode } from "./validation";

export function MfaEnrollScreen(): ReactElement {
  const session = useSession();
  const toast = useToast();
  const [enrollment, setEnrollment] = useState<MfaEnrollmentDto | null>(null);
  const [loadError, setLoadError] = useState<string | null>(null);
  const [code, setCode] = useState("");
  const [failure, setFailure] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);

  useEffect(() => {
    let cancelled = false;
    void session.api.post<MfaEnrollmentDto>("/mfa/enroll").then((result) => {
      if (cancelled) return;
      if (result.ok) setEnrollment(result.data);
      else setLoadError(result.message);
    });
    return () => {
      cancelled = true;
    };
  }, [session.api]);

  const copy = async (text: string, what: string): Promise<void> => {
    try {
      await navigator.clipboard.writeText(text);
      toast.notify(`${what} copié.`, "success");
    } catch {
      toast.notify("Copie impossible : sélectionnez le texte à la main.", "error");
    }
  };

  const confirm = async (): Promise<void> => {
    if (!isCompleteCode(code) || busy) return;
    setBusy(true);
    setFailure(null);
    const result = await session.confirmEnrollment(code);
    setBusy(false);
    if (!result.ok) {
      setFailure(result.message);
      setCode("");
    }
  };

  return (
    <AuthLayout title="Activez la double authentification" lead="Un second facteur est obligatoire pour accéder à la console. Ajoutez cette clé dans une application d'authentification, puis saisissez le code qu'elle affiche.">
      {loadError !== null ? (
        <p className="notice notice-error" role="alert">
          {loadError}
        </p>
      ) : enrollment === null ? (
        <Skeleton height={72} radius={12} />
      ) : (
        <div className="stack">
          <div className="secret-card">
            <span className="eyebrow">Clé de configuration</span>
            <div className="secret-row">
              <code className="secret" aria-label="Clé secrète, groupée par quatre caractères">
                {groupBy4(enrollment.secret)}
              </code>
              <Button size="s" icon="copy" onClick={() => void copy(enrollment.secret, "Clé")}>
                Copier
              </Button>
            </div>
          </div>
          <details className="uri-details">
            <summary>Utiliser l'adresse otpauth</summary>
            <div className="uri-row">
              <input className="input mono" readOnly value={enrollment.otpauthUri} aria-label="Adresse otpauth" onFocus={(event) => event.target.select()} />
              <Button size="s" icon="copy" onClick={() => void copy(enrollment.otpauthUri, "Adresse")}>
                Copier
              </Button>
            </div>
          </details>
          <form
            className="stack"
            onSubmit={(event) => {
              event.preventDefault();
              void confirm();
            }}
          >
            <p className="field-label-inline">Code de confirmation</p>
            <CodeInput legend="Code de confirmation à 6 chiffres" value={code} onChange={setCode} disabled={busy} invalid={failure !== null} />
            {failure !== null ? (
              <p className="notice notice-error" role="alert">
                {failure}
              </p>
            ) : null}
            <Button type="submit" variant="primary" loading={busy} disabled={!isCompleteCode(code)}>
              Activer et continuer
            </Button>
          </form>
        </div>
      )}
      <Button variant="ghost" onClick={session.logout}>
        Se déconnecter
      </Button>
    </AuthLayout>
  );
}
