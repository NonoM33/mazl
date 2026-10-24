import { useMemo } from "react";
import { CalendarHeart } from "lucide-react";
import { formatDate } from "../../shared/lib/format";
import { CoupleCard } from "./card";
import type { ImportantDate } from "./couple-api";
import { nextOccurrence } from "./couple-format";
import { useCoupleDates } from "./dates-card";
import { daysUntil, holidayDates, upcomingHolidays, type Holiday } from "./holidays";
import { Loaded } from "./loaded";

function countdown(days: number): string {
  if (days === 0) return "Ce soir";
  return days === 1 ? "Demain soir" : `J-${days}`;
}

function HolidayCard({ holiday, now }: { readonly holiday: Holiday; readonly now: Date }) {
  return (
    <li className="card holiday">
      <div className="holiday-top"><h3 className="title-l">{holiday.name}</h3><span className="countdown">{countdown(daysUntil(holiday, now))}</span></div>
      <p className="body-s">{holiday.description} · {holidayDates(holiday)}</p>
      <p className="holiday-hebrew" lang="he">{holiday.hebrewName}</p>
      {holiday.ideas.length > 0 && (
        <div className="stack gap-8"><span className="eyebrow">Idées en couple</span><div className="chips">{holiday.ideas.map((idea) => <span key={idea} className="tag">{idea}</span>)}</div></div>
      )}
    </li>
  );
}

function upcomingDates(rows: readonly ImportantDate[], now: Date): readonly { readonly entry: ImportantDate; readonly on: Date }[] {
  return rows
    .flatMap((entry) => { const on = nextOccurrence(entry.date, entry.is_recurring ?? false, now); return on ? [{ entry, on }] : []; })
    .sort((a, b) => a.on.getTime() - b.on.getTime());
}

export function CalendarScreen() {
  const now = useMemo(() => new Date(), []);
  const holidays = useMemo(() => upcomingHolidays(now), [now]);
  const dates = useCoupleDates();
  return (
    <div className="couple-cols">
      <section className="stack gap-16" aria-label="Prochaines fêtes">
        <h2 className="eyebrow">Prochaines fêtes</h2>
        <ul className="list stack gap-16">{holidays.map((holiday) => <HolidayCard key={holiday.name} holiday={holiday} now={now} />)}</ul>
      </section>
      <CoupleCard title="Nos dates" label="Dates du couple">
        <Loaded resource={dates}>
          {({ dates: rows }) => {
            const next = upcomingDates(rows, now);
            if (next.length === 0) return <p className="empty-note"><CalendarHeart size={16} aria-hidden="true" style={{ verticalAlign: "-3px" }} /> Aucune date à venir. Ajoutez vos anniversaires depuis Notre espace.</p>;
            return <ul className="couple-list">{next.map(({ entry, on }) => <li key={entry.id} className="row"><div className="row-main"><span className="row-title">{entry.title}</span><span className="row-sub">{formatDate(on)}</span></div></li>)}</ul>;
          }}
        </Loaded>
      </CoupleCard>
    </div>
  );
}
