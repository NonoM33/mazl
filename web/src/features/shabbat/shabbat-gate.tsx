import { useEffect, useMemo, useState, type ReactNode } from "react";
import { Flame } from "lucide-react";
import { useMe } from "../../shared/session";
import { activeWindow } from "./rest-windows";
import { placeFromProfile, readShabbatSettings, type ShabbatSettings } from "./shabbat-settings";

// During Shabbat or Yom Tov the connected space gives way to a quiet screen,
// with the time it ends. The member may continue: it is a pause, not a lock.

const TIME = new Intl.DateTimeFormat("fr-FR", { hour: "2-digit", minute: "2-digit" });
const DAY = new Intl.DateTimeFormat("fr-FR", { weekday: "long" });

function useShabbatSettings(): ShabbatSettings {
  const [settings, setSettings] = useState(readShabbatSettings);
  useEffect(() => {
    const onChange = () => setSettings(readShabbatSettings());
    window.addEventListener("mazl:shabbat", onChange);
    window.addEventListener("storage", onChange);
    return () => { window.removeEventListener("mazl:shabbat", onChange); window.removeEventListener("storage", onChange); };
  }, []);
  return settings;
}

function useMinuteClock(): Date {
  const [now, setNow] = useState(() => new Date());
  useEffect(() => {
    const timer = window.setInterval(() => setNow(new Date()), 60_000);
    return () => window.clearInterval(timer);
  }, []);
  return now;
}

export function ShabbatGate({ children }: { readonly children: ReactNode }) {
  const me = useMe();
  const settings = useShabbatSettings();
  const now = useMinuteClock();
  const [dismissedUntil, setDismissedUntil] = useState<number>(0);
  const place = useMemo(() => placeFromProfile(me.profile?.latitude, me.profile?.longitude, me.profile?.location), [me.profile?.latitude, me.profile?.longitude, me.profile?.location]);
  const window_ = useMemo(() => (settings.enabled ? activeWindow(now, place, settings) : null), [settings, now, place]);

  if (!window_ || window_.end.getTime() <= dismissedUntil) return <>{children}</>;
  return (
    <div className="fullpage" style={{ background: "var(--shabbat-bg)", color: "var(--shabbat-text)" }} data-testid="shabbat-screen">
      <div className="stack gap-24" style={{ alignItems: "center", textAlign: "center", maxWidth: 520 }}>
        <Flame size={36} color="var(--shabbat-flame)" aria-hidden="true" />
        <p className="eyebrow" style={{ color: "#8e8b84" }}>{window_.holiday ? "Yom Tov" : "Shabbat"} · {place.name}</p>
        <h1 className="display-s">{window_.holiday ? "’Hag saméa’h" : "Shabbat shalom"}</h1>
        <p className="body-l" style={{ color: "var(--shabbat-muted)" }}>
          MAZL fait une pause jusqu'à {DAY.format(window_.end)} {TIME.format(window_.end)}. Vos conversations vous attendent.
        </p>
        <button type="button" className="btn btn-outline" style={{ color: "var(--shabbat-text)", boxShadow: "inset 0 0 0 1px #3a3a42" }} onClick={() => setDismissedUntil(window_.end.getTime())}>
          Continuer quand même
        </button>
        <p className="label-m" style={{ color: "#8e8b84" }}>Réglable dans Réglages › Pause Shabbat.</p>
      </div>
    </div>
  );
}
