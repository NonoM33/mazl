import { appealDeadline } from "./appeal-window";
import { GROUND_TEXT } from "./grounds";
import type { DecisionGround, SanctionKind, StatementOfReasons } from "./types";

// Statement of reasons of DSA art. 17, built by the domain from the decision.

export type DecisionOrigin = "member_report" | "staff_initiative" | "automated_detection";

export interface StatementInput {
  readonly reference: string;
  readonly kind: SanctionKind;
  readonly ground: DecisionGround;
  readonly facts: string;
  readonly startsAt: Date;
  readonly endsAt: Date | null;
  readonly origin: DecisionOrigin;
  readonly issuedAt: Date;
}

const DATE_FORMAT = new Intl.DateTimeFormat("fr-FR", {
  timeZone: "Europe/Paris",
  day: "2-digit",
  month: "2-digit",
  year: "numeric",
});

export function formatDate(date: Date): string {
  return DATE_FORMAT.format(date);
}

export function describeScope(kind: SanctionKind, startsAt: Date, endsAt: Date | null): string {
  const from = formatDate(startsAt);
  switch (kind) {
    case "warning":
      return `Avertissement du ${from} : aucune restriction d'accès à votre compte.`;
    case "restriction":
      return endsAt
        ? `Restriction de visibilité depuis le ${from} et jusqu'au ${formatDate(endsAt)} : votre profil n'est plus proposé aux autres membres.`
        : `Restriction de visibilité à compter du ${from} : votre profil n'est plus proposé aux autres membres.`;
    case "suspension":
      return endsAt
        ? `Compte suspendu depuis le ${from} et jusqu'au ${formatDate(endsAt)} : accès impossible pendant cette période.`
        : `Compte suspendu à compter du ${from}.`;
    case "ban":
      return `Compte définitivement fermé à compter du ${from}.`;
  }
}

function describeRedress(reference: string, issuedAt: Date): string {
  const until = formatDate(appealDeadline(issuedAt));
  return [
    `Contestation interne, gratuite, ouverte jusqu'au ${until} (six mois) : indiquez la référence ${reference} et le code de contestation remis avec cette décision, sur le formulaire de contestation du service. Votre demande sera examinée par une personne qui n'a pas pris la décision.`,
    "Règlement extrajudiciaire : vous pouvez saisir un organisme de règlement extrajudiciaire des litiges certifié conformément à l'article 21 du règlement (UE) 2022/2065.",
    "Recours juridictionnel : vous pouvez à tout moment saisir le tribunal compétent.",
  ].join("\n");
}

export function buildStatement(input: StatementInput): StatementOfReasons {
  return {
    reference: input.reference,
    decision: input.kind,
    scope: describeScope(input.kind, input.startsAt, input.endsAt),
    facts: input.facts,
    ground: input.ground,
    groundText: GROUND_TEXT[input.ground],
    automatedDetection: input.origin === "automated_detection",
    automatedDecision: false,
    redress: describeRedress(input.reference, input.issuedAt),
    issuedAt: input.issuedAt.toISOString(),
  };
}
