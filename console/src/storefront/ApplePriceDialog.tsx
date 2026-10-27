import { useState, type ReactElement } from "react";
import { useSession } from "../app/session";
import type { ApiResult } from "../shared/api/client";
import { Button } from "../shared/ui/Button";
import { Field } from "../shared/ui/Field";
import { Modal } from "../shared/ui/Modal";
import { Select } from "../shared/ui/Select";
import { useToast } from "../shared/ui/Toast";
import { useAsync } from "../shared/ui/use-async";
import { storefrontApi } from "./api";
import { storefrontErrorMessage } from "./errors";
import { parisToday } from "./paris-time";
import { applePrice, changeLines, explainApplePlan, formatMoney, validateStartDate } from "./price-change";
import type { ApplePricePlanDto, PricePointsDto, ProductDto } from "./types";

const BASE_TERRITORY = "FRA";

export function ChangeTable({ plan }: { readonly plan: ApplePricePlanDto }): ReactElement {
  return (
    <table className="table change-table">
      <caption className="sr-only">Prix actuel et nouveau prix, pays par pays</caption>
      <thead>
        <tr>
          <th scope="col">Pays</th>
          <th scope="col" className="cell-right">
            Avant
          </th>
          <th scope="col" className="cell-right">
            Après
          </th>
        </tr>
      </thead>
      <tbody>
        {changeLines(plan.changes).map((line) => (
          <tr key={line.territory}>
            <td>{line.country}</td>
            <td className="cell-right muted">{line.before}</td>
            <td className="cell-right">
              <strong className={line.direction === "up" ? "price-up" : line.direction === "down" ? "price-down" : undefined}>{line.after}</strong>
              {line.direction !== "same" ? <span className="sr-only">{line.direction === "up" ? " (hausse)" : " (baisse)"}</span> : null}
            </td>
          </tr>
        ))}
      </tbody>
    </table>
  );
}

/** Changer le prix Apple d'un produit : choisir un palier, voir l'effet (dryRun), confirmer. Rien n'est écrit avant « Confirmer ». */
export function ApplePriceDialog({ product, onClose, onDone }: { readonly product: ProductDto; readonly onClose: () => void; readonly onDone: () => void }): ReactElement {
  const { api } = useSession();
  const toast = useToast();
  const store = storefrontApi(api);
  const isSubscription = product.kind === "subscription";
  const { state } = useAsync<PricePointsDto>(() => store.applePricePoints(product.productId, BASE_TERRITORY), [api, product.productId]);
  const [pricePointId, setPricePointId] = useState("");
  const [startDate, setStartDate] = useState(() => parisToday());
  const [preserve, setPreserve] = useState(true);
  const [plan, setPlan] = useState<ApplePricePlanDto | null>(null);
  const [fieldErrors, setFieldErrors] = useState<{ readonly point?: string; readonly date?: string }>({});
  const [failure, setFailure] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);
  const current = applePrice(product, BASE_TERRITORY);

  const call = async (dryRun: boolean): Promise<ApiResult<ApplePricePlanDto>> => store.applePrice(product.productId, { pricePointId, startDate, preserveCurrentPrice: preserve, dryRun });

  const preview = async (): Promise<void> => {
    const errors = { ...(pricePointId === "" ? { point: "Choisissez le nouveau palier de prix." } : {}), ...(validateStartDate(startDate) !== null ? { date: validateStartDate(startDate) ?? "" } : {}) };
    setFieldErrors(errors);
    if (Object.keys(errors).length > 0) return;
    setBusy(true);
    setFailure(null);
    const result = await call(true);
    setBusy(false);
    if (!result.ok) setFailure(storefrontErrorMessage(result));
    else setPlan(result.data);
  };

  const confirm = async (): Promise<void> => {
    setBusy(true);
    setFailure(null);
    const result = await call(false);
    setBusy(false);
    if (!result.ok) {
      setFailure(storefrontErrorMessage(result));
      return;
    }
    toast.notify(`Prix Apple de « ${product.label} » : changement demandé pour le ${result.data.startDate}.`, "success");
    onDone();
  };

  const pointOptions = state.status === "ok" ? state.data.pricePoints.map((point) => ({ value: point.id, label: `${formatMoney(point.customerPrice, point.currency)}${current !== undefined && Number(current.amount) === Number(point.customerPrice) ? " (prix actuel)" : ""}` })) : [];

  return (
    <Modal title={`Prix Apple — ${product.label}`} onClose={onClose} wide>
      {plan === null ? (
        <div className="stack">
          <p className="modal-lead">
            Le prix de base est celui de la France{current !== undefined ? ` (actuellement ${formatMoney(current.amount, current.currency)})` : ""} ; les autres pays suivent la conversion d'Apple. Rien n'est modifié avant la confirmation.
          </p>
          {state.status === "loading" ? <p className="muted">Chargement des paliers d'Apple…</p> : null}
          {state.status === "error" ? (
            <p className="notice notice-error" role="alert">
              {state.message}
            </p>
          ) : null}
          {state.status === "ok" ? <Select label="Nouveau prix (France)" value={pricePointId} options={pointOptions} placeholder="Choisir un palier Apple" onChange={setPricePointId} error={fieldErrors.point} /> : null}
          <Field label="Date d'effet" hint="Au plus tôt aujourd'hui. Apple applique le changement à cette date." error={fieldErrors.date}>
            {({ id, describedBy, invalid }) => <input id={id} type="date" className="input input-narrow-date" value={startDate} min={parisToday()} aria-describedby={describedBy} aria-invalid={invalid || undefined} onChange={(event) => setStartDate(event.target.value)} />}
          </Field>
          {isSubscription ? (
            <label className="check check-accent">
              <input type="checkbox" checked={preserve} onChange={(event) => setPreserve(event.target.checked)} />
              <span>Les abonnés actuels gardent leur prix (recommandé)</span>
            </label>
          ) : null}
          {failure !== null ? (
            <p className="notice notice-error" role="alert">
              {failure}
            </p>
          ) : null}
          <div className="row-actions">
            <Button variant="ghost" onClick={onClose}>
              Annuler
            </Button>
            <Button variant="primary" loading={busy} disabled={state.status !== "ok"} onClick={() => void preview()}>
              Voir l'effet
            </Button>
          </div>
        </div>
      ) : (
        <div className="stack">
          <p className="modal-lead">
            Voici ce qui va changer, pays par pays, pour « {product.label} ». C'est un aperçu : rien n'est encore envoyé à Apple.
          </p>
          <ChangeTable plan={plan} />
          <div className="notice notice-info explain-list">
            {explainApplePlan(plan, isSubscription).map((line) => (
              <p key={line}>{line}</p>
            ))}
          </div>
          {failure !== null ? (
            <p className="notice notice-error" role="alert">
              {failure}
            </p>
          ) : null}
          <div className="row-actions">
            <Button variant="ghost" onClick={() => setPlan(null)}>
              Modifier
            </Button>
            <Button variant="primary" loading={busy} onClick={() => void confirm()}>
              Confirmer le changement de prix
            </Button>
          </div>
        </div>
      )}
    </Modal>
  );
}
