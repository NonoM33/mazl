// Maquette de l'API /api/backoffice/matching : même contrat que le serveur, état en mémoire.
// Les réglages sont validés et le classement calculé par le VRAI moteur (domaine et simulation du serveur),
// sur sa population fictive : la maquette ne contient aucune donnée de membre.
import type { Hono } from "hono";
import { InvalidParamsError, InvalidPreviewError } from "../../src/features/matching/application/errors";
import { previewRanking } from "../../src/features/matching/application/preview";
import { DEFAULT_PARAMS, NUMERIC_PARAMS, type MatchingParams } from "../../src/features/matching/domain/params";
import { setParam, validateParams } from "../../src/features/matching/domain/validate-params";
import type { MeDto, ParamsVersionDto } from "../src/shared/api/contracts";

const DAY = 86_400_000;
const daysAgo = (days: number): string => new Date(Date.now() - days * DAY).toISOString();

interface StoredVersion extends ParamsVersionDto {
  activatedAt: string | null;
}

const tweak = (changes: readonly (readonly [string, number])[], base: MatchingParams = DEFAULT_PARAMS): MatchingParams => changes.reduce((params, [path, value]) => setParam(params, path, value), structuredClone(base));

const geometric: MatchingParams = { ...structuredClone(DEFAULT_PARAMS), reciprocity: { mode: "geometric" } };
const holidays = tweak([["weights.kashrut", 6], ["weights.shabbat", 6], ["religion.kashrutTolerance", 3]]);
const exploration = tweak([["exploration.epsilon", 0.2], ["exploration.minScore", 0.3]]);
const current = tweak([["weights.distance", 3], ["distance.halfScoreKm", 40], ["newcomer.bonus", 0.3]], holidays);

const versions: StoredVersion[] = [
  { id: 1, params: structuredClone(DEFAULT_PARAMS), note: "Réglages d'origine du moteur.", author: "admin@example.com", createdAt: daysAgo(74), parentId: null, activatedAt: daysAgo(74) },
  { id: 2, params: holidays, note: "Plus de poids à la cashrout et au chabbat avant les fêtes.", author: "admin@example.com", createdAt: daysAgo(41), parentId: 1, activatedAt: daysAgo(41) },
  { id: 3, params: exploration, note: "Essai : 20 % d'exploration pour mieux faire circuler les nouveaux profils.", author: "produit@example.com", createdAt: daysAgo(27), parentId: 2, activatedAt: daysAgo(27) },
  { id: 4, params: holidays, note: "Retour arrière : l'exploration à 20 % fait trop varier la page.", author: "admin@example.com", createdAt: daysAgo(19), parentId: 3, activatedAt: daysAgo(19) },
  { id: 5, params: geometric, note: "Variante réciprocité géométrique, à comparer en A/B.", author: "produit@example.com", createdAt: daysAgo(9), parentId: 4, activatedAt: null },
  { id: 6, params: current, note: "Distance moins pénalisante hors grandes villes, bonus nouveaux relevé.", author: "admin@example.com", createdAt: daysAgo(3), parentId: 4, activatedAt: daysAgo(3) },
];
const state: { activeId: number; abTest: { variantId: number; sharePercent: number; startedAt: string; startedBy: string } | null } = {
  activeId: 6,
  abTest: { variantId: 5, sharePercent: 15, startedAt: daysAgo(2), startedBy: "produit@example.com" },
};

const strip = ({ activatedAt: _activatedAt, ...version }: StoredVersion): ParamsVersionDto => version;
const byId = (id: number): StoredVersion | undefined => versions.find((version) => version.id === id);

function overview(): unknown {
  const active = byId(state.activeId);
  const variant = state.abTest === null ? undefined : byId(state.abTest.variantId);
  return {
    active: active === undefined ? null : strip(active),
    abTest: state.abTest === null || variant === undefined ? null : { variant: strip(variant), sharePercent: state.abTest.sharePercent, startedAt: state.abTest.startedAt, startedBy: state.abTest.startedBy },
    specs: NUMERIC_PARAMS,
    defaults: DEFAULT_PARAMS,
  };
}

const noteOk = (note: unknown): note is string => typeof note === "string" && note.trim().length >= 3 && note.trim().length <= 500;

type Guard = (c: never) => MeDto;

export function registerMatchingMock(api: Hono, meOf: Guard): void {
  const base = "/matching";
  const ok = <T,>(data: T): { success: true; data: T } => ({ success: true, data });
  const fail = (error: string, message?: string): { success: false; error: string; message?: string } => (message === undefined ? { success: false, error } : { success: false, error, message });
  const allowed = (c: never, permission: "matching.read" | "matching.tune"): boolean => meOf(c).permissions.includes(permission);
  const json = async (c: { req: { json: () => Promise<unknown> } }): Promise<Record<string, unknown>> => {
    try {
      const body = await c.req.json();
      return typeof body === "object" && body !== null ? (body as Record<string, unknown>) : {};
    } catch {
      return {};
    }
  };

  api.get(base, (c) => (allowed(c as never, "matching.read") ? c.json(ok(overview())) : c.json(fail("forbidden"), 403)));

  api.get(`${base}/versions`, (c) => {
    if (!allowed(c as never, "matching.read")) return c.json(fail("forbidden"), 403);
    const limit = Math.min(100, Math.max(1, Number(c.req.query("limit") ?? 20)));
    const offset = Math.max(0, Number(c.req.query("offset") ?? 0));
    const sorted = [...versions].sort((a, b) => b.id - a.id);
    return c.json(ok({ versions: sorted.slice(offset, offset + limit), total: sorted.length }));
  });

  api.post(`${base}/versions`, async (c) => {
    if (!allowed(c as never, "matching.tune")) return c.json(fail("forbidden"), 403);
    const body = await json(c);
    if (!noteOk(body["note"]) || body["params"] === undefined) return c.json(fail("invalid_body"), 400);
    const validation = validateParams(body["params"]);
    if (!validation.ok) return c.json(fail("invalid_params", validation.errors.join(" ; ")), 400);
    const version: StoredVersion = { id: Math.max(...versions.map((v) => v.id)) + 1, params: validation.params, note: body["note"].trim(), author: meOf(c as never).email, createdAt: new Date().toISOString(), parentId: state.activeId, activatedAt: null };
    versions.push(version);
    if (body["activate"] === true) {
      version.activatedAt = new Date().toISOString();
      if (state.abTest?.variantId === version.id) state.abTest = null;
      state.activeId = version.id;
    }
    return c.json(ok(strip(version)), 201);
  });

  api.post(`${base}/versions/:id/activate`, async (c) => {
    if (!allowed(c as never, "matching.tune")) return c.json(fail("forbidden"), 403);
    const version = byId(Number(c.req.param("id")));
    if (version === undefined) return c.json(fail("version_not_found"), 404);
    if (!noteOk((await json(c))["note"])) return c.json(fail("invalid_body"), 400);
    version.activatedAt = new Date().toISOString();
    if (state.abTest?.variantId === version.id) state.abTest = null;
    state.activeId = version.id;
    return c.json(ok(overview()));
  });

  api.post(`${base}/ab-test`, async (c) => {
    if (!allowed(c as never, "matching.tune")) return c.json(fail("forbidden"), 403);
    const body = await json(c);
    const share = body["sharePercent"];
    const variantId = body["variantId"];
    if (typeof share !== "number" || !Number.isInteger(share) || share < 1 || share > 50 || typeof variantId !== "number") return c.json(fail("invalid_body"), 400);
    if (byId(variantId) === undefined) return c.json(fail("version_not_found"), 404);
    if (variantId === state.activeId) return c.json(fail("variant_is_active", `La version ${variantId} est déjà la version active : elle ne peut pas être sa propre variante`), 409);
    state.abTest = { variantId, sharePercent: share, startedAt: new Date().toISOString(), startedBy: meOf(c as never).email };
    return c.json(ok(overview()));
  });

  api.delete(`${base}/ab-test`, (c) => {
    if (!allowed(c as never, "matching.tune")) return c.json(fail("forbidden"), 403);
    if (state.abTest === null) return c.json(fail("no_ab_test"), 404);
    state.abTest = null;
    return c.json(ok(overview()));
  });

  api.post(`${base}/preview`, async (c) => {
    if (!allowed(c as never, "matching.read")) return c.json(fail("forbidden"), 403);
    const body = await json(c);
    const seed = body["seed"];
    const viewer = body["viewer"];
    if (typeof seed !== "number" || !Number.isInteger(seed) || (typeof viewer !== "number" && typeof viewer !== "object") || body["params"] === undefined) return c.json(fail("invalid_body"), 400);
    try {
      const size = typeof body["size"] === "number" ? body["size"] : undefined;
      const compareWith = body["compareWith"];
      return c.json(ok(previewRanking({ params: body["params"], seed, viewer: viewer as never, ...(compareWith === undefined ? {} : { compareWith }), ...(size === undefined ? {} : { size }) })));
    } catch (error: unknown) {
      if (error instanceof InvalidParamsError) return c.json(fail("invalid_params", error.problems.join(" ; ")), 400);
      if (error instanceof InvalidPreviewError) return c.json(fail("invalid_preview", error.message), 400);
      throw error;
    }
  });
}
