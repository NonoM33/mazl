import { useState, type ReactElement } from "react";
import { useSession } from "../app/session";
import { Button } from "../shared/ui/Button";
import { Field } from "../shared/ui/Field";
import { Modal } from "../shared/ui/Modal";
import { Select } from "../shared/ui/Select";
import { useToast } from "../shared/ui/Toast";
import { storefrontApi } from "./api";
import { storefrontErrorMessage } from "./errors";
import { productLabel, webPrice } from "./product-view";
import { formatCents, validateWebPrice, WEB_CURRENCIES } from "./price-change";
import type { ProductDto } from "./types";
import { webPriceRequest } from "./request-bodies";

/** Changer le prix web (Stripe) : un prix Stripe est immuable, un nouveau est créé. Confirmation avant tout envoi. */
export function WebPriceDialog({ product, onClose, onDone }: { readonly product: ProductDto; readonly onClose: () => void; readonly onDone: () => void }): ReactElement {
  const { api } = useSession();
  const toast = useToast();
  const web = webPrice(product);
  const [amountText, setAmountText] = useState(web === null ? "" : (web.amountCents / 100).toFixed(2).replace(".", ","));
  const [currency, setCurrency] = useState<string>(web?.currency ?? "EUR");
  const [error, setError] = useState<string | undefined>(undefined);
  const [pending, setPending] = useState<number | null>(null);
  const [failure, setFailure] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);

  const review = (): void => {
    const checked = validateWebPrice(amountText, currency);
    if (!checked.ok) {
      setError(checked.error);
      return;
    }
    setError(undefined);
    setPending(checked.amountCents);
  };

  const confirm = async (): Promise<void> => {
    if (pending === null) return;
    setBusy(true);
    setFailure(null);
    const result = await storefrontApi(api).webPrice(product.productId, webPriceRequest(pending, currency));
    setBusy(false);
    if (!result.ok) {
      setFailure(storefrontErrorMessage(result));
      return;
    }
    toast.notify(`Prix web de « ${productLabel(product)} » : ${formatCents(result.data.price.amountCents, result.data.price.currency)}.`, "success");
    onDone();
  };

  return (
    <Modal title={`Prix web — ${productLabel(product)}`} onClose={onClose}>
      {pending === null ? (
        <div className="stack">
          <p className="modal-lead">Prix payé sur le site (Stripe){web !== null ? `, actuellement ${formatCents(web.amountCents, web.currency)}` : ""}. Rien n'est modifié avant la confirmation.</p>
          <Field label="Nouveau montant" hint="Deux décimales au plus, par exemple 44,99." error={error}>
            {({ id, describedBy, invalid }) => <input id={id} className="input" inputMode="decimal" value={amountText} aria-describedby={describedBy} aria-invalid={invalid || undefined} onChange={(event) => setAmountText(event.target.value)} />}
          </Field>
          <Select label="Devise" value={currency as (typeof WEB_CURRENCIES)[number]} options={WEB_CURRENCIES.map((code) => ({ value: code, label: code }))} onChange={(value) => value !== "" && setCurrency(value)} />
          <div className="row-actions">
            <Button variant="ghost" onClick={onClose}>
              Annuler
            </Button>
            <Button variant="primary" onClick={review}>
              Continuer
            </Button>
          </div>
        </div>
      ) : (
        <div className="stack">
          <p className="modal-lead">Vérifiez avant d'envoyer à Stripe.</p>
          <p className="price-compare">
            <span className="muted">{web === null ? "—" : formatCents(web.amountCents, web.currency)}</span>
            <span aria-hidden="true">→</span>
            <span className="sr-only">devient</span>
            <strong>{formatCents(pending, currency)}</strong>
          </p>
          <div className="notice notice-info explain-list">
            <p>Un prix Stripe ne se modifie pas : un nouveau prix est créé et remplace l'ancien dans le catalogue du site.</p>
            <p>Les achats faits sur le site à partir de maintenant paient le nouveau prix. Les abonnements web déjà en cours restent rattachés à l'ancien prix Stripe.</p>
          </div>
          {failure !== null ? (
            <p className="notice notice-error" role="alert">
              {failure}
            </p>
          ) : null}
          <div className="row-actions">
            <Button variant="ghost" onClick={() => setPending(null)}>
              Modifier
            </Button>
            <Button variant="primary" loading={busy} onClick={() => void confirm()}>
              Confirmer le nouveau prix web
            </Button>
          </div>
        </div>
      )}
    </Modal>
  );
}
