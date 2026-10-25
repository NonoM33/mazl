// Wording of the pushes: vouvoiement, no emoji, and never the content of a
// message, only the first name of the person it comes from.

export interface PushText {
  readonly title: string;
  readonly message: string;
}

export function firstNameOf(displayName: string | null): string | null {
  const first = (displayName ?? "").trim().split(/\s+/)[0] ?? "";
  return first === "" ? null : first;
}

export function newMatchText(otherName: string | null): PushText {
  const name = firstNameOf(otherName);
  return {
    title: "Nouveau match",
    message: name === null ? "Vous avez un nouveau match. Commencez la conversation." : `Vous avez un match avec ${name}. Commencez la conversation.`,
  };
}

export function newMessageText(senderName: string | null): PushText {
  const name = firstNameOf(senderName);
  return {
    title: "Nouveau message",
    message: name === null ? "Vous avez reçu un nouveau message." : `${name} vous a envoyé un message.`,
  };
}
