import { Link } from "../../shared/router";
import { answerKey, DENOMINATION_CHOICES, INTENTION_CHOICES, KASHRUT_CHOICES, SHABBAT_CHOICES, type Choice } from "../../shared/lib/profile-labels";
import { Eyebrow } from "../../shared/ui/eyebrow";
import type { DraftField, ProfileDraft } from "./profile-draft";

const GROUPS: readonly { readonly field: DraftField; readonly title: string; readonly choices: readonly Choice[] }[] = [
  { field: "denomination", title: "Courant", choices: DENOMINATION_CHOICES },
  { field: "kashrutLevel", title: "Cacherout", choices: KASHRUT_CHOICES },
  { field: "shabbatObservance", title: "Shabbat", choices: SHABBAT_CHOICES },
  { field: "relationshipIntention", title: "Intention", choices: INTENTION_CHOICES },
];

export function PracticeFields({ draft, granted, onChange }: { readonly draft: ProfileDraft; readonly granted: boolean; readonly onChange: (field: DraftField, value: string) => void }) {
  if (!granted) {
    return (
      <section className="banner" aria-label="Ma pratique">
        <div className="stack gap-8">
          <Eyebrow as="h2">Ma pratique</Eyebrow>
          <p>Votre pratique religieuse est une donnée sensible : elle n'est affichée et modifiable qu'avec votre accord explicite.</p>
          <p>Vous pouvez le donner à tout moment dans <Link to="/reglages">Réglages, section Confidentialité</Link>.</p>
        </div>
      </section>
    );
  }
  return (
    <section className="stack gap-16" aria-label="Ma pratique">
      <Eyebrow as="h2">Ma pratique</Eyebrow>
      {GROUPS.map((group) => (
        <div key={group.field} className="field" role="group" aria-label={group.title}>
          <span className="field-label">{group.title}</span>
          <div className="chips">
            {group.choices.map((choice) => (
              <button key={choice.value} type="button" className="chip" aria-pressed={answerKey(draft[group.field]) === answerKey(choice.value)} onClick={() => onChange(group.field, choice.value)}>{choice.label}</button>
            ))}
          </div>
        </div>
      ))}
    </section>
  );
}
