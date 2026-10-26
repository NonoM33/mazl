import { useState } from "react";
import { api } from "../../shared/api/client";
import { ApiError, describeError } from "../../shared/api/errors";
import type { EventRow } from "../../shared/api/types";
import { useToast } from "../../shared/ui/toast";
import { COMING_SOON, isComingSoon, isFull, rsvpErrorMessage } from "./event-format";

type Rsvp = "going" | "interested";

function failureMessage(error: unknown): string {
  return error instanceof ApiError && error.status < 500 && error.status !== 429 ? rsvpErrorMessage(error.code) : describeError(error);
}

// Registers, switches between « going » and « interested », or cancels. The
// server is asked first and the screen follows its answer. A coming soon event
// offers only « Me prévenir » (or withdraws it), registrations stay closed.
export function RsvpPanel({ event, status, onChanged }: { readonly event: EventRow; readonly status: string | null; readonly onChanged: () => Promise<void> }) {
  const [busy, setBusy] = useState(false);
  const toast = useToast();
  const run = async (action: () => Promise<unknown>, done: string) => {
    setBusy(true);
    try {
      await action();
      await onChanged();
      toast.show(done);
    } catch (error) {
      toast.show(failureMessage(error));
      await onChanged();
    } finally {
      setBusy(false);
    }
  };
  const register = (next: Rsvp, done: string) => void run(() => api.post(`/api/events/${event.id}/rsvp`, { status: next }), done);
  const cancel = () => void run(() => api.delete(`/api/events/${event.id}/rsvp`), "Inscription annulée");

  if (isComingSoon(event)) {
    const requested = event.notify_requested === true;
    const toggleAlert = () =>
      void run(
        () => (requested ? api.delete(`/api/events/${event.id}/notify`) : api.post(`/api/events/${event.id}/notify`, {})),
        requested ? "Alerte retirée" : "Nous vous préviendrons à l'ouverture des inscriptions.",
      );
    return (
      <div className="stack gap-12">
        <button type="button" className="btn btn-accent btn-block" disabled>{COMING_SOON}</button>
        <button type="button" className="btn btn-outline btn-block" disabled={busy} aria-pressed={requested} onClick={toggleAlert}>
          {requested ? "Vous serez prévenu" : "Me prévenir"}
        </button>
      </div>
    );
  }
  if (status === "going") {
    return (
      <div className="stack gap-12">
        <p className="body-m" role="status">Vous êtes inscrit(e) à cet événement.</p>
        <button type="button" className="btn btn-outline btn-block" disabled={busy} onClick={cancel}>Annuler mon inscription</button>
      </div>
    );
  }
  const full = isFull(event);
  return (
    <div className="stack gap-12">
      <button type="button" className="btn btn-accent btn-block" disabled={busy || full} onClick={() => register("going", "Inscription confirmée")}>{full ? "Complet" : "Je m'inscris"}</button>
      {status === "interested" ? (
        <button type="button" className="btn btn-ghost btn-block" disabled={busy} onClick={cancel}>Ne plus suivre</button>
      ) : (
        <button type="button" className="btn btn-outline btn-block" disabled={busy} onClick={() => register("interested", "Événement ajouté à votre intérêt")}>Cela m'intéresse</button>
      )}
    </div>
  );
}
