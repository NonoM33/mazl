// Erreurs de la conciergerie, dites en clair. Le message du serveur complète le code quand il en a un.
import type { ApiResult } from "../shared/api/client";

type Failure = Extract<ApiResult<never>, { readonly ok: false }>;

const KNOWN: Readonly<Record<string, string>> = {
  concierge_not_found: "Cette demande n'existe plus.",
  invalid_transition: "Cette demande a changé entre-temps : l'action n'est plus possible dans son état actuel. Rechargez la demande.",
  concierge_closed: "Cette demande est close ou annulée : on ne peut plus écrire au couple.",
  forbidden: "Votre rôle ne permet pas d'agir sur la conciergerie.",
  invalid_body: "Une valeur envoyée est refusée par le serveur.",
};

export function conciergeErrorMessage(failure: Pick<Failure, "code" | "message">): string {
  const known = KNOWN[failure.code];
  if (known === undefined) return failure.message;
  const detail = failure.message.trim();
  return detail === "" || detail === known ? known : `${known} Détail : ${detail}`;
}
