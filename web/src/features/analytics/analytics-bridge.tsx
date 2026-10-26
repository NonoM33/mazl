import { useEffect, useState } from "react";
import { api } from "../../shared/api/client";
import { describeError } from "../../shared/api/errors";
import type { ConsentsResponse } from "../../shared/api/types";
import { useResource } from "../../shared/hooks/use-resource";
import { useRouter } from "../../shared/router";
import { webAnalytics } from "./web-analytics";

const FLUSH_EVERY_MS = 10_000;

export async function decideAnalytics(granted: boolean, version: string): Promise<void> {
  await api.put("/api/privacy/consents/analytics", { granted, version, source: "web" });
  webAnalytics.setConsent(granted);
  await webAnalytics.flush();
}

// Follows the screens and sends them every few seconds, only once the member
// has agreed. Asks the question once, in a banner that blocks nothing.
export function AnalyticsBridge() {
  const { location } = useRouter();
  const consents = useResource("analytics:consents", (signal) => api.get<ConsentsResponse>("/api/privacy/consents", signal), null);
  const state = consents.state.data?.consents.analytics;
  const valid = state?.granted === true && state.version === state.current_version;
  const decided = state !== undefined && state.granted !== null && state.version === state.current_version;

  useEffect(() => {
    if (state !== undefined) webAnalytics.setConsent(decided ? valid : null);
  }, [state, decided, valid]);

  useEffect(() => webAnalytics.screen(location.path), [location.path]);

  useEffect(() => {
    const flush = () => void webAnalytics.flush();
    const timer = window.setInterval(flush, FLUSH_EVERY_MS);
    window.addEventListener("pagehide", flush);
    return () => {
      window.clearInterval(timer);
      window.removeEventListener("pagehide", flush);
    };
  }, []);

  if (state === undefined || decided) return null;
  return <AnalyticsBanner text={state.text} version={state.current_version} onDecided={() => void consents.reload()} />;
}

function AnalyticsBanner({ text, version, onDecided }: { readonly text: string; readonly version: string; readonly onDecided: () => void }) {
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const decide = async (granted: boolean) => {
    setBusy(true);
    setError(null);
    try {
      await decideAnalytics(granted, version);
      onDecided();
    } catch (cause) {
      setError(describeError(cause));
    } finally {
      setBusy(false);
    }
  };
  return (
    <section className="card stack gap-12" role="region" aria-label="Mesure d'audience"
      style={{ position: "fixed", insetInline: 16, bottom: 16, maxWidth: 560, marginInline: "auto", padding: 20, zIndex: 50, boxShadow: "0 8px 32px rgba(0,0,0,.18)" }}>
      <p className="eyebrow">Aider à améliorer MAZL</p>
      <p className="body-s">{text}</p>
      {error && <p className="field-error" role="alert">{error}</p>}
      <div className="inline gap-12">
        <button type="button" className="btn btn-outline" disabled={busy} onClick={() => void decide(false)}>Refuser</button>
        <button type="button" className="btn btn-outline" disabled={busy} onClick={() => void decide(true)}>Accepter</button>
      </div>
    </section>
  );
}
