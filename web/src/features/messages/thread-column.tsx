import { useCallback, useEffect, useMemo, useRef, useState, type DragEvent } from "react";
import { ArrowDown } from "lucide-react";
import type { ConversationSummary, MessageView } from "../../shared/api/types";
import { displayName, formatTime } from "../../shared/lib/format";
import { useMe } from "../../shared/session";
import { Avatar } from "../../shared/ui/photo";
import { EmptyState, Skeleton } from "../../shared/ui/empty-state";
import { useToast } from "../../shared/ui/toast";
import { MessageBubble, ScamCard, type BubbleHandlers } from "./message-bubble";
import { Composer } from "./composer";
import { ReportFlow, type ReportTarget } from "./report-flow";
import { detectScam, SCAM_EARLY_MESSAGE_COUNT } from "./scam-rules";
import { buildRows, canUnsend, lastSeenMessageId, newestReceivedId, scamCandidates } from "./thread-model";
import { useReadMarker } from "./use-read-marker";
import { useThread, type ReplyTarget } from "./use-thread";
import { useThreadScroll } from "./use-thread-scroll";

// Middle column: header, messages and composer of one conversation.

function TypingDots() {
  return <div className="typing" role="status" aria-label="Écrit…"><span /><span /><span /></div>;
}

export function ThreadColumn({ conversation, conversationId, onRead, onBlocked }: {
  readonly conversation: ConversationSummary | undefined; readonly conversationId: number; readonly onRead: () => void; readonly onBlocked: () => void;
}) {
  const myId = useMe().user.id;
  const toast = useToast();
  const thread = useThread(conversationId, myId);
  const { items } = thread;
  const box = useRef<HTMLDivElement>(null);
  const textRef = useRef<HTMLTextAreaElement>(null);
  const { unseen, onScroll, jumpToBottom } = useThreadScroll(box, items, myId);
  const [reply, setReply] = useState<ReplyTarget | null>(null);
  const [report, setReport] = useState<ReportTarget | null>(null);
  const [timeShownFor, setTimeShownFor] = useState<string | null>(null);
  const [dragging, setDragging] = useState(false);
  const [now, setNow] = useState(() => new Date());
  const otherName = conversation ? displayName(conversation.otherUser.display_name) : "Conversation";
  const otherId = conversation?.otherUser.user_id ?? 0;

  useEffect(() => { const timer = window.setInterval(() => setNow(new Date()), 30_000); return () => window.clearInterval(timer); }, []);
  useReadMarker(conversationId, newestReceivedId(items, myId), onRead);

  const rows = useMemo(() => buildRows(items, now), [items, now]);
  const seenId = lastSeenMessageId(items, myId);
  const flagged = useMemo(() => {
    const ranks = scamCandidates(items, myId, thread.hasMore, SCAM_EARLY_MESSAGE_COUNT);
    return new Set(items.filter((item) => { const rank = ranks.get(item.view.id); return rank !== undefined && detectScam(item.view.content, rank) !== null; }).map((item) => item.view.id));
  }, [items, myId, thread.hasMore]);

  const handlers: BubbleHandlers = useMemo(() => ({
    onReact: thread.react,
    onReply: (view: MessageView) => {
      setReply({ id: view.id, sender_id: view.sender_id, type: view.type, preview: view.content.slice(0, 80) || (view.type === "voice" ? "Message vocal" : "Photo") });
      textRef.current?.focus();
    },
    onCopy: (view: MessageView) => { navigator.clipboard.writeText(view.content).then(() => toast.show("Message copié."), () => toast.show("La copie n'a pas pu se faire.")); },
    onUnsend: thread.unsend,
    onReport: (view: MessageView) => setReport({ kind: "message", messageId: view.id }),
    onRetry: thread.retry,
    onExpired: () => void thread.reload(),
    onToggleTime: (key: string) => setTimeShownFor((current) => (current === key ? null : key)),
  }), [thread, toast]);

  const onScrollTop = useCallback(() => {
    onScroll();
    const element = box.current;
    if (element && element.scrollTop < 80 && thread.hasMore && !thread.loadingOlder) void thread.loadOlder();
  }, [onScroll, thread]);

  const onDrop = (event: DragEvent<HTMLElement>) => {
    event.preventDefault();
    setDragging(false);
    const files = Array.from(event.dataTransfer.files).filter((file) => file.type.startsWith("image/")).slice(0, 10);
    if (files.length > 0) void thread.sendPhotos(files, "", reply).then((ok) => { if (ok) setReply(null); });
  };

  if (thread.status === "not-found") return <section className="thread-col"><EmptyState title="Conversation introuvable">Cette conversation n'existe pas ou n'est plus disponible.</EmptyState></section>;

  const lastMessage = items[items.length - 1];
  return (
    <section className="thread-col" aria-label={`Conversation avec ${otherName}`} data-dragging={dragging}
      onDragOver={(event) => { if (event.dataTransfer.types.includes("Files")) { event.preventDefault(); setDragging(true); } }} onDragLeave={(event) => { if (event.currentTarget === event.target) setDragging(false); }} onDrop={onDrop}>
      <header className="thread-head">
        <Avatar src={conversation?.otherUser.picture} name={otherName} seed={otherId} size={40} />
        <div className="stack">
          <h2 className="title-m">{otherName}</h2>
          <p className="thread-status" data-typing={thread.otherTyping} aria-live="polite">{thread.otherTyping ? "écrit…" : ""}</p>
        </div>
      </header>
      <div ref={box} className="thread-scroll" onScroll={onScrollTop} role="log" aria-label="Messages">
        {thread.status === "loading" && <div className="stack gap-16" style={{ padding: 24 }}><Skeleton height={44} width="55%" /><Skeleton height={44} width="40%" /><Skeleton height={44} width="60%" /></div>}
        {thread.status === "error" && <p className="body-s" style={{ padding: 24 }} role="alert">Les messages n'ont pas pu être chargés. <button type="button" className="link-btn" onClick={() => void thread.reload()}>Réessayer</button></p>}
        {thread.loadingOlder && <p className="eyebrow thread-day">Chargement…</p>}
        {rows.map((row) => row.kind === "day" ? (
          <p key={row.key} className="eyebrow thread-day">{row.label}</p>
        ) : (
          <div key={row.key}>
            <MessageBubble row={row} myId={myId} otherName={otherName} otherSeed={otherId} unsendable={canUnsend(row.item.view, myId, now)} timeShown={timeShownFor === row.key}
              seenLabel={row.item.view.id === seenId && row.item.view.read_at ? `Vu à ${formatTime(row.item.view.read_at)}` : null} highlighted={false} handlers={handlers} />
            {flagged.has(row.item.view.id) && <ScamCard onReport={() => setReport({ kind: "member" })} />}
          </div>
        ))}
        {thread.otherTyping && <TypingDots />}
        {thread.status === "ready" && items.length === 0 && <p className="body-s" style={{ padding: 24, textAlign: "center" }}>Vous avez fait match avec {otherName}. Dites bonjour.</p>}
      </div>
      {unseen > 0 && lastMessage && <button type="button" className="new-pill" onClick={jumpToBottom}>{unseen === 1 ? "1 nouveau message" : `${unseen} nouveaux messages`}<ArrowDown size={14} aria-hidden="true" /></button>}
      {dragging && <div className="drop-veil" aria-hidden="true">Déposez vos photos pour les envoyer</div>}
      <Composer reply={reply ? { target: reply, who: reply.sender_id === myId ? "vous" : otherName.split(" ")[0] ?? otherName } : null} busy={thread.status !== "ready"} textRef={textRef} onTyping={thread.notifyTyping}
        onCancelReply={() => setReply(null)} onSend={(content) => { thread.send(content, reply); setReply(null); }}
        onPhotos={async (files, caption) => { const ok = await thread.sendPhotos(files, caption, reply); if (ok) setReply(null); return ok; }} />
      {report && <ReportFlow target={report} userId={otherId} name={otherName} onClose={() => setReport(null)} onBlocked={onBlocked} />}
    </section>
  );
}
