// Libellés français du vocabulaire de la confiance & sécurité.
import type { DecisionGround, Priority, ReportReason, ReportStatus, SanctionKind } from "./api/contracts";

export const REASON_LABELS: Readonly<Record<ReportReason, string>> = {
  underage: "Mineur présumé",
  offline_behavior: "Comportement hors application",
  harassment: "Harcèlement",
  scam: "Arnaque",
  fake_profile: "Faux profil",
  inappropriate_photos: "Photos inappropriées",
  spam: "Spam",
  other: "Autre motif",
};

export const REASON_ORDER: readonly ReportReason[] = [
  "underage",
  "offline_behavior",
  "harassment",
  "scam",
  "fake_profile",
  "inappropriate_photos",
  "spam",
  "other",
];

export const PRIORITY_LABELS: Readonly<Record<Priority, string>> = {
  P1: "P1 · Urgente",
  P2: "P2 · Haute",
  P3: "P3 · Normale",
  P4: "P4 · Basse",
};

export const PRIORITY_ORDER: readonly Priority[] = ["P1", "P2", "P3", "P4"];

export const STATUS_LABELS: Readonly<Record<ReportStatus, string>> = {
  pending: "En attente",
  in_review: "En cours",
  actioned: "Sanctionné",
  dismissed: "Classé sans suite",
};

export const STATUS_ORDER: readonly ReportStatus[] = ["pending", "in_review", "actioned", "dismissed"];

export const SANCTION_LABELS: Readonly<Record<SanctionKind, string>> = {
  warning: "Avertissement",
  restriction: "Restriction",
  suspension: "Suspension",
  ban: "Bannissement",
};

export const SANCTION_ORDER: readonly SanctionKind[] = ["warning", "restriction", "suspension", "ban"];

export const GROUND_LABELS: Readonly<Record<DecisionGround, string>> = {
  minor_on_platform: "Présence d'un mineur",
  threat_or_violence: "Menaces ou violence",
  sexual_content: "Contenu sexuel",
  harassment: "Harcèlement",
  hate_speech: "Propos haineux",
  scam_or_fraud: "Arnaque ou fraude",
  impersonation: "Usurpation d'identité",
  fake_profile: "Faux profil",
  commercial_spam: "Démarchage commercial",
  off_platform_solicitation: "Sollicitation hors application",
  inappropriate_photo: "Photo inappropriée",
  illegal_content: "Contenu illicite",
  other_terms_breach: "Autre manquement aux conditions",
};

export const GROUND_ORDER: readonly DecisionGround[] = [
  "minor_on_platform",
  "threat_or_violence",
  "sexual_content",
  "harassment",
  "hate_speech",
  "scam_or_fraud",
  "impersonation",
  "fake_profile",
  "commercial_spam",
  "off_platform_solicitation",
  "inappropriate_photo",
  "illegal_content",
  "other_terms_breach",
];

export const VERIFICATION_LABELS = {
  none: "Non vérifié",
  selfie: "Selfie vérifié",
  identity: "Identité vérifiée",
} as const;
