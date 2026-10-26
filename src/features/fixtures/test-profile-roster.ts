// The test members of the TestFlight phase and the conversations the administrator
// finds in their own account. Pure data: scripts/seed-test-profiles.ts writes it.
//
// The answers (denomination, kashrut, shabbat, intention) are the values the app
// itself stores (mobile edit_profile_screen.dart and RELATIONSHIP_INTENTIONS), so the
// profile ranking and the Discover filters treat these members like real ones.
// The photos are the stock photos chosen by the owner; the second photo of a member
// is the same picture framed differently (crop=entropy), because only 18 pictures
// were validated for 16 members.

export type Gender = "female" | "male";

export interface TestMember {
  // users.provider_id, also the idempotence key; the legacy development seed used
  // the same keys, which is how its members are taken over instead of duplicated.
  readonly providerId: string;
  readonly email: string;
  readonly name: string;
  readonly displayName: string;
  readonly gender: Gender;
  readonly age: number;
  readonly city: string;
  readonly bio: string;
  readonly denomination: string;
  readonly kashrut: string;
  readonly shabbat: string;
  readonly intention: "marriage" | "serious" | "open" | "friends_first";
  readonly photoId: string;
  readonly photoVerified: boolean;
}

const WOMEN_PHOTOS = [
  "1580489944761-15a19d654956",
  "1548382131-e0ebb1f0cdea",
  "1594756154841-ac5d160dbf46",
  "1594318223885-20dc4b889f9e",
  "1662850886700-4ec19bd30d11",
  "1592621385645-e41659e8aabe",
  "1607569708758-0270aa4651bd",
  "1611695434369-a8f5d76ceb7b",
  "1623717217554-72ca676de535",
  "1525186402429-b4ff38bedec6",
  "1581714161666-dade083654ae",
  "1619896382906-4f4681290afc",
  "1562337404-3044c84ac061",
] as const;

// Five men were validated; three profiles use the first three.
export const MEN_PHOTOS = [
  "1507003211169-0a1dd7228f2d",
  "1528892952291-009c663ce843",
  "1600603406200-5b2a104684ac",
  "1583123810408-23e7b5d1af9f",
  "1583264277168-58ceba4b84e7",
] as const;

type Answers = Pick<TestMember, "denomination" | "kashrut" | "shabbat" | "intention">;
interface Draft extends Answers {
  readonly name: string;
  readonly displayName: string;
  readonly age: number;
  readonly city: string;
  readonly bio: string;
  readonly photoVerified: boolean;
}

const answers = (denomination: string, kashrut: string, shabbat: string, intention: Answers["intention"]): Answers => ({ denomination, kashrut, shabbat, intention });

const WOMEN: readonly Draft[] = [
  { name: "Sarah Cohen", displayName: "Sarah", age: 28, city: "Paris", photoVerified: true, ...answers("Modern Orthodox", "Strict", "Observant", "marriage"),
    bio: "Pédiatre à l'hôpital Necker, je passe mes semaines entre les gardes et les câlins de petits patients. Le vendredi soir, je cuisine pour huit et j'adore quand la table est pleine. Je cherche quelqu'un de curieux, qui rit facilement." },
  { name: "Rachel Lévy", displayName: "Rachel", age: 26, city: "Lyon", photoVerified: false, ...answers("Traditionaliste", "A la maison", "Partiellement", "serious"),
    bio: "Graphiste dans une agence de design, je dessine des affiches et je rêve de la Drôme dès que le week-end approche. Je fais un kiddouch simple le vendredi, sans chichi. Ici pour une vraie rencontre, pas pour discuter pendant des semaines." },
  { name: "Léa Benhamou", displayName: "Léa", age: 24, city: "Marseille", photoVerified: true, ...answers("Massorti", "A la maison", "Partiellement", "open"),
    bio: "Étudiante en kiné, passionnée de natation en mer toute l'année, même en février. Je suis du genre à organiser un pique-nique aux Goudes sur un coup de tête. J'aime les gens simples qui savent écouter." },
  { name: "Myriam Ohayon", displayName: "Myriam", age: 31, city: "Neuilly-sur-Seine", photoVerified: false, ...answers("Orthodox", "Glatt", "Tres observant", "marriage"),
    bio: "Avocate en droit de la famille, ironique, je le sais. Je prépare mes plats de Shabbat le jeudi soir en écoutant de la musique andalouse. Je souhaite construire un foyer chaleureux avec quelqu'un de sincère." },
  { name: "Esther Azoulay", displayName: "Esther", age: 29, city: "Boulogne-Billancourt", photoVerified: true, ...answers("Traditionaliste", "Strict", "Observant", "serious"),
    bio: "Ingénieure dans l'aéronautique, je cours le long de la Seine le dimanche matin. Le couscous de ma grand-mère est ma plus grande fierté et je n'ai toujours pas réussi à l'égaler. Je cherche un partenaire pour les petits moments comme pour les grands projets." },
  { name: "Déborah Sebbag", displayName: "Déborah", age: 25, city: "Paris", photoVerified: false, ...answers("Laique", "Non", "Non observant", "friends_first"),
    bio: "Développeuse dans une start-up, je me ressource dans les galeries d'art et les concerts. Je fête les grandes fêtes en famille mais je ne suis pas pratiquante. Je préfère commencer par une vraie complicité avant de parler d'avenir." },
  { name: "Judith Toledano", displayName: "Judith", age: 33, city: "Strasbourg", photoVerified: true, ...answers("Massorti", "A la maison", "Observant", "marriage"),
    bio: "Professeure de yoga, je tiens un petit studio près de la cathédrale. J'ai vécu trois ans à Tel Aviv et j'en ai gardé le goût du marché du vendredi. J'aimerais rencontrer quelqu'un de posé, avec qui fonder une famille." },
  { name: "Noémie Mimoun", displayName: "Noémie", age: 27, city: "Nice", photoVerified: false, ...answers("Traditionaliste", "A la maison", "Partiellement", "serious"),
    bio: "Architecte d'intérieur, je passe mon temps entre les chantiers et les brocantes. Je fais Shabbat chez mes parents presque chaque semaine, c'est mon petit rituel. Je cherche quelqu'un de drôle, avec un vrai projet de vie." },
  { name: "Hannah Zerbib", displayName: "Hannah", age: 30, city: "Paris", photoVerified: true, ...answers("Modern Orthodox", "Strict", "Observant", "marriage"),
    bio: "Journaliste culture, je lis plus de livres que je ne peux en ranger. Mon rêve : une maison pleine de bruit, d'amis et de bonne cuisine. Je suis ouverte et patiente, mais je sais ce que je veux." },
  { name: "Tamar Abitbol", displayName: "Tamar", age: 23, city: "Lyon", photoVerified: false, ...answers("Massorti", "A la maison", "Non observant", "open"),
    bio: "En master de psychologie, je cherche encore ma voie mais je sais que j'aime aider. J'adore la randonnée, le cinéma d'auteur et les soirées entre amis. Pas de prise de tête, juste de la bonne humeur." },
  { name: "Yaël Attal", displayName: "Yaël", age: 34, city: "Neuilly-sur-Seine", photoVerified: true, ...answers("Habad", "Glatt", "Tres observant", "marriage"),
    bio: "Directrice financière, organisée au millimètre sauf quand il s'agit de mes week-ends. J'ai grandi dans une famille Loubavitch et ces valeurs me tiennent à cœur. Je désire fonder une famille unie, avec un homme de cœur." },
  { name: "Eva Bensimon", displayName: "Eva", age: 26, city: "Boulogne-Billancourt", photoVerified: false, ...answers("Autre", "Non", "Non observant", "open"),
    bio: "Photographe indépendante, je capte la lumière de Paris à toute heure. Je suis curieuse de tout : cuisine, voyages, Talmud lu à ma façon. Je cherche quelqu'un d'ouvert, avec qui échanger sans préjugés." },
  { name: "Ilana Elbaz", displayName: "Ilana", age: 28, city: "Marseille", photoVerified: true, ...answers("Orthodox", "Strict", "Observant", "serious"),
    bio: "Médecin urgentiste à la Timone, j'ai un humour noir que mes collègues adorent. Le dimanche, je file à la plage avec un bon roman et une glace. Je cherche un homme patient, qui comprend un emploi du temps de fou." },
];

const MEN: readonly Draft[] = [
  { name: "David Cohen", displayName: "David", age: 31, city: "Paris", photoVerified: true, ...answers("Modern Orthodox", "Strict", "Observant", "marriage"),
    bio: "Ingénieur en intelligence artificielle, je passe mes journées à expliquer à des machines ce que mes amis comprennent à demi-mot. Le samedi, je prends le temps : synagogue, déjeuner qui s'éternise, sieste. Je cherche ma moitié pour construire quelque chose de solide." },
  { name: "Raphaël Lévy", displayName: "Raphaël", age: 29, city: "Lyon", photoVerified: false, ...answers("Traditionaliste", "A la maison", "Partiellement", "serious"),
    bio: "Chef de projet dans le retail, fan de l'OL et de cuisine lyonnaise, version casher évidemment. Je cours deux fois par semaine, un peu moins quand il pleut. J'aimerais rencontrer quelqu'un de chaleureux, avec qui rire autour d'une table." },
  { name: "Jonathan Sebbag", displayName: "Jonathan", age: 33, city: "Nice", photoVerified: false, ...answers("Massorti", "A la maison", "Observant", "friends_first"),
    bio: "Kinésithérapeute du sport, je soigne les genoux des joueurs du coin. Voile le week-end, shakshouka le dimanche, et Shabbat chez mes parents dès que je peux. Je préfère apprendre à connaître quelqu'un avant de m'engager." },
];

function members(drafts: readonly Draft[], gender: Gender, photos: readonly string[]): TestMember[] {
  return drafts.map((draft, index) => ({
    ...draft,
    gender,
    providerId: `seed-${gender}-${index + 1}`,
    email: `fake.${gender}.${index + 1}@mazl.seed`,
    photoId: photos[index] ?? "",
  }));
}

export const TEST_MEMBERS: readonly TestMember[] = [...members(WOMEN, "female", WOMEN_PHOTOS), ...members(MEN, "male", MEN_PHOTOS)];

const STOCK_BASE = "https://images.unsplash.com/photo-";
export const stockPhoto = (photoId: string, size: "portrait" | "thumbnail", crop: "faces" | "entropy" = "faces"): string =>
  size === "thumbnail"
    ? `${STOCK_BASE}${photoId}?w=200&h=200&fit=crop&crop=${crop}&q=80`
    : `${STOCK_BASE}${photoId}?w=800&h=1000&fit=crop&crop=${crop}&q=80`;

// ---- the administrator's account ----

export const MATCHES_PER_ADMIN = 5;
export const CONVERSATIONS_PER_ADMIN = 4;

export interface ScriptedMessage {
  readonly from: "partner" | "admin";
  readonly text: string;
  readonly minutesAgo: number;
  // Only a message from the partner can be unread (by the administrator).
  readonly unread?: boolean;
}

// Wording that fits any partner and any administrator (no agreement of gender).
export const CONVERSATION_SCRIPTS: readonly (readonly ScriptedMessage[])[] = [
  [
    { from: "partner", minutesAgo: 4300, text: "Salut ! Alors comme ça on a matché, ça fait plaisir. Comment se passe ta semaine ?" },
    { from: "admin", minutesAgo: 4250, text: "Salut ! Plutôt bien, merci, un peu dense au travail mais ça va. Et toi, tu es de quel coin exactement ?" },
    { from: "partner", minutesAgo: 2900, unread: true, text: "Du coin depuis toujours ! Je cherche un bon restaurant casher pour dimanche, tu aurais une adresse à me conseiller ?" },
    { from: "partner", minutesAgo: 2890, unread: true, text: "Pas de pression, réponds quand tu as un moment 🙂" },
  ],
  [
    { from: "partner", minutesAgo: 2600, text: "Hello ! Ton profil m'a donné envie d'écrire. Tu fais quoi de bon pour Shabbat ?" },
    { from: "admin", minutesAgo: 2560, text: "Haha, mon plat signature, c'est le poulet rôti aux épices. La challah reste un grand mystère pour moi." },
    { from: "partner", minutesAgo: 1500, text: "La challah, j'en fais tous les vendredis ! Je te donnerai le secret si on se voit un jour." },
    { from: "admin", minutesAgo: 1460, text: "Marché conclu. Un café cette semaine pour commencer ?" },
    { from: "partner", minutesAgo: 180, unread: true, text: "Avec plaisir ! Jeudi en fin d'après-midi, ça te va ?" },
  ],
  [
    { from: "admin", minutesAgo: 5800, text: "Bonsoir ! Ta bio m'a fait sourire, surtout la partie sur le week-end idéal." },
    { from: "partner", minutesAgo: 5700, text: "Merci ! Mon week-end idéal a un protocole précis : marché le matin, grande balade, dîner entre amis." },
    { from: "admin", minutesAgo: 5650, text: "Ça donne envie. Et la balade, plutôt mer, montagne ou ville ?" },
    { from: "partner", minutesAgo: 3000, text: "Ville, sans hésiter. J'aime flâner sans but précis et m'arrêter dès qu'un café me tente." },
    { from: "admin", minutesAgo: 2950, text: "On pourrait en faire une ensemble un de ces jours, non ?" },
    { from: "partner", minutesAgo: 420, unread: true, text: "Très bonne idée. Tu es libre dimanche prochain ?" },
  ],
  [
    { from: "partner", minutesAgo: 700, text: "Coucou ! Je vois qu'on partage la même idée du dîner de Shabbat en famille, ça fait plaisir de le lire." },
    { from: "admin", minutesAgo: 640, text: "Oui, c'est un moment auquel je tiens beaucoup. Et chez toi, plutôt ambiance calme ou table qui déborde ?" },
    { from: "partner", minutesAgo: 90, unread: true, text: "Table qui déborde, sans hésiter ! Il y a toujours quelqu'un de plus qui arrive à la dernière minute 😄" },
  ],
];

// The matches of an account that holds the scripts above (the fifth one is brand new,
// nobody has written yet) and how long ago each happened.
export const NEW_MATCH_MINUTES_AGO = 200;
export const MATCH_LEAD_MINUTES = 30;
export const SWIPE_MINUTES_AGO = 14_400;
