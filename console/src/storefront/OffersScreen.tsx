import { useEffect, useState, type DragEvent, type ReactElement } from "react";
import { useMe, useSession } from "../app/session";
import { Badge } from "../shared/ui/Badge";
import { Button } from "../shared/ui/Button";
import { ErrorState, SkeletonRows } from "../shared/ui/Feedback";
import { Icon } from "../shared/ui/Icon";
import { PageHeader } from "../shared/ui/PageHeader";
import { useToast } from "../shared/ui/Toast";
import { useAsync } from "../shared/ui/use-async";
import { canWriteStorefront, SUPER_ADMIN_ONLY } from "./access";
import { storefrontApi } from "./api";
import { ApplePriceDialog } from "./ApplePriceDialog";
import { storefrontErrorMessage } from "./errors";
import { HighlightDialog } from "./HighlightDialog";
import { applyOrder, groupProducts, KIND_LABELS, reorder, type OfferGroup } from "./offers-model";
import { applePrice, formatCents, formatMoney } from "./price-change";
import type { ProductDto } from "./types";
import { WebPriceDialog } from "./WebPriceDialog";

type Dialog = { readonly kind: "apple" | "web" | "highlight"; readonly product: ProductDto };

const SHORT: Readonly<Record<string, string>> = { USA: "US", GBR: "GB", ISR: "IL", CAN: "CA" };

function Switch({ checked, label, onChange }: { readonly checked: boolean; readonly label: string; readonly onChange: (value: boolean) => void }): ReactElement {
  return (
    <label className="switch">
      <input type="checkbox" role="switch" checked={checked} aria-label={label} onChange={(event) => onChange(event.target.checked)} />
      <span className="switch-track" aria-hidden="true" />
    </label>
  );
}

interface RowProps {
  readonly product: ProductDto;
  readonly index: number;
  readonly count: number;
  readonly canWrite: boolean;
  readonly dragging: boolean;
  readonly onMove: (index: number) => void;
  readonly onPatch: (patch: { readonly visible?: boolean; readonly featured?: boolean }) => void;
  readonly onDialog: (kind: Dialog["kind"]) => void;
  readonly onDragStart: () => void;
  readonly onDragEnd: () => void;
  readonly onDropHere: () => void;
}

function OfferRow({ product, index, count, canWrite, dragging, onMove, onPatch, onDialog, onDragStart, onDragEnd, onDropHere }: RowProps): ReactElement {
  const france = applePrice(product, "FRA");
  const others = product.applePrices.filter((price) => price.territory !== "FRA");
  const allow = (event: DragEvent): void => event.preventDefault();
  return (
    <tr className={`offer-row${dragging ? " is-dragging" : ""}${product.visible ? "" : " is-hidden"}`} onDragOver={allow} onDrop={onDropHere} data-product={product.productId}>
      <td>
        <span className="order-cell">
          <span className="grip" draggable onDragStart={onDragStart} onDragEnd={onDragEnd} title="Glisser pour changer l'ordre" aria-hidden="true">
            <Icon name="grip" size={16} />
          </span>
          <button type="button" className="icon-btn icon-btn-s" aria-label={`Monter ${product.label}`} disabled={index === 0} onClick={() => onMove(index - 1)}>
            <Icon name="arrow-up" size={15} />
          </button>
          <button type="button" className="icon-btn icon-btn-s" aria-label={`Descendre ${product.label}`} disabled={index === count - 1} onClick={() => onMove(index + 1)}>
            <Icon name="arrow-down" size={15} />
          </button>
          <span className="order-rank" aria-hidden="true">
            {index + 1}
          </span>
        </span>
      </td>
      <td>
        <span className="cell-stack">
          <strong>{product.label}</strong>
          <span className="cell-sub mono">{product.productId.replace(/\./g, ".\u200B")}</span>
        </span>
      </td>
      <td>
        <Switch checked={product.visible} label={`${product.label} : visible dans l'app`} onChange={(visible) => onPatch({ visible })} />
      </td>
      <td>
        <label className="check check-plain">
          <input type="checkbox" checked={product.featured} aria-label={`${product.label} : mise en avant`} onChange={(event) => onPatch({ featured: event.target.checked })} />
        </label>
      </td>
      <td>
        <button type="button" className="link-btn" aria-label={`Accroche de ${product.label}`} onClick={() => onDialog("highlight")}>
          {product.highlight === null ? <span className="muted">Ajouter une accroche</span> : <Badge tone="accent">{product.highlight.fr}</Badge>}
        </button>
      </td>
      <td>
        <span className="price-cell">
          <span className="cell-stack">
            {france !== undefined ? <strong className="price-main">{formatMoney(france.amount, france.currency)}</strong> : <span className="muted">{product.appleError ?? "Prix indisponible"}</span>}
            {others.length > 0 ? <span className="cell-sub">{others.map((price) => `${SHORT[price.territory] ?? price.territory} ${formatMoney(price.amount, price.currency)}`).join(" · ")}</span> : null}
          </span>
          <Button size="s" variant="secondary" disabled={!canWrite} title={canWrite ? undefined : SUPER_ADMIN_ONLY} aria-label={`Changer le prix Apple de ${product.label}`} onClick={() => onDialog("apple")}>
            Changer
          </Button>
        </span>
      </td>
      <td>
        {product.web === null ? (
          <span className="muted">Non vendu sur le web</span>
        ) : (
          <span className="price-cell">
            <strong className="price-main">{formatCents(product.web.amountCents, product.web.currency)}</strong>
            <Button size="s" variant="secondary" disabled={!canWrite} title={canWrite ? undefined : SUPER_ADMIN_ONLY} aria-label={`Changer le prix web de ${product.label}`} onClick={() => onDialog("web")}>
              Changer
            </Button>
          </span>
        )}
      </td>
    </tr>
  );
}

function GroupCard({ group, canWrite, dragId, setDragId, onMove, onPatch, onDialog }: { readonly group: OfferGroup; readonly canWrite: boolean; readonly dragId: string | null; readonly setDragId: (id: string | null) => void; readonly onMove: (group: OfferGroup, productId: string, index: number) => void; readonly onPatch: (product: ProductDto, patch: { readonly visible?: boolean; readonly featured?: boolean }) => void; readonly onDialog: (dialog: Dialog) => void }): ReactElement {
  const kinds = [...new Set(group.products.map((product) => KIND_LABELS[product.kind]))].join(", ");
  return (
    <section className="card offers-card" aria-labelledby={`g-${group.id}`}>
      <div className="card-head">
        <div>
          <h2 id={`g-${group.id}`}>{group.title}</h2>
          <p className="card-lead offers-lead">{kinds}</p>
        </div>
      </div>
      <div className="table-wrap">
        <table className="table offers-table">
          <caption className="sr-only">{group.title}</caption>
          <colgroup>
            <col style={{ width: 148 }} />
            <col />
            <col style={{ width: 70 }} />
            <col style={{ width: 78 }} />
            <col style={{ width: 150 }} />
            <col style={{ width: "27%" }} />
            <col style={{ width: "16%" }} />
          </colgroup>
          <thead>
            <tr>
              <th scope="col">Ordre</th>
              <th scope="col">Offre</th>
              <th scope="col">Visible</th>
              <th scope="col">En avant</th>
              <th scope="col">Accroche</th>
              <th scope="col">Prix Apple</th>
              <th scope="col">Prix web</th>
            </tr>
          </thead>
          <tbody>
            {group.products.map((product, index) => (
              <OfferRow
                key={product.productId}
                product={product}
                index={index}
                count={group.products.length}
                canWrite={canWrite}
                dragging={dragId === product.productId}
                onMove={(target) => onMove(group, product.productId, target)}
                onPatch={(patch) => onPatch(product, patch)}
                onDialog={(kind) => onDialog({ kind, product })}
                onDragStart={() => setDragId(product.productId)}
                onDragEnd={() => setDragId(null)}
                onDropHere={() => {
                  if (dragId !== null) onMove(group, dragId, index);
                  setDragId(null);
                }}
              />
            ))}
          </tbody>
        </table>
      </div>
    </section>
  );
}

export function OffersScreen(): ReactElement {
  const { api } = useSession();
  const me = useMe();
  const toast = useToast();
  const store = storefrontApi(api);
  const canWrite = canWriteStorefront(me);
  const { state, reload } = useAsync(() => store.products(), [api]);
  const [products, setProducts] = useState<readonly ProductDto[]>([]);
  const [dialog, setDialog] = useState<Dialog | null>(null);
  const [dragId, setDragId] = useState<string | null>(null);
  const [announcement, setAnnouncement] = useState("");

  useEffect(() => {
    if (state.status === "ok") setProducts(state.data.products);
  }, [state]);

  const patch = async (product: ProductDto, changes: { readonly visible?: boolean; readonly featured?: boolean }): Promise<void> => {
    const before = products;
    setProducts((current) => current.map((candidate) => (candidate.productId === product.productId ? { ...candidate, ...changes } : candidate)));
    const result = await store.patchProduct(product.productId, changes);
    if (!result.ok) {
      setProducts(before);
      toast.notify(storefrontErrorMessage(result), "error");
      return;
    }
    toast.notify(changes.visible !== undefined ? (changes.visible ? `« ${product.label} » est visible dans l'app.` : `« ${product.label} » est masqué dans l'app.`) : changes.featured === true ? `« ${product.label} » est mis en avant.` : `« ${product.label} » n'est plus mis en avant.`, "success");
  };

  const move = async (group: OfferGroup, productId: string, targetIndex: number): Promise<void> => {
    const patches = reorder(group.products, productId, targetIndex);
    if (patches.length === 0) return;
    const before = products;
    setProducts((current) => applyOrder(current, patches));
    const label = group.products.find((product) => product.productId === productId)?.label ?? "";
    setAnnouncement(`${label} est maintenant en position ${targetIndex + 1} sur ${group.products.length}.`);
    const results = await Promise.all(patches.map((change) => store.patchProduct(change.productId, { sortOrder: change.sortOrder })));
    const failed = results.find((result) => !result.ok);
    if (failed !== undefined && !failed.ok) {
      setProducts(before);
      toast.notify(storefrontErrorMessage(failed), "error");
    }
  };

  const done = (): void => {
    setDialog(null);
    reload();
  };

  return (
    <>
      <PageHeader eyebrow="Vitrine" title="Offres" lead="Ce que l'app propose, dans quel ordre et à quel prix. Le prix affiché sur iPhone vient toujours d'Apple : ici, vous choisissez quoi montrer et vous changez les prix chez Apple et sur le site." />
      <div className="page-body">
        {!canWrite ? (
          <p className="notice notice-info" role="note">
            <Icon name="lock" size={15} /> Vous pouvez régler la visibilité, l'ordre et les accroches. Changer un prix est réservé aux super-administrateurs.
          </p>
        ) : null}
        <div className="sr-only" role="status" aria-live="polite">
          {announcement}
        </div>
        {state.status === "loading" ? <SkeletonRows rows={6} label="Chargement des offres" /> : null}
        {state.status === "error" ? <ErrorState message={state.message} onRetry={reload} /> : null}
        {state.status === "ok"
          ? groupProducts(products).map((group) => (
              <GroupCard key={group.id} group={group} canWrite={canWrite} dragId={dragId} setDragId={setDragId} onMove={(g, id, index) => void move(g, id, index)} onPatch={(product, changes) => void patch(product, changes)} onDialog={setDialog} />
            ))
          : null}
        <p className="page-foot">Les prix viennent d'Apple (France et quatre pays témoins : États-Unis, Royaume-Uni, Israël, Canada) et de Stripe. L'app relit cette vitrine au démarrage et au retour au premier plan, sans mise à jour.</p>
      </div>
      {dialog?.kind === "apple" ? <ApplePriceDialog product={dialog.product} onClose={() => setDialog(null)} onDone={done} /> : null}
      {dialog?.kind === "web" ? <WebPriceDialog product={dialog.product} onClose={() => setDialog(null)} onDone={done} /> : null}
      {dialog?.kind === "highlight" ? <HighlightDialog product={dialog.product} onClose={() => setDialog(null)} onDone={done} /> : null}
    </>
  );
}
