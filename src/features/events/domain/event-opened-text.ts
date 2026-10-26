import type { PushText } from "../../push/domain/push-texts";

// Wording of the push sent when an event opens: vouvoiement, no emoji, the
// title of the event only.
export function eventOpenedText(title: string): PushText {
  const name = title.trim();
  return {
    title: "Inscriptions ouvertes",
    message: name === "" ? "Un événement que vous suivez est ouvert aux inscriptions." : `« ${name} » est ouvert aux inscriptions.`,
  };
}
