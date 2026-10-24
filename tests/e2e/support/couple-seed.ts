import { db } from "./seed";

// Fictitious couple activities and events for the couple screens and their
// screenshots. The API has no route to create them, so they go in by SQL
// (columns of couple_activities / couple_events in src/db.ts). The rows the
// server seeds at start-up (pictures hosted elsewhere, dates already past) are
// set aside so the screenshots only show these.

const ACTIVITIES = [
  { title: "Atelier de poterie à deux", description: "Tournage et modelage dans un atelier du 11e, pièces à emporter.", category: "culture", location: "Atelier de la Roquette", city: "Paris", price: 6500, minutes: 150, rating: 4.7, kosher: false },
  { title: "Dîner casher aux chandelles", description: "Menu dégustation dans un restaurant casher du Marais.", category: "gastronomy", location: "Table du Pletzl", city: "Paris", price: 12000, minutes: 120, rating: 4.8, kosher: true },
  { title: "Matinée thermale en duo", description: "Bains chauds, hammam et temps de repos, sans écran.", category: "wellness", location: "Bains du Canal", city: "Paris", price: 8500, minutes: 180, rating: 4.6, kosher: false },
  { title: "Balade en kayak sur la Marne", description: "Deux heures sur l'eau au coucher du soleil.", category: "sport", location: "Base nautique de Joinville", city: "Joinville-le-Pont", price: 4500, minutes: 120, rating: 4.5, kosher: false },
  { title: "Étude de la paracha à deux", description: "Un rendez-vous d'étude, café et textes fournis.", category: "spiritual", location: "Maison d'étude du 3e", city: "Paris", price: 0, minutes: 90, rating: 4.9, kosher: true },
  { title: "Week-end à Honfleur", description: "Une nuit dans une maison d'hôtes, petit déjeuner inclus.", category: "travel", location: "Honfleur", city: "Honfleur", price: 32000, minutes: 2880, rating: 4.7, kosher: false },
] as const;

const EVENTS = [
  { title: "Shabbat à quatre mains", description: "Un dîner de Shabbat entre couples, cuisiné ensemble l'après-midi.", category: "dinner", inDays: 6, time: "18:30", location: "Paris 11e", price: 0, max: 12, taken: 5, dress: "Tenue de Shabbat", included: "Dîner, vin casher" },
  { title: "Dégustation de vins d'Israël", description: "Six vins casher présentés par un caviste, avec une planche à partager.", category: "tasting", inDays: 12, time: "20:00", location: "Paris 3e", price: 0, max: 20, taken: 19, dress: null, included: "Six vins, planche" },
  { title: "Brunch du dimanche en couple", description: "Un brunch tranquille, tables de deux.", category: "brunch", inDays: 17, time: "11:00", location: "Paris 9e", price: 0, max: 16, taken: 3, dress: null, included: "Buffet" },
  { title: "Week-end en Normandie", description: "Deux jours en gîte, balades et dîner commun.", category: "travel", inDays: 30, time: "09:00", location: "Étretat", price: 18000, max: 8, taken: 2, dress: "Décontracté", included: "Hébergement, dîner" },
] as const;

export async function seedCoupleContent(): Promise<void> {
  await db`UPDATE couple_activities SET is_active = false`;
  await db`UPDATE couple_events SET is_published = false`;
  for (const item of ACTIVITIES) {
    await db`
      INSERT INTO couple_activities (title, description, category, location, city, price_cents, duration_minutes, rating, is_kosher)
      VALUES (${item.title}, ${item.description}, ${item.category}, ${item.location}, ${item.city}, ${item.price}, ${item.minutes}, ${item.rating}, ${item.kosher})`;
  }
  for (const item of EVENTS) {
    const date = new Date(Date.now() + item.inDays * 86_400_000).toISOString().slice(0, 10);
    await db`
      INSERT INTO couple_events (title, description, category, event_date, event_time, location, city, price_cents, max_couples, current_couples, dress_code, what_included, is_kosher, is_published)
      VALUES (${item.title}, ${item.description}, ${item.category}, ${date}, ${item.time}, ${item.location}, 'Paris', ${item.price}, ${item.max}, ${item.taken}, ${item.dress}, ${item.included}, true, true)`;
  }
}
