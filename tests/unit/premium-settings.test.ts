import { describe, expect, test } from "bun:test";
import { Hono } from "hono";
import { createMiddleware } from "hono/factory";
import { PremiumSettingsService } from "../../src/features/premium-settings/application/premium-settings-service";
import type { SettingsStore } from "../../src/features/premium-settings/application/ports";
import { DEFAULT_SETTINGS, type Passport, type StoredSettings } from "../../src/features/premium-settings/domain/settings";
import { registerPremiumSettingsRoutes } from "../../src/features/premium-settings/presentation/settings.routes";
import type { AppVariables } from "../../src/shared/http/middleware";

// docs/premium/MONETISATION.md sections 2, 3 and 4: the server says what is in
// force. Passport and discreet mode need mazl+, the receipts switch does not.

class MemoryStore implements SettingsStore {
  readonly rows = new Map<number, StoredSettings>();
  read = async (userId: number) => this.rows.get(userId) ?? DEFAULT_SETTINGS;
  private put(userId: number, patch: Partial<StoredSettings>) { this.rows.set(userId, { ...(this.rows.get(userId) ?? DEFAULT_SETTINGS), ...patch }); }
  setPassport = async (userId: number, passport: Passport | null) => this.put(userId, { passport });
  setIncognito = async (userId: number, incognito: boolean) => this.put(userId, { incognito });
  setReadReceipts = async (userId: number, sendReadReceipts: boolean) => this.put(userId, { sendReadReceipts });
}

const TEL_AVIV = { city: "Tel-Aviv", latitude: 32.0853, longitude: 34.7818 };

function setup(plus: boolean) {
  const store = new MemoryStore();
  const state = { plus };
  const service = new PremiumSettingsService(store, { isPlus: async () => state.plus });
  const app = new Hono<{ Variables: AppVariables }>();
  const authenticate = createMiddleware<{ Variables: AppVariables }>(async (c, next) => { c.set("userId", 7); await next(); });
  registerPremiumSettingsRoutes(app, { authenticate, settings: service });
  const call = (method: string, path: string, body?: unknown) =>
    app.request(path, { method, headers: { "Content-Type": "application/json" }, ...(body === undefined ? {} : { body: JSON.stringify(body) }) });
  return { store, state, call };
}

describe("GET /api/premium/settings", () => {
  test("defaults: nothing switched on, receipts sent", async () => {
    const { call } = setup(false);
    const res = await call("GET", "/api/premium/settings");
    expect(res.status).toBe(200);
    expect(await res.json()).toEqual({ success: true, data: { is_plus: false, passport: null, incognito: false, send_read_receipts: true } });
  });

  test("a passport and a discreet mode kept from a past subscription are not in force", async () => {
    const { call, state, store } = setup(true);
    await call("PUT", "/api/discover/passport", TEL_AVIV);
    await call("PUT", "/api/profile/incognito", { enabled: true });
    state.plus = false;
    const body = (await (await call("GET", "/api/premium/settings")).json()) as { data: Record<string, unknown> };
    expect(body.data).toEqual({ is_plus: false, passport: null, incognito: false, send_read_receipts: true });
    // Kept, ready for when mazl+ is back.
    expect(store.rows.get(7)?.passport).toEqual(TEL_AVIV);
    state.plus = true;
    expect(((await (await call("GET", "/api/premium/settings")).json()) as { data: { passport: unknown } }).data.passport).toEqual(TEL_AVIV);
  });
});

describe("PUT /api/discover/passport", () => {
  test("402 mazl_plus_required without mazl+, and nothing is stored", async () => {
    const { call, store } = setup(false);
    const res = await call("PUT", "/api/discover/passport", TEL_AVIV);
    expect([res.status, await res.json()]).toEqual([402, { success: false, error: "mazl_plus_required" }]);
    expect(store.rows.size).toBe(0);
  });

  test("with mazl+ the city is kept and handed back", async () => {
    const { call } = setup(true);
    const res = await call("PUT", "/api/discover/passport", { ...TEL_AVIV, city: "  Tel-Aviv  " });
    expect([res.status, await res.json()]).toEqual([200, { success: true, data: { passport: TEL_AVIV } }]);
  });

  test("null brings the member home, even once the subscription has ended", async () => {
    const { call, state, store } = setup(true);
    await call("PUT", "/api/discover/passport", TEL_AVIV);
    state.plus = false;
    const res = await call("PUT", "/api/discover/passport", null);
    expect([res.status, await res.json()]).toEqual([200, { success: true, data: { passport: null } }]);
    expect(store.rows.get(7)?.passport).toBeNull();
  });

  test("400 invalid_body for anything that is not a city with a position", async () => {
    const { call } = setup(true);
    const bad: unknown[] = [
      {}, { city: "", latitude: 1, longitude: 1 }, { city: "x".repeat(81), latitude: 1, longitude: 1 }, { city: "Paris", latitude: 91, longitude: 1 },
      { city: "Paris", latitude: 1, longitude: -181 }, { city: "Paris", latitude: "48", longitude: 2 }, { city: "Pa\u0000ris", latitude: 48, longitude: 2 }, "Paris", 42, [],
    ];
    for (const body of bad) {
      const res = await call("PUT", "/api/discover/passport", body);
      expect([JSON.stringify(body), res.status, ((await res.json()) as { error: string }).error]).toEqual([JSON.stringify(body), 400, "invalid_body"]);
    }
    const notJson = await setup(true).call("PUT", "/api/discover/passport");
    expect(notJson.status).toBe(400);
  });

  test("an error never carries the text of an exception", async () => {
    const { call, store } = setup(true);
    store.setPassport = async () => { throw new Error("password=secret db down"); };
    const original = console.error;
    console.error = () => undefined;
    try {
      const res = await call("PUT", "/api/discover/passport", TEL_AVIV);
      expect([res.status, await res.json()]).toEqual([500, { success: false, error: "internal_error" }]);
    } finally {
      console.error = original;
    }
  });
});

describe("PUT /api/profile/incognito", () => {
  test("402 to switch it on without mazl+; switching it off is always allowed", async () => {
    const { call, state, store } = setup(false);
    const refused = await call("PUT", "/api/profile/incognito", { enabled: true });
    expect([refused.status, await refused.json()]).toEqual([402, { success: false, error: "mazl_plus_required" }]);
    state.plus = true;
    await call("PUT", "/api/profile/incognito", { enabled: true });
    state.plus = false;
    const off = await call("PUT", "/api/profile/incognito", { enabled: false });
    expect([off.status, await off.json()]).toEqual([200, { success: true, data: { incognito: false } }]);
    expect(store.rows.get(7)?.incognito).toBe(false);
  });

  test("400 for a body without a boolean", async () => {
    const { call } = setup(true);
    for (const body of [{}, { enabled: "yes" }, { enabled: 1 }, null]) expect((await call("PUT", "/api/profile/incognito", body)).status).toBe(400);
  });
});

describe("PUT /api/profile/read-receipts", () => {
  test("every member may turn their receipts off and on, mazl+ or not", async () => {
    const { call, store } = setup(false);
    const off = await call("PUT", "/api/profile/read-receipts", { enabled: false });
    expect([off.status, await off.json()]).toEqual([200, { success: true, data: { send_read_receipts: false } }]);
    expect(store.rows.get(7)?.sendReadReceipts).toBe(false);
    const settings = (await (await call("GET", "/api/premium/settings")).json()) as { data: { send_read_receipts: boolean } };
    expect(settings.data.send_read_receipts).toBe(false);
    await call("PUT", "/api/profile/read-receipts", { enabled: true });
    expect(store.rows.get(7)?.sendReadReceipts).toBe(true);
  });

  test("400 for a body without a boolean", async () => {
    expect((await setup(false).call("PUT", "/api/profile/read-receipts", { enabled: "no" })).status).toBe(400);
  });
});
