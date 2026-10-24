import { useState } from "react";
import { api } from "../../shared/api/client";
import { describeError } from "../../shared/api/errors";
import type { LookingFor, OwnProfileRow } from "../../shared/api/types";
import { useSession } from "../../shared/session";
import { useToast } from "../../shared/ui/toast";

// « Préférences »: who is proposed. Saved with PUT /api/profile, then the lot
// is reloaded by the screen.

export const MIN_DISTANCE_KM = 5;
const MIN_AGE = 18;
const MAX_AGE = 99;
const GENDERS: readonly { readonly value: LookingFor; readonly label: string }[] = [
  { value: "female", label: "Femmes" }, { value: "male", label: "Hommes" }, { value: "all", label: "Tous" },
];

interface Draft { readonly lookingFor: LookingFor; readonly ageMin: number; readonly ageMax: number; readonly distanceMax: number }

function initialDraft(profile: OwnProfileRow | null): Draft {
  return {
    lookingFor: profile?.looking_for ?? "all",
    ageMin: profile?.age_min ?? MIN_AGE,
    ageMax: profile?.age_max ?? MAX_AGE,
    distanceMax: Math.max(MIN_DISTANCE_KM, profile?.distance_max ?? 50),
  };
}

export function PreferencesPanel({ profile, onSaved }: { readonly profile: OwnProfileRow | null; readonly onSaved: () => void }) {
  const toast = useToast();
  const session = useSession();
  const [saved, setSaved] = useState(() => initialDraft(profile));
  const [draft, setDraft] = useState(saved);
  const [busy, setBusy] = useState(false);
  const dirty = JSON.stringify(draft) !== JSON.stringify(saved);

  const save = async () => {
    setBusy(true);
    try {
      await api.put("/api/profile", { lookingFor: draft.lookingFor, ageMin: draft.ageMin, ageMax: draft.ageMax, distanceMax: draft.distanceMax });
      setSaved(draft);
      toast.show("Préférences enregistrées.");
      void session.refresh();
      onSaved();
    } catch (error) {
      toast.show(describeError(error));
    } finally {
      setBusy(false);
    }
  };

  return (
    <section className="stack gap-24" aria-label="Préférences de recherche">
      <p className="eyebrow">Préférences</p>
      <div className="field" role="group" aria-label="Je recherche">
        <span className="field-label">Je recherche</span>
        <div className="chips">
          {GENDERS.map((gender) => (
            <button key={gender.value} type="button" className="chip" aria-pressed={draft.lookingFor === gender.value} onClick={() => setDraft({ ...draft, lookingFor: gender.value })}>{gender.label}</button>
          ))}
        </div>
      </div>
      <div className="field">
        <label htmlFor="age-min">Âge minimum · {draft.ageMin} ans</label>
        <input id="age-min" className="range" type="range" min={MIN_AGE} max={MAX_AGE} value={draft.ageMin} onChange={(event) => { const ageMin = Number(event.target.value); setDraft({ ...draft, ageMin, ageMax: Math.max(ageMin, draft.ageMax) }); }} />
      </div>
      <div className="field">
        <label htmlFor="age-max">Âge maximum · {draft.ageMax} ans</label>
        <input id="age-max" className="range" type="range" min={MIN_AGE} max={MAX_AGE} value={draft.ageMax} onChange={(event) => { const ageMax = Number(event.target.value); setDraft({ ...draft, ageMax, ageMin: Math.min(ageMax, draft.ageMin) }); }} />
      </div>
      <div className="field">
        <label htmlFor="distance">Distance maximale · {draft.distanceMax} km</label>
        <input id="distance" className="range" type="range" min={MIN_DISTANCE_KM} max={Math.max(200, saved.distanceMax)} step={5} value={draft.distanceMax} onChange={(event) => setDraft({ ...draft, distanceMax: Number(event.target.value) })} />
      </div>
      <button type="button" className="btn btn-primary btn-sm" disabled={!dirty || busy} onClick={() => void save()}>Enregistrer</button>
    </section>
  );
}
