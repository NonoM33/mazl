import { useState, type ReactElement } from "react";
import { useSession } from "../app/session";
import { Button } from "../shared/ui/Button";
import { AuthLayout } from "./AuthLayout";
import { CodeInput } from "./CodeInput";
import { isCompleteCode } from "./validation";

export function MfaCodeStep({ challenge }: { readonly challenge: string }): ReactElement {
  const session = useSession();
  const [code, setCode] = useState("");
  const [failure, setFailure] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);

  const submit = async (value: string): Promise<void> => {
    if (!isCompleteCode(value) || busy) return;
    setBusy(true);
    setFailure(null);
    const result = await session.submitCode(challenge, value);
    setBusy(false);
    if (!result.ok) {
      setFailure(result.message);
      setCode("");
    }
  };

  // La validation part dès que le sixième chiffre est saisi ou collé.
  const change = (value: string): void => {
    setCode(value);
    if (isCompleteCode(value)) void submit(value);
  };

  return (
    <AuthLayout title="Code de vérification" lead="Saisissez le code à 6 chiffres affiché par votre application d'authentification.">
      <form
        className="stack"
        onSubmit={(event) => {
          event.preventDefault();
          void submit(code);
        }}
      >
        <CodeInput legend="Code de vérification à 6 chiffres" value={code} onChange={change} disabled={busy} invalid={failure !== null} />
        {failure !== null ? (
          <p className="notice notice-error" role="alert">
            {failure}
          </p>
        ) : null}
        <Button type="submit" variant="primary" loading={busy} disabled={!isCompleteCode(code)}>
          Vérifier
        </Button>
        <Button variant="ghost" onClick={session.logout}>
          Revenir à la connexion
        </Button>
      </form>
    </AuthLayout>
  );
}
