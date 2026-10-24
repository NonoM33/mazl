// Données SYNTHÉTIQUES de la maquette : aucune personne réelle, domaine example.com, photos générées.
import type {
  ConversationDto,
  DashboardDto,
  MemberFileDto,
  MemberRefDto,
  ReportDetailDto,
  ReportListItemDto,
  RiskSignal,
  SanctionDto,
} from "../src/shared/api/contracts";
import type { Priority, ReportReason, ReportStatus, SanctionKind } from "../src/shared/api/contracts";

const HOUR = 3_600_000;
const DAY = 24 * HOUR;
export const now = (): number => Date.now();
const iso = (ms: number): string => new Date(ms).toISOString();

const FIRST = ["Jeanne", "Samuel", "Ruth", "David", "Léa", "Noé", "Sarah", "Élie", "Judith", "Raphaël", "Naomi", "Gabriel", "Tamar", "Yoav", "Esther", "Ilan", "Rachel", "Arthur", "Myriam", "Simon"];
const LAST = ["Exemple", "Modèle", "Démo", "Fictif", "Test", "Imaginaire"];
const CITIES = ["Paris", "Lyon", "Marseille", "Strasbourg", "Nice", "Toulouse", "Bordeaux"];

export interface MockMember {
  readonly id: number;
  readonly displayName: string;
  readonly email: string;
  readonly verification: "none" | "selfie" | "identity";
  readonly active: boolean;
  readonly age: number;
  readonly city: string;
  readonly gender: string;
  readonly denomination: string;
  readonly createdAt: string;
  readonly lastActiveAt: string;
  readonly bio: string;
}

export const members: readonly MockMember[] = Array.from({ length: 28 }, (_, index) => {
  const id = 1200 + index * 7;
  const first = FIRST[index % FIRST.length] ?? "Jeanne";
  const last = LAST[index % LAST.length] ?? "Exemple";
  return {
    id,
    displayName: `${first} ${last}`,
    email: `${first.normalize("NFD").replace(/[̀-ͯ]/g, "").toLowerCase()}.${last.normalize("NFD").replace(/[̀-ͯ]/g, "").toLowerCase()}.${id}@example.com`,
    verification: index % 3 === 0 ? "identity" : index % 3 === 1 ? "selfie" : "none",
    active: index % 11 !== 5,
    age: 24 + ((index * 5) % 17),
    city: CITIES[index % CITIES.length] ?? "Paris",
    gender: index % 2 === 0 ? "Femme" : "Homme",
    denomination: ["Traditionnel", "Libéral", "Orthodoxe moderne", "Masorti"][index % 4] ?? "Traditionnel",
    createdAt: iso(now() - (20 + index * 23) * DAY),
    lastActiveAt: iso(now() - (index % 9) * 5 * HOUR),
    bio: "Profil fictif de démonstration. Aime la cuisine du vendredi soir, les randonnées et les longues conversations.",
  };
});

export function memberRef(member: MockMember): MemberRefDto {
  return { id: member.id, displayName: member.displayName, photoUrl: photoUrl(member.id, 0), verification: member.verification, active: member.active };
}

export const photoUrl = (memberId: number, index: number): string => `/mock/photos/${memberId}-${index}.svg`;

/** Silhouette stylisée : aucun visage réel. */
export function silhouetteSvg(seed: number): string {
  const tints = ["#E7E4DF", "#E1E5EA", "#E8E2E5", "#E1E8E4", "#E3E1EA"];
  const bg = tints[seed % tints.length] ?? "#E7E4DF";
  const fg = ["#B9B3AA", "#A9B3BF", "#BDAEB4", "#A9BAB1", "#B1ACC2"][seed % 5] ?? "#B9B3AA";
  return `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 200 200"><rect width="200" height="200" fill="${bg}"/><circle cx="100" cy="78" r="36" fill="${fg}"/><path d="M28 200c4-46 34-70 72-70s68 24 72 70z" fill="${fg}"/></svg>`;
}

const SLA_HOURS: Readonly<Record<Priority, number>> = { P1: 4, P2: 24, P3: 72, P4: 168 };
const REASON_PRIORITY: readonly { readonly reason: ReportReason; readonly priority: Priority }[] = [
  { reason: "harassment", priority: "P2" },
  { reason: "scam", priority: "P2" },
  { reason: "underage", priority: "P1" },
  { reason: "fake_profile", priority: "P3" },
  { reason: "inappropriate_photos", priority: "P3" },
  { reason: "spam", priority: "P4" },
  { reason: "offline_behavior", priority: "P1" },
  { reason: "other", priority: "P4" },
  { reason: "scam", priority: "P3" },
  { reason: "harassment", priority: "P3" },
];

export interface MockReport extends ReportListItemDto {
  readonly details: string;
  readonly decisionNote: string | null;
  readonly handledBy: string | null;
  readonly handledAt: string | null;
}

const DETAILS: Readonly<Record<ReportReason, string>> = {
  harassment: "Cette personne continue de m'écrire alors que j'ai dit clairement que je ne souhaitais pas poursuivre. Les messages s'enchaînent la nuit.",
  scam: "On m'a demandé de l'argent pour un « billet d'avion » après trois jours de conversation, puis de passer sur une autre messagerie.",
  underage: "Le profil affiche 25 ans mais la personne m'a dit être au lycée.",
  fake_profile: "Les photos semblent venir d'un autre compte, et les réponses sont toujours les mêmes.",
  inappropriate_photos: "Photo envoyée sans demande, contenu gênant.",
  spam: "Message publicitaire pour un site extérieur, envoyé à plusieurs personnes.",
  offline_behavior: "Rendez-vous annulé au dernier moment, puis propos agressifs en dehors de l'application.",
  other: "Je préfère en parler directement à l'équipe.",
};

export const reports: MockReport[] = Array.from({ length: 42 }, (_, index) => {
  const pair = REASON_PRIORITY[index % REASON_PRIORITY.length] ?? { reason: "other" as const, priority: "P4" as const };
  const reported = members[(index * 3 + 2) % members.length] ?? members[0];
  if (reported === undefined) throw new Error("members vide");
  const ageHours = 1 + ((index * 37) % 140);
  const createdMs = now() - ageHours * HOUR;
  const dueMs = createdMs + SLA_HOURS[pair.priority] * HOUR;
  const status: ReportStatus = index % 13 === 4 ? "actioned" : index % 17 === 9 ? "dismissed" : index % 5 === 2 ? "in_review" : "pending";
  const open = status === "pending" || status === "in_review";
  return {
    id: 4100 + index,
    createdAt: iso(createdMs),
    reason: pair.reason,
    priority: pair.priority,
    status,
    dueAt: iso(dueMs),
    overdue: open && dueMs < now(),
    assignedTo: status === "in_review" ? (index % 2 === 0 ? "moderation@example.com" : "claire.exemple@example.com") : null,
    reported: memberRef(reported),
    reporterId: index % 9 === 8 ? null : (members[(index * 5 + 1) % members.length]?.id ?? null),
    otherOpenReports: index % 4 === 1 ? 1 + (index % 3) : 0,
    hasMessage: pair.reason === "harassment" || pair.reason === "scam",
    excerpt: DETAILS[pair.reason].slice(0, 140),
    details: DETAILS[pair.reason],
    decisionNote: open ? null : "Dossier examiné, historique vérifié.",
    handledBy: open ? null : "moderation@example.com",
    handledAt: open ? null : iso(now() - 3 * HOUR),
  };
}).sort((a, b) => a.priority.localeCompare(b.priority) || a.dueAt.localeCompare(b.dueAt));

const SIGNALS: Readonly<Record<string, readonly RiskSignal[]>> = {
  scam: [
    { code: "money_request", label: "Demande d'argent", weight: 5, evidence: "Le mot « virement » apparaît dans 2 messages envoyés." },
    { code: "off_platform", label: "Sortie de l'application", weight: 3, evidence: "Invitation à poursuivre sur une messagerie externe dès le 3e message." },
    { code: "new_account", label: "Compte récent", weight: 2, evidence: "Inscrit depuis 4 jours." },
  ],
  harassment: [
    { code: "many_blocks", label: "Blocages multiples", weight: 4, evidence: "Bloqué par 3 membres en 7 jours." },
    { code: "many_reports", label: "Signalements répétés", weight: 3, evidence: "2 autres signalements ouverts." },
  ],
  fake_profile: [
    { code: "copy_paste", label: "Messages identiques", weight: 4, evidence: "Même message d'ouverture envoyé à 14 membres." },
    { code: "no_verification", label: "Aucune vérification", weight: 1, evidence: "Ni selfie ni pièce d'identité." },
  ],
};

function signalsFor(reason: ReportReason): readonly RiskSignal[] {
  return SIGNALS[reason] ?? (reason === "underage" ? [{ code: "no_verification", label: "Aucune vérification", weight: 3, evidence: "Âge déclaré non vérifié." }] : []);
}

const SUGGESTED: Readonly<Partial<Record<ReportReason, SanctionKind>>> = { harassment: "restriction", scam: "suspension", underage: "suspension", spam: "warning", fake_profile: "warning" };

export function sanctionsFor(memberId: number): SanctionDto[] {
  if (memberId % 3 !== 0) return [];
  return [
    {
      id: memberId * 10,
      memberId,
      kind: "warning",
      ground: "harassment",
      startsAt: iso(now() - 40 * DAY),
      endsAt: null,
      decidedBy: "moderation@example.com",
      reportId: 4100,
      revokedAt: null,
      revokedBy: null,
      statement: {
        reference: `EXP-2026-${memberId}`,
        decision: "warning",
        scope: "Avertissement : aucune restriction d'accès à votre compte.",
        facts: "Messages répétés après un refus explicite d'un autre membre.",
        ground: "harassment",
        groundText: "Les conditions d'utilisation interdisent le harcèlement et les comportements insistants.",
        automatedDetection: false,
        automatedDecision: false,
        redress: "Vous pouvez contester cette décision grâce au code joint, saisir un organisme extrajudiciaire ou un tribunal.",
        issuedAt: iso(now() - 40 * DAY),
      },
      appeal: null,
    },
  ];
}

export function reportDetail(report: MockReport): ReportDetailDto {
  const memberId = report.reported.id;
  const history = reports.filter((other) => other.reported.id === memberId && other.id !== report.id);
  return {
    ...report,
    reportedMessage: report.hasMessage
      ? { id: 90_000 + report.id, content: report.reason === "scam" ? "Je dois régler un billet urgent, tu peux me faire un virement ? Je te rembourse dès mon retour." : "Pourquoi tu ne réponds plus ? Réponds-moi, je sais que tu es en ligne.", unsent: false, sentAt: iso(Date.parse(report.createdAt) - 2 * HOUR) }
      : null,
    memberHistory: { reports: history, sanctions: sanctionsFor(memberId), blocksReceived: memberId % 5, accountAgeDays: 6 + (memberId % 300) },
    riskSignals: signalsFor(report.reason),
    suggestedSanction: SUGGESTED[report.reason] ?? null,
  };
}

export function conversationFor(report: MockReport): ConversationDto {
  const reported = members.find((member) => member.id === report.reported.id);
  const other = members[(report.id * 3) % members.length] ?? members[0];
  if (reported === undefined || other === undefined) throw new Error("membres introuvables");
  const lines: readonly [boolean, string][] = [
    [true, "Salut ! Ton profil m'a fait sourire, tu travailles dans quoi ?"],
    [false, "Merci ! Je suis architecte. Et toi ?"],
    [true, "Consultant. On peut se parler ailleurs ? Cette application est lente."],
    [false, "Je préfère rester ici pour l'instant, désolée."],
    [true, report.reason === "scam" ? "Je dois régler un billet urgent, tu peux me faire un virement ? Je te rembourse dès mon retour." : "Pourquoi tu ne réponds plus ? Réponds-moi, je sais que tu es en ligne."],
    [false, "Je ne souhaite pas poursuivre cette conversation."],
  ];
  return {
    conversationId: 7000 + report.id,
    participants: [memberRef(reported), memberRef(other)],
    messages: lines.map(([fromReported, content], index) => ({
      id: 80_000 + report.id * 10 + index,
      senderId: fromReported ? reported.id : other.id,
      type: "text" as const,
      content,
      sentAt: iso(Date.parse(report.createdAt) - (6 - index) * 25 * 60_000),
      unsent: false,
      reported: index === 4,
    })),
  };
}

export function memberFile(member: MockMember): MemberFileDto {
  const received = reports.filter((report) => report.reported.id === member.id);
  const sanctions = sanctionsFor(member.id);
  const first = sanctions[0];
  return {
    member: { ...memberRef(member), email: member.email, createdAt: member.createdAt, lastActiveAt: member.lastActiveAt, age: member.age, city: member.city, gender: member.gender, denomination: member.denomination, photos: [0, 1, 2].map((index) => photoUrl(member.id, index)), bio: member.bio },
    reportsReceived: received,
    reportsMade: member.id % 4,
    sanctions,
    activeSanction: first !== undefined && first.endsAt !== null ? first : null,
    riskSignals: received[0] === undefined ? [] : signalsFor(received[0].reason),
    stats: { matches: 12 + (member.id % 40), blocksReceived: member.id % 5, likesReceived7d: 20 + (member.id % 60) },
  };
}

export function dashboard(): DashboardDto {
  const open = reports.filter((report) => report.status === "pending" || report.status === "in_review");
  const byPriority = { P1: 0, P2: 0, P3: 0, P4: 0 } satisfies Record<Priority, number>;
  for (const report of open) byPriority[report.priority] += 1;
  const daily = Array.from({ length: 30 }, (_, index) => {
    const day = new Date(now() - (29 - index) * DAY);
    const wave = Math.round(6 + 4 * Math.sin(index / 3.2) + (index % 5));
    return { day: day.toISOString().slice(0, 10), received: wave, handled: Math.max(1, wave - 2 + ((index * 7) % 5)) };
  });
  return {
    generatedAt: iso(now() - 4 * 60_000),
    reports: { open: open.length, byPriority, overdue: open.filter((report) => report.overdue).length, receivedLast7d: 47, medianHandlingHours30d: 6.4, daily },
    sanctions30d: { warning: 18, restriction: 9, suspension: 6, ban: 2 },
    appeals: { pending: 3, decided30d: 11, overturnRate30d: 0.18 },
    verification: { pending: 14, verifiedMembers: 1840 },
    members: { total: 5320, new7d: 212, active7d: 3105, matches7d: 640 },
    authorities: { open: 1 },
  };
}
