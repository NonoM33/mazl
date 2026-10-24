import { useState } from "react";
import { api } from "../../shared/api/client";
import type { CoupleView } from "../../shared/api/types";
import { useCouple } from "../../shared/couple-context";
import { Dialog } from "../../shared/ui/dialog";
import { CoupleCard } from "./card";
import { useAction } from "./use-action";

// Ends the couple for both members. The shell only changes once the server
// answered and the couple was read again; on failure nothing changes.
export function LeaveCouple({ couple }: { readonly couple: CoupleView }) {
  const [open, setOpen] = useState(false);
  const { reload } = useCouple();
  const { busy, run } = useAction();
  const partner = couple.partner_name ?? "votre partenaire";
  return (
    <CoupleCard title="Réglages du couple">
      <p className="body-m muted">Quitter le mode couple y met fin pour vous deux et vous ramène à la navigation de rencontre.</p>
      <button type="button" className="btn btn-outline btn-sm" style={{ alignSelf: "flex-start" }} onClick={() => setOpen(true)}>Quitter le mode couple</button>
      {open && (
        <Dialog title="Quitter le mode couple ?" onClose={() => setOpen(false)}>
          <div className="stack gap-16">
            <p className="body-m">Le mode couple prendra fin pour {partner} comme pour vous.</p>
            <button type="button" className="btn btn-danger" disabled={busy} onClick={() => void run(() => api.delete(`/api/couple/${couple.id}`), { after: reload })}>Quitter le mode couple</button>
            <button type="button" className="btn btn-ghost" disabled={busy} onClick={() => setOpen(false)}>Annuler</button>
          </div>
        </Dialog>
      )}
    </CoupleCard>
  );
}
