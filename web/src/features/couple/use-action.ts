import { useCallback, useState } from "react";
import { describeError } from "../../shared/api/errors";
import { useToast } from "../../shared/ui/toast";

// Runs one write to the API: while it runs the buttons are disabled, a
// failure is told to the member in French, and the screen only changes after
// the server answered.
export function useAction(): { readonly busy: boolean; readonly run: (action: () => Promise<unknown>, options?: { readonly done?: string; readonly after?: () => Promise<void> | void }) => Promise<boolean> } {
  const [busy, setBusy] = useState(false);
  const toast = useToast();
  const run = useCallback(async (action: () => Promise<unknown>, options: { readonly done?: string; readonly after?: () => Promise<void> | void } = {}) => {
    setBusy(true);
    try {
      await action();
      await options.after?.();
      if (options.done) toast.show(options.done);
      return true;
    } catch (error) {
      toast.show(describeError(error));
      return false;
    } finally {
      setBusy(false);
    }
  }, [toast]);
  return { busy, run };
}
