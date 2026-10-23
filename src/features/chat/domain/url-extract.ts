// The first http(s) link of a text message, the only one a preview is made for.

const MAX_URL_LENGTH = 2048;
const URL_AT = /https?:\/\/[^\s<>"'`]+/i;
const TRAILING = /[.,;:!?)\]}»”’]+$/;

export function firstHttpUrl(text: string): string | null {
  const match = URL_AT.exec(text);
  if (match === null) return null;
  const url = match[0].replace(TRAILING, "");
  return url.length > 0 && url.length <= MAX_URL_LENGTH ? url : null;
}
