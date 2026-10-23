import type { DecisionStatus } from "../domain/types";
import type { DocumentRepository } from "./ports";
import type { Purger } from "./purge-documents";

// Every admin decision on a document is followed by the purge of the decided
// files, in the same use case, so no route can decide without purging.
export function createReviewDocuments(deps: { repo: DocumentRepository; purger: Purger }) {
  const { repo, purger } = deps;

  return {
    async approveDocument(documentId: number): Promise<void> {
      await repo.decide({ ids: [documentId], status: "approved", notes: null });
      await purger.purgeDecided({ ids: [documentId] });
    },

    async rejectDocument(documentId: number, notes: string | null): Promise<void> {
      await repo.decide({ ids: [documentId], status: "rejected", notes });
      await purger.purgeDecided({ ids: [documentId] });
    },

    async reviewBulk(params: {
      waitlistId: number;
      documentIds: readonly number[];
      status: DecisionStatus;
      notes?: string;
    }): Promise<void> {
      if (params.documentIds.length === 0) return;
      await repo.decide({
        ids: params.documentIds,
        waitlistId: params.waitlistId,
        status: params.status,
        notes: params.notes ?? null,
      });
      await purger.purgeDecided({ ids: params.documentIds });
    },

    async approveAllForWaitlist(waitlistId: number): Promise<void> {
      await repo.approveAllNotRejected(waitlistId);
      await purger.purgeDecided({ waitlistId });
    },

    async rejectAllForWaitlist(waitlistId: number, notes: string | null): Promise<void> {
      await repo.rejectAll(waitlistId, notes);
      await purger.purgeDecided({ waitlistId });
    },
  };
}

export type ReviewDocuments = ReturnType<typeof createReviewDocuments>;
