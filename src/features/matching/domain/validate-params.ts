import { answerKey } from "./normalize";
import {
  CRITERIA,
  DEFAULT_PARAMS,
  NUMERIC_PARAMS,
  RECIPROCITY_MODES,
  SCALES,
  SCALE_RANK_BOUNDS,
  type MatchingParams,
  type NumericParamSpec,
  type OrdinalScale,
  type ParamsValidation,
  type ReciprocityMode,
  type ScaleName,
} from "./params";

type Rec = Record<string, unknown>;
const isRec = (v: unknown): v is Rec => typeof v === "object" && v !== null && !Array.isArray(v);

function lookup(root: unknown, path: string): unknown {
  let node: unknown = root;
  for (const key of path.split(".")) {
    if (!isRec(node) || !Object.hasOwn(node, key)) return undefined;
    node = node[key];
  }
  return node;
}

export function getParam(params: MatchingParams, path: string): number {
  const value = lookup(params, path);
  if (typeof value !== "number") throw new RangeError(`Paramètre numérique inconnu : ${path}`);
  return value;
}

function assign(node: Rec, keys: readonly string[], value: number): Rec {
  const [head, ...rest] = keys;
  if (head === undefined) throw new RangeError("Chemin vide");
  if (rest.length === 0) return { ...node, [head]: value };
  const child = node[head];
  if (!isRec(child)) throw new RangeError(`Chemin inconnu : ${keys.join(".")}`);
  return { ...node, [head]: assign(child, rest, value) };
}

export function setParam(params: MatchingParams, path: string, value: number): MatchingParams {
  getParam(params, path);
  return assign(params as unknown as Rec, path.split("."), value) as unknown as MatchingParams;
}

function checkNumber(input: unknown, spec: NumericParamSpec, errors: string[]): number | null {
  const value = lookup(input, spec.path);
  if (value === undefined) return pushError(errors, `${spec.path} : valeur manquante`);
  if (typeof value !== "number" || !Number.isFinite(value)) return pushError(errors, `${spec.path} : nombre attendu`);
  if (value < spec.min || value > spec.max) {
    return pushError(errors, `${spec.path} = ${value} : hors bornes [${spec.min}, ${spec.max}]`);
  }
  const steps = (value - spec.min) / spec.step;
  if (Math.abs(steps - Math.round(steps)) * spec.step > 1e-9) {
    return pushError(errors, `${spec.path} = ${value} : doit être un multiple de ${spec.step} à partir de ${spec.min}`);
  }
  return value;
}

function pushError(errors: string[], message: string): null {
  errors.push(message);
  return null;
}

function checkScale(input: unknown, name: ScaleName, errors: string[]): OrdinalScale | null {
  const path = `scales.${name}`;
  const raw = lookup(input, path);
  if (raw === undefined) return pushError(errors, `${path} : échelle manquante`);
  if (!isRec(raw)) return pushError(errors, `${path} : objet attendu`);
  const entries = Object.entries(raw);
  const before = errors.length;
  if (entries.length < 2) errors.push(`${path} : au moins 2 réponses attendues`);
  for (const [key, rank] of entries) {
    if (answerKey(key) !== key || key === "") errors.push(`${path}.${key} : clé non normalisée`);
    const { min, max } = SCALE_RANK_BOUNDS;
    if (typeof rank !== "number" || !Number.isInteger(rank) || rank < min || rank > max) {
      errors.push(`${path}.${key} : rang entier attendu dans [${min}, ${max}]`);
    }
  }
  return errors.length === before ? ({ ...(raw as Record<string, number>) }) : null;
}

function checkFlag(input: unknown, path: string, errors: string[]): boolean | null {
  const value = lookup(input, path);
  if (typeof value !== "boolean") return pushError(errors, `${path} : booléen attendu`);
  return value;
}

function checkMode(input: unknown, errors: string[]): ReciprocityMode | null {
  const value = lookup(input, "reciprocity.mode");
  const mode = RECIPROCITY_MODES.find((m) => m === value);
  if (mode === undefined) return pushError(errors, `reciprocity.mode : un de ${RECIPROCITY_MODES.join(", ")} attendu`);
  return mode;
}

export function validateParams(input: unknown): ParamsValidation {
  if (!isRec(input)) return { ok: false, errors: ["Les paramètres doivent être un objet"] };
  const errors: string[] = [];
  let params = structuredClone(DEFAULT_PARAMS);
  for (const spec of NUMERIC_PARAMS) {
    const value = checkNumber(input, spec, errors);
    if (value !== null) params = setParam(params, spec.path, value);
  }
  const mutualAge = checkFlag(input, "filters.mutualAge", errors);
  const mutualDistance = checkFlag(input, "filters.mutualDistance", errors);
  const mode = checkMode(input, errors);
  const scales = Object.fromEntries(SCALES.map((name) => [name, checkScale(input, name, errors)]));
  if (CRITERIA.every((c) => (lookup(input, `weights.${c}`) as unknown) === 0)) {
    errors.push("weights : la somme des poids doit être supérieure à 0");
  }
  if (errors.length > 0 || mutualAge === null || mutualDistance === null || mode === null) return { ok: false, errors };
  return {
    ok: true,
    params: { ...params, filters: { mutualAge, mutualDistance }, reciprocity: { mode }, scales: scales as MatchingParams["scales"] },
  };
}
