import { useEffect, useEffectEvent, useRef } from "react";
import { describeError } from "../../shared/api/errors";
import { duePasses, nextDueAt, type PendingPass } from "./deck";
import { postSwipe } from "./swipe-client";

// Sends the deferred passes when they fall due, and all of them when the
// member leaves the page (pagehide, unmount) with `keepalive` so the browser
// finishes the requests after the page is gone.

interface Options {
  readonly pending: readonly PendingPass[];
  readonly onSettled: (userIds: readonly number[]) => void;
  readonly onFailure: (message: string) => void;
}

export function usePassQueue({ pending, onSettled, onFailure }: Options): void {
  const latest = useRef(pending);
  const sent = useRef(new Set<number>());
  useEffect(() => { latest.current = pending; }, [pending]);

  const send = useEffectEvent((entries: readonly PendingPass[], keepalive: boolean) => {
    const fresh = entries.filter((entry) => !sent.current.has(entry.card.user_id));
    for (const entry of fresh) sent.current.add(entry.card.user_id);
    if (fresh.length === 0) return;
    onSettled(fresh.map((entry) => entry.card.user_id));
    for (const entry of fresh) {
      postSwipe(entry.card.user_id, "pass", keepalive).catch((error: unknown) => {
        sent.current.delete(entry.card.user_id);
        if (!keepalive) onFailure(describeError(error));
      });
    }
  });

  const next = nextDueAt(pending);
  useEffect(() => {
    if (next === null) return undefined;
    const timer = window.setTimeout(() => send(duePasses(latest.current, Date.now()), false), Math.max(0, next - Date.now()));
    return () => window.clearTimeout(timer);
  }, [next]);

  useEffect(() => {
    const flush = () => send(latest.current, true);
    window.addEventListener("pagehide", flush);
    return () => {
      window.removeEventListener("pagehide", flush);
      flush();
    };
  }, []);
}
