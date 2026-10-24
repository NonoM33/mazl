import { describe, expect, test } from "bun:test";
import { buildQueryString, createApiClient, createTokenStore, TOKEN_KEY, type ApiClientDeps } from "../../console/src/shared/api/client";

interface Harness {
  readonly deps: ApiClientDeps;
  readonly calls: { url: string; init: RequestInit | undefined }[];
  readonly events: string[];
}

function harness(respond: () => Response | Promise<Response>, token: string | null = "tok"): Harness {
  const calls: Harness["calls"] = [];
  const events: string[] = [];
  const deps: ApiClientDeps = {
    fetch: async (url, init) => {
      calls.push({ url, init });
      return respond();
    },
    getToken: () => token,
    onUnauthorized: () => events.push("401"),
    onMfaRequired: () => events.push("mfa"),
  };
  return { deps, calls, events };
}

const json = (status: number, body: unknown): Response => new Response(JSON.stringify(body), { status, headers: { "Content-Type": "application/json" } });

describe("client d'API", () => {
  test("succès : enveloppe dépliée, jeton en Bearer, base /api/backoffice", async () => {
    const h = harness(() => json(200, { success: true, data: { open: 3 } }));
    const result = await createApiClient(h.deps).get<{ open: number }>("/dashboard");
    expect(result).toEqual({ ok: true, data: { open: 3 } });
    expect(h.calls[0]?.url).toBe("/api/backoffice/dashboard");
    expect((h.calls[0]?.init?.headers as Record<string, string>)["Authorization"]).toBe("Bearer tok");
  });

  test("pas d'en-tête Authorization sans jeton", async () => {
    const h = harness(() => json(200, { success: true, data: 1 }), null);
    await createApiClient(h.deps).get("/x");
    expect((h.calls[0]?.init?.headers as Record<string, string>)["Authorization"]).toBeUndefined();
  });

  test("erreur métier : code et message du serveur conservés", async () => {
    const h = harness(() => json(409, { success: false, error: "same_decider", message: "Même décideur." }));
    const result = await createApiClient(h.deps).post("/appeals/1/decision", { outcome: "upheld" });
    expect(result).toEqual({ ok: false, status: 409, code: "same_decider", message: "Même décideur." });
  });

  test("401 avec jeton : retour à la connexion", async () => {
    const h = harness(() => json(401, { success: false, error: "unauthorized" }));
    const result = await createApiClient(h.deps).get("/me");
    expect(h.events).toEqual(["401"]);
    expect(result.ok).toBe(false);
  });

  test("401 sans jeton (mot de passe faux) : pas de redirection, message du serveur", async () => {
    const h = harness(() => json(401, { success: false, error: "invalid_credentials" }), null);
    const result = await createApiClient(h.deps).post("/auth/password", {});
    expect(h.events).toEqual([]);
    expect(result).toMatchObject({ ok: false, code: "invalid_credentials", message: "Identifiants incorrects." });
  });

  test("403 mfa_required : écran d'enrôlement", async () => {
    const h = harness(() => json(403, { success: false, error: "mfa_required" }));
    await createApiClient(h.deps).get("/dashboard");
    expect(h.events).toEqual(["mfa"]);
  });

  test("403 ordinaire : pas d'enrôlement", async () => {
    const h = harness(() => json(403, { success: false, error: "forbidden" }));
    const result = await createApiClient(h.deps).get("/members");
    expect(h.events).toEqual([]);
    expect(result).toMatchObject({ ok: false, status: 403, code: "forbidden" });
  });

  test("réseau coupé et réponse illisible", async () => {
    const down = createApiClient({ ...harness(() => json(200, {})).deps, fetch: async () => Promise.reject(new Error("offline")) });
    expect(await down.get("/x")).toMatchObject({ ok: false, status: 0, code: "network" });
    const html = harness(() => new Response("<html>", { status: 502 }));
    expect(await createApiClient(html.deps).get("/x")).toMatchObject({ ok: false, status: 502, code: "bad_response" });
  });

  test("corps JSON et chaîne de requête sans valeurs vides", async () => {
    const h = harness(() => json(200, { success: true, data: null }));
    await createApiClient(h.deps).post("/reports/1/assign", { to: "me" });
    expect(h.calls[0]?.init?.body).toBe('{"to":"me"}');
    expect(buildQueryString({ q: "jeanne", status: "", limit: 25, none: null })).toBe("?q=jeanne&limit=25");
    expect(buildQueryString({})).toBe("");
  });
});

describe("jeton de session", () => {
  test("lu, écrit et effacé sous la clé mazl.staff.token", () => {
    const data = new Map<string, string>();
    const store = createTokenStore({
      getItem: (k) => data.get(k) ?? null,
      setItem: (k, v) => void data.set(k, v),
      removeItem: (k) => void data.delete(k),
    });
    expect(store.read()).toBeNull();
    store.write("abc");
    expect(data.get(TOKEN_KEY)).toBe("abc");
    expect(TOKEN_KEY).toBe("mazl.staff.token");
    store.clear();
    expect(store.read()).toBeNull();
  });
});
