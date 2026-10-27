// Wording of the pushes: vouvoiement, no emoji, and never the content of a
// message, only the first name of the person it comes from. A like never names
// who sent it: « Voir qui vous a aimé » is a mazl+ benefit, and a lock screen
// is seen by others.

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

export function newLikeText(): PushText {
  return { title: "Quelqu'un vous a remarqué", message: "Une personne a aimé votre profil. Ouvrez MAZL pour en savoir plus." };
}

export function superLikeText(): PushText {
  return { title: "Vous avez reçu un super like", message: "Une personne tient particulièrement à vous rencontrer. Ouvrez MAZL pour en savoir plus." };
}

export function boostEndedText(): PushText {
  return { title: "Votre Boost est terminé", message: "Votre profil n'est plus mis en avant. Vous pouvez relancer un Boost quand vous le souhaitez." };
}

export function scheduledBoostStartedText(): PushText {
  return { title: "Votre Boost a démarré", message: "Votre profil est mis en avant pendant 30 minutes, à l'heure que vous aviez choisie." };
}

export function scheduledBoostMissedText(): PushText {
  return { title: "Votre Boost programmé n'a pas démarré", message: "Il ne vous restait plus de Boost à cette heure. Rien ne vous a été débité." };
}

const EVENT_TITLE_MAX = 80;

export function eventAvailableText(eventTitle: string): PushText {
  const title = eventTitle.trim();
  const shown = title.length > EVENT_TITLE_MAX ? `${title.slice(0, EVENT_TITLE_MAX - 1).trimEnd()}…` : title;
  return { title: "Nouvel événement", message: `« ${shown} » est ouvert. Découvrez-le dans MAZL.` };
}

export function testPushText(): PushText {
  return { title: "Notification de test", message: "Les notifications de MAZL arrivent bien sur cet appareil." };
}
