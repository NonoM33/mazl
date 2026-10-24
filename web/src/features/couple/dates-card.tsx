import { useState } from "react";
import { Plus, Trash2 } from "lucide-react";
import { api } from "../../shared/api/client";
import { useResource } from "../../shared/hooks/use-resource";
import { formatDate } from "../../shared/lib/format";
import { AddDialog } from "./add-dialog";
import { CoupleCard } from "./card";
import type { DatesResponse, ImportantDate } from "./couple-api";
import { nextOccurrence, parseDay } from "./couple-format";
import { Loaded } from "./loaded";
import { useAction } from "./use-action";

export function useCoupleDates() {
  return useResource("couple-dates", (signal) => api.get<DatesResponse>("/api/couple/dates", signal), null);
}

function DateRow({ entry, onRemoved }: { readonly entry: ImportantDate; readonly onRemoved: () => Promise<void> }) {
  const { busy, run } = useAction();
  const next = nextOccurrence(entry.date, entry.is_recurring ?? false, new Date());
  return (
    <li className="row">
      <div className="row-main"><span className="row-title">{entry.title}</span><span className="row-sub">{formatDate(next ?? parseDay(entry.date) ?? new Date())}{entry.is_recurring ? " · chaque année" : ""}</span></div>
      <button type="button" className="icon-btn" aria-label={`Supprimer la date « ${entry.title} »`} disabled={busy} onClick={() => void run(() => api.delete(`/api/couple/dates/${entry.id}`), { after: onRemoved, done: "Date supprimée" })}><Trash2 size={18} aria-hidden="true" /></button>
    </li>
  );
}

export function DatesCard() {
  const dates = useCoupleDates();
  const [adding, setAdding] = useState(false);
  return (
    <CoupleCard title="Dates importantes" action={<button type="button" className="btn btn-outline btn-sm" onClick={() => setAdding(true)}><Plus size={16} aria-hidden="true" />Ajouter une date</button>}>
      <Loaded resource={dates}>
        {({ dates: rows }) => rows.length === 0
          ? <p className="empty-note">Aucune date importante. Ajoutez vos anniversaires, fêtes, etc.</p>
          : <ul className="couple-list">{rows.map((entry) => <DateRow key={entry.id} entry={entry} onRemoved={dates.reload} />)}</ul>}
      </Loaded>
      {adding && (
        <AddDialog
          heading="Ajouter une date importante" titleLabel="Titre" dateLabel="Date" submitLabel="Ajouter" onClose={() => setAdding(false)} onDone={dates.reload}
          onSubmit={(values) => api.post("/api/couple/dates", { title: values.title, date: values.date, type: "anniversary" })}
        />
      )}
    </CoupleCard>
  );
}
