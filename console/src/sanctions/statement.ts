// Aperçu de l'exposé des motifs (DSA, art. 17) montré au modérateur AVANT validation.
// Indicatif : le texte définitif est construit et scellé par le serveur.
import type { DecisionGround, SanctionKind } from "../shared/api/contracts";
import { SANCTION_LABELS } from "../shared/labels";

export const GROUND_TEXT: Readonly<Record<DecisionGround, string>> = {
  minor_on_platform: "Les conditions d'utilisation réservent le service aux personnes majeures.",
  threat_or_violence: "Les conditions d'utilisation interdisent les menaces et les propos violents.",
  sexual_content: "Les conditions d'utilisation interdisent les contenus à caractère sexuel explicite.",
  harassment: "Les conditions d'utilisation interdisent le harcèlement et les comportements insistants.",
  hate_speech: "Les conditions d'utilisation interdisent les propos discriminatoires ou haineux.",
  scam_or_fraud: "Les conditions d'utilisation interdisent les arnaques et toute tentative d'obtenir de l'argent.",
  impersonation: "Les conditions d'utilisation interdisent l'usurpation de l'identité d'autrui.",
  fake_profile: "Les conditions d'utilisation exigent un profil sincère, au nom de son titulaire.",
  commercial_spam: "Les conditions d'utilisation interdisent le démarchage commercial et le spam.",
  off_platform_solicitation: "Les conditions d'utilisation interdisent de pousser les membres vers des services extérieurs à des fins abusives.",
  inappropriate_photo: "Les conditions d'utilisation interdisent les photos inappropriées ou ne vous représentant pas.",
  illegal_content: "Le contenu est contraire à la loi applicable, que les conditions d'utilisation rappellent.",
  other_terms_breach: "Le comportement constaté contrevient aux conditions d'utilisation.",
};

export interface StatementPreview {
  readonly decision: string;
  readonly scope: string;
  readonly facts: string;
  readonly groundText: string;
  readonly automated: string;
  readonly redress: string;
}

const DAY_MS = 86_400_000;

function untilLabel(days: number, now: Date): string {
  const until = new Date(now.getTime() + days * DAY_MS);
  return new Intl.DateTimeFormat("fr-FR", { day: "2-digit", month: "2-digit", year: "numeric" }).format(until);
}

export function scopeOf(kind: SanctionKind, durationDays: number | null, now: Date): string {
  switch (kind) {
    case "warning":
      return "Avertissement : aucune restriction d'accès à votre compte.";
    case "restriction":
      return durationDays === null ? "Fonctionnalités restreintes." : `Fonctionnalités restreintes pendant ${durationDays} jour${durationDays > 1 ? "s" : ""}, jusqu'au ${untilLabel(durationDays, now)}.`;
    case "suspension":
      return durationDays === null ? "Compte suspendu." : `Compte suspendu pendant ${durationDays} jour${durationDays > 1 ? "s" : ""}, jusqu'au ${untilLabel(durationDays, now)}.`;
    case "ban":
      return "Compte définitivement fermé.";
  }
}

export function buildStatementPreview(input: {
  readonly kind: SanctionKind;
  readonly ground: DecisionGround;
  readonly facts: string;
  readonly durationDays: number | null;
  readonly now?: Date;
}): StatementPreview {
  const now = input.now ?? new Date();
  return {
    decision: SANCTION_LABELS[input.kind],
    scope: scopeOf(input.kind, input.durationDays, now),
    facts: input.facts.trim(),
    groundText: GROUND_TEXT[input.ground],
    automated: "Cette décision a été prise par une personne de l'équipe de modération. Aucun outil automatisé n'a décidé.",
    redress:
      "Vous pouvez contester cette décision auprès de MAZL grâce au code de contestation joint, saisir un organisme extrajudiciaire de règlement des litiges, ou former un recours devant un tribunal.",
  };
}
