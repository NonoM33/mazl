// The fake events of the TestFlight phase: what testers find in the Events tab.
// All of them are "coming soon" (registrations refused, « Me prévenir » offered),
// in the cities of the test members, in the weeks to come. No picture: the app
// draws the visual of each kind. No real venue nor street: the address is given
// when registrations open.

// The kinds the app knows (mobile EventKind, web event-format).
export type TestEventKind = "shabbat_dinner" | "speed_dating" | "holiday" | "lecture" | "social";

export interface TestEvent {
  // Stable key of the row (events.fixture_key): what makes the seed idempotent and the purge exact.
  readonly key: string;
  readonly title: string;
  readonly description: string;
  readonly kind: TestEventKind;
  readonly city: string;
  readonly venue: string;
  // The event takes place on this weekday (0 = Sunday) of the week that starts `weeksAhead` weeks from today.
  readonly weeksAhead: number;
  readonly weekday: number;
  // A feast has its own date (YYYY-MM-DD), kept while it is to come; the
  // weekday rule applies once it has passed.
  readonly on?: string;
  readonly time: string;
  readonly endTime: string;
  readonly price: number;
  readonly maxAttendees: number;
}

export const TEST_EVENT_ADDRESS = "Adresse communiquée à l'ouverture des inscriptions";

const FRIDAY = 5;
const SUNDAY = 0;
const TUESDAY = 2;
const WEDNESDAY = 3;
const THURSDAY = 4;

export const TEST_EVENTS: readonly TestEvent[] = [
  {
    key: "test-event-shabbat-paris", kind: "shabbat_dinner", city: "Paris", venue: "Paris 17e",
    title: "Dîner de Shabbat des 25-35 ans",
    description: "Un vrai dîner de Shabbat, kiddouch, hallot et chants, autour de grandes tablées où l'on vous place pour faire connaissance. Repas glatt casher, servi à l'assiette. Venez seul, on s'occupe du reste.",
    weeksAhead: 1, weekday: FRIDAY, time: "19:30", endTime: "23:00", price: 35, maxAttendees: 40,
  },
  {
    key: "test-event-speed-lyon", kind: "speed_dating", city: "Lyon", venue: "Lyon 6e",
    title: "Speed dating casher",
    description: "Huit rencontres de sept minutes, un verre offert et une animatrice qui veille à ce que chacun passe une bonne soirée. Les participants sont répartis par tranche d'âge. Buffet casher à la fin pour prolonger les échanges.",
    weeksAhead: 1, weekday: THURSDAY, time: "20:00", endTime: "22:30", price: 20, maxAttendees: 24,
  },
  {
    key: "test-event-lecture-neuilly", kind: "lecture", city: "Neuilly-sur-Seine", venue: "Neuilly-sur-Seine, centre-ville",
    title: "Conférence : l'amour dans le Cantique des Cantiques",
    description: "Que dit le plus poétique des livres de la Bible sur le désir, l'attente et la fidélité ? Une heure d'exposé suivie d'un temps de questions, puis d'un moment convivial autour d'un thé.",
    weeksAhead: 2, weekday: TUESDAY, time: "20:00", endTime: "21:45", price: 0, maxAttendees: 80,
  },
  {
    key: "test-event-hike-marseille", kind: "social", city: "Marseille", venue: "Marseille, départ des calanques",
    title: "Randonnée dans les calanques",
    description: "Une boucle de dix kilomètres, accessible à tous, avec pique-nique casher face à la mer. Prévoir de bonnes chaussures, de l'eau et un chapeau. Covoiturage organisé depuis le centre de Marseille.",
    weeksAhead: 2, weekday: SUNDAY, time: "09:30", endTime: "15:30", price: 0, maxAttendees: 30,
  },
  {
    key: "test-event-cooking-boulogne", kind: "social", city: "Boulogne-Billancourt", venue: "Boulogne-Billancourt, atelier de cuisine",
    title: "Atelier cuisine casher : hallot et houmous maison",
    description: "On pétrit, on tresse et on goûte, par équipes de deux tirées au sort. Un chef vous apprend la hallah tressée à six brins et un houmous comme à Tel-Aviv. Vous repartez avec votre pain pour Shabbat.",
    weeksAhead: 3, weekday: SUNDAY, time: "14:30", endTime: "17:30", price: 30, maxAttendees: 16,
  },
  {
    key: "test-event-shabbat-strasbourg", kind: "shabbat_dinner", city: "Strasbourg", venue: "Strasbourg, quartier de l'Orangerie",
    title: "Shabbat ensemble à Strasbourg",
    description: "Office facultatif, puis dîner de Shabbat traditionnel en petit comité. Une soirée chaleureuse pour rencontrer les célibataires de la région, accueillis par une famille de la communauté.",
    weeksAhead: 3, weekday: FRIDAY, time: "19:00", endTime: "22:30", price: 30, maxAttendees: 30,
  },
  {
    key: "test-event-rooftop-nice", kind: "social", city: "Nice", venue: "Nice, promenade des Anglais",
    title: "Afterwork rencontres sur un toit-terrasse",
    description: "Coucher de soleil sur la baie des Anges, cocktails sans alcool et vins casher, petites bouchées. Un jeu pour briser la glace en début de soirée, puis place aux discussions.",
    weeksAhead: 4, weekday: THURSDAY, time: "19:00", endTime: "22:00", price: 15, maxAttendees: 50,
  },
  {
    key: "test-event-brunch-paris", kind: "speed_dating", city: "Paris", venue: "Paris 11e",
    title: "Brunch rencontres du dimanche",
    description: "Un brunch casher lacté et des tables qui tournent toutes les vingt minutes. L'occasion de rencontrer une quinzaine de personnes dans une ambiance détendue, sans pression.",
    weeksAhead: 4, weekday: SUNDAY, time: "11:00", endTime: "14:00", price: 25, maxAttendees: 40,
  },
  {
    key: "test-event-lecture-lyon", kind: "lecture", city: "Lyon", venue: "Lyon 2e",
    title: "Construire un foyer juif aujourd'hui",
    description: "Un rabbin et un couple marié depuis dix ans échangent sur le Shabbat à deux, la cacheroute au quotidien et la transmission. Questions libres et anonymes, posées sur papier.",
    weeksAhead: 5, weekday: WEDNESDAY, time: "20:00", endTime: "22:00", price: 0, maxAttendees: 60,
  },
  {
    key: "test-event-hanukkah-paris", kind: "holiday", city: "Paris", venue: "Paris 16e",
    title: "Soirée de Hanoukka",
    description: "Allumage des bougies, sufganiyot, latkes et un DJ pour finir la soirée. Une grande fête pour les célibataires de 25 à 40 ans, tenue correcte exigée.",
    // Hanoukka 5787: from the evening of 2026-12-04 to 2026-12-12.
    weeksAhead: 6, weekday: SUNDAY, on: "2026-12-06", time: "19:30", endTime: "23:30", price: 25, maxAttendees: 120,
  },
];

const DAY_MS = 86_400_000;

// The date of an event, YYYY-MM-DD: its own date while it is to come,
// otherwise its weekday in the week that starts `weeksAhead` weeks after
// `today` (UTC). Always in the future.
export function testEventDate(event: TestEvent, today: Date): string {
  if (event.on !== undefined && event.on > today.toISOString().slice(0, 10)) return event.on;
  const start = Date.UTC(today.getUTCFullYear(), today.getUTCMonth(), today.getUTCDate()) + event.weeksAhead * 7 * DAY_MS;
  const shift = (event.weekday - new Date(start).getUTCDay() + 7) % 7;
  return new Date(start + shift * DAY_MS).toISOString().slice(0, 10);
}
