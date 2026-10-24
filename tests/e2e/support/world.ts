import { BASE_URL } from "./env";
import { createEvent, createMember, grantReligiousConsent, match, say, swipe, type Member, type MemberSpec } from "./seed";

// One coherent, fictitious community for the scenarios and the screenshots:
// Léa (the member we look through), the men Découvrir proposes, the ones who
// liked her, two matches with a conversation, events, and a couple.

const PARIS = { latitude: 48.8566, longitude: 2.3522 };
const near = (dLat: number, dLng: number) => ({ latitude: PARIS.latitude + dLat, longitude: PARIS.longitude + dLng });

const LEA: MemberSpec = {
  name: "Léa", gender: "female", birthdate: "1994-03-12", city: "Paris 11e", ...PARIS,
  bio: "Architecte d'intérieur, amoureuse des marchés du dimanche et des longues tables du vendredi soir. Je cherche quelqu'un de curieux, qui rit facilement.",
  denomination: "Massorti", kashrutLevel: "A la maison", shabbatObservance: "Partiellement", photos: 4,
  prompts: [["perfect_sunday", "Le marché d'Aligre, un brunch qui s'éternise, puis une expo."], ["friday_night", "Une grande tablée, des challot maison et des débats qui finissent tard."], ["together_we_could", "Apprendre à faire des bourekas comme ma grand-mère."]],
};

const CANDIDATES: readonly MemberSpec[] = [
  { name: "David", gender: "male", birthdate: "1990-06-02", city: "Paris 17e", ...near(0.03, -0.04), bio: "Médecin urgentiste, coureur du dimanche, fan de jazz manouche. Shabbat en famille dès que les gardes le permettent.", denomination: "Massorti", kashrutLevel: "A la maison", shabbatObservance: "Observant", photos: 3, prompts: [["shabbat_ideal", "Un repas long chez mes parents, puis une balade le long du canal."], ["teach_me", "Apprenez-moi à cuisiner autre chose que des pâtes."]] },
  { name: "Yonathan", gender: "male", birthdate: "1992-11-20", city: "Boulogne-Billancourt", ...near(-0.02, -0.09), bio: "Ingénieur dans l'énergie, je partage ma vie entre Paris et Tel-Aviv. Toujours partant pour un week-end improvisé.", denomination: "Traditionaliste", kashrutLevel: "A la maison", shabbatObservance: "Partiellement", photos: 3, prompts: [["israel_memory", "Un lever de soleil sur Massada, après une nuit sans sommeil."]] },
  { name: "Raphaël", gender: "male", birthdate: "1989-01-08", city: "Neuilly-sur-Seine", ...near(0.02, -0.07), bio: "Avocat, lecteur compulsif, mauvais joueur aux échecs mais très bon perdant.", denomination: "Modern Orthodox", kashrutLevel: "Strict", shabbatObservance: "Tres observant", photos: 2 },
  { name: "Elie", gender: "male", birthdate: "1993-08-30", city: "Paris 3e", ...near(0.01, 0.01), bio: "Chef pâtissier. Je vous dois un babka.", denomination: "Massorti", kashrutLevel: "A la maison", shabbatObservance: "Partiellement", photos: 3, prompts: [["hidden_talent", "Je reconnais une farine à l'odeur."]] },
  { name: "Nathan", gender: "male", birthdate: "1991-04-15", city: "Vincennes", ...near(0.0, 0.08), bio: "Professeur d'histoire, bénévole dans une association de quartier, randonneur.", denomination: "Laique", kashrutLevel: "Non", shabbatObservance: "Non observant", photos: 2 },
  { name: "Benjamin", gender: "male", birthdate: "1988-12-03", city: "Levallois-Perret", ...near(0.04, -0.06), bio: "Entrepreneur dans la santé, papa d'un golden retriever, cuisinier du vendredi.", denomination: "Traditionaliste", kashrutLevel: "A la maison", shabbatObservance: "Observant", photos: 3 },
];

const LIKERS: readonly MemberSpec[] = [
  { name: "Jonas", gender: "male", birthdate: "1990-09-09", city: "Paris 9e", ...near(0.02, 0.0), bio: "Musicien et développeur.", denomination: "Massorti", photos: 2 },
  { name: "Ilan", gender: "male", birthdate: "1987-02-21", city: "Saint-Mandé", ...near(-0.01, 0.07), bio: "Photographe, toujours un argentique dans la poche.", denomination: "Traditionaliste", photos: 2 },
  { name: "Gabriel", gender: "male", birthdate: "1995-05-05", city: "Paris 15e", ...near(-0.02, -0.03), bio: "Data scientist, joueur de basket le jeudi.", denomination: "Massorti", photos: 2 },
];

const MATCHES: readonly MemberSpec[] = [
  { name: "Noam", gender: "male", birthdate: "1991-07-18", city: "Paris 10e", ...near(0.02, 0.02), bio: "Urbaniste, cycliste, cuisinier amateur de plats yéménites.", denomination: "Massorti", kashrutLevel: "A la maison", shabbatObservance: "Partiellement", photos: 3, prompts: [["first_date", "Un falafel rue des Rosiers puis une expo au MAHJ."]] },
  { name: "Adam", gender: "male", birthdate: "1990-10-01", city: "Paris 5e", ...near(-0.01, 0.0), bio: "Chercheur en biologie, grand lecteur de Primo Levi.", denomination: "Laique", photos: 2 },
];

export interface World {
  readonly lea: Member;
  readonly candidates: readonly Member[];
  readonly likers: readonly Member[];
  readonly noam: Member;
  readonly adam: Member;
  readonly noamConversation: number;
  readonly adamConversation: number;
  readonly couple: { readonly myriam: Member; readonly daniel: Member };
  readonly events: readonly number[];
}

async function seedConversation(lea: Member, noam: Member): Promise<number> {
  const id = await match(lea, noam);
  await say(noam, id, "Bonjour Léa ! J'ai vu que vous aimiez le marché d'Aligre, j'y suis presque tous les dimanches.");
  await say(lea, id, "Bonjour Noam ! Alors on s'y est sûrement croisés. Vous y allez pour quoi ?");
  await say(noam, id, "Le fromager du fond, et les herbes pour le shakshuka du soir.");
  await say(noam, id, "Et vous, vous êtes plutôt brunch ou plutôt marché ?");
  return id;
}

async function seedCouple(): Promise<World["couple"]> {
  const myriam = await createMember({ name: "Myriam", gender: "female", birthdate: "1993-02-14", city: "Paris 12e", ...PARIS, bio: "Sage-femme.", photos: 2 });
  const daniel = await createMember({ name: "Daniel", gender: "male", birthdate: "1991-05-30", city: "Paris 12e", ...PARIS, bio: "Ingénieur du son.", photos: 2 });
  await match(myriam, daniel);
  const res = await fetch(`${BASE_URL}/api/dev/couple/enable`, { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ userId: myriam.id, partnerId: daniel.id }) });
  if (!res.ok) throw new Error(`couple enable ${res.status}`);
  return { myriam, daniel };
}

async function seedEvents(): Promise<number[]> {
  return Promise.all([
    createEvent({ title: "Shabbat dinner des 25-35 ans", description: "Un dîner de Shabbat convivial, cacher, pour rencontrer de nouvelles personnes autour d'une grande table.", type: "shabbat", location: "Paris 16e", address: "Adresse communiquée après inscription", inDays: 5, time: "19:30", price: 35, maxAttendees: 40 }),
    createEvent({ title: "Soirée jeux de société", description: "Catan, Codenames et Dixit : on mélange les tables toutes les 30 minutes.", type: "soiree", location: "Paris 11e", address: "Café des Jeux, rue Oberkampf", inDays: 9, time: "20:00", price: 12, maxAttendees: 30 }),
    createEvent({ title: "Balade guidée du Marais juif", description: "Deux heures dans l'histoire du Pletzl, avec une historienne, puis un verre.", type: "culture", location: "Paris 4e", address: "Départ rue des Rosiers", inDays: 13, time: "15:00", price: 0, maxAttendees: 25 }),
  ]);
}

export async function seedWorld(): Promise<World> {
  const lea = await createMember(LEA);
  await grantReligiousConsent(lea);
  const candidates = await Promise.all(CANDIDATES.map((spec) => createMember(spec)));
  const likers = await Promise.all(LIKERS.map((spec) => createMember(spec)));
  for (const liker of likers) await swipe(liker, lea, "like");
  const [noam, adam] = await Promise.all(MATCHES.map((spec) => createMember(spec)));
  if (!noam || !adam) throw new Error("matches not created");
  const noamConversation = await seedConversation(lea, noam);
  const adamConversation = await match(lea, adam);
  return { lea, candidates, likers, noam, adam, noamConversation, adamConversation, couple: await seedCouple(), events: await seedEvents() };
}
