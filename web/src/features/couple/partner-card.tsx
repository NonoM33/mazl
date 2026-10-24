import { api } from "../../shared/api/client";
import type { CoupleView, RelationshipStatus } from "../../shared/api/types";
import { displayName } from "../../shared/lib/format";
import { useCouple } from "../../shared/couple-context";
import { Photo } from "../../shared/ui/photo";
import { CoupleCard } from "./card";
import { STATUS_OPTIONS, daysTogether, statusLabel, togetherSince } from "./couple-format";
import { useAction } from "./use-action";

function StatusPicker({ couple }: { readonly couple: CoupleView }) {
  const { reload } = useCouple();
  const { busy, run } = useAction();
  const choose = (status: RelationshipStatus) => {
    if (status === couple.status) return;
    void run(() => api.patch(`/api/couple/${couple.id}/status`, { relationshipStatus: status }), { after: reload, done: "Statut mis à jour" });
  };
  return (
    <div className="chips" role="group" aria-label="Statut de la relation">
      {STATUS_OPTIONS.map((option) => (
        <button key={option.key} type="button" className="chip" aria-pressed={couple.status === option.key} disabled={busy} onClick={() => choose(option.key)}>{option.label}</button>
      ))}
    </div>
  );
}

export function PartnerCard({ couple }: { readonly couple: CoupleView }) {
  const { reload } = useCouple();
  const name = displayName(couple.partner_name);
  const days = daysTogether(couple.started_at);
  return (
    <CoupleCard title="Votre moitié" label="Votre partenaire">
      <div className="partner">
        <Photo src={couple.partner_picture} alt={`Photo de ${name}`} seed={couple.partner_id} radius={48} className="partner-photo" initial={name.charAt(0).toUpperCase()} onExpired={() => void reload()} />
        <div className="stack gap-4">
          <h2 className="headline-s">{name}</h2>
          <p className="body-m muted">{statusLabel(couple.status)}</p>
          {togetherSince(couple.started_at) && <p className="body-m">{togetherSince(couple.started_at)}</p>}
          {days !== null && <p className="body-s tabular">{days === 1 ? "1 jour" : `${days} jours`} ensemble</p>}
        </div>
      </div>
      <StatusPicker couple={couple} />
    </CoupleCard>
  );
}
