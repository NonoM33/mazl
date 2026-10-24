import { ShieldAlert } from "lucide-react";
import type { MessageView } from "../../shared/api/types";
import { formatTime } from "../../shared/lib/format";
import { LinkPreviewCard, PhotoGrid, VoicePlayer } from "./chat-media";
import { MessageActions } from "./message-actions";
import type { ThreadRow } from "./thread-model";

type MessageRow = Extract<ThreadRow, { kind: "message" }>;

export interface BubbleHandlers {
  readonly onReact: (view: MessageView, emoji: string) => void;
  readonly onReply: (view: MessageView) => void;
  readonly onCopy: (view: MessageView) => void;
  readonly onUnsend: (view: MessageView) => void;
  readonly onReport: (view: MessageView) => void;
  readonly onRetry: (clientId: string) => void;
  readonly onExpired: () => void;
  readonly onToggleTime: (key: string) => void;
}

interface BubbleProps {
  readonly row: MessageRow;
  readonly myId: number;
  readonly otherName: string;
  readonly otherSeed: number;
  readonly unsendable: boolean;
  readonly timeShown: boolean;
  readonly seenLabel: string | null;
  readonly highlighted: boolean;
  readonly handlers: BubbleHandlers;
}

const REACTION_ARIA = (reactions: MessageView["reactions"]): string => reactions.map((reaction) => `${reaction.emoji} ${reaction.user_ids.length}`).join(", ");

function Reactions({ reactions, myId }: { readonly reactions: MessageView["reactions"]; readonly myId: number }) {
  if (reactions.length === 0) return null;
  const total = reactions.reduce((sum, reaction) => sum + reaction.user_ids.length, 0);
  const mine = reactions.some((reaction) => reaction.user_ids.includes(myId));
  return (
    <span className="reaction-pill" data-mine={mine} role="img" aria-label={`Réactions : ${REACTION_ARIA(reactions)}`}>
      {reactions.slice(0, 3).map((reaction) => <span key={reaction.emoji} aria-hidden="true">{reaction.emoji}</span>)}
      {total > 1 && <span className="reaction-total" aria-hidden="true">{total}</span>}
    </span>
  );
}

function Quote({ reply, myId, otherName }: { readonly reply: NonNullable<MessageView["reply_to"]>; readonly myId: number; readonly otherName: string }) {
  return (
    <span className="bubble-quote">
      <span className="bubble-quote-who">{reply.sender_id === myId ? "Vous" : otherName.split(" ")[0]}</span>
      <span className="bubble-quote-text">{reply.preview}</span>
    </span>
  );
}

function Body({ view, mine, myId, otherName, otherSeed, onExpired }: { readonly view: MessageView; readonly mine: boolean; readonly myId: number; readonly otherName: string; readonly otherSeed: number; readonly onExpired: () => void }) {
  if (view.unsent) return <span className="bubble-unsent">Message retiré</span>;
  return (
    <>
      {view.reply_to && <Quote reply={view.reply_to} myId={myId} otherName={otherName} />}
      {view.media.length > 0 && <PhotoGrid media={view.media} mine={mine} name={otherName} seed={otherSeed} onExpired={onExpired} />}
      {view.voice && <VoicePlayer voice={view.voice} />}
      {view.content.length > 0 && <span className="bubble-text">{view.content}</span>}
      {view.link_preview && <LinkPreviewCard preview={view.link_preview} seed={view.id} />}
    </>
  );
}

export function MessageBubble({ row, myId, otherName, otherSeed, unsendable, timeShown, seenLabel, highlighted, handlers }: BubbleProps) {
  const { view } = row.item;
  const state = row.item.state;
  const mine = view.sender_id === myId;
  const key = row.key;
  const bare = !view.unsent && view.media.length > 0 && view.content.length === 0 && !view.reply_to;
  return (
    <div className="msg" data-mine={mine} data-position={row.position} data-new-group={row.newGroup} data-id={view.id} data-highlight={highlighted}>
      <div className="msg-line">
        <div className="bubble-wrap">
          <div className="bubble" data-sending={state === "sending"} data-bare={bare} data-unsent={view.unsent} onClick={() => handlers.onToggleTime(key)}>
            <Body view={view} mine={mine} myId={myId} otherName={otherName} otherSeed={otherSeed} onExpired={handlers.onExpired} />
          </div>
          {!view.unsent && state === "sent" && (
            <MessageActions view={view} mine={mine} canUnsend={unsendable} myId={myId} onReact={(emoji) => handlers.onReact(view, emoji)} onReply={() => handlers.onReply(view)}
              onCopy={() => handlers.onCopy(view)} onUnsend={() => handlers.onUnsend(view)} onReport={() => handlers.onReport(view)} />
          )}
          <Reactions reactions={view.reactions} myId={myId} />
        </div>
      </div>
      {state === "failed" && view.client_id && (
        <p className="msg-meta msg-failed">Échec · <button type="button" onClick={() => handlers.onRetry(view.client_id ?? "")}>Réessayer</button></p>
      )}
      {state !== "failed" && (row.lastOfGroup || timeShown) && <p className="msg-meta" data-reveal={timeShown && !row.lastOfGroup}>{state === "sending" ? "Envoi…" : formatTime(view.created_at)}</p>}
      {seenLabel && <p className="msg-meta msg-seen">{seenLabel}</p>}
    </div>
  );
}

export function ScamCard({ onReport }: { readonly onReport: () => void }) {
  return (
    <div className="scam-card" role="note">
      <ShieldAlert size={20} aria-hidden="true" />
      <div className="scam-card-body">
        <p className="scam-card-title">Restez prudent</p>
        <p className="scam-card-text">Ne transférez jamais d'argent à quelqu'un que vous n'avez pas rencontré.</p>
        <button type="button" className="scam-card-link" onClick={onReport}>Signaler</button>
      </div>
    </div>
  );
}
