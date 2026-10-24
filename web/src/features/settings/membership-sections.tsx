import { api } from "../../shared/api/client";
import type { BillingStatus, VerificationLevel, VerificationStatus } from "../../shared/api/types";
import { useResource } from "../../shared/hooks/use-resource";
import { formatDate } from "../../shared/lib/format";
import { Link } from "../../shared/router";
import { MobileOnly } from "../../shared/ui/mobile-only";
import { VerifiedBadge } from "../../shared/ui/verified-badge";
import { Row, Section } from "./section";

const LEVELS: Readonly<Record<VerificationLevel, string>> = { none: "Non vérifié", photo: "Photo vérifiée", identity: "Identité vérifiée" };

export function VerificationSection() {
  const status = useResource("settings:verification", (signal) => api.get<VerificationStatus>("/api/verification/status", signal), null);
  const level = status.state.data?.level ?? "none";
  return (
    <Section id="verification" title="Vérification" plain>
      {level !== "none" && <div className="card-surface settings-card"><Row title={LEVELS[level]} sub="Le badge s'affiche sur votre profil." action={<VerifiedBadge />} /></div>}
      {level === "none" && <MobileOnly title="Vérifier mon profil">La vérification par selfie ou par pièce d'identité se fait dans l'application MAZL, sur votre téléphone.</MobileOnly>}
    </Section>
  );
}

const SOURCES = { apple: "App Store", stripe: "le site" } as const;

export function PlusSummarySection() {
  const status = useResource("settings:plus", (signal) => api.get<BillingStatus>("/api/billing/status", signal), null);
  const plus = status.state.data?.plus;
  const sub = plus?.active
    ? `Actif via ${plus.source ? SOURCES[plus.source] : "MAZL"}${plus.expires_at ? `, jusqu'au ${formatDate(plus.expires_at)}` : ""}.`
    : "Pas d'abonnement en cours.";
  return (
    <Section id="mazl-plus" title="mazl+">
      <Row title={plus?.active ? "mazl+ est actif" : "mazl+"} sub={status.state.data ? sub : "…"} action={<Link to="/premium" className="btn btn-outline btn-sm">Voir mazl+</Link>} />
    </Section>
  );
}
