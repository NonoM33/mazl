import { useState } from "react";
import { api } from "../../shared/api/client";
import { ApiError, describeError } from "../../shared/api/errors";
import type { ConsentsResponse } from "../../shared/api/types";
import { useResource } from "../../shared/hooks/use-resource";
import { formatDate } from "../../shared/lib/format";
import { Dialog } from "../../shared/ui/dialog";
import { Row } from "./section";

async function decide(granted: boolean, version: string): Promise<void> {
  await api.put("/api/privacy/consents/religious_data", { granted, version, source: "web" });
}

function WithdrawDialog({ busy, error, onConfirm, onClose }: { readonly busy: boolean; readonly error: string | null; readonly onConfirm: () => void; readonly onClose: () => void }) {
  return (
    <Dialog title="Retirer mon consentement" onClose={onClose}>
      <p className="body-m">Votre courant, votre niveau de cashrout, votre pratique du Shabbat et votre intention seront effacés de votre profil. Vous pourrez les saisir de nouveau si vous consentez plus tard.</p>
      {error && <p className="field-error" role="alert">{error}</p>}
      <div className="inline gap-12">
        <button type="button" className="btn btn-outline" onClick={onClose}>Garder mon consentement</button>
        <button type="button" className="btn btn-danger" disabled={busy} onClick={onConfirm}>Retirer et effacer</button>
      </div>
    </Dialog>
  );
}

export function ConsentCard() {
  const consents = useResource("settings:consents", (signal) => api.get<ConsentsResponse>("/api/privacy/consents", signal), null);
  const [confirming, setConfirming] = useState(false);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const state = consents.state.data?.consents.religious_data;

  const change = async (granted: boolean) => {
    if (!state) return;
    setBusy(true);
    setError(null);
    try {
      await decide(granted, state.current_version);
      await consents.reload();
      setConfirming(false);
    } catch (cause) {
      setError(describeError(cause));
    } finally {
      setBusy(false);
    }
  };

  if (consents.state.status === "error" && !state) {
    const missing = consents.state.error instanceof ApiError && consents.state.error.isNotFound;
    return <Row title="Données de pratique religieuse" sub={missing ? "Indisponible pour le moment." : describeError(consents.state.error)} />;
  }
  if (!state) return <Row title="Données de pratique religieuse" sub="…" />;
  const granted = state.granted === true;
  return (
    <>
      <Row title="Données de pratique religieuse" sub={granted ? `Consentement donné${state.decided_at ? ` le ${formatDate(state.decided_at)}` : ""}.` : "Consentement non donné."}
        action={granted
          ? <button type="button" className="btn btn-outline btn-sm" onClick={() => setConfirming(true)}>Retirer mon consentement</button>
          : <button type="button" className="btn btn-outline btn-sm" disabled={busy} onClick={() => void change(true)}>Donner mon consentement</button>} />
      <p className="body-s settings-note">{state.text}</p>
      {error && !confirming && <p className="field-error settings-note" role="alert">{error}</p>}
      {confirming && <WithdrawDialog busy={busy} error={error} onConfirm={() => void change(false)} onClose={() => setConfirming(false)} />}
    </>
  );
}
