import { useState } from "react";
import { api } from "../../shared/api/client";
import { describeError } from "../../shared/api/errors";
import type { BlockedResponse } from "../../shared/api/types";
import { useResource } from "../../shared/hooks/use-resource";
import { displayName } from "../../shared/lib/format";
import { ConsentCard } from "./consent-card";
import { downloadExport } from "./export-download";
import { exportMessage } from "./export-outcome";
import { Row, Section } from "./section";

function ExportRow() {
  const [busy, setBusy] = useState(false);
  const [message, setMessage] = useState<string | null>(null);
  const start = async () => {
    setBusy(true);
    setMessage(null);
    try {
      const outcome = await downloadExport();
      setMessage(outcome === "done" ? "Votre export a été téléchargé." : exportMessage(outcome));
    } catch (cause) {
      setMessage(describeError(cause));
    } finally {
      setBusy(false);
    }
  };
  return <Row title="Mes données" sub={message ?? "Une copie de tout ce que MAZL conserve sur vous."} action={<button type="button" className="btn btn-outline btn-sm" disabled={busy} onClick={() => void start()}>Télécharger mes données (JSON)</button>} />;
}

function BlockedRows() {
  const blocked = useResource("settings:blocked", (signal) => api.get<BlockedResponse>("/api/users/blocked", signal), null);
  const [error, setError] = useState<string | null>(null);
  const unblock = async (userId: number) => {
    setError(null);
    try {
      await api.delete(`/api/users/${userId}/block`);
      await blocked.reload();
    } catch (cause) {
      setError(describeError(cause));
    }
  };
  const list = blocked.state.data?.blocked ?? [];
  return (
    <>
      <Row title="Utilisateurs bloqués" sub={blocked.state.data ? (list.length === 0 ? "Vous n'avez bloqué personne." : `${list.length} personne${list.length > 1 ? "s" : ""}`) : "…"} />
      {list.map((user) => <Row key={user.user_id} title={displayName(user.display_name)} action={<button type="button" className="btn btn-outline btn-sm" onClick={() => void unblock(user.user_id)}>Débloquer</button>} />)}
      {error && <p className="field-error settings-note" role="alert">{error}</p>}
    </>
  );
}

export function PrivacySection() {
  return (
    <Section id="confidentialite" title="Confidentialité">
      <ConsentCard />
      <ExportRow />
      <BlockedRows />
      <div className="inline gap-16 settings-note">
        <a href="/cgu" target="_blank" rel="noreferrer">Conditions d'utilisation</a>
        <a href="/cgv" target="_blank" rel="noreferrer">Conditions de vente</a>
        <a href="/confidentialite" target="_blank" rel="noreferrer">Confidentialité</a>
      </div>
    </Section>
  );
}
