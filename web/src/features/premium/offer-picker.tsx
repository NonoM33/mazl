import type { BillingCatalog, Offer, OfferId } from "../../shared/api/types";
import { Eyebrow } from "../../shared/ui/eyebrow";
import { durationLabel, packLabel, packOffers, perMonthLabel, priceLabel, subscriptionOffers } from "./premium-model";

interface PickerProps {
  readonly catalog: BillingCatalog;
  readonly selected: OfferId | null;
  readonly canSubscribe: boolean;
  readonly onSelect: (id: OfferId) => void;
}

function OfferCard({ offer, title, selected, disabled, onSelect }: { readonly offer: Offer; readonly title: string; readonly selected: boolean; readonly disabled: boolean; readonly onSelect: (id: OfferId) => void }) {
  const perMonth = perMonthLabel(offer);
  return (
    <button type="button" role="radio" aria-checked={selected} disabled={disabled} className="offer" onClick={() => onSelect(offer.id)}>
      {offer.featured && <span className="tag tag-accent">Le plus choisi</span>}
      <span className="title-m">{title}</span>
      <span className="offer-price">{priceLabel(offer.amount_ttc_cents)}</span>
      {perMonth && <span className="body-s">{perMonth}</span>}
    </button>
  );
}

function Group({ label, children, columns }: { readonly label: string; readonly children: React.ReactNode; readonly columns?: "packs" }) {
  return (
    <section className="stack gap-12" aria-label={label}>
      <Eyebrow>{label}</Eyebrow>
      <div className={columns ? `offer-grid ${columns}` : "offer-grid"} role="radiogroup" aria-label={label}>{children}</div>
    </section>
  );
}

export function OfferPicker({ catalog, selected, canSubscribe, onSelect }: PickerProps) {
  const card = (offer: Offer, title: string, disabled = false) => <OfferCard key={offer.id} offer={offer} title={title} selected={selected === offer.id} disabled={disabled} onSelect={onSelect} />;
  return (
    <div className="stack gap-24">
      <Group label="Abonnement mazl+">{subscriptionOffers(catalog).map((offer) => card(offer, durationLabel(offer.months ?? 1), !canSubscribe))}</Group>
      <Group label="Boosts" columns="packs">{packOffers(catalog, "boost").map((offer) => card(offer, packLabel(offer)))}</Group>
      <Group label="Super Likes" columns="packs">{packOffers(catalog, "super_like").map((offer) => card(offer, packLabel(offer)))}</Group>
    </div>
  );
}
