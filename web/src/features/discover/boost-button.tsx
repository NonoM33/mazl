import { useEffect, useState } from "react";
import { Zap } from "lucide-react";
import { api } from "../../shared/api/client";
import { ApiError, describeError } from "../../shared/api/errors";
import type { BoostStatus } from "../../shared/api/types";
import { useResource } from "../../shared/hooks/use-resource";
import { Link } from "../../shared/router";
import { Dialog } from "../../shared/ui/dialog";
import { useToast } from "../../shared/ui/toast";
import { formatMinutes, remainingMs } from "./clock";
import { useNow } from "./use-now";

// Boost (30 minutes of extra visibility): GET /api/boost/status, POST /api/boost/activate.

function ActiveBoost({ expiresAt, onEnd }: { readonly expiresAt: string; readonly onEnd: () => void }) {
  const left = remainingMs(expiresAt, useNow());
  useEffect(() => { if (left === 0) onEnd(); }, [left, onEnd]);
  return <span className="tag tag-accent" role="status"><Zap size={14} aria-hidden="true" />Boost actif · reste {formatMinutes(left)}</span>;
}

export function BoostButton() {
  const toast = useToast();
  const status = useResource<BoostStatus>("boost", (signal) => api.get<BoostStatus>("/api/boost/status", signal), null);
  const [busy, setBusy] = useState(false);
  const [empty, setEmpty] = useState(false);
  const { reload } = status;
  const data = status.state.data;

  const activate = async () => {
    setBusy(true);
    try {
      await api.post("/api/boost/activate");
      toast.show("Boost activé pour 30 minutes.");
    } catch (error) {
      if (error instanceof ApiError && error.code === "boosts_exhausted") setEmpty(true);
      else if (!(error instanceof ApiError && error.code === "boost_already_active")) toast.show(describeError(error));
    } finally {
      await reload();
      setBusy(false);
    }
  };

  if (!data) return null;
  if (data.is_active && data.expires_at) return <ActiveBoost expiresAt={data.expires_at} onEnd={() => void reload()} />;
  return (
    <>
      <button type="button" className="btn btn-outline btn-sm" onClick={() => void activate()} disabled={busy}><Zap size={16} aria-hidden="true" />Booster mon profil</button>
      {empty && (
        <Dialog title="Plus de Boost disponible" onClose={() => setEmpty(false)}>
          <div className="refusal-body">
            <p className="body-m">Un Boost place votre profil en tête pendant 30 minutes. Un pack vous en donne d'autres.</p>
            <Link to="/premium" className="btn btn-accent">Voir les packs</Link>
          </div>
        </Dialog>
      )}
    </>
  );
}
