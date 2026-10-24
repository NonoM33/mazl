import { useState } from "react";
import { Lock } from "lucide-react";
import { api } from "../../shared/api/client";
import type { BillingCatalog, OfferId, RedirectResponse } from "../../shared/api/types";
import { canPay, checkoutErrorMessage } from "./premium-model";

// The withdrawal waiver (CGV 6.2) is a mandatory, unticked box: without it the
// pay button stays closed and the server refuses the checkout anyway.

export function CheckoutForm({ catalog, selected }: { readonly catalog: BillingCatalog; readonly selected: OfferId | null }) {
  const [waiver, setWaiver] = useState(false);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const pay = async () => {
    if (selected === null) return;
    setBusy(true);
    setError(null);
    try {
      const { url } = await api.post<RedirectResponse>("/api/billing/checkout", { offer: selected, withdrawal_waiver: true, waiver_version: catalog.withdrawal.version });
      window.location.assign(url);
    } catch (cause) {
      setError(checkoutErrorMessage(cause));
      setBusy(false);
    }
  };

  return (
    <div className="stack gap-16">
      <label className="checkbox inline gap-12" style={{ alignItems: "flex-start" }}>
        <input type="checkbox" checked={waiver} onChange={(event) => setWaiver(event.target.checked)} />
        <span className="body-s" style={{ color: "var(--text)" }}>{catalog.withdrawal.text}</span>
      </label>
      <button type="button" className="btn btn-accent btn-block" disabled={!canPay({ selected, waiver, busy })} onClick={() => void pay()}>Payer avec Stripe</button>
      {error && <p className="field-error" role="alert">{error}</p>}
      <div className="stack gap-4">
        <p className="label-m">Renouvellement automatique pour les abonnements. Résiliation possible à tout moment depuis cette page.</p>
        <p className="label-m"><a href="/cgv" target="_blank" rel="noreferrer">Conditions générales de vente</a></p>
        <p className="label-m inline gap-4"><Lock size={12} aria-hidden="true" /> Paiement sécurisé par Stripe : MAZL ne voit pas votre carte.</p>
      </div>
    </div>
  );
}
