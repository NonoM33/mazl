// The fake outings of the couple space during the TestFlight phase: 12 activities and 6 events,
// in the cities of the test members. Each entry has a free Unsplash photo (credit above it,
// Unsplash License, never Unsplash+). Coordinates are those of the district or the commune,
// never a street: the venues are fictional or generic.

export type CoupleActivityCategory =
  | "wellness" | "gastronomy" | "culture" | "sport" | "romantic" | "travel" | "spiritual" | "diy";

export interface CoupleActivityFixture {
  // Stable key of the row: what makes the seed idempotent and the purge exact.
  readonly key: string;
  readonly title: string;
  readonly description: string;
  readonly category: CoupleActivityCategory;
  readonly subcategory?: string;
  readonly city: string;
  readonly location: string;
  readonly latitude: number;
  readonly longitude: number;
  readonly priceCents: number;
  readonly durationMinutes: number;
  readonly isKosher: boolean;
  readonly tags: readonly string[];
  readonly imageUrl: string;
}

export interface CoupleEventFixture {
  readonly key: string;
  readonly title: string;
  readonly description: string;
  readonly category: string;
  readonly city: string;
  readonly location: string;
  readonly latitude: number;
  readonly longitude: number;
  readonly priceCents: number;
  readonly maxCouples: number;
  readonly isKosher: boolean;
  readonly dressCode?: string;
  readonly whatIncluded?: string;
  readonly isFeatured: boolean;
  // The event takes place on this weekday (0 = Sunday) of the week that starts `weeksAhead` weeks from today.
  readonly weeksAhead: number;
  readonly weekday: number;
  readonly time: string;
  readonly endTime: string;
  readonly imageUrl: string;
}

const SUNDAY = 0;
const FRIDAY = 5;
const SATURDAY = 6;
const THURSDAY = 4;

export const COUPLE_ACTIVITY_FIXTURES: readonly CoupleActivityFixture[] = [
  // Photo: https://unsplash.com/photos/LuPV3cVEQmA by phoebe lynch (Unsplash License).
  {
    key: "test-couple-activity-spa-paris", title: "Bains et massage en duo", category: "wellness", subcategory: "spa",
    description: "Une parenthèse à deux : bain bouillonnant, hammam puis massage relaxant côte à côte. Peignoirs et tisane fournis.",
    city: "Paris", location: "Spa du Passage, Paris 9e", latitude: 48.8772, longitude: 2.3376,
    priceCents: 16000, durationMinutes: 120, isKosher: false, tags: ["spa", "duo", "détente", "massage"],
    imageUrl: "https://images.unsplash.com/photo-1620733723572-11c53f73a416?w=1600&q=80&auto=format&fit=crop",
  },
  // Photo: https://unsplash.com/photos/46B9jBPhoUo by Tómas Rekstad (Unsplash License).
  {
    key: "test-couple-activity-dinner-paris", title: "Dîner casher aux chandelles", category: "gastronomy", subcategory: "restaurant",
    description: "Une table dressée pour deux, des bougies et un menu de saison sous surveillance rabbinique. Une soirée simple et chaleureuse.",
    city: "Paris", location: "Table de Rachel, Paris 4e", latitude: 48.8566, longitude: 2.3622,
    priceCents: 9000, durationMinutes: 120, isKosher: true, tags: ["dîner", "casher", "romantique"],
    imageUrl: "https://images.unsplash.com/photo-1758705477547-1070b9fac15d?w=1600&q=80&auto=format&fit=crop",
  },
  // Photo: https://unsplash.com/photos/B-dgq-DrmbU by Maxime Gilbert (Unsplash License).
  {
    key: "test-couple-activity-cruise-paris", title: "Croisière sur la Seine au coucher du soleil", category: "romantic", subcategory: "cruise",
    description: "Une heure et demie sur l'eau, de l'île de la Cité aux quais éclairés. Une façon douce de voir Paris autrement, à deux.",
    city: "Paris", location: "Embarcadère de la Cité, Paris 4e", latitude: 48.8546, longitude: 2.347,
    priceCents: 4500, durationMinutes: 90, isKosher: false, tags: ["croisière", "Seine", "coucher de soleil"],
    imageUrl: "https://images.unsplash.com/photo-1661681241250-ffd062ad125f?w=1600&q=80&auto=format&fit=crop",
  },
  // Photo: https://unsplash.com/photos/OmaFZNYOy6E by Zachary Keimig (Unsplash License).
  {
    key: "test-couple-activity-escape-paris", title: "Escape game romantique : la lettre perdue", category: "culture", subcategory: "game",
    description: "Une enquête à deux dans un appartement des années folles, énigmes à résoudre en soixante minutes. Complicité garantie, fou rire probable.",
    city: "Paris", location: "Salle Le Grenier, Paris 11e", latitude: 48.8602, longitude: 2.3818,
    priceCents: 5000, durationMinutes: 60, isKosher: false, tags: ["escape game", "jeu", "duo"],
    imageUrl: "https://images.unsplash.com/photo-1569002925653-ed18f55d7292?w=1600&q=80&auto=format&fit=crop",
  },
  // Photo: https://unsplash.com/photos/8cxuRk9N0Ns by Kwami Fattah Al Sissi (Unsplash License).
  {
    key: "test-couple-activity-cooking-lyon", title: "Cours de cuisine casher à quatre mains", category: "gastronomy", subcategory: "cooking",
    description: "Un chef vous guide pour préparer un repas complet, entrée, plat et dessert. Vous dégustez ensemble ce que vous avez cuisiné.",
    city: "Lyon", location: "Atelier des Saveurs, Lyon 6e", latitude: 45.7725, longitude: 4.8558,
    priceCents: 8500, durationMinutes: 180, isKosher: true, tags: ["cuisine", "casher", "atelier"],
    imageUrl: "https://images.unsplash.com/photo-1763570645098-371723617ee9?w=1600&q=80&auto=format&fit=crop",
  },
  // Photo: https://unsplash.com/photos/ZSgWcW70cTs by Taylor Heery (Unsplash License).
  {
    key: "test-couple-activity-pottery-lyon", title: "Atelier poterie pour deux", category: "diy", subcategory: "pottery",
    description: "Façonnez un bol ou un vase au tour, côte à côte. Votre création est cuite puis vous est remise quelques semaines plus tard.",
    city: "Lyon", location: "Atelier de la Croix-Rousse, Lyon 4e", latitude: 45.7747, longitude: 4.8317,
    priceCents: 3500, durationMinutes: 120, isKosher: false, tags: ["poterie", "créatif", "atelier"],
    imageUrl: "https://images.unsplash.com/photo-1595351298020-038700609878?w=1600&q=80&auto=format&fit=crop",
  },
  // Photo: https://unsplash.com/photos/GeFlT1yelTc by Laura Ollier (Unsplash License).
  {
    key: "test-couple-activity-calanques-marseille", title: "Balade guidée dans les calanques", category: "sport", subcategory: "hiking",
    description: "Une boucle accessible entre pins et falaises blanches, avec une pause baignade si la mer s'y prête. Prévoir de bonnes chaussures.",
    city: "Marseille", location: "Départ des calanques, Marseille 9e", latitude: 43.2108, longitude: 5.4187,
    priceCents: 2500, durationMinutes: 240, isKosher: false, tags: ["randonnée", "mer", "nature"],
    imageUrl: "https://images.unsplash.com/photo-1626954488567-a4948d6d648b?w=1600&q=80&auto=format&fit=crop",
  },
  // Photo: https://unsplash.com/photos/j1egA73qp7c by Katherine McCormack (Unsplash License).
  {
    key: "test-couple-activity-sailing-marseille", title: "Sortie en voilier au coucher du soleil", category: "travel", subcategory: "sailing",
    description: "Deux heures en mer face à la rade, un skipper à la barre et un apéritif à bord. La lumière du soir fait le reste.",
    city: "Marseille", location: "Vieux-Port, Marseille 1er", latitude: 43.2951, longitude: 5.3739,
    priceCents: 7500, durationMinutes: 120, isKosher: false, tags: ["voile", "mer", "romantique"],
    imageUrl: "https://images.unsplash.com/photo-1444487233259-dae9d907a740?w=1600&q=80&auto=format&fit=crop",
  },
  // Photo: https://unsplash.com/photos/2rsK_rdiDJ8 by Nick Karvounis (Unsplash License).
  {
    key: "test-couple-activity-tour-nice", title: "Visite guidée du Vieux-Nice", category: "culture", subcategory: "tour",
    description: "Ruelles colorées, marché aux fleurs et histoire de la communauté niçoise racontées par un guide passionné.",
    city: "Nice", location: "Vieux-Nice", latitude: 43.6961, longitude: 7.2755,
    priceCents: 1800, durationMinutes: 90, isKosher: false, tags: ["visite", "histoire", "balade"],
    imageUrl: "https://images.unsplash.com/photo-1491166617655-0723a0999cfc?w=1600&q=80&auto=format&fit=crop",
  },
  // Photo: https://unsplash.com/photos/H4XpA8JSYuQ by phoebe lynch (Unsplash License).
  {
    key: "test-couple-activity-wine-nice", title: "Dégustation de vins casher en duo", category: "gastronomy", subcategory: "wine",
    description: "Cinq vins casher de France et d'Israël présentés par un sommelier, avec de petites bouchées pour accompagner chaque verre.",
    city: "Nice", location: "Cave du Port, Nice", latitude: 43.6955, longitude: 7.285,
    priceCents: 6000, durationMinutes: 90, isKosher: true, tags: ["vin", "casher", "dégustation"],
    imageUrl: "https://images.unsplash.com/photo-1768497262022-2afdf6b1266f?w=1600&q=80&auto=format&fit=crop",
  },
  // Photo: https://unsplash.com/photos/-v3X-8oDgUo by Steve Sharp (Unsplash License).
  {
    key: "test-couple-activity-boat-strasbourg", title: "Promenade en bateau sur les canaux", category: "romantic", subcategory: "boat",
    description: "Glissez entre les maisons à colombages de la Petite France, écluses et ponts tournants à l'appui. Une heure de calme à deux.",
    city: "Strasbourg", location: "Petite France, Strasbourg", latitude: 48.58, longitude: 7.7425,
    priceCents: 1500, durationMinutes: 70, isKosher: false, tags: ["bateau", "canaux", "balade"],
    imageUrl: "https://images.unsplash.com/photo-1779479598719-8f150c28544c?w=1600&q=80&auto=format&fit=crop",
  },
  // Photo: https://unsplash.com/photos/NEEzl9lxUSg by Eliezer Muller (Unsplash License).
  {
    key: "test-couple-activity-shabbat-strasbourg", title: "Shabbat en couple chez l'habitant", category: "spiritual", subcategory: "shabbat",
    description: "Une famille de la communauté vous reçoit pour le dîner de Shabbat : bougies, kiddouch et chants. Repas glatt casher.",
    city: "Strasbourg", location: "Quartier de l'Orangerie, Strasbourg", latitude: 48.5898, longitude: 7.775,
    priceCents: 3000, durationMinutes: 180, isKosher: true, tags: ["Shabbat", "famille", "casher"],
    imageUrl: "https://images.unsplash.com/photo-1735867553479-2678a73add09?w=1600&q=80&auto=format&fit=crop",
  },
];

export const COUPLE_EVENT_FIXTURES: readonly CoupleEventFixture[] = [
  // Photo: https://unsplash.com/photos/XgYb1OXCDG8 by Tetiana Thiel (Unsplash License).
  {
    key: "test-couple-event-shabbat-paris", title: "Dîner de Shabbat pour couples", category: "dinner",
    description: "Une longue tablée de couples, kiddouch, hallot et chants. Repas glatt casher servi à l'assiette, dans une ambiance conviviale.",
    city: "Paris", location: "Paris 17e", latitude: 48.8877, longitude: 2.3048,
    priceCents: 4500, maxCouples: 20, isKosher: true, dressCode: "Tenue de Shabbat", whatIncluded: "Dîner complet, vin casher, bougies",
    isFeatured: true, weeksAhead: 1, weekday: FRIDAY, time: "19:30", endTime: "23:00",
    imageUrl: "https://images.unsplash.com/photo-1680079033073-860e3b9c2094?w=1600&q=80&auto=format&fit=crop",
  },
  // Photo: https://unsplash.com/photos/bA02qvE5sxA by Thomas K (Unsplash License).
  {
    key: "test-couple-event-walk-lyon", title: "Balade au crépuscule sur la colline de Fourvière", category: "walk",
    description: "Une marche tranquille jusqu'aux hauteurs de Lyon pour voir la ville s'allumer, puis un thé chaud pour finir.",
    city: "Lyon", location: "Fourvière, Lyon 5e", latitude: 45.7622, longitude: 4.8226,
    priceCents: 1000, maxCouples: 15, isKosher: false, dressCode: "Chaussures confortables", whatIncluded: "Thé et petites douceurs",
    isFeatured: false, weeksAhead: 2, weekday: SUNDAY, time: "17:00", endTime: "19:30",
    imageUrl: "https://images.unsplash.com/photo-1761562044763-55c7581d3d89?w=1600&q=80&auto=format&fit=crop",
  },
  // Photo: https://unsplash.com/photos/NwGdGFuJcOI by Natalia Rüdisüli (Unsplash License).
  {
    key: "test-couple-event-workshop-marseille", title: "Atelier hallot en couple", category: "workshop",
    description: "On pétrit, on tresse et on enfourne à deux. Vous repartez avec votre pain pour le Shabbat.",
    city: "Marseille", location: "Marseille 6e", latitude: 43.2878, longitude: 5.3805,
    priceCents: 3000, maxCouples: 10, isKosher: true, whatIncluded: "Ingrédients, tablier, pain à emporter",
    isFeatured: false, weeksAhead: 3, weekday: SUNDAY, time: "14:30", endTime: "17:30",
    imageUrl: "https://images.unsplash.com/photo-1689343118010-047c2b4f44d8?w=1600&q=80&auto=format&fit=crop",
  },
  // Photo: https://unsplash.com/photos/0jVZkTGmRNs by Anastase Maragos (Unsplash License).
  {
    key: "test-couple-event-brunch-nice", title: "Brunch casher entre couples", category: "brunch",
    description: "Un brunch lacté en terrasse, fruits frais et viennoiseries, pour faire connaissance d'autres couples sans façons.",
    city: "Nice", location: "Nice, quartier Libération", latitude: 43.7058, longitude: 7.265,
    priceCents: 2800, maxCouples: 16, isKosher: true, whatIncluded: "Brunch, boissons chaudes et jus pressés",
    isFeatured: false, weeksAhead: 4, weekday: SUNDAY, time: "11:00", endTime: "14:00",
    imageUrl: "https://images.unsplash.com/photo-1624462965565-9b3682640389?w=1600&q=80&auto=format&fit=crop",
  },
  // Photo: https://unsplash.com/photos/_VyvWmlvxH0 by Joao Vitor Marcilio (Unsplash License).
  {
    key: "test-couple-event-tasting-strasbourg", title: "Dégustation de vins casher à Strasbourg", category: "tasting",
    description: "Un sommelier fait voyager vos papilles de l'Alsace à la Galilée, avec des bouchées casher pour accompagner chaque verre.",
    city: "Strasbourg", location: "Strasbourg, centre-ville", latitude: 48.5839, longitude: 7.7455,
    priceCents: 3500, maxCouples: 14, isKosher: true, dressCode: "Décontracté chic", whatIncluded: "Six vins, bouchées casher",
    isFeatured: false, weeksAhead: 5, weekday: SATURDAY, time: "20:30", endTime: "23:00",
    imageUrl: "https://images.unsplash.com/photo-1765850258962-61c55ba2be3b?w=1600&q=80&auto=format&fit=crop",
  },
  // Photo: https://unsplash.com/photos/NcdG9mK3PBY by Nainoa Shizuru (Unsplash License).
  {
    key: "test-couple-event-concert-paris", title: "Soirée concert à deux", category: "concert",
    description: "Un petit concert en salle intime, musique live et verre de bienvenue, suivi d'un temps pour discuter entre couples.",
    city: "Paris", location: "Paris 10e", latitude: 48.876, longitude: 2.36,
    priceCents: 2500, maxCouples: 30, isKosher: false, whatIncluded: "Entrée et verre de bienvenue",
    isFeatured: true, weeksAhead: 6, weekday: THURSDAY, time: "20:00", endTime: "22:30",
    imageUrl: "https://images.unsplash.com/photo-1459749411175-04bf5292ceea?w=1600&q=80&auto=format&fit=crop",
  },
];

const DAY_MS = 86_400_000;

// The date of an event, YYYY-MM-DD: its weekday in the week that starts
// `weeksAhead` weeks after `today` (UTC). Always in the future.
export function coupleEventDate(
  event: Pick<CoupleEventFixture, "weeksAhead" | "weekday">,
  today: Date = new Date(),
): string {
  const start = Date.UTC(today.getUTCFullYear(), today.getUTCMonth(), today.getUTCDate()) + event.weeksAhead * 7 * DAY_MS;
  const shift = (event.weekday - new Date(start).getUTCDay() + 7) % 7;
  return new Date(start + shift * DAY_MS).toISOString().slice(0, 10);
}
