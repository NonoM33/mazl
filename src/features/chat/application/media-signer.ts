import { hmacBase64Url, safeEqual } from "../../../shared/crypto/signer";
import { expiryFor, isExpired, parseExpiry } from "../../media/domain/signed-url";

// Signed URLs of chat media, CONTRAT.md §0.2 / §2: HMAC-SHA256 with the same
// MEDIA_SIGNING_KEY as profile photos, over `chat:<id>:<exp>`, valid one hour.
// The prefix keeps a photo signature from ever being valid for a chat file.

export function chatMediaSigningMessage(mediaId: number, exp: number): string {
  return `chat:${mediaId}:${exp}`;
}

function baseUrl(): string {
  return (process.env.PUBLIC_BASE_URL ?? "").replace(/\/+$/, "");
}

function signature(mediaId: number, exp: number): string {
  return hmacBase64Url("MEDIA_SIGNING_KEY", chatMediaSigningMessage(mediaId, exp));
}

export function signChatMediaUrl(mediaId: number, nowMs: number = Date.now()): string {
  const exp = expiryFor(nowMs);
  return `${baseUrl()}/media/chat/${mediaId}?exp=${exp}&sig=${signature(mediaId, exp)}`;
}

export function verifyChatMediaSignature(
  mediaId: number,
  rawExp: string | undefined,
  sig: string | undefined,
  nowMs: number = Date.now(),
): boolean {
  const exp = parseExpiry(rawExp);
  if (exp === null || !sig || isExpired(exp, nowMs)) return false;
  return safeEqual(sig, signature(mediaId, exp));
}
