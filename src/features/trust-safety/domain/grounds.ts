import type { DecisionGround, ReportReason } from "./types";

// Clauses of the terms of use cited in the statement of reasons (DSA art. 17).
// Sober, in French, without any detail about the facts.
export const GROUND_TEXT: Readonly<Record<DecisionGround, string>> = {
  minor_on_platform:
    "Conditions générales d'utilisation, article « Conditions d'accès » : le service est réservé aux personnes majeures.",
  threat_or_violence:
    "Conditions générales d'utilisation, article « Comportements interdits » : menaces, violences ou mise en danger d'autrui.",
  sexual_content:
    "Conditions générales d'utilisation, article « Contenus interdits » : contenus à caractère sexuel explicite ou non sollicité.",
  harassment:
    "Conditions générales d'utilisation, article « Comportements interdits » : harcèlement, insultes ou pressions envers d'autres membres.",
  hate_speech:
    "Conditions générales d'utilisation, article « Contenus interdits » : propos haineux ou discriminatoires.",
  scam_or_fraud:
    "Conditions générales d'utilisation, article « Comportements interdits » : escroquerie, demande d'argent ou tentative de fraude.",
  impersonation:
    "Conditions générales d'utilisation, article « Identité » : usurpation de l'identité d'une autre personne.",
  fake_profile:
    "Conditions générales d'utilisation, article « Identité » : profil comportant des informations fausses ou trompeuses.",
  commercial_spam:
    "Conditions générales d'utilisation, article « Comportements interdits » : sollicitation commerciale ou messages répétitifs non sollicités.",
  off_platform_solicitation:
    "Conditions générales d'utilisation, article « Comportements interdits » : incitation à quitter le service dans un but frauduleux ou abusif.",
  inappropriate_photo:
    "Conditions générales d'utilisation, article « Contenus interdits » : photographie inappropriée ou ne respectant pas les règles de publication.",
  illegal_content:
    "Conditions générales d'utilisation, article « Contenus interdits » : contenu manifestement illicite au regard de la loi française.",
  other_terms_breach:
    "Conditions générales d'utilisation : manquement à une autre obligation du membre.",
};

// The ground a moderator most likely picks for a report reason (a hint only).
export const DEFAULT_GROUND_FOR_REASON: Readonly<Record<ReportReason, DecisionGround>> = {
  underage: "minor_on_platform",
  offline_behavior: "threat_or_violence",
  harassment: "harassment",
  scam: "scam_or_fraud",
  fake_profile: "fake_profile",
  inappropriate_photos: "inappropriate_photo",
  spam: "commercial_spam",
  other: "other_terms_breach",
};
