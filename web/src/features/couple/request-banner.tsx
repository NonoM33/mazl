import { useCallback, useEffect, useState } from "react";
import { api } from "../../shared/api/client";
import type { CoupleRequestsResponse, CoupleRequestView } from "../../shared/api/types";
import { useCouple } from "../../shared/couple-context";
import { useResource } from "../../shared/hooks/use-resource";
import { realtime } from "../../shared/realtime/socket";
import { useToast } from "../../shared/ui/toast";
import { MazelTov } from "./mazel-tov";
import { useAction } from "./use-action";

const POLL_MS = 10_000;
const ARCHIVE_FAILED = "Vos autres conversations n'ont pas pu être archivées.";

// The payload of `couple:accepted` is `{ couple }` (docs/couple/CONTRAT.md §3).
function partnerNameOf(payload: unknown): string | null {
  if (typeof payload !== "object" || payload === null || !("couple" in payload)) return null;
  const { couple } = payload;
  if (typeof couple !== "object" || couple === null || !("partner_name" in couple)) return null;
  return typeof couple.partner_name === "string" ? couple.partner_name : null;
}

const pending = (rows: readonly CoupleRequestView[]): readonly CoupleRequestView[] => rows.filter((row) => row.status === "pending");

// Asks for the couple requests, and keeps asking every 10 s while one is
// waiting: the socket only speeds things up (docs/couple/CONTRAT.md §3).
function useCoupleRequests(active: boolean) {
  const resource = useResource("couple-requests", (signal) => api.get<CoupleRequestsResponse>("/api/couple/requests", signal), null);
  const { reload } = resource;
  const data = resource.state.data;
  const waiting = data !== undefined && pending(data.received).length + pending(data.sent).length > 0;
  useEffect(() => {
    if (!active) return undefined;
    const refresh = () => void reload();
    const offs = ["couple:request", "couple:rejected"].map((type) => realtime.on(type, refresh));
    const onVisible = () => { if (document.visibilityState === "visible") refresh(); };
    document.addEventListener("visibilitychange", onVisible);
    const timer = waiting ? window.setInterval(refresh, POLL_MS) : null;
    return () => {
      for (const off of offs) off();
      document.removeEventListener("visibilitychange", onVisible);
      if (timer !== null) window.clearInterval(timer);
    };
  }, [active, waiting, reload]);
  return resource;
}

function Received({ request, onAccepted, onChanged }: { readonly request: CoupleRequestView; readonly onAccepted: () => void; readonly onChanged: () => Promise<void> }) {
  const { busy, run } = useAction();
  const toast = useToast();
  const name = request.requester_name ?? "Un membre";
  const accept = () => void run(async () => {
    await api.put(`/api/couple/request/${request.id}`, { action: "accept" });
    try { await api.post("/api/couple/archive-conversations", {}); } catch { toast.show(ARCHIVE_FAILED); }
  }, { after: onAccepted });
  return (
    <div className="banner banner-accent request-banner" role="region" aria-label="Demande de mode couple">
      <p className="grow title-m">{name} souhaite activer le mode couple avec vous</p>
      <div className="inline gap-8">
        <button type="button" className="btn btn-accent btn-sm" disabled={busy} onClick={accept}>Accepter</button>
        <button type="button" className="btn btn-outline btn-sm" disabled={busy} onClick={() => void run(() => api.put(`/api/couple/request/${request.id}`, { action: "reject" }), { after: onChanged })}>Non merci</button>
      </div>
    </div>
  );
}

function Sent({ request, onChanged }: { readonly request: CoupleRequestView; readonly onChanged: () => Promise<void> }) {
  const { busy, run } = useAction();
  return (
    <div className="banner request-banner" role="region" aria-label="Demande de mode couple envoyée">
      <p className="grow body-m">Demande envoyée à {request.target_name ?? "ce membre"}</p>
      <button type="button" className="btn btn-outline btn-sm" disabled={busy} onClick={() => void run(() => api.delete(`/api/couple/request/${request.id}`), { after: onChanged, done: "Demande annulée" })}>Annuler la demande</button>
    </div>
  );
}

// Mounted by the shell, always: outside couple mode it shows the pending
// request; the celebration outlives the switch of navigation.
export function CoupleRequestBanner() {
  const { couple, reload } = useCouple();
  const [celebrating, setCelebrating] = useState<{ readonly partner: string | null } | null>(null);
  const resource = useCoupleRequests(couple === null);
  const toast = useToast();
  const celebrate = useCallback((partner: string | null) => setCelebrating({ partner }), []);

  useEffect(() => {
    return realtime.on("couple:accepted", (payload) => {
      celebrate(partnerNameOf(payload));
      api.post("/api/couple/archive-conversations", {}).catch(() => toast.show(ARCHIVE_FAILED));
    });
  }, [celebrate, toast]);

  const finish = useCallback(() => { setCelebrating(null); void reload(); }, [reload]);
  const data = resource.state.data;
  const received = data ? pending(data.received)[0] : undefined;
  const sent = data ? pending(data.sent)[0] : undefined;
  return (
    <>
      {couple === null && received && <Received request={received} onAccepted={() => celebrate(received.requester_name)} onChanged={resource.reload} />}
      {couple === null && !received && sent && <Sent request={sent} onChanged={resource.reload} />}
      {celebrating && <MazelTov partner={celebrating.partner} onDone={finish} />}
    </>
  );
}
