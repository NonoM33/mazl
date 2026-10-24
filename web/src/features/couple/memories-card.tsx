import { useState } from "react";
import { Plus, Trash2 } from "lucide-react";
import { api } from "../../shared/api/client";
import { useResource } from "../../shared/hooks/use-resource";
import { formatDate } from "../../shared/lib/format";
import { AddDialog } from "./add-dialog";
import { CoupleCard } from "./card";
import type { MemoriesResponse, Memory } from "./couple-api";
import { Loaded } from "./loaded";
import { useAction } from "./use-action";

function MemoryRow({ memory, onRemoved }: { readonly memory: Memory; readonly onRemoved: () => Promise<void> }) {
  const { busy, run } = useAction();
  const title = memory.title ?? "Souvenir";
  return (
    <li className="row">
      <div className="row-main">
        <span className="row-title">{title}</span>
        {memory.content && <span className="row-sub">{memory.content}</span>}
        <span className="row-sub">{formatDate(memory.created_at)}</span>
      </div>
      <button type="button" className="icon-btn" aria-label={`Supprimer le souvenir « ${title} »`} disabled={busy} onClick={() => void run(() => api.delete(`/api/couple/memories/${memory.id}`), { after: onRemoved, done: "Souvenir supprimé" })}><Trash2 size={18} aria-hidden="true" /></button>
    </li>
  );
}

// Text only on the web: no picture upload here.
export function MemoriesCard() {
  const memories = useResource("couple-memories", (signal) => api.get<MemoriesResponse>("/api/couple/memories", signal), null);
  const [adding, setAdding] = useState(false);
  return (
    <CoupleCard title="Nos souvenirs" action={<button type="button" className="btn btn-outline btn-sm" onClick={() => setAdding(true)}><Plus size={16} aria-hidden="true" />Ajouter un souvenir</button>}>
      <Loaded resource={memories}>
        {({ memories: rows }) => rows.length === 0
          ? <p className="empty-note">Aucun souvenir pour l'instant. Ajoutez vos premiers souvenirs ensemble.</p>
          : <ul className="couple-list">{rows.map((memory) => <MemoryRow key={memory.id} memory={memory} onRemoved={memories.reload} />)}</ul>}
      </Loaded>
      {adding && (
        <AddDialog
          heading="Ajouter un souvenir" titleLabel="Titre" textLabel="Description" submitLabel="Ajouter" onClose={() => setAdding(false)} onDone={memories.reload}
          onSubmit={(values) => api.post("/api/couple/memories", { type: "note", title: values.title, content: values.text === "" ? null : values.text })}
        />
      )}
    </CoupleCard>
  );
}
