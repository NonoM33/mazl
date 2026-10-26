import { describe, expect, test } from "bun:test";
import { can, SECTIONS, visibleSections } from "../../console/src/app/permissions";
import { createApiClient } from "../../console/src/shared/api/client";
import { tabFromParam } from "../../console/src/matching/tabs";
import {
  GROUP_ORDER,
  diffParams,
  formatValue,
  groupSpecs,
  hasErrors,
  isDefault,
  readValue,
  snapToStep,
  validateDraft,
  validateValue,
  writeValue,
} from "../../console/src/matching/specs";
import { ROLE_PERMISSIONS } from "../../src/features/staff/domain/roles";
import { DEFAULT_PARAMS, NUMERIC_PARAMS, type NumericParamSpec } from "../../src/features/matching/domain/params";
import { getParam, setParam, validateParams } from "../../src/features/matching/domain/validate-params";

// Le validateur du serveur sert d'arbitre : il est écrit à part et ne connaît pas la console.
const serverAccepts = (path: string, value: number): boolean => validateParams(setParam(structuredClone(DEFAULT_PARAMS), path, value)).ok;

function probes(spec: NumericParamSpec): readonly number[] {
  return [spec.min, spec.max, spec.min - spec.step, spec.max + spec.step, spec.min + spec.step * 1.5, (spec.min + spec.max) / 2, spec.min + spec.step, Number.NaN, Number.POSITIVE_INFINITY];
}

describe("regroupement des réglages", () => {
  test("chaque réglage du serveur apparaît une fois, dans un groupe connu de la console", () => {
    const grouped = groupSpecs(NUMERIC_PARAMS);
    expect(grouped.flatMap((g) => g.specs.map((s) => s.path)).sort()).toEqual(NUMERIC_PARAMS.map((s) => s.path).sort());
    for (const spec of NUMERIC_PARAMS) expect(GROUP_ORDER).toContain(spec.group);
    for (const g of grouped) expect(g.title).not.toBe(g.group);
  });
  test("les groupes suivent l'ordre d'affichage, les poids d'abord", () => {
    const ids = groupSpecs(NUMERIC_PARAMS).map((g) => g.group);
    expect(ids[0]).toBe("weights");
    expect(ids).toEqual(GROUP_ORDER.filter((id) => ids.includes(id)));
  });
  test("un groupe inconnu de la console est conservé à la fin, pas perdu", () => {
    const extra = { ...(NUMERIC_PARAMS[0] as NumericParamSpec), path: "weights.age", group: "nouveau-groupe" } as unknown as NumericParamSpec;
    const grouped = groupSpecs([...NUMERIC_PARAMS, extra]);
    expect(grouped.at(-1)?.group).toBe("nouveau-groupe");
    expect(grouped.at(-1)?.title).toBe("nouveau-groupe");
  });
});

describe("lecture et écriture par chemin", () => {
  test("lit comme le serveur", () => {
    for (const spec of NUMERIC_PARAMS) expect(readValue(DEFAULT_PARAMS, spec.path)).toBe(getParam(DEFAULT_PARAMS, spec.path));
  });
  test("écrire ne modifie pas l'original", () => {
    const next = writeValue(DEFAULT_PARAMS, "weights.kashrut", 9);
    expect(readValue(next, "weights.kashrut")).toBe(9);
    expect(DEFAULT_PARAMS.weights.kashrut).toBe(4);
    expect(next.scales).toBe(DEFAULT_PARAMS.scales);
  });
  test("chemin inconnu ou non numérique", () => {
    expect(readValue(DEFAULT_PARAMS, "weights.inconnu")).toBeUndefined();
    expect(readValue(DEFAULT_PARAMS, "reciprocity.mode")).toBeUndefined();
    expect(() => writeValue(DEFAULT_PARAMS, "weights.inconnu", 1)).toThrow();
  });
});

describe("bornes et pas : même verdict que le serveur", () => {
  for (const spec of NUMERIC_PARAMS) {
    test(spec.path, () => {
      for (const value of probes(spec)) {
        const mine = validateValue(spec, value) === null;
        // Le serveur ne reçoit que du JSON : NaN et l'infini y deviennent null, toujours refusés.
        const theirs = Number.isFinite(value) && serverAccepts(spec.path, value);
        expect({ value, accepted: mine }).toEqual({ value, accepted: theirs });
      }
    });
  }
  test("le message dit la borne, en français", () => {
    const spec = NUMERIC_PARAMS.find((s) => s.path === "distance.halfScoreKm") as NumericParamSpec;
    expect(validateValue(spec, 900)).toBe("Entre 1 et 500.");
    expect(validateValue(spec, Number.NaN)).toBe("Saisissez un nombre.");
    const weight = NUMERIC_PARAMS.find((s) => s.path === "weights.age") as NumericParamSpec;
    expect(validateValue(weight, 2.7)).toContain("Par pas de 0,5");
  });
  test("le curseur ramène toujours dans les bornes, sur le pas", () => {
    for (const spec of NUMERIC_PARAMS) {
      for (const raw of [spec.min - 100, spec.max + 100, (spec.min + spec.max) / 3]) {
        expect(validateValue(spec, snapToStep(spec, raw))).toBeNull();
      }
    }
  });
});

describe("validation du brouillon", () => {
  test("les valeurs par défaut sont valides", () => {
    expect(hasErrors(validateDraft(DEFAULT_PARAMS, NUMERIC_PARAMS))).toBe(false);
  });
  test("un champ vide (NaN) ou hors bornes est signalé sous son chemin", () => {
    const draft = writeValue(writeValue(DEFAULT_PARAMS, "distance.halfScoreKm", 900), "weights.age", Number.NaN);
    const errors = validateDraft(draft, NUMERIC_PARAMS);
    expect(Object.keys(errors.fields).sort()).toEqual(["distance.halfScoreKm", "weights.age"]);
    expect(hasErrors(errors)).toBe(true);
  });
  test("des poids tous nuls sont refusés comme au serveur", () => {
    let draft = DEFAULT_PARAMS;
    for (const key of Object.keys(DEFAULT_PARAMS.weights)) draft = writeValue(draft, `weights.${key}`, 0);
    expect(validateDraft(draft, NUMERIC_PARAMS).general).toHaveLength(1);
    expect(validateParams(draft).ok).toBe(false);
  });
});

describe("écarts entre deux jeux de réglages", () => {
  test("aucun écart", () => {
    expect(diffParams(DEFAULT_PARAMS, structuredClone(DEFAULT_PARAMS), NUMERIC_PARAMS)).toEqual([]);
  });
  test("un nombre : valeurs formatées et écart signé", () => {
    const changes = diffParams(DEFAULT_PARAMS, writeValue(DEFAULT_PARAMS, "freshness.halfLifeDays", 21), NUMERIC_PARAMS);
    expect(changes).toHaveLength(1);
    expect(changes[0]).toMatchObject({ key: "freshness.halfLifeDays", from: "14 jours", to: "21 jours", delta: 7 });
  });
  test("mode, filtres réciproques et échelles", () => {
    const next = {
      ...structuredClone(DEFAULT_PARAMS),
      reciprocity: { mode: "min" as const },
      filters: { mutualAge: false, mutualDistance: true },
      scales: { ...DEFAULT_PARAMS.scales, shabbat: { ...DEFAULT_PARAMS.scales.shabbat, observant: 3 } },
    };
    expect(diffParams(DEFAULT_PARAMS, next, NUMERIC_PARAMS).map((c) => c.key)).toEqual(["reciprocity.mode", "filters.mutualAge", "scales"]);
  });
  test("écart nul sous le seuil de comparaison des flottants", () => {
    expect(diffParams(DEFAULT_PARAMS, writeValue(DEFAULT_PARAMS, "freshness.floor", 0.35), NUMERIC_PARAMS)).toHaveLength(1);
    expect(diffParams(DEFAULT_PARAMS, writeValue(DEFAULT_PARAMS, "freshness.floor", 0.3 + 1e-12), NUMERIC_PARAMS)).toEqual([]);
  });
  test("valeur par défaut", () => {
    const spec = NUMERIC_PARAMS[0] as NumericParamSpec;
    expect(isDefault(DEFAULT_PARAMS, DEFAULT_PARAMS, spec)).toBe(true);
    expect(isDefault(writeValue(DEFAULT_PARAMS, spec.path, 1), DEFAULT_PARAMS, spec)).toBe(false);
  });
});

describe("affichage des valeurs", () => {
  const spec = (path: string): NumericParamSpec => NUMERIC_PARAMS.find((s) => s.path === path) as NumericParamSpec;
  test("décimales selon le pas, virgule française, unités", () => {
    expect(formatValue(0.5, spec("religion.unknownScore"))).toBe("0,50");
    expect(formatValue(6, spec("weights.denomination"))).toBe("6,0");
    expect(formatValue(25, spec("distance.halfScoreKm"))).toBe("25 km");
    expect(formatValue(1.5, spec("boost.factor"))).toBe("×1,50");
    expect(formatValue(Number.NaN, spec("boost.factor"))).toBe("—");
  });
});

describe("écran protégé par permission", () => {
  const algorithme = SECTIONS.find((s) => s.id === "algorithme");
  test("la section est livrée et demande matching.read", () => {
    expect(algorithme).toMatchObject({ implemented: true, permission: "matching.read" });
  });
  test("l'analyste lit sans pouvoir régler ; le support ne voit pas la section ; l'administrateur règle", () => {
    const analyst = { permissions: ROLE_PERMISSIONS.analyst };
    expect(visibleSections(analyst).map((s) => s.id)).toContain("algorithme");
    expect(can(analyst, "matching.tune")).toBe(false);
    expect(visibleSections({ permissions: ROLE_PERMISSIONS.support }).map((s) => s.id)).not.toContain("algorithme");
    expect(can({ permissions: ROLE_PERMISSIONS.admin }, "matching.tune")).toBe(true);
  });
  test("onglet demandé par l'adresse, « Comprendre » par défaut", () => {
    expect(tabFromParam("regler")).toBe("regler");
    expect(tabFromParam("historique")).toBe("historique");
    expect(tabFromParam("n-importe-quoi")).toBe("comprendre");
    expect(tabFromParam(undefined)).toBe("comprendre");
  });
});

describe("client d'API : suppression", () => {
  test("DELETE sans corps, jeton en Bearer", async () => {
    const calls: { url: string; init: RequestInit | undefined }[] = [];
    const client = createApiClient({
      fetch: async (url, init) => {
        calls.push({ url, init });
        return new Response(JSON.stringify({ success: true, data: { ok: 1 } }), { status: 200 });
      },
      getToken: () => "tok",
      onUnauthorized: () => {},
      onMfaRequired: () => {},
    });
    const result = await client.delete<{ ok: number }>("/matching/ab-test");
    expect(result).toEqual({ ok: true, data: { ok: 1 } });
    expect(calls[0]?.url).toBe("/api/backoffice/matching/ab-test");
    expect(calls[0]?.init?.method).toBe("DELETE");
    expect(calls[0]?.init?.body).toBeUndefined();
  });
});
