import { useState, type ReactNode } from "react";
import { ShieldCheck } from "lucide-react";
import { api } from "../../shared/api/client";
import { describeError } from "../../shared/api/errors";
import type { ConsentsResponse } from "../../shared/api/types";
import { useResource } from "../../shared/hooks/use-resource";
import { Wordmark } from "../../shared/ui/wordmark";

// GDPR art. 9 (docs/web/adr/W06-rgpd-article9.md): before the first use of
// the web, the member decides, separately from the terms of use, whether MAZL
// may process their religious practice. Refusing is a real option: the site
// works, those fields stay empty.

export function ConsentGate({ children }: { readonly children: ReactNode }) {
  const consents = useResource("consents", (signal) => api.get<ConsentsResponse>("/api/privacy/consents", signal), null);
  if (consents.state.status === "loading") return <div className="splash"><Wordmark size={40} /></div>;
  // Without the privacy routes (older server), do not block the member.
  if (consents.state.status === "error" && consents.state.data === undefined) return <>{children}</>;
  const state = consents.state.data?.consents.religious_data;
  if (!state || (state.granted !== null && state.version === state.current_version)) return <>{children}</>;
  return <ConsentScreen text={state.text} version={state.current_version} onDecided={() => void consents.reload()} />;
}

function ConsentScreen({ text, version, onDecided }: { readonly text: string; readonly version: string; readonly onDecided: () => void }) {
  const [checked, setChecked] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);
  const decide = async (granted: boolean) => {
    setBusy(true);
    setError(null);
    try {
      await api.put("/api/privacy/consents/religious_data", { granted, version, source: "web" });
      onDecided();
    } catch (cause) {
      setError(describeError(cause));
    } finally {
      setBusy(false);
    }
  };
  return (
    <div className="fullpage">
      <div className="card stack gap-24" style={{ maxWidth: 620, padding: 40, boxShadow: "inset 0 0 0 1px var(--hairline)" }}>
        <ShieldCheck size={28} aria-hidden="true" color="var(--accent)" />
        <div className="stack gap-8">
          <p className="eyebrow">Données sensibles · RGPD article 9</p>
          <h1 className="headline-m">Votre pratique religieuse, avec votre accord</h1>
        </div>
        <p className="body-m muted">
          Courant, cacherout, Shabbat et intention aident à vous proposer des profils compatibles. Ce sont des données sensibles :
          MAZL ne les traite qu'avec votre accord explicite, distinct des conditions d'utilisation. Vous pouvez refuser et utiliser MAZL quand même.
        </p>
        <label className="checkbox">
          <input type="checkbox" checked={checked} onChange={(event) => setChecked(event.target.checked)} />
          <span className="body-m">{text}</span>
        </label>
        {error && <p className="field-error" role="alert">{error}</p>}
        <div className="inline gap-12">
          <button type="button" className="btn btn-primary" disabled={!checked || busy} onClick={() => void decide(true)}>J'accepte</button>
          <button type="button" className="btn btn-outline" disabled={busy} onClick={() => void decide(false)}>Continuer sans</button>
        </div>
        <p className="label-m">Version {version}. Retrait à tout moment dans Réglages › Confidentialité. <a href="/confidentialite">Politique de confidentialité</a></p>
      </div>
    </div>
  );
}
