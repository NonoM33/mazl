import { findMissingRequired } from "../domain/required-documents";
import type { DocumentRepository, WaitlistPort } from "./ports";

export type StatusResult =
  | { kind: "invalid_token" }
  | {
      kind: "ok";
      email: string;
      verificationStatus: string;
      requiredReady: boolean;
      missing: string[];
    };

export type SubmitResult =
  | { kind: "invalid_token" }
  | { kind: "missing_documents"; missing: string[] }
  | { kind: "submitted" };

// The member-facing side of /verify, addressed by the emailed token.
export function createVerificationFlow(deps: { repo: DocumentRepository; waitlist: WaitlistPort }) {
  return {
    async status(token: string): Promise<StatusResult> {
      const entry = await deps.waitlist.findByVerificationToken(token);
      if (!entry) return { kind: "invalid_token" };

      const missing = findMissingRequired(await deps.repo.latestByType(entry.id));
      return {
        kind: "ok",
        email: entry.email,
        verificationStatus: entry.verificationStatus,
        requiredReady: missing.length === 0,
        missing,
      };
    },

    async submit(token: string, os: "ios" | "android" | undefined): Promise<SubmitResult> {
      const entry = await deps.waitlist.findByVerificationToken(token);
      if (!entry) return { kind: "invalid_token" };
      if (os) await deps.waitlist.setOs(entry.id, os);

      const missing = findMissingRequired(await deps.repo.latestByType(entry.id));
      if (missing.length > 0) return { kind: "missing_documents", missing };

      await deps.waitlist.markSubmitted(entry.id);
      return { kind: "submitted" };
    },

    async waitlistIdForToken(token: string): Promise<number | null> {
      return (await deps.waitlist.findByVerificationToken(token))?.id ?? null;
    },
  };
}
