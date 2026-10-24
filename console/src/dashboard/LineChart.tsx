import { useId, type ReactElement } from "react";
import { formatDayMonth, formatNumber } from "../shared/format";

export interface DailyPoint {
  readonly day: string;
  readonly received: number;
  readonly handled: number;
}

const W = 720;
const H = 232;
const PAD = { top: 16, right: 12, bottom: 28, left: 34 };

export function niceMax(value: number): number {
  if (value <= 4) return 4;
  const step = 10 ** Math.floor(Math.log10(value));
  return Math.ceil(value / step) * step;
}

/** Courbe 30 jours reçus / traités. Accessible : titre, description et tableau masqué. */
export function LineChart({ data }: { readonly data: readonly DailyPoint[] }): ReactElement {
  const titleId = useId();
  const max = niceMax(Math.max(1, ...data.flatMap((point) => [point.received, point.handled])));
  const innerW = W - PAD.left - PAD.right;
  const innerH = H - PAD.top - PAD.bottom;
  const x = (index: number): number => PAD.left + (data.length <= 1 ? 0 : (index / (data.length - 1)) * innerW);
  const y = (value: number): number => PAD.top + innerH - (value / max) * innerH;
  const path = (pick: (point: DailyPoint) => number): string => data.map((point, index) => `${index === 0 ? "M" : "L"}${x(index).toFixed(1)} ${y(pick(point)).toFixed(1)}`).join(" ");
  const ticks = [0, 1, 2, 3, 4].map((step) => (max / 4) * step);
  const totalReceived = data.reduce((sum, point) => sum + point.received, 0);
  const totalHandled = data.reduce((sum, point) => sum + point.handled, 0);
  const first = data[0];
  const last = data[data.length - 1];

  return (
    <figure className="chart">
      <svg viewBox={`0 0 ${W} ${H}`} role="img" aria-labelledby={titleId} className="chart-svg">
        <title id={titleId}>Signalements reçus et traités par jour, sur 30 jours</title>
        <desc>
          {formatNumber(totalReceived)} signalements reçus et {formatNumber(totalHandled)} traités sur la période
          {first !== undefined && last !== undefined ? `, du ${formatDayMonth(first.day)} au ${formatDayMonth(last.day)}` : ""}.
        </desc>
        {ticks.map((tick) => (
          <g key={tick}>
            <line x1={PAD.left} x2={W - PAD.right} y1={y(tick)} y2={y(tick)} className="chart-grid" />
            <text x={PAD.left - 8} y={y(tick) + 4} textAnchor="end" className="chart-axis">
              {formatNumber(Math.round(tick))}
            </text>
          </g>
        ))}
        {data.map((point, index) =>
          index % 7 === 0 || index === data.length - 1 ? (
            <text key={point.day} x={x(index)} y={H - 8} textAnchor={index === 0 ? "start" : index === data.length - 1 ? "end" : "middle"} className="chart-axis">
              {formatDayMonth(point.day)}
            </text>
          ) : null,
        )}
        <path d={path((point) => point.handled)} className="chart-line chart-line-handled" />
        <path d={path((point) => point.received)} className="chart-line chart-line-received" />
        {last !== undefined ? (
          <>
            <circle cx={x(data.length - 1)} cy={y(last.received)} r={3.5} className="chart-dot-received" />
            <circle cx={x(data.length - 1)} cy={y(last.handled)} r={3.5} className="chart-dot-handled" />
          </>
        ) : null}
      </svg>
      <figcaption className="chart-legend">
        <span className="legend-item">
          <svg width="22" height="8" aria-hidden="true">
            <line x1="0" x2="22" y1="4" y2="4" className="chart-line chart-line-received" />
          </svg>
          Reçus
        </span>
        <span className="legend-item">
          <svg width="22" height="8" aria-hidden="true">
            <line x1="0" x2="22" y1="4" y2="4" className="chart-line chart-line-handled" />
          </svg>
          Traités
        </span>
      </figcaption>
      <table className="sr-only">
        <caption>Données de la courbe : signalements par jour</caption>
        <thead>
          <tr>
            <th scope="col">Jour</th>
            <th scope="col">Reçus</th>
            <th scope="col">Traités</th>
          </tr>
        </thead>
        <tbody>
          {data.map((point) => (
            <tr key={point.day}>
              <th scope="row">{formatDayMonth(point.day)}</th>
              <td>{point.received}</td>
              <td>{point.handled}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </figure>
  );
}
