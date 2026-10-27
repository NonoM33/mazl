import type { ReactElement } from "react";
import { formatStamp } from "./dates";
import type { MessageDto, MessageRole } from "./types";

export const ROLE_LABELS: Readonly<Record<MessageRole, string>> = { member: "Le couple", assistant: "Assistant", staff: "Équipe MAZL" };

/** Le couple à gauche, l'assistant et l'équipe (ce qui part de MAZL) à droite. */
export function Conversation({ messages }: { readonly messages: readonly MessageDto[] }): ReactElement {
  if (messages.length === 0) return <p className="muted">Aucun message dans cette demande.</p>;
  return (
    <ol className="chat" aria-label="Conversation du couple avec l'assistant et l'équipe">
      {messages.map((message) => (
        <li key={message.id} className={`bubble-row${message.role === "member" ? "" : " is-right"}`}>
          <div className={`bubble bubble-${message.role}`}>
            <div className="bubble-meta">
              <span>{ROLE_LABELS[message.role]}</span>
              <time dateTime={message.createdAt}>{formatStamp(message.createdAt)}</time>
            </div>
            <p>{message.text}</p>
          </div>
        </li>
      ))}
    </ol>
  );
}
