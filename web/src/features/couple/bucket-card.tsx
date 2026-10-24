import { useState } from "react";
import { Check, Plus, Trash2 } from "lucide-react";
import { api } from "../../shared/api/client";
import { useResource } from "../../shared/hooks/use-resource";
import { AddDialog } from "./add-dialog";
import { CoupleCard } from "./card";
import type { BucketItem, BucketResponse } from "./couple-api";
import { Loaded } from "./loaded";
import { useAction } from "./use-action";

function ItemRow({ item, onChanged }: { readonly item: BucketItem; readonly onChanged: () => Promise<void> }) {
  const { busy, run } = useAction();
  return (
    <li className="row">
      <div className="row-main">
        <span className="row-title" style={item.is_completed ? { textDecoration: "line-through", color: "var(--muted)" } : undefined}>{item.title}</span>
        {item.description && <span className="row-sub">{item.description}</span>}
      </div>
      {!item.is_completed && <button type="button" className="icon-btn" aria-label={`Valider l'objectif « ${item.title} »`} disabled={busy} onClick={() => void run(() => api.post(`/api/couple/bucket-list/${item.id}/complete`), { after: onChanged, done: "Objectif accompli" })}><Check size={18} aria-hidden="true" /></button>}
      <button type="button" className="icon-btn" aria-label={`Supprimer l'objectif « ${item.title} »`} disabled={busy} onClick={() => void run(() => api.delete(`/api/couple/bucket-list/${item.id}`), { after: onChanged })}><Trash2 size={18} aria-hidden="true" /></button>
    </li>
  );
}

export function BucketCard() {
  const list = useResource("couple-bucket", (signal) => api.get<BucketResponse>("/api/couple/bucket-list", signal), null);
  const [adding, setAdding] = useState(false);
  const done = list.state.data?.items.filter((item) => item.is_completed).length;
  const total = list.state.data?.items.length;
  const heading = total ? `Liste de rêves · ${done}/${total}` : "Liste de rêves";
  return (
    <CoupleCard title={heading} label="Liste de rêves" action={<button type="button" className="btn btn-outline btn-sm" onClick={() => setAdding(true)}><Plus size={16} aria-hidden="true" />Ajouter</button>}>
      <Loaded resource={list}>
        {({ items }) => items.length === 0
          ? <p className="empty-note">Votre liste de rêves est vide. Ajoutez des expériences à vivre ensemble.</p>
          : <ul className="couple-list">{items.map((item) => <ItemRow key={item.id} item={item} onChanged={list.reload} />)}</ul>}
      </Loaded>
      {adding && (
        <AddDialog
          heading="Ajouter un rêve" titleLabel="Ce que vous voulez vivre ensemble" textLabel="Description" submitLabel="Ajouter" onClose={() => setAdding(false)} onDone={list.reload}
          onSubmit={(values) => api.post("/api/couple/bucket-list", { title: values.title, description: values.text === "" ? null : values.text })}
        />
      )}
    </CoupleCard>
  );
}
