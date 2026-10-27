import { useEffect, useMemo, useState, type ReactElement } from "react";
import { buildHash } from "../app/router";
import { navigate } from "../app/use-route";
import { useSession } from "../app/session";
import { formatDayShort, formatLastDay, parisParts } from "./paris-time";
import { Badge } from "../shared/ui/Badge";
import { Button } from "../shared/ui/Button";
import { EmptyState, ErrorState, SkeletonRows } from "../shared/ui/Feedback";
import { PageHeader } from "../shared/ui/PageHeader";
import { Select } from "../shared/ui/Select";
import { Table, type Column } from "../shared/ui/Table";
import { useAsync } from "../shared/ui/use-async";
import { storefrontApi } from "./api";
import { CampaignEditor } from "./CampaignEditor";
import { newForm, type CampaignForm } from "./campaign-form";
import { campaignState, countdown, STATE_LABELS, STATE_TONES } from "./campaign-state";
import { CampaignTimeline } from "./CampaignTimeline";
import { Glyph } from "./Glyph";
import { PresetsDialog } from "./PresetsDialog";
import { accentForConsole, themeById } from "./themes";
import type { CampaignDto, ProductDto } from "./types";

function yearOf(param: string | undefined, fallback: number): number {
  const value = Number(param);
  return Number.isInteger(value) && value >= 2024 && value <= 2100 ? value : fallback;
}

export function CampaignsScreen({ selectedId, year: yearParam }: { readonly selectedId: number | null; readonly year: string | undefined }): ReactElement {
  const { api } = useSession();
  const store = storefrontApi(api);
  const now = new Date();
  const currentYear = parisParts(now).year;
  const year = yearOf(yearParam, currentYear);
  const [creating, setCreating] = useState<CampaignForm | null>(null);
  const [presets, setPresets] = useState(false);
  const products = useAsync(() => store.products(), [api]);
  const campaigns = useAsync(() => store.campaigns(year), [api, year]);

  useEffect(() => setCreating(null), [year]);

  const productList: readonly ProductDto[] = products.state.status === "ok" ? products.state.data.products : [];
  const list: readonly CampaignDto[] = campaigns.state.status === "ok" ? campaigns.state.data.campaigns : [];
  const sorted = useMemo(() => [...list].sort((a, b) => Date.parse(a.startsAt) - Date.parse(b.startsAt)), [list]);
  const selected = selectedId === null ? null : (sorted.find((campaign) => campaign.id === selectedId) ?? null);

  const go = (id: number | null, nextYear: number = year): void => navigate(buildHash("campagnes", id, { annee: String(nextYear) }));

  const startNew = (): void => {
    const theme = themeById("valentine");
    const start = Date.UTC(year, 0, 1) - 3_600_000;
    setCreating(newForm(theme.id, productList, `${theme.label} ${year}`, new Date(start).toISOString(), new Date(start + 7 * 86_400_000).toISOString()));
    go(null);
  };

  const columns: readonly Column<CampaignDto>[] = [
    {
      key: "name",
      header: "Campagne",
      width: "30%",
      render: (campaign) => {
        const theme = themeById(campaign.themeId);
        return (
          <span className="campaign-name">
            <span className="campaign-glyph" style={{ color: accentForConsole(theme) }}>
              <Glyph glyph={theme.glyph} size={20} />
            </span>
            <span className="cell-stack">
              <strong>{campaign.name}</strong>
              <span className="cell-sub">{theme.label}</span>
            </span>
          </span>
        );
      },
    },
    { key: "dates", header: "Dates (Paris)", width: "22%", render: (campaign) => `${formatDayShort(campaign.startsAt)} → ${formatLastDay(campaign.endsAt)}` },
    {
      key: "state",
      header: "État",
      width: "22%",
      render: (campaign) => {
        const state = campaignState(campaign, now);
        const text = countdown(campaign, now);
        return (
          <span className="cell-stack">
            <span>
              <Badge tone={STATE_TONES[state]}>{STATE_LABELS[state]}</Badge>
            </span>
            {text !== null ? <span className="cell-sub">{text}</span> : null}
          </span>
        );
      },
    },
    { key: "targets", header: "Remises", render: (campaign) => (campaign.targets.length === 0 ? <span className="muted">Aucune</span> : `${campaign.targets.length} offre${campaign.targets.length > 1 ? "s" : ""}, ${[...new Set(campaign.targets.map((target) => `−${target.discountPercent} %`))].join(" / ")}`) },
    { key: "icon", header: "Icône", width: "90px", render: (campaign) => (campaign.changeAppIcon ? "Change" : <span className="muted">Non</span>) },
  ];

  const years = [currentYear - 1, currentYear, currentYear + 1, currentYear + 2];
  const loading = campaigns.state.status === "loading" || products.state.status === "loading";
  const editorOpen = creating !== null || selected !== null;

  return (
    <>
      <PageHeader
        eyebrow="Vitrine"
        title="Campagnes"
        lead="Les fêtes de l'année : chacune a son thème, son icône d'app, sa remise et son écran mazl+. Programmez-les à l'avance, l'app s'adapte toute seule, sans mise à jour."
        actions={
          <>
            <span className="year-select"><Select label="Année" compact value={String(year) as `${number}`} options={years.map((y) => ({ value: String(y) as `${number}`, label: String(y) }))} onChange={(value) => value !== "" && go(null, Number(value))} /></span>
            <Button icon="wand" onClick={() => setPresets(true)} disabled={products.state.status !== "ok"}>
              Préremplir l'année
            </Button>
            <Button variant="primary" icon="plus" onClick={startNew} disabled={products.state.status !== "ok"}>
              Nouvelle campagne
            </Button>
          </>
        }
      />
      <div className="page-body">
        {loading ? <SkeletonRows rows={5} label="Chargement des campagnes" /> : null}
        {campaigns.state.status === "error" ? <ErrorState message={campaigns.state.message} onRetry={campaigns.reload} /> : null}
        {products.state.status === "error" ? <ErrorState message={products.state.message} onRetry={products.reload} /> : null}
        {campaigns.state.status === "ok" && products.state.status === "ok" ? (
          <>
            <CampaignTimeline campaigns={sorted} year={year} now={now} selectedId={selectedId} onSelect={(id) => go(id)} />
            {sorted.length === 0 ? (
              <EmptyState icon="calendar" title={`Aucune campagne en ${year}`} action={<Button icon="wand" onClick={() => setPresets(true)}>Préremplir l'année</Button>}>
                Un brouillon par fête, avec les dates calculées, en un clic.
              </EmptyState>
            ) : (
              <Table caption={`Campagnes ${year}`} columns={columns} rows={sorted} rowKey={(campaign) => campaign.id} selectedKey={selectedId} onRowActivate={(campaign) => go(campaign.id)} />
            )}
          </>
        ) : null}
      </div>
      {editorOpen && products.state.status === "ok" ? (
        <CampaignEditor
          key={selected === null ? "new" : `${selected.id}-${selected.updatedAt}-${selected.status}`}
          campaign={selected}
          initial={creating}
          products={productList}
          others={sorted}
          onClose={() => {
            setCreating(null);
            go(null);
          }}
          onChanged={(openId) => {
            setCreating(null);
            campaigns.reload();
            go(openId);
          }}
        />
      ) : null}
      {presets && products.state.status === "ok" ? (
        <PresetsDialog
          year={year}
          products={productList}
          existing={sorted}
          onClose={() => setPresets(false)}
          onDone={() => {
            setPresets(false);
            campaigns.reload();
          }}
        />
      ) : null}
    </>
  );
}
