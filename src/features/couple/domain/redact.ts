// Defence in depth for what leaves for the assistant: members may type their
// own e-mail or phone number in a request. They are masked before sending.

const EMAIL = /[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}/g;
// Seven digits or more, with the separators people use, optionally +country code.
const PHONE = /(?:\+|00)?\d(?:[\s.\-()]?\d){6,}/g;
const URL_LIKE = /https?:\/\/\S+/g;

export const MASK = "[masqué]";

export function redactPersonalData(text: string): string {
  return text.replace(EMAIL, MASK).replace(URL_LIKE, MASK).replace(PHONE, MASK);
}
