import { hmacBase64Url } from "../../../shared/crypto/signer";

// Per-user secret behind the fixed location offset: HMAC(MEDIA_SIGNING_KEY, "geo:<userId>").
export function locationSeedFor(userId: number): Uint8Array {
  return new Uint8Array(Buffer.from(hmacBase64Url("MEDIA_SIGNING_KEY", `geo:${userId}`), "base64url"));
}
