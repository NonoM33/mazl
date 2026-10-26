import { useState } from "react";
import { api } from "../../shared/api/client";
import { describeError } from "../../shared/api/errors";
import type { ConsentsResponse } from "../../shared/api/types";
import { useResource } from "../../shared/hooks/use-resource";
import { formatDate } from "../../shared/lib/format";
import { decideAnalytics } from "../analytics/analytics-bridge";
import { Row } from "./section";

export function AnalyticsConsentRow() {
  const consents = useResource("settings:analytics", (signal) => api.get<ConsentsResponse>("/api/privacy/consents", signal), null);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const state = consents.state.data?.consents.analytics;
  if (!state) return null;
  const granted = state.granted === true && state.version === state.current_version;
  const change = async (next: boolean) => {
    setBusy(true);
    setError(null);
    try {
      await decideAnalytics(next, state.current_version);
      await consents.reload();
    } catch (cause) {
      setError(describeError(cause));
    } finally {
      setBusy(false);
    }
  };
  return (
    <>
      <Row title="Mesure d'audience" sub={granted ? `Acceptée${state.decided_at ? ` le ${formatDate(state.decided_at)}` : ""}.` : "Refusée ou pas encore décidée."}
        action={<button type="button" className="btn btn-outline btn-sm" disabled={busy} onClick={() => void change(!granted)}>{granted ? "Retirer mon accord" : "Accepter"}</button>} />
      <p className="body-s settings-note">{state.text}</p>
      {error && <p className="field-error settings-note" role="alert">{error}</p>}
    </>
  );
}
