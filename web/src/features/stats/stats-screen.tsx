import { Check, Circle } from "lucide-react";
import { ScreenHeader } from "../../app/shell";
import { useResource } from "../../shared/hooks/use-resource";
import { Link } from "../../shared/router";
import { Eyebrow } from "../../shared/ui/eyebrow";
import { Skeleton } from "../../shared/ui/empty-state";
import { completenessPercent, completenessSteps } from "./completeness";
import { loadStats, type StatsData } from "./stats-data";
import "./stats.css";

const NA = "Indisponible";
const show = (value: number | null): string => (value === null ? NA : String(value));

function Tile({ eyebrow, value, note }: { readonly eyebrow: string; readonly value: string; readonly note?: string }) {
  return (
    <div className="card-surface stat-tile" role="group" aria-label={eyebrow}>
      <Eyebrow>{eyebrow}</Eyebrow>
      <p className={value === NA ? "title-m muted" : "headline-l tabular"}>{value}</p>
      {note && <p className="body-s">{note}</p>}
    </div>
  );
}

function boostNote(data: StatsData): string | undefined {
  if (!data.boost) return undefined;
  return data.boost.is_active ? "Un Boost est en cours." : "Aucun Boost en cours.";
}

const LEVELS = { none: "Non vérifié", photo: "Selfie vérifié", identity: "Identité vérifiée" } as const;

function Completeness({ data }: { readonly data: StatsData }) {
  const profile = data.profile;
  const input = {
    photos: data.photos?.length ?? 0,
    prompts: data.prompts ?? 0,
    hasBio: (profile?.bio ?? "").trim().length > 0,
    hasPractice: [profile?.denomination, profile?.kashrut_level, profile?.shabbat_observance].some((value) => (value ?? "").trim() !== ""),
    verified: data.level !== null && data.level !== "none",
  };
  const percent = completenessPercent(input);
  const todo = completenessSteps(input).filter((step) => !step.done);
  return (
    <section className="card-surface stat-completeness" aria-label="Complétude du profil">
      <div className="spread"><Eyebrow as="h2">Complétude du profil</Eyebrow><span className="title-m tabular">{percent} %</span></div>
      <div className="stat-bar" role="progressbar" aria-label="Complétude du profil" aria-valuemin={0} aria-valuemax={100} aria-valuenow={percent}><span style={{ width: `${percent}%` }} /></div>
      <h3 className="title-s">Pour améliorer votre profil</h3>
      {todo.length === 0 ? <p className="body-m inline gap-8"><Check size={16} aria-hidden="true" />Votre profil est complet.</p> : (
        <ul className="list">
          {todo.map((step) => (
            <li key={step.key} className="row">
              <Circle size={14} aria-hidden="true" className="muted" />
              <div className="row-main"><span className="row-title">{step.label}</span><span className="row-sub">{step.hint}</span></div>
              {step.to && <Link to={step.to} className="btn btn-outline btn-sm">Compléter</Link>}
            </li>
          ))}
        </ul>
      )}
    </section>
  );
}

function Dashboard({ data }: { readonly data: StatsData }) {
  const credits = data.credits;
  return (
    <div className="page-narrow stack gap-24">
      <div className="stat-grid">
        <Tile eyebrow="Likes reçus" value={show(data.likes)} />
        <Tile eyebrow="Matchs" value={show(data.matches)} />
        <Tile eyebrow="Conversations actives" value={show(data.conversations)} />
        <Tile eyebrow="Messages non lus" value={show(data.unread)} />
        <Tile eyebrow="Super Likes du jour" value={credits ? String(credits.super_like.available) : NA} note={credits ? `${credits.super_like.daily_remaining} offert${credits.super_like.daily_remaining > 1 ? "s" : ""} aujourd'hui` : undefined} />
        <Tile eyebrow="Boosts du jour" value={credits ? String(credits.boost.available) : NA} note={boostNote(data)} />
        <Tile eyebrow="Vérification" value={data.level ? LEVELS[data.level] : NA} />
      </div>
      <Completeness data={data} />
      <p className="body-s">Les vues de votre profil et vos visiteurs ne sont pas encore mesurés : aucun chiffre n'est affiché tant que ce n'est pas le cas.</p>
    </div>
  );
}

export function StatsScreen() {
  const stats = useResource<StatsData>("stats", loadStats, null);
  return (
    <>
      <ScreenHeader eyebrow="Mon activité" title="Statistiques" />
      <div className="screen-body">
        {stats.state.data ? <Dashboard data={stats.state.data} /> : <div className="page-narrow stat-grid"><Skeleton height={110} radius={24} /><Skeleton height={110} radius={24} /><Skeleton height={110} radius={24} /></div>}
      </div>
    </>
  );
}
