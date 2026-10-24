import { useState } from "react";
import { Check } from "lucide-react";
import { ScreenHeader } from "../../app/shell";
import { api } from "../../shared/api/client";
import { describeError } from "../../shared/api/errors";
import type { BillingCatalog, BillingStatus, OfferId } from "../../shared/api/types";
import { useResource } from "../../shared/hooks/use-resource";
import { Eyebrow } from "../../shared/ui/eyebrow";
import { Skeleton } from "../../shared/ui/empty-state";
import { CheckoutForm } from "./checkout-form";
import { OfferPicker } from "./offer-picker";
import { PlusStatus } from "./plus-status";
import { defaultOffer } from "./premium-model";
import { useCheckoutReturn } from "./use-checkout-return";
import "./premium.css";

const PERKS = [
  "Likes illimités (10 par jour en formule gratuite)",
  "Voir qui vous a aimé",
  "5 Super Likes inclus par jour (1 en formule gratuite)",
  "1 Boost inclus par jour",
  "Revenir en arrière après un « Passer »",
  "Filtres avancés : pratique, communauté…",
] as const;

function Perks() {
  return (
    <section className="stack gap-12" aria-label="Avantages mazl+">
      <Eyebrow>Avantages</Eyebrow>
      <ul className="perks">{PERKS.map((perk) => <li key={perk}><Check size={16} aria-hidden="true" />{perk}</li>)}</ul>
    </section>
  );
}

function Purchase({ catalog, status }: { readonly catalog: BillingCatalog; readonly status: BillingStatus | undefined }) {
  const canSubscribe = status?.can_subscribe ?? true;
  const [chosen, setChosen] = useState<OfferId | null | undefined>(undefined);
  const selected = chosen === undefined ? defaultOffer(catalog, canSubscribe) : chosen;
  return (
    <div className="premium-cols">
      <OfferPicker catalog={catalog} selected={selected} canSubscribe={canSubscribe} onSelect={setChosen} />
      <CheckoutForm catalog={catalog} selected={selected} />
    </div>
  );
}

export function PremiumScreen() {
  const catalog = useResource("billing:catalog", (signal) => api.get<BillingCatalog>("/api/billing/catalog", signal), null);
  const status = useResource("billing:status", (signal) => api.get<BillingStatus>("/api/billing/status", signal), null);
  useCheckoutReturn(status.reload, status.state.data?.plus.active === true);
  const offers = catalog.state.data;

  return (
    <>
      <ScreenHeader eyebrow="mazl+" title="Allez plus loin avec mazl+" />
      <div className="screen-body"><div className="page stack gap-32">
        {status.state.data && <PlusStatus status={status.state.data} />}
        {status.state.status === "error" && !status.state.data && <p className="body-s" role="status">{describeError(status.state.error)}</p>}
        <Perks />
        {catalog.state.status === "loading" && <Skeleton height={240} />}
        {catalog.state.status === "error" && !offers && <p className="field-error" role="alert">{describeError(catalog.state.error)}</p>}
        {offers && !offers.available && <div className="banner" role="status">Le paiement sur le site sera bientôt disponible.</div>}
        {offers?.available && <Purchase catalog={offers} status={status.state.data} />}
      </div></div>
    </>
  );
}
