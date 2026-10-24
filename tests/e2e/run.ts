// Runs the web e2e scenarios against a real server and a throwaway database:
//   bun tests/e2e/run.ts                    every tests/e2e/*.e2e.ts
//   bun tests/e2e/run.ts discover messages  only those scenarios
// It builds the web client, resets the e2e database, starts the server
// (development mode, test secrets drawn at random, low proof-of-work
// difficulty, fake Stripe), runs the scenarios, then stops everything.
import { randomBytes } from "node:crypto";
import { readdir } from "node:fs/promises";
import postgres from "postgres";
import { BASE_URL, DATABASE_URL, E2E_PORT } from "./support/env";
import { startFakeStripe } from "./support/fake-stripe-server";

const root = new URL("../../", import.meta.url).pathname;

async function resetDatabase(): Promise<void> {
  const sql = postgres(DATABASE_URL, { max: 1, onnotice: () => undefined });
  await sql.unsafe("DROP SCHEMA public CASCADE; CREATE SCHEMA public;");
  await sql.end();
}

async function waitForHealth(): Promise<void> {
  for (let attempt = 0; attempt < 60; attempt += 1) {
    try {
      if ((await fetch(`${BASE_URL}/api/health`)).ok) return;
    } catch {
      // Not listening yet.
    }
    await Bun.sleep(500);
  }
  throw new Error("e2e server did not start");
}

async function scenarios(filter: readonly string[]): Promise<string[]> {
  const files = (await readdir(new URL("./", import.meta.url))).filter((file) => file.endsWith(".e2e.ts")).sort();
  const chosen = filter.length === 0 ? files : files.filter((file) => filter.some((name) => file.startsWith(name)));
  return chosen.map((file) => `./tests/e2e/${file}`);
}

const build = Bun.spawnSync(["bun", "web/build.ts"], { cwd: root, stdout: "ignore", stderr: "inherit" });
if (build.exitCode !== 0) process.exit(build.exitCode);
const secret = () => randomBytes(32).toString("hex");

// Each scenario file gets a fresh database and server: they seed their own
// community and must not see another file's members.
async function runScenario(file: string): Promise<number> {
  await resetDatabase();
  const stripe = await startFakeStripe();
  const env = {
    ...process.env,
    NODE_ENV: "development",
    // Like the production container: TIMESTAMP columns hold UTC and are read as such.
    TZ: "UTC",
    PORT: String(E2E_PORT),
    DATABASE_URL,
    JWT_SECRET: secret(),
    ADMIN_JWT_SECRET: secret(),
    ADMIN_EMAIL: "admin@example.com",
    ADMIN_EMAILS: "admin@example.com",
    ADMIN_PASSWORD: secret(),
    UPLOADS_DIR: `/tmp/mazl-web-e2e-uploads-${E2E_PORT}`,
    PUBLIC_BASE_URL: BASE_URL,
    APP_URL: BASE_URL,
    // One client address per test browser (support/browser.ts), as behind Traefik.
    TRUSTED_PROXY_HOPS: "1",
    WEB_POW_DIFFICULTY: "8",
    STRIPE_SECRET_KEY: `sk_test_${secret()}`,
    STRIPE_WEBHOOK_SECRET: stripe.webhookSecret,
    STRIPE_API_BASE: stripe.baseUrl,
    ...stripe.priceEnv,
  };
  const server = Bun.spawn(["bun", "src/index.ts"], { cwd: root, env, stdout: Bun.file(`/tmp/mazl-web-e2e-${E2E_PORT}.log`), stderr: Bun.file(`/tmp/mazl-web-e2e-${E2E_PORT}.err.log`) });
  try {
    await waitForHealth();
    const run = Bun.spawn(["bun", "test", "--timeout", "120000", file], {
      cwd: root,
      env: { ...env, TEST_API_URL: BASE_URL, TEST_DATABASE_URL: DATABASE_URL, E2E_WEBHOOK_SECRET: stripe.webhookSecret, E2E_STRIPE_BASE: stripe.baseUrl },
      stdout: "inherit",
      stderr: "inherit",
    });
    return await run.exited;
  } finally {
    server.kill();
    await server.exited;
    stripe.stop();
  }
}

const failed: string[] = [];
for (const file of await scenarios(process.argv.slice(2))) {
  if ((await runScenario(file)) !== 0) failed.push(file);
}
console.log(failed.length === 0 ? "e2e: every scenario passed" : `e2e: failed scenarios: ${failed.join(", ")}`);
process.exit(failed.length === 0 ? 0 : 1);
