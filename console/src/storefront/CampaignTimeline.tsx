import type { CSSProperties, ReactElement } from "react";
import { Glyph } from "./Glyph";
import { campaignState, STATE_LABELS } from "./campaign-state";
import { formatDayShort, formatLastDay, parisDayOfYear } from "./paris-time";
import { daysInYear, findOverlaps, laneCount, layoutYear, monthColumns } from "./timeline";
import { accentForConsole, themeById } from "./themes";
import type { CampaignDto } from "./types";

const LANE_HEIGHT = 40;

/** Frise de l'année : douze mois, chaque campagne colorée par l'accent de son thème et son glyphe, une ligne par chevauchement. */
export function CampaignTimeline({ campaigns, year, now, selectedId, onSelect }: { readonly campaigns: readonly CampaignDto[]; readonly year: number; readonly now: Date; readonly selectedId: number | null; readonly onSelect: (id: number) => void }): ReactElement {
  const placed = layoutYear(campaigns.map((campaign) => ({ key: campaign.id, startsAt: campaign.startsAt, endsAt: campaign.endsAt, campaign })), year);
  const overlaps = findOverlaps(campaigns.filter((c) => c.status !== "cancelled").map((c) => ({ key: c.id, startsAt: c.startsAt, endsAt: c.endsAt })));
  const lanes = laneCount(placed);
  const today = parisDayOfYear(now.getTime(), year);
  const todayShare = today >= 0 && today < daysInYear(year) ? (today + 0.5) / daysInYear(year) : null;
  return (
    <section className="card timeline-card" aria-labelledby="timeline-title">
      <div className="card-head">
        <h2 id="timeline-title">Année {year}</h2>
        <span className="muted">{campaigns.filter((c) => c.status !== "cancelled").length} campagne(s) · dates à l'heure de Paris</span>
      </div>
      <div className="timeline" role="group" aria-label={`Frise des campagnes ${year}`}>
        <div className="timeline-months" aria-hidden="true">
          {monthColumns(year).map((month) => (
            <span key={month.index} className="timeline-month" style={{ left: `${month.start * 100}%`, width: `${month.width * 100}%` }}>
              {month.label}
            </span>
          ))}
        </div>
        <div className="timeline-lanes" style={{ height: Math.max(1, lanes) * LANE_HEIGHT + 8 }}>
          {monthColumns(year).map((month) => (
            <span key={month.index} className="timeline-grid" aria-hidden="true" style={{ left: `${month.start * 100}%` }} />
          ))}
          {todayShare !== null ? <span className="timeline-today" aria-hidden="true" style={{ left: `${todayShare * 100}%` }} title="Aujourd'hui" /> : null}
          {placed.map(({ item, start, end, lane, clippedStart, clippedEnd }) => {
            const campaign = item.campaign;
            const theme = themeById(campaign.themeId);
            const state = campaignState(campaign, now);
            const conflicts = overlaps.get(campaign.id);
            const style = { left: `min(${start * 100}%, calc(100% - 34px))`, width: `${Math.max(end - start, 0.012) * 100}%`, top: 4 + lane * LANE_HEIGHT, "--c": accentForConsole(theme) } as CSSProperties;
            const description = `${campaign.name}, ${theme.label}, du ${formatDayShort(campaign.startsAt)} au ${formatLastDay(campaign.endsAt)}, ${STATE_LABELS[state].toLowerCase()}${conflicts !== undefined ? ", chevauche une autre campagne" : ""}`;
            return (
              <button
                key={campaign.id}
                type="button"
                className={`timeline-bar state-${state}${selectedId === campaign.id ? " is-selected" : ""}${clippedStart ? " is-clipped-start" : ""}${clippedEnd ? " is-clipped-end" : ""}${conflicts !== undefined ? " has-conflict" : ""}`}
                style={style}
                title={description}
                aria-label={description}
                onClick={() => onSelect(campaign.id)}
              >
                <Glyph glyph={theme.glyph} size={16} />
                <span className="timeline-bar-name">{campaign.name}</span>
              </button>
            );
          })}
        </div>
      </div>
      {placed.length === 0 ? <p className="muted timeline-empty">Aucune campagne cette année. « Préremplir l'année » propose un brouillon par fête.</p> : null}
    </section>
  );
}
