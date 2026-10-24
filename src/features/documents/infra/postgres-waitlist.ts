import {
  findWaitlistByVerificationToken,
  markVerificationSubmitted,
  setWaitlistOS,
} from "../../../db";
import type { WaitlistPort } from "../application/ports";
import { VERIFICATION_TOKEN_TTL_DAYS } from "../domain/types";

export class PostgresWaitlist implements WaitlistPort {
  async findByVerificationToken(token: string) {
    const row = await findWaitlistByVerificationToken(token, VERIFICATION_TOKEN_TTL_DAYS);
    return row ? { id: row.id, email: row.email, verificationStatus: row.verification_status } : null;
  }
  setOs(waitlistId: number, os: "ios" | "android") {
    return setWaitlistOS(waitlistId, os);
  }
  markSubmitted(waitlistId: number) {
    return markVerificationSubmitted(waitlistId);
  }
}
