import { createHmac } from "node:crypto";
import type { Pseudonymizer } from "../application/ports";

const MIN_KEY_LENGTH = 32;
const PSEUDONYM_LENGTH = 32;

// HMAC-SHA256 of the member id under ANALYTICS_ID_KEY: stable for one member,
// impossible to turn back into the id without the key.
export class HmacPseudonymizer implements Pseudonymizer {
  constructor(private readonly key: string) {
    if (key.length < MIN_KEY_LENGTH) throw new Error(`ANALYTICS_ID_KEY must be at least ${MIN_KEY_LENGTH} characters`);
  }

  profileIdOf(userId: number): string {
    return createHmac("sha256", this.key).update(`member:${userId}`).digest("hex").slice(0, PSEUDONYM_LENGTH);
  }
}
