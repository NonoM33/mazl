import { useState } from "react";
import { api } from "../../shared/api/client";
import { describeError } from "../../shared/api/errors";
import { useToast } from "../../shared/ui/toast";
import { ReportDialog, type ReportInput } from "./report-dialog";

export type ReportTarget = { readonly kind: "member" } | { readonly kind: "message"; readonly messageId: number };

// Sends a report of the member (POST /api/users/:id/report) or of one message
// (POST /api/messages/:id/report). « Bloquer aussi » is handled by the server.
export function ReportFlow({ target, userId, name, onClose, onBlocked }: {
  readonly target: ReportTarget; readonly userId: number; readonly name: string; readonly onClose: () => void; readonly onBlocked?: () => void;
}) {
  const toast = useToast();
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const submit = async (input: ReportInput) => {
    setBusy(true);
    setError(null);
    try {
      if (target.kind === "message") await api.post(`/api/messages/${target.messageId}/report`, { reason: input.category });
      else await api.post(`/api/users/${userId}/report`, { category: input.category, comment: input.comment, block_user: input.blockUser });
      toast.show("Merci, votre signalement a été transmis.");
      onClose();
      if (target.kind === "member" && input.blockUser) onBlocked?.();
    } catch (cause) {
      setError(describeError(cause));
      setBusy(false);
    }
  };
  return <ReportDialog scope={target.kind} name={name} busy={busy} error={error} onSubmit={(input) => void submit(input)} onClose={onClose} />;
}
