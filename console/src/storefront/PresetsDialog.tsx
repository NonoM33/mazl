import { useMemo, useState, type ReactElement } from "react";
import { useSession } from "../app/session";
import { Badge } from "../shared/ui/Badge";
import { Button } from "../shared/ui/Button";
import { Modal } from "../shared/ui/Modal";
import { useToast } from "../shared/ui/Toast";
import { useAsync } from "../shared/ui/use-async";
import { storefrontApi } from "./api";
import { errorMessages, newForm, validateForm } from "./campaign-form";
import { storefrontErrorMessage } from "./errors";
import { Glyph } from "./Glyph";
import { formatDayShort, formatLastDay } from "./paris-time";
import { findOverlaps } from "./timeline";
import { themeById } from "./themes";
import type { CampaignDto, PresetDto, PresetListDto, ProductDto, ThemeId } from "./types";

/** Un brouillon par fête de l'année, avec les dates calculées par le serveur ; les chevauchements sont signalés avant de créer quoi que ce soit. */
export function PresetsDialog({ year, products, existing, onClose, onDone }: { readonly year: number; readonly products: readonly ProductDto[]; readonly existing: readonly CampaignDto[]; readonly onClose: () => void; readonly onDone: () => void }): ReactElement {
  const { api } = useSession();
  const toast = useToast();
  const store = storefrontApi(api);
  const { state, reload } = useAsync<PresetListDto>(() => store.presets(year), [api, year]);
  const alreadyThere = useMemo(() => new Set(existing.filter((campaign) => campaign.status !== "cancelled").map((campaign) => campaign.themeId)), [existing]);
  const [unchecked, setUnchecked] = useState<ReadonlySet<ThemeId>>(new Set());
  const [busy, setBusy] = useState(false);
  const [failures, setFailures] = useState<readonly string[]>([]);

  const presets = state.status === "ok" ? state.data.presets : [];
  const conflicts = useMemo(() => {
    const own = findOverlaps(presets.map((preset) => ({ key: preset.themeId, startsAt: preset.startsAt, endsAt: preset.endsAt })));
    const result = new Map<ThemeId, Set<ThemeId>>();
    for (const preset of presets) {
      const set = new Set<ThemeId>([...preset.overlapsThemes, ...((own.get(preset.themeId) ?? []) as ThemeId[])]);
      if (set.size > 0) result.set(preset.themeId, set);
    }
    return result;
  }, [presets]);

  const selected = presets.filter((preset) => !alreadyThere.has(preset.themeId) && !unchecked.has(preset.themeId));

  const toggle = (themeId: ThemeId, on: boolean): void =>
    setUnchecked((current) => {
      const next = new Set(current);
      if (on) next.delete(themeId);
      else next.add(themeId);
      return next;
    });

  const create = async (): Promise<void> => {
    setBusy(true);
    const problems: string[] = [];
    let created = 0;
    for (const preset of selected) {
      const theme = themeById(preset.themeId);
      const checked = validateForm(newForm(preset.themeId, products, `${theme.label} ${year}`, preset.startsAt, preset.endsAt));
      if (!checked.ok) {
        problems.push(`${theme.label} : ${errorMessages(checked.errors).join(" ")}`);
        continue;
      }
      const result = await store.createCampaign(checked.input);
      if (result.ok) created += 1;
      else problems.push(`${theme.label} : ${storefrontErrorMessage(result)}`);
    }
    setBusy(false);
    setFailures(problems);
    if (created > 0) toast.notify(`${created} brouillon${created > 1 ? "s" : ""} créé${created > 1 ? "s" : ""} pour ${year}.`, "success");
    if (problems.length === 0) onDone();
    else if (created > 0) reload();
  };

  return (
    <Modal title={`Préremplir ${year}`} onClose={onClose} wide>
      <div className="stack">
        <p className="modal-lead">Une campagne en brouillon par fête, avec les dates calculées (heure de Paris), les textes du thème et la remise habituelle. Rien n'est programmé : vous relisez chaque fiche avant.</p>
        {state.status === "loading" ? <p className="muted">Calcul des dates des fêtes…</p> : null}
        {state.status === "error" ? (
          <p className="notice notice-error" role="alert">
            {state.message}
          </p>
        ) : null}
        {state.status === "ok" ? (
          <ul className="preset-list">
            {presets.map((preset: PresetDto) => {
              const theme = themeById(preset.themeId);
              const done = alreadyThere.has(preset.themeId);
              const clash = conflicts.get(preset.themeId);
              return (
                <li key={preset.themeId} className={`preset-row${done ? " is-done" : ""}`}>
                  <label className="preset-check">
                    <input type="checkbox" disabled={done} checked={!done && !unchecked.has(preset.themeId)} onChange={(event) => toggle(preset.themeId, event.target.checked)} />
                    <span className="preset-glyph" style={{ color: theme.accent === "#0B0B0F" ? "var(--text)" : theme.accent }}>
                      <Glyph glyph={theme.glyph} size={20} />
                    </span>
                    <span className="cell-stack">
                      <strong>{theme.label}</strong>
                      <span className="cell-sub">
                        du {formatDayShort(preset.startsAt)} au {formatLastDay(preset.endsAt)}
                      </span>
                    </span>
                  </label>
                  <span className="preset-flags">
                    {done ? <Badge>Déjà créée</Badge> : null}
                    {clash !== undefined ? <Badge tone="warning">{`Chevauche ${[...clash].map((id) => themeById(id).label).join(", ")}`}</Badge> : null}
                  </span>
                </li>
              );
            })}
          </ul>
        ) : null}
        {conflicts.size > 0 ? <p className="notice notice-warning">Deux campagnes programmées ne peuvent pas se chevaucher. Vous pouvez créer les deux brouillons, puis raccourcir l'une avant de les programmer.</p> : null}
        {failures.length > 0 ? (
          <div className="notice notice-error" role="alert">
            {failures.map((line) => (
              <p key={line}>{line}</p>
            ))}
          </div>
        ) : null}
        <div className="row-actions">
          <Button variant="ghost" onClick={onClose}>
            Fermer
          </Button>
          <Button variant="primary" loading={busy} disabled={selected.length === 0} onClick={() => void create()}>
            {selected.length === 0 ? "Aucun brouillon à créer" : `Créer ${selected.length} brouillon${selected.length > 1 ? "s" : ""}`}
          </Button>
        </div>
      </div>
    </Modal>
  );
}
