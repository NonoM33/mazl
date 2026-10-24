import { useEffect } from "react";
import { useRouter } from "../../shared/router";
import { useToast } from "../../shared/ui/toast";
import { CHECKOUT_POLL_MAX, CHECKOUT_POLL_MS } from "./premium-model";

// Back from Stripe. The webhook may arrive after the redirect, so on success
// the status is reloaded every 2 s for up to 30 s (until it shows mazl+).
// `reload` must be stable (useResource's is).
export function useCheckoutReturn(reload: () => Promise<void>, active: boolean): void {
  const { location } = useRouter();
  const toast = useToast();
  const result = location.search.get("checkout");

  useEffect(() => {
    if (result === "cancel") toast.show("Paiement annulé");
    if (result === "success") toast.show("Paiement reçu, activation en cours…");
  }, [result, toast]);

  useEffect(() => {
    if (result !== "success" || active) return undefined;
    let ticks = 0;
    const timer = window.setInterval(() => {
      ticks += 1;
      if (ticks > CHECKOUT_POLL_MAX) window.clearInterval(timer);
      else void reload();
    }, CHECKOUT_POLL_MS);
    return () => window.clearInterval(timer);
  }, [result, active, reload]);
}
