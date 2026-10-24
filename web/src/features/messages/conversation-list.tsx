import { useMemo, type KeyboardEvent, type RefObject } from "react";
import { Search } from "lucide-react";
import type { ConversationSummary } from "../../shared/api/types";
import { displayName, shortWhen } from "../../shared/lib/format";
import { Avatar } from "../../shared/ui/photo";
import { Eyebrow } from "../../shared/ui/eyebrow";
import { EmptyState, Skeleton } from "../../shared/ui/empty-state";

// Left column: new matches first, then conversations, filtered by NAME only
// (never by message content).

export function filterByName(conversations: readonly ConversationSummary[], query: string): ConversationSummary[] {
  const needle = query.trim().toLocaleLowerCase("fr");
  if (needle.length === 0) return [...conversations];
  return conversations.filter((item) => displayName(item.otherUser.display_name).toLocaleLowerCase("fr").includes(needle));
}

function Row({ item, selected, onSelect, onExpired }: { readonly item: ConversationSummary; readonly selected: boolean; readonly onSelect: (id: number) => void; readonly onExpired: () => void }) {
  const name = displayName(item.otherUser.display_name);
  const unread = item.unreadCount > 0;
  return (
    <li>
      <button type="button" className="conv-row" data-selected={selected} aria-current={selected ? "true" : undefined} onClick={() => onSelect(item.id)}
        aria-label={`${name}${unread ? `, ${item.unreadCount} non lu${item.unreadCount > 1 ? "s" : ""}` : ""}`}>
        <Avatar src={item.otherUser.picture} name={name} seed={item.otherUser.user_id} size={48} onExpired={onExpired} />
        <span className="conv-main">
          <span className="conv-name" data-unread={unread}>{name}</span>
          <span className="conv-preview" data-unread={unread}>{item.lastMessage ?? "Dites bonjour"}</span>
        </span>
        <span className="conv-meta">
          <span className="conv-time">{shortWhen(item.lastMessageAt)}</span>
          {unread && <span className="conv-badge" aria-hidden="true">{item.unreadCount}</span>}
        </span>
      </button>
    </li>
  );
}

function moveFocus(event: KeyboardEvent<HTMLElement>): void {
  if (event.key !== "ArrowDown" && event.key !== "ArrowUp") return;
  const rows = Array.from(event.currentTarget.querySelectorAll<HTMLButtonElement>(".conv-row"));
  const current = rows.indexOf(document.activeElement as HTMLButtonElement);
  if (rows.length === 0) return;
  event.preventDefault();
  const step = event.key === "ArrowDown" ? 1 : -1;
  const next = current === -1 ? (step === 1 ? 0 : rows.length - 1) : Math.min(rows.length - 1, Math.max(0, current + step));
  rows[next]?.focus();
}

interface ListProps {
  readonly conversations: readonly ConversationSummary[] | undefined;
  readonly failed: boolean;
  readonly selectedId: number | null;
  readonly query: string;
  readonly searchRef: RefObject<HTMLInputElement | null>;
  readonly onQuery: (query: string) => void;
  readonly onSelect: (id: number) => void;
  readonly onExpired: () => void;
}

export function ConversationList({ conversations, failed, selectedId, query, searchRef, onQuery, onSelect, onExpired }: ListProps) {
  const shown = useMemo(() => filterByName(conversations ?? [], query), [conversations, query]);
  const fresh = shown.filter((item) => item.lastMessage === null);
  const talked = shown.filter((item) => item.lastMessage !== null);
  const renderRows = (rows: readonly ConversationSummary[]) => rows.map((item) => <Row key={item.id} item={item} selected={item.id === selectedId} onSelect={onSelect} onExpired={onExpired} />);
  return (
    <aside className="conv-col" aria-label="Conversations">
      <div className="conv-head">
        <h1 className="headline-m">Messages</h1>
        <label className="conv-search">
          <Search size={18} aria-hidden="true" />
          <input ref={searchRef} type="search" className="conv-search-input" placeholder="Rechercher un nom" aria-label="Rechercher une conversation par nom" value={query}
            onChange={(event) => onQuery(event.target.value)} onKeyDown={(event) => { if (event.key === "ArrowDown") { event.preventDefault(); document.querySelector<HTMLButtonElement>(".conv-row")?.focus(); } }} />
          <kbd aria-hidden="true">⌘K</kbd>
        </label>
      </div>
      <div className="conv-scroll" onKeyDown={moveFocus}>
        {conversations === undefined && !failed && <div className="stack gap-16" style={{ padding: 20 }}>{[0, 1, 2, 3].map((n) => <Skeleton key={n} height={48} />)}</div>}
        {failed && conversations === undefined && <p className="body-s" style={{ padding: 20 }} role="alert">Vos conversations n'ont pas pu être chargées.</p>}
        {conversations !== undefined && shown.length === 0 && (query.trim().length > 0
          ? <p className="body-s" style={{ padding: 20 }}>Aucun nom ne correspond.</p>
          : <EmptyState title="Aucune conversation">Vos matchs apparaîtront ici dès qu'ils se présenteront.</EmptyState>)}
        {fresh.length > 0 && <section><Eyebrow>Nouveaux · {fresh.length}</Eyebrow><ul className="list">{renderRows(fresh)}</ul></section>}
        {talked.length > 0 && <section><Eyebrow>Conversations · {talked.length}</Eyebrow><ul className="list">{renderRows(talked)}</ul></section>}
      </div>
    </aside>
  );
}
