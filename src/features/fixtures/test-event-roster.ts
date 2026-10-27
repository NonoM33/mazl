// The fake events of the TestFlight phase: what testers find in the Events tab.
// All of them are "coming soon" (registrations refused, « Me prévenir » offered),
// in the cities of the test members, in the weeks to come. Each has a free Unsplash photo (credit above its entry)
// and the coordinates of its district or city, never a street: the address is
// given when registrations open.
// Coordinates: Geoplateforme geocoder (data.geopf.fr/geocodage, IGN), centre of the
// arrondissement or commune; Marseille = calanque de Sormiou (departure of the walks);
// Strasbourg = boulevard de l'Orangerie; Nice = Promenade des Anglais.

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
  readonly imageUrl: string;
  // District or city centre, degrees (WGS84).
  readonly latitude: number;
  readonly longitude: number;
}

export const TEST_EVENT_ADDRESS = "Adresse communiquée à l'ouverture des inscriptions";

const FRIDAY = 5;
const SUNDAY = 0;
const TUESDAY = 2;
const WEDNESDAY = 3;
const THURSDAY = 4;

export const TEST_EVENTS: readonly TestEvent[] = [
  // Photo: https://unsplash.com/photos/KKTCngYYWFk by David Goldman (Unsplash License).
  {
    key: "test-event-shabbat-paris", kind: "shabbat_dinner", city: "Paris", venue: "Paris 17e",
    title: "Dîner de Shabbat des 25-35 ans",
    description: "Un vrai dîner de Shabbat, kiddouch, hallot et chants, autour de grandes tablées où l'on vous place pour faire connaissance. Repas glatt casher, servi à l'assiette. Venez seul, on s'occupe du reste.",
    weeksAhead: 1, weekday: FRIDAY, time: "19:30", endTime: "23:00", price: 35, maxAttendees: 40,
    imageUrl: "https://images.unsplash.com/photo-1641834948278-449f060477fa?w=1600&q=80&auto=format&fit=crop", latitude: 48.8877, longitude: 2.3048,
  },
  // Photo: https://unsplash.com/photos/Y8gXPB8Mq98 by Frankie Cordoba (Unsplash License).
  {
    key: "test-event-speed-lyon", kind: "speed_dating", city: "Lyon", venue: "Lyon 6e",
    title: "Speed dating casher",
    description: "Huit rencontres de sept minutes, un verre offert et une animatrice qui veille à ce que chacun passe une bonne soirée. Les participants sont répartis par tranche d'âge. Buffet casher à la fin pour prolonger les échanges.",
    weeksAhead: 1, weekday: THURSDAY, time: "20:00", endTime: "22:30", price: 20, maxAttendees: 24,
    imageUrl: "https://images.unsplash.com/photo-1696627958251-775068a8ddbc?w=1600&q=80&auto=format&fit=crop", latitude: 45.7725, longitude: 4.8558,
  },
  // Photo: https://unsplash.com/photos/RDf6Cvns88Q by Vitaly Gariev (Unsplash License).
  {
    key: "test-event-lecture-neuilly", kind: "lecture", city: "Neuilly-sur-Seine", venue: "Neuilly-sur-Seine, centre-ville",
    title: "Conférence : l'amour dans le Cantique des Cantiques",
    description: "Que dit le plus poétique des livres de la Bible sur le désir, l'attente et la fidélité ? Une heure d'exposé suivie d'un temps de questions, puis d'un moment convivial autour d'un thé.",
    weeksAhead: 2, weekday: TUESDAY, time: "20:00", endTime: "21:45", price: 0, maxAttendees: 80,
    imageUrl: "https://images.unsplash.com/photo-1758270704262-ecc82b23dc37?w=1600&q=80&auto=format&fit=crop", latitude: 48.8862, longitude: 2.2659,
  },
  // Photo: https://unsplash.com/photos/ycvDUNFbe5A by Hugo Vidal (Unsplash License).
  {
    key: "test-event-hike-marseille", kind: "social", city: "Marseille", venue: "Marseille, départ des calanques",
    title: "Randonnée dans les calanques",
    description: "Une boucle de dix kilomètres, accessible à tous, avec pique-nique casher face à la mer. Prévoir de bonnes chaussures, de l'eau et un chapeau. Covoiturage organisé depuis le centre de Marseille.",
    weeksAhead: 2, weekday: SUNDAY, time: "09:30", endTime: "15:30", price: 0, maxAttendees: 30,
    imageUrl: "https://images.unsplash.com/photo-1608037580875-df901b196878?w=1600&q=80&auto=format&fit=crop", latitude: 43.2108, longitude: 5.4187,
  },
  // Photo: https://unsplash.com/photos/LDXu5N0W82k by Jing Wang (Unsplash License).
  {
    key: "test-event-cooking-boulogne", kind: "social", city: "Boulogne-Billancourt", venue: "Boulogne-Billancourt, atelier de cuisine",
    title: "Atelier cuisine casher : hallot et houmous maison",
    description: "On pétrit, on tresse et on goûte, par équipes de deux tirées au sort. Un chef vous apprend la hallah tressée à six brins et un houmous comme à Tel-Aviv. Vous repartez avec votre pain pour Shabbat.",
    weeksAhead: 3, weekday: SUNDAY, time: "14:30", endTime: "17:30", price: 30, maxAttendees: 16,
    imageUrl: "https://images.unsplash.com/photo-1775172258063-8f20e384503c?w=1600&q=80&auto=format&fit=crop", latitude: 48.8378, longitude: 2.2432,
  },
  // Photo: https://unsplash.com/photos/qgyyK3QVy9g by menachem weinreb (Unsplash License).
  {
    key: "test-event-shabbat-strasbourg", kind: "shabbat_dinner", city: "Strasbourg", venue: "Strasbourg, quartier de l'Orangerie",
    title: "Shabbat ensemble à Strasbourg",
    description: "Office facultatif, puis dîner de Shabbat traditionnel en petit comité. Une soirée chaleureuse pour rencontrer les célibataires de la région, accueillis par une famille de la communauté.",
    weeksAhead: 3, weekday: FRIDAY, time: "19:00", endTime: "22:30", price: 30, maxAttendees: 30,
    imageUrl: "https://images.unsplash.com/photo-1636983909953-72ab3388d990?w=1600&q=80&auto=format&fit=crop", latitude: 48.5898, longitude: 7.775,
  },
  // Photo: https://unsplash.com/photos/ftQxXRLVwXw by Philipp Hubert (Unsplash License).
  {
    key: "test-event-rooftop-nice", kind: "social", city: "Nice", venue: "Nice, promenade des Anglais",
    title: "Afterwork rencontres sur un toit-terrasse",
    description: "Coucher de soleil sur la baie des Anges, cocktails sans alcool et vins casher, petites bouchées. Un jeu pour briser la glace en début de soirée, puis place aux discussions.",
    weeksAhead: 4, weekday: THURSDAY, time: "19:00", endTime: "22:00", price: 15, maxAttendees: 50,
    imageUrl: "https://images.unsplash.com/photo-1760454477181-4d2d1f7e30ce?w=1600&q=80&auto=format&fit=crop", latitude: 43.686, longitude: 7.2407,
  },
  // Photo: https://unsplash.com/photos/4h9Ffh6aawI by Caramel (Unsplash License).
  {
    key: "test-event-brunch-paris", kind: "speed_dating", city: "Paris", venue: "Paris 11e",
    title: "Brunch rencontres du dimanche",
    description: "Un brunch casher lacté et des tables qui tournent toutes les vingt minutes. L'occasion de rencontrer une quinzaine de personnes dans une ambiance détendue, sans pression.",
    weeksAhead: 4, weekday: SUNDAY, time: "11:00", endTime: "14:00", price: 25, maxAttendees: 40,
    imageUrl: "https://images.unsplash.com/photo-1670710028442-06a2df4bdf85?w=1600&q=80&auto=format&fit=crop", latitude: 48.8602, longitude: 2.3818,
  },
  // Photo: https://unsplash.com/photos/7hxOWrk-8RI by Juli Kosolapova (Unsplash License).
  {
    key: "test-event-lecture-lyon", kind: "lecture", city: "Lyon", venue: "Lyon 2e",
    title: "Construire un foyer juif aujourd'hui",
    description: "Un rabbin et un couple marié depuis dix ans échangent sur le Shabbat à deux, la cacheroute au quotidien et la transmission. Questions libres et anonymes, posées sur papier.",
    weeksAhead: 5, weekday: WEDNESDAY, time: "20:00", endTime: "22:00", price: 0, maxAttendees: 60,
    imageUrl: "https://images.unsplash.com/photo-1638957835514-224c57ffe617?w=1600&q=80&auto=format&fit=crop", latitude: 45.7504, longitude: 4.8261,
  },
  // Photo: https://unsplash.com/photos/BsGQHOuOo0k by Dad Grass (Unsplash License).
  {
    key: "test-event-hanukkah-paris", kind: "holiday", city: "Paris", venue: "Paris 16e",
    title: "Soirée de Hanoukka",
    description: "Allumage des bougies, sufganiyot, latkes et un DJ pour finir la soirée. Une grande fête pour les célibataires de 25 à 40 ans, tenue correcte exigée.",
    // Hanoukka 5787: from the evening of 2026-12-04 to 2026-12-12.
    weeksAhead: 6, weekday: SUNDAY, on: "2026-12-06", time: "19:30", endTime: "23:30", price: 25, maxAttendees: 120,
    imageUrl: "https://images.unsplash.com/photo-1637758961487-bd7e5d163e6d?w=1600&q=80&auto=format&fit=crop", latitude: 48.8563, longitude: 2.267,
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
