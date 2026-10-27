import type { MeDto, Permission } from "../shared/api/contracts";

export type SectionId =
  | "tableau-de-bord"
  | "signalements"
  | "membres"
  | "contestations"
  | "verification"
  | "autorites"
  | "algorithme"
  | "offres"
  | "campagnes"
  | "audit"
  | "equipe"
  | "transparence";

export interface SectionDef {
  readonly id: SectionId;
  readonly label: string;
  readonly permission: Permission;
  /** Faux : l'écran affiche l'état « Bientôt ». */
  readonly implemented: boolean;
  readonly description: string;
}

export const SECTIONS: readonly SectionDef[] = [
  { id: "tableau-de-bord", label: "Tableau de bord", permission: "dashboard.read", implemented: true, description: "Vue d'ensemble de la modération." },
  { id: "signalements", label: "Signalements", permission: "reports.read", implemented: true, description: "File priorisée des signalements." },
  { id: "membres", label: "Membres", permission: "members.read", implemented: true, description: "Recherche et fiches des membres." },
  { id: "contestations", label: "Contestations", permission: "appeals.decide", implemented: false, description: "Décisions contestées par les membres (DSA, art. 20)." },
  { id: "verification", label: "Vérification", permission: "verification.review", implemented: false, description: "Dossiers d'identité et de selfie en attente." },
  { id: "autorites", label: "Autorités", permission: "authorities.manage", implemented: false, description: "Réquisitions et demandes des autorités." },
  { id: "algorithme", label: "Algorithme", permission: "matching.read", implemented: true, description: "Réglage et simulation du moteur de rencontres." },
  { id: "offres", label: "Offres", permission: "operations.manage", implemented: true, description: "Prix, ordre et accroches des abonnements et des achats à l'unité." },
  { id: "campagnes", label: "Campagnes", permission: "operations.manage", implemented: true, description: "Campagnes saisonnières : fêtes, remises et icône de l'app." },
  { id: "audit", label: "Journal d'audit", permission: "audit.read", implemented: false, description: "Historique scellé des actions du staff." },
  { id: "equipe", label: "Équipe", permission: "staff.manage", implemented: false, description: "Membres du staff, rôles et second facteur." },
  { id: "transparence", label: "Transparence", permission: "dashboard.read", implemented: false, description: "Chiffres de l'article 15 du DSA." },
];

export function sectionById(id: SectionId): SectionDef {
  const found = SECTIONS.find((section) => section.id === id);
  if (found === undefined) throw new Error(`Section inconnue : ${id}`);
  return found;
}

export function can(me: Pick<MeDto, "permissions">, permission: Permission): boolean {
  return me.permissions.includes(permission);
}

export function visibleSections(me: Pick<MeDto, "permissions">): readonly SectionDef[] {
  return SECTIONS.filter((section) => can(me, section.permission));
}

/** Première section accessible, pour la redirection depuis une adresse refusée. */
export function firstAccessible(me: Pick<MeDto, "permissions">): SectionDef | null {
  return visibleSections(me)[0] ?? null;
}
