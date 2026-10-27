// Synthetic examples of the couple space API: invented first names, example.com
// addresses, obviously invented identifiers. Never real data.

export const premiumExample = { active: true, paidBy: "partner", renewsAt: "2026-12-01T09:30:00.000Z" } as const;

export const outingExample = {
  id: 4,
  kind: "event",
  title: "Dîner de Shabbat entre couples",
  subtitle: "Paris 17e",
  imageUrl: "https://example.com/images/shabbat-table.jpg",
  city: "Paris",
  startsAt: "2026-11-06T17:30:00.000Z",
  priceCents: 6500,
  kosher: true,
  saved: false,
} as const;

export const activityOutingExample = {
  id: 9,
  kind: "activity",
  title: "Atelier poterie à deux",
  subtitle: "Lyon 2e",
  imageUrl: "https://example.com/images/pottery.jpg",
  city: "Lyon",
  startsAt: null,
  priceCents: 3800,
  kosher: false,
  saved: true,
} as const;

export const todayExample = {
  days: 214,
  partner: { id: 45, name: "David", picture: "https://example.com/photos/partner.jpg" },
  question: { id: 8, text: "Quel est ton moment préféré de la semaine ensemble ?", myAnswered: false, partnerAnswered: true },
  upcoming: [
    { kind: "ritual", title: "Shabbat ensemble", at: "2026-10-30T16:12:00.000Z", subtitle: "shabbat", refId: 1 },
    { kind: "date", title: "Anniversaire de rencontre", at: "2026-11-04T23:00:00.000Z", subtitle: "anniversary", refId: 3 },
  ],
  outing: outingExample,
  mood: { mine: null, partner: "good" },
  checkin: { due: true, period: "2026-11" },
  premium: premiumExample,
} as const;

export const ritualExample = {
  id: 1,
  couple_id: 12,
  kind: "shabbat",
  title: "Shabbat ensemble",
  weekday: 5,
  time: null,
  enabled: true,
  remind_minutes: 60,
} as const;

export const weeklyRitualExample = {
  id: 2,
  couple_id: 12,
  kind: "weekly",
  title: "Soirée sans écran",
  weekday: 2,
  time: "20:00",
  enabled: false,
  remind_minutes: 60,
} as const;

export const checkinOpenExample = { period: "2026-11", mine: null, partnerDone: true, summary: null } as const;
export const checkinDoneExample = {
  period: "2026-11",
  mine: { talk: 4, time: 3, close: 5 },
  partnerDone: true,
  summary: { aligned: 2, lowest: "time", trend: "up" },
} as const;

export const dailyQuestionExample = { id: 8, text: "Quel est ton moment préféré de la semaine ensemble ?", myAnswer: null, partnerAnswer: null } as const;
export const answeredQuestionExample = { id: 8, text: "Quel est ton moment préféré de la semaine ensemble ?", myAnswer: "Le dîner du vendredi.", partnerAnswer: "Nos balades du dimanche." } as const;

export const optionExample = { title: "Table au calme dans le Marais", details: "Restaurant casher avec salle intime, à confirmer par l'équipe.", priceHint: "autour de 80 à 100 euros pour deux, à confirmer" } as const;

export const conciergeRequestExample = {
  id: 31,
  title: "Dîner casher pour notre anniversaire",
  brief: "Dîner casher pour notre anniversaire de couple, vendredi 13 novembre, quelque chose de calme.",
  kind: "table",
  status: "proposed",
  step: 1,
  wantedAt: "2026-11-13",
  city: "Paris",
  constraints: { kosher: true, budget: "100 euros" },
  options: [optionExample],
  chosenIndex: null,
  createdAt: "2026-10-27T10:00:00.000Z",
  updatedAt: "2026-10-27T10:00:05.000Z",
} as const;

export const conciergeMessagesExample = [
  { id: 101, role: "member", text: "Dîner casher pour notre anniversaire de couple, vendredi 13 novembre, quelque chose de calme.", createdAt: "2026-10-27T10:00:00.000Z", mine: true },
  { id: 102, role: "assistant", text: "Voici une idée pour votre anniversaire. L'équipe MAZL pourra vérifier la disponibilité et réserver.", createdAt: "2026-10-27T10:00:05.000Z", mine: false },
] as const;

export const conciergeDetailExample = { request: conciergeRequestExample, messages: conciergeMessagesExample } as const;

export const staffRequestExample = {
  id: 31,
  title: "Dîner casher pour notre anniversaire",
  brief: "Dîner casher pour notre anniversaire de couple, vendredi 13 novembre, quelque chose de calme.",
  status: "chosen",
  wantedAt: "2026-11-13",
  city: "Paris",
  constraints: { kosher: true, budget: "100 euros" },
  options: [optionExample],
  chosenIndex: 0,
  staffNote: null,
  assignedTo: "equipe@example.com",
  createdAt: "2026-10-27T10:00:00.000Z",
  updatedAt: "2026-10-27T10:05:00.000Z",
} as const;

export const staffDetailExample = {
  request: staffRequestExample,
  couple: { firstNames: ["Léa", "David"], months: 7 },
  messages: [
    { id: 101, role: "member", authorId: 12, text: "Dîner casher pour notre anniversaire de couple, vendredi 13 novembre.", createdAt: "2026-10-27T10:00:00.000Z" },
    { id: 102, role: "assistant", authorId: null, text: "Voici une idée pour votre anniversaire.", createdAt: "2026-10-27T10:00:05.000Z" },
  ],
} as const;

export const staffListExample = {
  requests: [
    { id: 31, title: "Dîner casher pour notre anniversaire", status: "chosen", wantedAt: "2026-11-13", updatedAt: "2026-10-27T10:05:00.000Z", step: 2, assignedTo: "equipe@example.com", couple: { firstNames: ["Léa", "David"], months: 7 } },
  ],
} as const;

export const staffMembersExample = { staff: [{ email: "equipe@example.com", name: "Équipe Exemple" }] } as const;
