import { useState } from "react";
import { useDiscreet } from "../../shared/discreet-context";
import { useMe } from "../../shared/session";
import { nextWindow } from "../shabbat/rest-windows";
import { placeFromProfile, readShabbatSettings, saveShabbatSettings, type ShabbatSettings } from "../shabbat/shabbat-settings";
import { Row, Section } from "./section";
import { BUFFER_CHOICES, bufferLabel, windowLabel } from "./settings-model";
import { Switch } from "../../shared/ui/switch";

export function ShabbatSection() {
  const { profile } = useMe();
  const [settings, setSettings] = useState<ShabbatSettings>(readShabbatSettings);
  const place = placeFromProfile(profile?.latitude, profile?.longitude, profile?.location);
  const update = (patch: Partial<ShabbatSettings>) => {
    const next = { ...settings, ...patch };
    saveShabbatSettings(next);
    setSettings(next);
  };
  const upcoming = nextWindow(new Date(), place, settings);
  return (
    <Section id="shabbat" title="Pause Shabbat">
      <Row title="Mettre MAZL en pause pendant Shabbat" sub="Le site se met en retrait du coucher du soleil à la nuit." action={<Switch checked={settings.enabled} label="Pause Shabbat" onChange={(enabled) => update({ enabled })} />} />
      <Row title="Inclure les fêtes (Yom Tov)" action={<Switch checked={settings.includeHolidays} label="Inclure les fêtes" disabled={!settings.enabled} onChange={(includeHolidays) => update({ includeHolidays })} />} />
      <Row title="Marge avant l'allumage" sub="La pause commence un peu avant l'allumage des bougies." action={
        <select className="select" aria-label="Marge avant l'allumage" value={settings.bufferMin} disabled={!settings.enabled} onChange={(event) => update({ bufferMin: Number(event.target.value) })}>
          {BUFFER_CHOICES.map((minutes) => <option key={minutes} value={minutes}>{bufferLabel(minutes)}</option>)}
        </select>} />
      {settings.enabled && <p className="body-m settings-note" aria-live="polite">{windowLabel(upcoming, place)}</p>}
      <p className="body-s settings-note">Ce réglage est propre à ce navigateur : il n'est pas partagé avec votre téléphone.</p>
    </Section>
  );
}

export function DiscreetSection() {
  const discreet = useDiscreet();
  return (
    <Section id="discret" title="Mode discret">
      <div className="stack gap-12">
        <p className="body-m">Le mode discret masque l'écran d'un geste, par exemple quand quelqu'un entre dans la pièce.</p>
        <p className="body-s">Raccourci : appuyez deux fois sur <kbd>Échap</kbd>. Les captures d'écran ne peuvent pas être empêchées sur le web.</p>
        <div><button type="button" className="btn btn-outline btn-sm" onClick={discreet.enter}>Activer le mode discret</button></div>
      </div>
    </Section>
  );
}
