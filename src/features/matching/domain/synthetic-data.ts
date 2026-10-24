// Fictitious material for the synthetic population: first names and French
// cities with approximate centres. No real person appears here.

export interface City {
  readonly name: string;
  readonly latitude: number;
  readonly longitude: number;
  // Relative weight in the draw.
  readonly weight: number;
}

export const CITIES: readonly City[] = [
  { name: "Paris", latitude: 48.8566, longitude: 2.3522, weight: 10 },
  { name: "Sarcelles", latitude: 48.9975, longitude: 2.3783, weight: 4 },
  { name: "Créteil", latitude: 48.7904, longitude: 2.4556, weight: 3 },
  { name: "Lyon", latitude: 45.764, longitude: 4.8357, weight: 5 },
  { name: "Marseille", latitude: 43.2965, longitude: 5.3698, weight: 5 },
  { name: "Nice", latitude: 43.7102, longitude: 7.262, weight: 3 },
  { name: "Strasbourg", latitude: 48.5734, longitude: 7.7521, weight: 2 },
  { name: "Toulouse", latitude: 43.6047, longitude: 1.4442, weight: 2 },
  { name: "Bordeaux", latitude: 44.8378, longitude: -0.5792, weight: 2 },
  { name: "Lille", latitude: 50.6292, longitude: 3.0573, weight: 2 },
  { name: "Nantes", latitude: 47.2184, longitude: -1.5536, weight: 1 },
  { name: "Montpellier", latitude: 43.6108, longitude: 3.8767, weight: 1 },
];

export const MALE_NAMES: readonly string[] = [
  "Daniel", "Samuel", "Noam", "Yonathan", "Ethan", "Raphaël", "Gabriel", "Élie", "Jérémie", "Benjamin",
  "Simon", "David", "Léo", "Avi", "Itaï", "Mathis", "Jonas", "Nathan", "Ilan", "Tom",
];

export const FEMALE_NAMES: readonly string[] = [
  "Sarah", "Léa", "Rachel", "Noa", "Chloé", "Yaël", "Esther", "Mélanie", "Tamar", "Déborah",
  "Eden", "Jade", "Lia", "Nina", "Orly", "Hannah", "Salomé", "Maya", "Anaïs", "Ruth",
];

// Free answers that are not on any scale (the engine must treat them as unknown).
export const FREE_ANSWERS: readonly string[] = ["Séfarade", "Autre", "Ça dépend"];
