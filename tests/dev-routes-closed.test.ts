import { afterAll, beforeAll, describe, expect, test } from "bun:test";
import type { Subprocess } from "bun";
import { join } from "node:path";

// The /api/dev/* routes hand out a token for any e-mail. They must exist only
// when NODE_ENV says development or test: a staging server that forgot
// NODE_ENV, or set it to anything else, keeps them closed. This test boots a
// second server on the test database with such values.

const PORT = 3000 + Math.floor(Math.random() * 900) + 4100;
const BASE = `http://127.0.0.1:${PORT}`;
let server: Subprocess | null = null;

async function boot(nodeEnv: string | undefined): Promise<void> {
  const env: Record<string, string> = { ...(process.env as Record<string, string>), PORT: String(PORT) };
  if (nodeEnv === undefined) delete env.NODE_ENV;
  else env.NODE_ENV = nodeEnv;
  server = Bun.spawn(["bun", join(import.meta.dir, "../src/index.ts")], { env, stdout: "ignore", stderr: "ignore" });
  for (let i = 0; i < 100; i++) {
    try {
      if ((await fetch(`${BASE}/api/health`)).ok) return;
    } catch {
      // not listening yet
    }
    await Bun.sleep(100);
  }
  throw new Error("second server did not start");
}

async function stop(): Promise<void> {
  server?.kill();
  await server?.exited;
  server = null;
}

const DEV_ROUTES: Array<[string, string, unknown]> = [
  ["POST", "/api/dev/test-login", { email: "anyone@example.com" }],
  ["POST", "/api/dev/test-user", { email: "anyone@example.com", password: "x" }],
  ["POST", "/api/dev/couple/enable", { userId: 1, partnerId: 2 }],
  ["GET", "/api/dev/couple/status/1", undefined],
  ["GET", "/api/dev/reset-swipes/anyone@example.com", undefined],
];

for (const nodeEnv of ["staging", undefined]) {
  describe(`NODE_ENV=${nodeEnv ?? "(unset)"}`, () => {
    beforeAll(() => boot(nodeEnv), 15_000);
    afterAll(stop);

    test("every development route answers 404 and gives no token", async () => {
      for (const [method, path, body] of DEV_ROUTES) {
        const res = await fetch(`${BASE}${path}`, {
          method,
          headers: { "Content-Type": "application/json" },
          body: body === undefined ? undefined : JSON.stringify(body),
        });
        expect(res.status).toBe(404);
        expect(await res.text()).not.toContain("token");
      }
    });
  });
}
