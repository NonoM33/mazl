import type { ReactNode } from "react";
import { LIMITS, type DraftErrors, type DraftField, type ProfileDraft } from "./profile-draft";

interface FieldsProps {
  readonly draft: ProfileDraft;
  readonly errors: DraftErrors;
  readonly birthdateLocked: boolean;
  readonly onChange: (field: DraftField, value: string) => void;
}

function Message({ id, error, hint }: { readonly id: string; readonly error: string | undefined; readonly hint?: ReactNode }) {
  if (error) return <p id={id} className="field-error" role="alert">{error}</p>;
  return hint ? <p id={id} className="field-hint">{hint}</p> : null;
}

const GENDERS = [{ value: "female", label: "Une femme" }, { value: "male", label: "Un homme" }] as const;

export function InfoFields({ draft, errors, birthdateLocked, onChange }: FieldsProps) {
  const text = (field: DraftField, label: string, max: number, hint?: ReactNode) => (
    <div className="field">
      <label htmlFor={`f-${field}`}>{label}</label>
      <input id={`f-${field}`} className="input" value={draft[field]} maxLength={max + 20} aria-invalid={errors[field] !== undefined} aria-describedby={`d-${field}`} onChange={(event) => onChange(field, event.target.value)} />
      <Message id={`d-${field}`} error={errors[field]} hint={hint} />
    </div>
  );
  return (
    <section className="stack gap-16" aria-label="Informations">
      {text("displayName", "Prénom", LIMITS.displayName)}
      <div className="field">
        <label htmlFor="f-birthdate">Date de naissance</label>
        <input id="f-birthdate" type="date" className="input" value={draft.birthdate} disabled={birthdateLocked} aria-invalid={errors.birthdate !== undefined} aria-describedby="d-birthdate" onChange={(event) => onChange("birthdate", event.target.value)} />
        <Message id="d-birthdate" error={errors.birthdate} hint={birthdateLocked ? "Vérifiée par votre pièce d'identité : elle ne peut plus être modifiée." : undefined} />
      </div>
      <div className="field" role="group" aria-labelledby="g-gender">
        <span id="g-gender" className="field-label">Genre</span>
        <div className="chips">
          {GENDERS.map((option) => (
            <button key={option.value} type="button" className="chip" aria-pressed={draft.gender === option.value} onClick={() => onChange("gender", option.value)}>{option.label}</button>
          ))}
        </div>
        <Message id="d-gender" error={errors.gender} />
      </div>
      {text("location", "Ville", LIMITS.location, "Votre position précise vient de votre téléphone, jamais de ce site.")}
      <div className="field">
        <div className="spread"><label htmlFor="f-bio">Présentation</label><span className="field-hint tabular">{draft.bio.length}/{LIMITS.bio}</span></div>
        <textarea id="f-bio" className="textarea" rows={6} value={draft.bio} aria-invalid={errors.bio !== undefined} aria-describedby="d-bio" onChange={(event) => onChange("bio", event.target.value)} />
        <Message id="d-bio" error={errors.bio} />
      </div>
    </section>
  );
}
