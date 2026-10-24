import { createHmac, timingSafeEqual } from "node:crypto";
import { getKey, type KeyName } from "./keys";

// Keyed HMAC-SHA256, used for two different jobs with two different keys:
//  - MEDIA_SIGNING_KEY: short-lived signed photo URLs;
//  - DOC_FINGERPRINT_KEY: pseudonymous identity-document fingerprints (one
//    document = one account, banned documents stay banned) without storing the
//    document number itself.

export function hmacHex(keyName: KeyName, message: string): string {
  return createHmac("sha256", getKey(keyName)).update(message, "utf8").digest("hex");
}

export function hmacBase64Url(keyName: KeyName, message: string): string {
  return createHmac("sha256", getKey(keyName)).update(message, "utf8").digest("base64url");
}

export function safeEqual(a: string, b: string): boolean {
  const left = Buffer.from(a, "utf8");
  const right = Buffer.from(b, "utf8");
  return left.length === right.length && timingSafeEqual(left, right);
}
