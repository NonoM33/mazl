import { useState } from "react";
import { api } from "../../shared/api/client";
import { describeError } from "../../shared/api/errors";
import type { WebSessionsResponse } from "../../shared/api/types";
import { useResource } from "../../shared/hooks/use-resource";
import { Row, Section } from "./section";
import { others, sessionDetail, sessionTitle } from "./settings-model";

export function SessionsSection() {
  const sessions = useResource("settings:sessions", (signal) => api.get<WebSessionsResponse>("/api/web/sessions", signal), null);
  const [error, setError] = useState<string | null>(null);
  const run = async (call: () => Promise<unknown>) => {
    setError(null);
    try {
      await call();
      await sessions.reload();
    } catch (cause) {
      setError(describeError(cause));
    }
  };
  const list = sessions.state.data?.sessions ?? [];
  return (
    <Section id="ordinateurs" title="Ordinateurs connectés">
      {list.map((session) => (
        <Row key={session.id} title={sessionTitle(session)} sub={sessionDetail(session)}
          action={session.current === true ? undefined : <button type="button" className="btn btn-outline btn-sm" aria-label={`Déconnecter ${session.browser}`} onClick={() => void run(() => api.delete(`/api/web/sessions/${session.id}`))}>Déconnecter</button>} />
      ))}
      {sessions.state.status === "error" && !sessions.state.data && <p className="field-error settings-note" role="alert">{describeError(sessions.state.error)}</p>}
      {error && <p className="field-error settings-note" role="alert">{error}</p>}
      {others(list).length > 0 && <Row title="Les autres ordinateurs" action={<button type="button" className="btn btn-outline btn-sm" onClick={() => void run(() => api.delete("/api/web/sessions?others=true"))}>Déconnecter les autres ordinateurs</button>} />}
      <p className="body-s settings-note">Une session se ferme après 4 heures d'inactivité, et au plus tard après 7 jours. Vous pouvez aussi la révoquer depuis l'application.</p>
    </Section>
  );
}
