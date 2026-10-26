import { describe, expect, test } from "bun:test";
import {
  CRITERION_ORDER,
  MULTIPLIER_ORDER,
  explorationSlots,
  exposureFactor,
  freshnessFactor,
  fuse,
  newcomerFactor,
  safetyFactor,
  scaleRows,
  weightShares,
} from "../../console/src/matching/explain";
import { EXCLUSION_ORDER, droppedOut, exclusionCounts, labelOf, movementOf, movementText, sameRanking } from "../../console/src/matching/simulation";
import { RECIPROCITY_ORDER } from "../../console/src/matching/specs";
import { PREVIEW_WINDOW, previewRanking } from "../../src/features/matching/application/preview";
import { CRITERIA, DEFAULT_PARAMS, RECIPROCITY_MODES, type MatchingParams } from "../../src/features/matching/domain/params";
import { multipliers } from "../../src/features/matching/domain/multipliers";
import type { MatchProfile } from "../../src/features/matching/domain/profile";
import { fuse as serverFuse } from "../../src/features/matching/domain/reciprocity";
import { setParam } from "../../src/features/matching/domain/validate-params";

const NOW = "2026-06-01T12:00:00.000Z";
const DAY = 86_400_000;
const daysBefore = (days: number): string => new Date(Date.parse(NOW) - days * DAY).toISOString();

const profile = (patch: Partial<MatchProfile>): MatchProfile => ({
  userId: 9,
  gender: "female",
  lookingFor: "male",
  age: 30,
  ageMin: 25,
  ageMax: 40,
  distanceMaxKm: null,
  location: null,
  denomination: null,
  kashrut: null,
  shabbat: null,
  intention: null,
  photoCount: 2,
  hasBio: true,
  promptCount: 1,
  verification: "none",
  lastActiveAt: NOW,
  createdAt: daysBefore(400),
  boostedUntil: null,
  likesReceived7d: 0,
  openReports90d: 0,
  ...patch,
});

const factorOf = (candidate: MatchProfile, params: MatchingParams, key: string): number => multipliers(candidate, params, NOW).find((m) => m.key === key)?.factor ?? Number.NaN;

describe("vocabulaire aligné sur le moteur", () => {
  test("même liste de critères, de modes et de multiplicateurs que le serveur", () => {
    expect([...CRITERION_ORDER].sort()).toEqual([...CRITERIA].sort());
    expect([...RECIPROCITY_ORDER].sort()).toEqual([...RECIPROCITY_MODES].sort());
    expect(multipliers(profile({}), DEFAULT_PARAMS, NOW).map((m) => m.key)).toEqual([...MULTIPLIER_ORDER]);
  });
  test("chaque motif d'exclusion du serveur a un libellé", () => {
    expect(EXCLUSION_ORDER).toEqual(["excluded", "gender", "age", "distance", "filters"]);
  });
});

describe("poids normalisés", () => {
  test("la somme des parts vaut 1 et reflète les poids actifs", () => {
    const shares = weightShares(DEFAULT_PARAMS.weights);
    expect(shares.reduce((acc, row) => acc + row.share, 0)).toBeCloseTo(1, 12);
    expect(shares.find((row) => row.criterion === "denomination")?.share).toBeCloseTo(6 / 30, 12);
  });
  test("tous nuls : aucune part, pas de division par zéro", () => {
    const zero = Object.fromEntries(CRITERIA.map((c) => [c, 0])) as MatchingParams["weights"];
    expect(weightShares(zero).every((row) => row.share === 0)).toBe(true);
  });
});

describe("réciprocité : même résultat que le moteur", () => {
  test("quatre modes sur une grille de scores", () => {
    const grid = [0, 0.1, 0.4, 0.8, 1];
    for (const mode of RECIPROCITY_MODES) {
      for (const a of grid) for (const b of grid) expect(fuse(a, b, mode)).toBeCloseTo(serverFuse(a, b, mode), 12);
    }
  });
});

describe("multiplicateurs : mêmes facteurs que le moteur", () => {
  const params = setParam(setParam(DEFAULT_PARAMS, "freshness.halfLifeDays", 10), "exposure.strength", 1.2);
  test("fraîcheur", () => {
    for (const idle of [0, 3, 10, 25, 90]) expect(freshnessFactor(idle, params.freshness)).toBeCloseTo(factorOf(profile({ lastActiveAt: daysBefore(idle) }), params, "freshness"), 12);
  });
  test("nouveau venu", () => {
    for (const age of [0, 5, 14, 200]) expect(newcomerFactor(age, params.newcomer)).toBeCloseTo(factorOf(profile({ createdAt: daysBefore(age) }), params, "newcomer"), 12);
    const never = setParam(params, "newcomer.days", 0);
    expect(newcomerFactor(3, never.newcomer)).toBe(1);
  });
  test("exposition", () => {
    for (const likes of [0, 30, 60, 120, 480]) expect(exposureFactor(likes, params.exposure)).toBeCloseTo(factorOf(profile({ likesReceived7d: likes }), params, "exposure"), 12);
  });
  test("sécurité", () => {
    for (const reports of [0, 1, 2, 5, 12]) expect(safetyFactor(reports, params.safety)).toBeCloseTo(factorOf(profile({ openReports90d: reports }), params, "safety"), 12);
  });
});

describe("exploration", () => {
  test("places = partie entière de la part × taille de page, jamais plus que le serveur n'en place", () => {
    expect(explorationSlots(0.1, 30)).toBe(3);
    expect(explorationSlots(0.01, 30)).toBe(0);
    const params = setParam(DEFAULT_PARAMS, "exploration.epsilon", 0.2);
    const { result } = previewRanking({ params, seed: 42, viewer: 4, size: 400 });
    const explored = result.ranked.filter((item) => item.explored).length;
    expect(explored).toBeLessThanOrEqual(explorationSlots(0.2, PREVIEW_WINDOW));
    expect(explored).toBeGreaterThan(0);
  });
});

describe("échelles de réponses", () => {
  test("regroupées par rang, du plus bas au plus haut, sans tirets bas", () => {
    const rows = scaleRows({ non: 0, a_la_maison: 1, home: 1, glatt: 3 });
    expect(rows).toEqual([
      { rank: 0, answers: ["non"] },
      { rank: 1, answers: ["a la maison", "home"] },
      { rank: 3, answers: ["glatt"] },
    ]);
  });
});

describe("lecture d'une simulation", () => {
  const draft = setParam(setParam(DEFAULT_PARAMS, "weights.distance", 10), "weights.denomination", 0);
  const run = previewRanking({ params: draft, compareWith: DEFAULT_PARAMS, seed: 42, viewer: 1, size: 400 });
  const same = previewRanking({ params: DEFAULT_PARAMS, compareWith: DEFAULT_PARAMS, seed: 42, viewer: 1, size: 400 });

  test("des réglages identiques donnent un classement identique, des réglages différents non", () => {
    expect(sameRanking(same.result, same.compare)).toBe(true);
    expect(sameRanking(run.result, run.compare)).toBe(false);
    expect(sameRanking(run.result, null)).toBe(false);
  });
  test("mouvement d'un candidat par rapport à la version active", () => {
    const compare = run.compare;
    expect(compare).not.toBeNull();
    if (compare === null) return;
    for (const candidate of run.result.ranked) {
      const before = compare.ranked.find((item) => item.userId === candidate.userId);
      const move = movementOf(candidate, compare);
      if (before === undefined) expect(move.kind).toBe("new");
      else if (before.rank > candidate.rank) expect(move).toEqual({ kind: "up", places: before.rank - candidate.rank });
      else if (before.rank < candidate.rank) expect(move).toEqual({ kind: "down", places: candidate.rank - before.rank });
      else expect(move.kind).toBe("same");
    }
    expect(run.result.ranked.some((item) => movementOf(item, compare).kind !== "same")).toBe(true);
    expect(movementOf(run.result.ranked[0] ?? (null as never), null)).toEqual({ kind: "same" });
  });
  test("textes de mouvement lisibles par un lecteur d'écran", () => {
    expect(movementText({ kind: "up", places: 3 })).toBe("monte de 3");
    expect(movementText({ kind: "down", places: 1 })).toBe("descend de 1");
    expect(movementText({ kind: "new" })).toBe("entre dans la page");
    expect(movementText({ kind: "same" })).toBe("inchangé");
  });
  test("profils qui sortent de la liste visible", () => {
    const compare = run.compare;
    if (compare === null) throw new Error("comparaison attendue");
    const out = droppedOut(run.result, compare, 5);
    const kept = new Set(run.result.ranked.slice(0, 5).map((item) => item.userId));
    for (const item of out) {
      expect(kept.has(item.userId)).toBe(false);
      expect(compare.ranked.slice(0, 5).map((c) => c.userId)).toContain(item.userId);
    }
    expect(droppedOut(run.result, null, 5)).toEqual([]);
  });
  test("compte des écartés par motif, somme égale au total", () => {
    const counts = exclusionCounts(run.result);
    expect(counts.reduce((acc, row) => acc + row.count, 0)).toBe(run.result.exclusions.length);
    expect(counts.every((row) => row.count > 0)).toBe(true);
  });
  test("étiquette fictive d'un profil, repli lisible", () => {
    const first = run.result.ranked[0];
    expect(first).toBeDefined();
    if (first === undefined) return;
    expect(labelOf(run, first.userId).name).not.toBe("");
    expect(labelOf(run, 999_999)).toEqual({ name: "Profil 999999", city: "—" });
  });
});
