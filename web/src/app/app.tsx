import { useEffect, useState } from "react";
import { AnalyticsBridge } from "../features/analytics/analytics-bridge";
import { ConsentGate } from "../features/consent/consent-gate";
import { CoupleRequestBanner } from "../features/couple";
import { DiscreetProvider } from "../features/discreet/discreet-mode";
import { LoginScreen } from "../features/auth/login-screen";
import { ShabbatGate } from "../features/shabbat/shabbat-gate";
import { CoupleProvider, useCouple } from "../shared/couple-context";
import { useHotkeys } from "../shared/hooks/use-hotkeys";
import { realtime } from "../shared/realtime/socket";
import { RouterProvider, useRouter } from "../shared/router";
import { SessionProvider, useSession } from "../shared/session";
import { ToastProvider } from "../shared/ui/toast";
import { Wordmark } from "../shared/ui/wordmark";
import { resolveRoute } from "./routes";
import { COUPLE_ENTRIES, datingEntries, Shell } from "./shell";
import { ShortcutsHelp } from "./shortcuts-help";
import { useUnreadCount } from "./use-unread";

function Routed() {
  const { location, navigate } = useRouter();
  const { couple, ready } = useCouple();
  const unread = useUnreadCount(couple === null && ready);
  const [help, setHelp] = useState(false);
  useHotkeys({ "?": () => setHelp(true) });
  const resolved = resolveRoute(location.path, couple !== null);
  const redirect = "redirect" in resolved ? resolved.redirect : null;

  useEffect(() => {
    if (ready && redirect !== null) navigate(redirect, { replace: true });
  }, [ready, redirect, navigate]);

  if (!ready) return <div className="splash"><Wordmark size={40} /></div>;
  return (
    <Shell entries={couple ? COUPLE_ENTRIES : datingEntries(unread)}>
      <CoupleRequestBanner />
      {"node" in resolved ? resolved.node : null}
      {help && <ShortcutsHelp onClose={() => setHelp(false)} />}
      <AnalyticsBridge />
    </Shell>
  );
}

function SignedIn() {
  useEffect(() => {
    realtime.start();
    return () => realtime.stop();
  }, []);
  return (
    <ConsentGate>
      <ShabbatGate>
        <CoupleProvider>
          <Routed />
        </CoupleProvider>
      </ShabbatGate>
    </ConsentGate>
  );
}

function Gate() {
  const { state } = useSession();
  const { location, navigate } = useRouter();
  const signedOut = state.status === "signed-out";
  useEffect(() => {
    if (signedOut && location.path !== "/connexion") navigate("/connexion", { replace: true });
    if (state.status === "signed-in" && location.path === "/connexion") navigate("/", { replace: true });
  }, [signedOut, state.status, location.path, navigate]);
  if (state.status === "loading") return <div className="splash"><Wordmark size={40} /></div>;
  if (signedOut) return <LoginScreen />;
  return <SignedIn />;
}

export function App() {
  return (
    <RouterProvider>
      <ToastProvider>
        <DiscreetProvider>
          <SessionProvider>
            <Gate />
          </SessionProvider>
        </DiscreetProvider>
      </ToastProvider>
    </RouterProvider>
  );
}
