import { useState } from "react";
import { api } from "../../shared/api/client";
import type { WebSessionResponse } from "../../shared/api/types";
import { useResource } from "../../shared/hooks/use-resource";
import { readThemeChoice, saveThemeChoice, type ThemeChoice } from "../../shared/lib/theme";
import { Link } from "../../shared/router";
import { useSession } from "../../shared/session";
import { Row, Section } from "./section";

const THEMES: readonly { readonly value: ThemeChoice; readonly label: string }[] = [
  { value: "system", label: "Système" },
  { value: "light", label: "Clair" },
  { value: "dark", label: "Sombre" },
];

export function AccountSection() {
  const { signOut } = useSession();
  const session = useResource("settings:session", (signal) => api.get<WebSessionResponse>("/api/web/session", signal), null);
  return (
    <Section id="compte" title="Compte">
      <Row title="Adresse e-mail" sub={session.state.data?.user.email ?? "…"} />
      <Row title="Profil" sub="Photos, présentation, pratique." action={<Link to="/profil" className="btn btn-outline btn-sm">Modifier le profil</Link>} />
      <Row title="Session" sub="Ferme ce navigateur uniquement." action={<button type="button" className="btn btn-outline btn-sm" onClick={() => void signOut()}>Se déconnecter</button>} />
    </Section>
  );
}

export function AppearanceSection() {
  const [choice, setChoice] = useState<ThemeChoice>(readThemeChoice);
  const pick = (next: ThemeChoice) => { saveThemeChoice(next); setChoice(next); };
  return (
    <Section id="apparence" title="Apparence">
      <div className="stack gap-12">
        <div className="chips" role="radiogroup" aria-label="Thème">
          {THEMES.map((theme) => <button key={theme.value} type="button" role="radio" aria-checked={choice === theme.value} className="chip" onClick={() => pick(theme.value)}>{theme.label}</button>)}
        </div>
        <p className="body-s">Ce choix reste dans ce navigateur.</p>
      </div>
    </Section>
  );
}
