// Réglages numériques du moteur : regroupement, lecture et écriture par chemin pointé, bornes, écarts.
// Fonctions pures. Les bornes viennent des `specs` de l'API (jamais recopiées ici) ; les règles de
// validation reprennent celles du serveur (`validate-params.ts`) pour refuser un essai avant l'envoi.
import type { MatchingParams, NumericParamSpec, ParamGroup, ReciprocityMode } from "../shared/api/contracts";

export const GROUP_ORDER: readonly ParamGroup[] = ["weights", "religion", "age", "distance", "freshness", "newcomer", "boost", "exposure", "safety", "exploration"];

export const GROUP_TEXT: Readonly<Record<ParamGroup, { readonly title: string; readonly lead: string }>> = {
  weights: { title: "Poids des critères", lead: "Importance relative de chaque critère, de 0 à 10. Seul le rapport entre les poids compte : ils sont ramenés à une somme de 100 %." },
  religion: { title: "Critères religieux", lead: "À partir de quel écart de réponses un critère religieux ne rapporte plus rien, et le score donné quand une réponse manque." },
  age: { title: "Âge", lead: "Score d'un candidat selon sa place dans la tranche d'âge souhaitée." },
  distance: { title: "Distance", lead: "Rapidité avec laquelle le score baisse quand le candidat s'éloigne." },
  freshness: { title: "Fraîcheur", lead: "Pénalise les profils qui ne se connectent plus." },
  newcomer: { title: "Nouveaux membres", lead: "Petit coup de pouce aux comptes récents, qui s'estompe jusqu'à zéro." },
  boost: { title: "Boost payant", lead: "Multiplicateur d'un membre dont le boost est en cours." },
  exposure: { title: "Exposition", lead: "Évite que quelques profils très populaires accaparent tout l'écran." },
  safety: { title: "Sécurité", lead: "Les signalements ouverts font baisser la visibilité, sans remplacer la modération." },
  exploration: { title: "Exploration", lead: "Réserve quelques places à des profils plausibles hors du haut du classement." },
};

export interface SpecGroup {
  readonly group: string;
  readonly title: string;
  readonly lead: string;
  readonly specs: readonly NumericParamSpec[];
}

/** Groupes dans l'ordre d'affichage ; un groupe inconnu du client est ajouté à la fin plutôt que perdu. */
export function groupSpecs(specs: readonly NumericParamSpec[]): readonly SpecGroup[] {
  const byGroup = new Map<string, NumericParamSpec[]>();
  for (const spec of specs) byGroup.set(spec.group, [...(byGroup.get(spec.group) ?? []), spec]);
  const known: readonly string[] = GROUP_ORDER;
  const order = [...known.filter((group) => byGroup.has(group)), ...[...byGroup.keys()].filter((group) => !known.includes(group))];
  return order.map((group) => {
    const text = (GROUP_TEXT as Readonly<Record<string, { readonly title: string; readonly lead: string }>>)[group];
    return { group, title: text?.title ?? group, lead: text?.lead ?? "", specs: byGroup.get(group) ?? [] };
  });
}

type Rec = Record<string, unknown>;
const isRec = (value: unknown): value is Rec => typeof value === "object" && value !== null && !Array.isArray(value);

export function readValue(params: MatchingParams, path: string): number | undefined {
  let node: unknown = params;
  for (const key of path.split(".")) {
    if (!isRec(node) || !Object.hasOwn(node, key)) return undefined;
    node = node[key];
  }
  return typeof node === "number" ? node : undefined;
}

function assign(node: Rec, keys: readonly string[], value: number): Rec {
  const [head, ...rest] = keys;
  if (head === undefined) throw new RangeError("Chemin vide");
  if (rest.length === 0) return { ...node, [head]: value };
  const child = node[head];
  if (!isRec(child)) throw new RangeError(`Chemin inconnu : ${keys.join(".")}`);
  return { ...node, [head]: assign(child, rest, value) };
}

export function writeValue(params: MatchingParams, path: string, value: number): MatchingParams {
  if (readValue(params, path) === undefined) throw new RangeError(`Réglage inconnu : ${path}`);
  return assign(params as unknown as Rec, path.split("."), value) as unknown as MatchingParams;
}

export function decimalsOf(step: number): number {
  const text = String(step);
  const dot = text.indexOf(".");
  return dot === -1 ? 0 : text.length - dot - 1;
}

const formatters = new Map<number, Intl.NumberFormat>();
function formatter(decimals: number): Intl.NumberFormat {
  const found = formatters.get(decimals);
  if (found !== undefined) return found;
  const created = new Intl.NumberFormat("fr-FR", { minimumFractionDigits: decimals, maximumFractionDigits: decimals });
  formatters.set(decimals, created);
  return created;
}

/** « 0,05 », « 14 jours », « ×1,5 » : le nombre de décimales suit le pas du réglage. */
export function formatValue(value: number, spec: NumericParamSpec): string {
  if (!Number.isFinite(value)) return "—";
  const text = formatter(decimalsOf(spec.step)).format(value);
  if (spec.unit === undefined) return text;
  return spec.unit === "×" ? `×${text}` : `${text} ${spec.unit}`;
}

/** Même règle que le serveur : dans les bornes et multiple du pas à partir du minimum. */
export function validateValue(spec: NumericParamSpec, value: number): string | null {
  if (!Number.isFinite(value)) return "Saisissez un nombre.";
  const lo = formatter(decimalsOf(spec.step)).format(spec.min);
  const hi = formatter(decimalsOf(spec.step)).format(spec.max);
  if (value < spec.min || value > spec.max) return `Entre ${lo} et ${hi}.`;
  const steps = (value - spec.min) / spec.step;
  if (Math.abs(steps - Math.round(steps)) * spec.step > 1e-9) return `Par pas de ${formatter(decimalsOf(spec.step)).format(spec.step)} à partir de ${lo}.`;
  return null;
}

/** Ramène une valeur dans les bornes et sur le pas le plus proche (pour les curseurs). */
export function snapToStep(spec: NumericParamSpec, value: number): number {
  const clamped = Math.min(spec.max, Math.max(spec.min, value));
  const snapped = spec.min + Math.round((clamped - spec.min) / spec.step) * spec.step;
  return Number(Math.min(spec.max, snapped).toFixed(decimalsOf(spec.step) + 2));
}

export interface DraftErrors {
  /** Erreur par chemin de réglage. */
  readonly fields: Readonly<Record<string, string>>;
  /** Erreurs qui ne tiennent pas à un seul champ (somme des poids nulle). */
  readonly general: readonly string[];
}

export function validateDraft(params: MatchingParams, specs: readonly NumericParamSpec[]): DraftErrors {
  const fields: Record<string, string> = {};
  for (const spec of specs) {
    const value = readValue(params, spec.path);
    const error = value === undefined ? "Valeur manquante." : validateValue(spec, value);
    if (error !== null) fields[spec.path] = error;
  }
  const weights = Object.values(params.weights);
  const general = weights.every((weight) => weight === 0) ? ["Les poids ne peuvent pas être tous nuls : le moteur n'aurait plus de critère."] : [];
  return { fields, general };
}

export const hasErrors = (errors: DraftErrors): boolean => Object.keys(errors.fields).length > 0 || errors.general.length > 0;

export const RECIPROCITY_LABELS: Readonly<Record<ReciprocityMode, string>> = {
  harmonic: "Moyenne harmonique",
  geometric: "Moyenne géométrique",
  min: "Le plus faible des deux",
  forward_only: "Sens aller seulement",
};
export const RECIPROCITY_ORDER: readonly ReciprocityMode[] = ["harmonic", "geometric", "min", "forward_only"];

export interface ParamChange {
  readonly key: string;
  readonly label: string;
  readonly group: string;
  readonly from: string;
  readonly to: string;
  /** Écart numérique (à − de) pour les nombres, null sinon. */
  readonly delta: number | null;
}

const same = (a: number, b: number): boolean => Math.abs(a - b) < 1e-9;
const yesNo = (value: boolean): string => (value ? "oui" : "non");

/** Écarts de `to` par rapport à `from` : réglages numériques, mode de réciprocité, filtres réciproques, échelles. */
export function diffParams(from: MatchingParams, to: MatchingParams, specs: readonly NumericParamSpec[]): readonly ParamChange[] {
  const changes: ParamChange[] = [];
  for (const spec of specs) {
    const before = readValue(from, spec.path);
    const after = readValue(to, spec.path);
    if (before === undefined || after === undefined || same(before, after)) continue;
    changes.push({ key: spec.path, label: spec.label, group: spec.group, from: formatValue(before, spec), to: formatValue(after, spec), delta: after - before });
  }
  if (from.reciprocity.mode !== to.reciprocity.mode) {
    changes.push({ key: "reciprocity.mode", label: "Mode de réciprocité", group: "reciprocity", from: RECIPROCITY_LABELS[from.reciprocity.mode], to: RECIPROCITY_LABELS[to.reciprocity.mode], delta: null });
  }
  if (from.filters.mutualAge !== to.filters.mutualAge) {
    changes.push({ key: "filters.mutualAge", label: "Âge réciproque", group: "reciprocity", from: yesNo(from.filters.mutualAge), to: yesNo(to.filters.mutualAge), delta: null });
  }
  if (from.filters.mutualDistance !== to.filters.mutualDistance) {
    changes.push({ key: "filters.mutualDistance", label: "Distance réciproque", group: "reciprocity", from: yesNo(from.filters.mutualDistance), to: yesNo(to.filters.mutualDistance), delta: null });
  }
  if (JSON.stringify(from.scales) !== JSON.stringify(to.scales)) {
    changes.push({ key: "scales", label: "Échelles de réponses", group: "scales", from: "version de départ", to: "modifiées", delta: null });
  }
  return changes;
}

/** Vrai si le champ est à sa valeur par défaut. */
export function isDefault(params: MatchingParams, defaults: MatchingParams, spec: NumericParamSpec): boolean {
  const a = readValue(params, spec.path);
  const b = readValue(defaults, spec.path);
  return a !== undefined && b !== undefined && same(a, b);
}
