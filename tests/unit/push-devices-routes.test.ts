import { beforeEach, describe, expect, test } from "bun:test";
import { Hono } from "hono";
import { createMiddleware } from "hono/factory";
import type { ApnsEnvironment, PushDevice, PushDeviceStore } from "../../src/features/push/application/ports";
import { registerPushDevicesRoutes } from "../../src/features/push/presentation/push-devices.routes";
import type { AppVariables } from "../../src/shared/http/middleware";

// The app declares its APNs token (PUT /api/push/devices) at every signed-in
// launch and withdraws it at sign-out (DELETE). Contract shared with the app:
// token in lowercase hexadecimal, 64 to 200 characters; environment
// "production" or "sandbox".

class FakeStore implements PushDeviceStore {
  registered: Array<[number, string, ApnsEnvironment]> = [];
  unregistered: Array<[number, string]> = [];
  register(userId: number, token: string, environment: ApnsEnvironment): Promise<void> {
    this.registered.push([userId, token, environment]);
    return Promise.resolve();
  }
  unregister(userId: number, token: string): Promise<void> {
    this.unregistered.push([userId, token]);
    return Promise.resolve();
  }
  devicesOf(): Promise<PushDevice[]> {
    return Promise.resolve([]);
  }
  forget(): Promise<void> {
    return Promise.resolve();
  }
}

const TOKEN = "0a1b2c3d".repeat(8);
let store: FakeStore;
let app: Hono<{ Variables: AppVariables }>;

beforeEach(() => {
  store = new FakeStore();
  const authenticate = createMiddleware<{ Variables: AppVariables }>(async (c, next) => {
    const id = Number(c.req.header("x-test-user"));
    if (!Number.isInteger(id)) return c.json({ success: false, error: "Invalid token" }, 401);
    c.set("userId", id);
    await next();
  });
  app = new Hono<{ Variables: AppVariables }>();
  registerPushDevicesRoutes(app, { authenticate, devices: store });
});

const call = (method: "PUT" | "DELETE", body: unknown, user: number | null = 44) =>
  app.request("/api/push/devices", {
    method,
    headers: { "content-type": "application/json", ...(user === null ? {} : { "x-test-user": String(user) }) },
    body: JSON.stringify(body),
  });

describe("PUT /api/push/devices", () => {
  test("records the token of the signed-in member with its environment", async () => {
    const res = await call("PUT", { token: TOKEN, environment: "production" });
    expect(res.status).toBe(200);
    expect(await res.json()).toEqual({ success: true });
    expect(store.registered).toEqual([[44, TOKEN, "production"]]);
  });

  test("an upper-case token is the same token", async () => {
    await call("PUT", { token: TOKEN.toUpperCase(), environment: "sandbox" });
    expect(store.registered).toEqual([[44, TOKEN, "sandbox"]]);
  });

  test("a malformed token or environment is 400, nothing recorded", async () => {
    for (const body of [
      { token: "abc", environment: "production" },
      { token: "z".repeat(64), environment: "production" },
      { token: "a".repeat(201), environment: "production" },
      { token: TOKEN, environment: "staging" },
      { token: TOKEN },
    ]) {
      expect((await call("PUT", body)).status).toBe(400);
    }
    expect(store.registered).toEqual([]);
  });

  test("requires a signed-in member", async () => {
    expect((await call("PUT", { token: TOKEN, environment: "production" }, null)).status).toBe(401);
    expect(store.registered).toEqual([]);
  });
});

describe("DELETE /api/push/devices", () => {
  test("withdraws the token for the signed-in member only", async () => {
    const res = await call("DELETE", { token: TOKEN });
    expect(res.status).toBe(200);
    expect(store.unregistered).toEqual([[44, TOKEN]]);
  });

  test("a malformed token is 400; no member, 401", async () => {
    expect((await call("DELETE", { token: "nope" })).status).toBe(400);
    expect((await call("DELETE", { token: TOKEN }, null)).status).toBe(401);
    expect(store.unregistered).toEqual([]);
  });
});
