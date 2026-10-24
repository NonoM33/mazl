import { useState } from "react";
import { api } from "../../shared/api/client";
import type { BillingStatus, RedirectResponse } from "../../shared/api/types";
import { describeError } from "../../shared/api/errors";
import { Eyebrow } from "../../shared/ui/eyebrow";
import { plusView } from "./premium-model";

function DoubleSubscription() {
  return (
    <div className="banner banner-warning" role="alert">
      <div className="stack gap-4">
        <p className="title-s">Vous avez deux abonnements mazl+</p>
        <p className="body-s">Résiliez-en un pour ne pas payer deux fois. Abonnement du site : « Gérer ou résilier », ci-dessous. Abonnement App Store : Réglages de l'iPhone › votre nom › Abonnements.</p>
      </div>
    </div>
  );
}

export function PlusStatus({ status }: { readonly status: BillingStatus }) {
  const view = plusView(status);
  const [error, setError] = useState<string | null>(null);
  const openPortal = async () => {
    setError(null);
    try {
      window.location.assign((await api.post<RedirectResponse>("/api/billing/portal")).url);
    } catch (cause) {
      setError(describeError(cause));
    }
  };
  if (view.kind === "none") return status.conflict ? <DoubleSubscription /> : null;
  return (
    <section className="card-surface stack gap-12" style={{ padding: 20 }} aria-label="Votre abonnement">
      <Eyebrow>Votre abonnement</Eyebrow>
      <h2 className="headline-s">mazl+ est actif</h2>
      <p className="body-m">{view.line}</p>
      {view.kind === "apple" && <p className="body-s">Votre abonnement mazl+ est géré par l'App Store. Il se résilie dans les Réglages de l'iPhone › votre nom › Abonnements.</p>}
      {view.kind === "stripe" && <div><button type="button" className="btn btn-outline btn-sm" onClick={() => void openPortal()}>Gérer ou résilier</button></div>}
      {error && <p className="field-error" role="alert">{error}</p>}
      {status.conflict && <DoubleSubscription />}
    </section>
  );
}
