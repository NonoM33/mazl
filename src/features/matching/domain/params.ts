// Parameters of the matching engine (docs/backoffice/CADRAGE.md §7). Stored in
// the database as versioned JSON, tuned from the back-office. Every numeric
// knob is declared ONCE in NUMERIC_PARAMS, with its bounds: the validator and
// the sliders of the console are both generated from that list, so a value
// outside its bounds can be neither saved nor shown.

export const CRITERIA = [
  "denomination",
  "kashrut",
  "shabbat",
  "intention",
  "age",
  "distance",
  "profile",
  "verification",
] as const;
export type Criterion = (typeof CRITERIA)[number];

export const RECIPROCITY_MODES = ["harmonic", "geometric", "min", "forward_only"] as const;
export type ReciprocityMode = (typeof RECIPROCITY_MODES)[number];

export const SCALES = ["denomination", "kashrut", "shabbat", "intention"] as const;
export type ScaleName = (typeof SCALES)[number];

// Normalised answer key (lower case, no accent, "_" for spaces) → rank.
export type OrdinalScale = Readonly<Record<string, number>>;

export interface MatchingParams {
  // Relative importance of each criterion, 0..10. Normalised by their sum.
  readonly weights: Readonly<Record<Criterion, number>>;
  readonly religion: {
    // Rank gap at which a religious criterion scores 0.
    readonly denominationTolerance: number;
    readonly kashrutTolerance: number;
    readonly shabbatTolerance: number;
    readonly intentionTolerance: number;
    // Score given when one side did not answer (or answered "autre").
    readonly unknownScore: number;
  };
  readonly age: {
    // Score of a candidate exactly on the edge of the viewer's range (1 at the centre).
    readonly edgeScore: number;
  };
  readonly distance: {
    // Distance at which the distance score is 0.5.
    readonly halfScoreKm: number;
  };
  readonly filters: {
    // The candidate must also accept the viewer's age / distance.
    readonly mutualAge: boolean;
    readonly mutualDistance: boolean;
  };
  readonly reciprocity: {
    readonly mode: ReciprocityMode;
  };
  readonly freshness: {
    // Days of inactivity that halve the score…
    readonly halfLifeDays: number;
    // …without ever going below this factor.
    readonly floor: number;
  };
  readonly newcomer: {
    // Extra factor (1 + bonus) given to accounts younger than `days`, fading linearly.
    readonly bonus: number;
    readonly days: number;
  };
  readonly boost: {
    // Factor applied to a member whose paid boost is running. Capped by the bounds.
    readonly factor: number;
  };
  readonly exposure: {
    // Likes received over 7 days above which the score starts to be damped…
    readonly popularityCap: number;
    // …and how hard (0 disables).
    readonly strength: number;
  };
  readonly safety: {
    // Factor lost per open report (multiplicative), never below `floor`.
    readonly penaltyPerReport: number;
    readonly floor: number;
  };
  readonly exploration: {
    // Share of the page given to plausible candidates outside the top.
    readonly epsilon: number;
    // A candidate is "plausible" from this reciprocal score.
    readonly minScore: number;
  };
  readonly scales: Readonly<Record<ScaleName, OrdinalScale>>;
}

export type ParamGroup =
  | "weights"
  | "religion"
  | "age"
  | "distance"
  | "freshness"
  | "newcomer"
  | "boost"
  | "exposure"
  | "safety"
  | "exploration";

export interface NumericParamSpec {
  // Dotted path in MatchingParams: "weights.denomination", "freshness.halfLifeDays".
  readonly path: string;
  readonly group: ParamGroup;
  readonly label: string;
  readonly help: string;
  readonly min: number;
  readonly max: number;
  readonly step: number;
  readonly unit?: string;
}

const weight = (criterion: Criterion, label: string, help: string): NumericParamSpec => ({
  path: `weights.${criterion}`,
  group: "weights",
  label,
  help,
  min: 0,
  max: 10,
  step: 0.5,
});

export const NUMERIC_PARAMS: readonly NumericParamSpec[] = [
  weight("denomination", "Courant", "Proximité du courant religieux (laïque … Habad)."),
  weight("kashrut", "Cashrout", "Proximité du niveau de cashrout."),
  weight("shabbat", "Chabbat", "Proximité de l'observance du chabbat."),
  weight("intention", "Intention", "Proximité de l'intention (mariage, relation sérieuse…)."),
  weight("age", "Âge", "Place de l'âge du candidat dans la tranche souhaitée."),
  weight("distance", "Distance", "Proximité géographique."),
  weight("profile", "Profil complet", "Photos, bio et questions remplies."),
  weight("verification", "Vérification", "Selfie ou identité vérifiés."),
  { path: "religion.denominationTolerance", group: "religion", label: "Tolérance courant", help: "Écart de rangs à partir duquel le courant ne compte plus.", min: 1, max: 6, step: 0.5, unit: "rangs" },
  { path: "religion.kashrutTolerance", group: "religion", label: "Tolérance cashrout", help: "Écart de niveaux à partir duquel la cashrout ne compte plus.", min: 1, max: 4, step: 0.5, unit: "niveaux" },
  { path: "religion.shabbatTolerance", group: "religion", label: "Tolérance chabbat", help: "Écart de niveaux à partir duquel le chabbat ne compte plus.", min: 1, max: 4, step: 0.5, unit: "niveaux" },
  { path: "religion.intentionTolerance", group: "religion", label: "Tolérance intention", help: "Écart d'intention à partir duquel le critère ne compte plus.", min: 1, max: 4, step: 0.5, unit: "niveaux" },
  { path: "religion.unknownScore", group: "religion", label: "Réponse manquante", help: "Score donné quand l'un des deux n'a pas répondu.", min: 0, max: 1, step: 0.05 },
  { path: "age.edgeScore", group: "age", label: "Score en bord de tranche", help: "Score d'un âge pile à la limite de la tranche (1 au centre).", min: 0, max: 1, step: 0.05 },
  { path: "distance.halfScoreKm", group: "distance", label: "Distance « mi-score »", help: "Distance à laquelle le score de distance vaut 0,5.", min: 1, max: 500, step: 1, unit: "km" },
  { path: "freshness.halfLifeDays", group: "freshness", label: "Demi-vie d'inactivité", help: "Jours sans connexion qui divisent le score par deux.", min: 1, max: 90, step: 1, unit: "jours" },
  { path: "freshness.floor", group: "freshness", label: "Plancher d'inactivité", help: "Facteur minimal d'un profil inactif.", min: 0.05, max: 1, step: 0.05 },
  { path: "newcomer.bonus", group: "newcomer", label: "Bonus nouveaux", help: "Bonus d'un compte qui vient d'arriver, dégressif.", min: 0, max: 1, step: 0.05 },
  { path: "newcomer.days", group: "newcomer", label: "Durée du bonus nouveaux", help: "Âge du compte où le bonus atteint zéro.", min: 0, max: 60, step: 1, unit: "jours" },
  { path: "boost.factor", group: "boost", label: "Effet d'un boost", help: "Multiplicateur d'un boost payant en cours. Plafonné à ×2.", min: 1, max: 2, step: 0.05, unit: "×" },
  { path: "exposure.popularityCap", group: "exposure", label: "Seuil de popularité", help: "Likes reçus en 7 jours au-delà desquels le profil est moins montré.", min: 5, max: 500, step: 5, unit: "likes" },
  { path: "exposure.strength", group: "exposure", label: "Force de l'amortissement", help: "0 désactive la limite de surexposition.", min: 0, max: 2, step: 0.1 },
  { path: "safety.penaltyPerReport", group: "safety", label: "Pénalité par signalement", help: "Part du score perdue par signalement ouvert.", min: 0, max: 0.5, step: 0.05 },
  { path: "safety.floor", group: "safety", label: "Plancher signalements", help: "Facteur minimal d'un profil signalé (la sanction relève de la modération).", min: 0.1, max: 1, step: 0.05 },
  { path: "exploration.epsilon", group: "exploration", label: "Part d'exploration", help: "Part de la page offerte à des profils plausibles hors du haut du classement.", min: 0, max: 0.3, step: 0.01 },
  { path: "exploration.minScore", group: "exploration", label: "Seuil de plausibilité", help: "Score réciproque minimal d'un profil d'exploration.", min: 0, max: 1, step: 0.05 },
];

// Every rank of an ordinal scale must lie in this interval.
export const SCALE_RANK_BOUNDS = { min: 0, max: 10 } as const;

export const DEFAULT_PARAMS: MatchingParams = {
  weights: {
    denomination: 6,
    kashrut: 4,
    shabbat: 4,
    intention: 5,
    age: 3,
    distance: 4,
    profile: 2,
    verification: 2,
  },
  religion: {
    denominationTolerance: 3,
    kashrutTolerance: 2,
    shabbatTolerance: 2,
    intentionTolerance: 2,
    unknownScore: 0.5,
  },
  age: { edgeScore: 0.6 },
  distance: { halfScoreKm: 25 },
  filters: { mutualAge: true, mutualDistance: true },
  reciprocity: { mode: "harmonic" },
  freshness: { halfLifeDays: 14, floor: 0.3 },
  newcomer: { bonus: 0.2, days: 14 },
  boost: { factor: 1.5 },
  exposure: { popularityCap: 60, strength: 0.5 },
  safety: { penaltyPerReport: 0.15, floor: 0.4 },
  exploration: { epsilon: 0.1, minScore: 0.35 },
  scales: {
    denomination: {
      laique: 0,
      liberal: 1,
      liberale: 1,
      traditionaliste: 2,
      massorti: 2,
      modern_orthodox: 3,
      orthodoxe_moderne: 3,
      orthodox: 4,
      orthodoxe: 4,
      habad: 5,
      loubavitch: 5,
    },
    kashrut: {
      non: 0,
      no: 0,
      none: 0,
      a_la_maison: 1,
      kasher_a_la_maison: 1,
      cacher_a_la_maison: 1,
      home: 1,
      strict: 2,
      kasher_strict: 2,
      glatt: 3,
    },
    shabbat: {
      non_observant: 0,
      not_observant: 0,
      partiellement: 1,
      partial: 1,
      partially: 1,
      shabbat_en_famille: 1,
      observant: 2,
      tres_observant: 3,
      strict: 3,
    },
    intention: {
      open: 0,
      friends_first: 1,
      serious: 2,
      marriage: 3,
      mariage: 3,
    },
  },
};

export type ParamsValidation =
  | { readonly ok: true; readonly params: MatchingParams }
  | { readonly ok: false; readonly errors: readonly string[] };
