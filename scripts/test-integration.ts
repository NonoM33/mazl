// Runs the integration suites (tests/*.test.ts) against a real server.
//
//   bun scripts/test-integration.ts                     every tests/*.test.ts
//   bun scripts/test-integration.ts tests/likes-visibility.test.ts [...]
//
// Everything is disposable and nothing leaves the machine:
//   - a throwaway Postgres (docker, free local port, removed at the end);
//   - the API server in NODE_ENV=test, with secrets drawn at random;
//   - the fake Stripe (tests/support/run-fake-stripe.ts) the billing suites drive.
// Needs docker. Logs go to .integ/ (server.log, stripe.log, integ.log).
import { randomBytes } from "node:crypto";
import { mkdir, mkdtemp, rm } from "node:fs/promises";
import { createServer } from "node:net";
import { tmpdir } from "node:os";
import { join } from "node:path";
import postgres from "postgres";
import { FAKE_PRICE_ENV } from "../tests/support/fake-stripe";

const root = new URL("../", import.meta.url).pathname;
const logDir = join(root, ".integ");
const hex = (bytes = 32): string => randomBytes(bytes).toString("hex");
const base64 = (bytes = 32): string => randomBytes(bytes).toString("base64");

async function freePort(): Promise<number> {
  return new Promise((resolve, reject) => {
    const probe = createServer();
    probe.once("error", reject);
    probe.listen(0, "127.0.0.1", () => {
      const address = probe.address();
      probe.close(() => (typeof address === "object" && address !== null ? resolve(address.port) : reject(new Error("no port"))));
    });
  });
}

async function docker(...args: string[]): Promise<{ code: number; out: string }> {
  const proc = Bun.spawn(["docker", ...args], { stdout: "pipe", stderr: "pipe" });
  const [out, err, code] = await Promise.all([new Response(proc.stdout).text(), new Response(proc.stderr).text(), proc.exited]);
  return { code, out: code === 0 ? out : `${out}${err}` };
}

async function waitFor(what: string, attempts: number, probe: () => Promise<boolean>): Promise<void> {
  for (let attempt = 0; attempt < attempts; attempt += 1) {
    if (await probe().catch(() => false)) return;
    await Bun.sleep(500);
  }
  throw new Error(`${what} did not become ready`);
}

// The image restarts its server once after initialising: a TCP connection from
// the host (it only listens there after the restart) answering twice in a row
// means the database is really up.
async function waitForPostgres(url: string): Promise<void> {
  let streak = 0;
  await waitFor("Postgres", 120, async () => {
    const sql = postgres(url, { max: 1, connect_timeout: 2, onnotice: () => undefined });
    try {
      await sql`SELECT 1`;
      streak += 1;
    } catch {
      streak = 0;
    } finally {
      await sql.end({ timeout: 1 }).catch(() => undefined);
    }
    return streak >= 2;
  });
}

const cleanups: Array<() => Promise<void>> = [];
let cleaned = false;
async function cleanUp(): Promise<void> {
  if (cleaned) return;
  cleaned = true;
  for (const cleanup of cleanups.reverse()) await cleanup().catch(() => undefined);
}
for (const signal of ["SIGINT", "SIGTERM"] as const) {
  process.on(signal, () => {
    void cleanUp().finally(() => process.exit(130));
  });
}

async function main(): Promise<number> {
  await mkdir(logDir, { recursive: true });
  for (const log of ["server.log", "stripe.log", "openpanel.log", "anthropic.log", "integ.log"]) await Bun.write(join(logDir, log), "");

  const container = `mazl-it-${hex(4)}`;
  const pgPort = await freePort();
  const apiPort = await freePort();
  const stripePort = await freePort();
  const openPanelPort = await freePort();
  const anthropicPort = await freePort();
  const apiUrl = `http://127.0.0.1:${apiPort}`;
  const databaseUrl = `postgres://postgres:it@127.0.0.1:${pgPort}/mazl`;

  const started = await docker("run", "-d", "--name", container, "-e", "POSTGRES_PASSWORD=it", "-e", "POSTGRES_DB=mazl", "-p", `127.0.0.1:${pgPort}:5432`, "postgres:16");
  if (started.code !== 0) throw new Error(`docker could not start Postgres: ${started.out}`);
  cleanups.push(async () => void (await docker("rm", "-f", container)));
  await waitForPostgres(databaseUrl);

  const uploads = await mkdtemp(join(tmpdir(), "mazl-it-uploads-"));
  cleanups.push(() => rm(uploads, { recursive: true, force: true }));

  const stripeSecret = `whsec_test_${hex(16)}`;
  const stripe = Bun.spawn(["bun", "tests/support/run-fake-stripe.ts"], {
    cwd: root,
    env: { ...process.env, FAKE_STRIPE_PORT: String(stripePort) },
    stdout: Bun.file(join(logDir, "stripe.log")),
    stderr: Bun.file(join(logDir, "stripe.log")),
  });
  cleanups.push(async () => {
    stripe.kill();
    await stripe.exited;
  });
  const stripeUrl = `http://127.0.0.1:${stripePort}`;
  await waitFor("fake Stripe", 60, async () => (await fetch(`${stripeUrl}/__test/requests`)).ok);

  const openPanel = Bun.spawn(["bun", "tests/support/run-fake-openpanel.ts"], {
    cwd: root,
    env: { ...process.env, FAKE_OPENPANEL_PORT: String(openPanelPort) },
    stdout: Bun.file(join(logDir, "openpanel.log")),
    stderr: Bun.file(join(logDir, "openpanel.log")),
  });
  cleanups.push(async () => {
    openPanel.kill();
    await openPanel.exited;
  });
  const openPanelUrl = `http://127.0.0.1:${openPanelPort}`;
  await waitFor("fake OpenPanel", 60, async () => (await fetch(`${openPanelUrl}/__test/requests`)).ok);

  const anthropic = Bun.spawn(["bun", "tests/support/run-fake-anthropic.ts"], {
    cwd: root,
    env: { ...process.env, FAKE_ANTHROPIC_PORT: String(anthropicPort) },
    stdout: Bun.file(join(logDir, "anthropic.log")),
    stderr: Bun.file(join(logDir, "anthropic.log")),
  });
  cleanups.push(async () => {
    anthropic.kill();
    await anthropic.exited;
  });
  const anthropicUrl = `http://127.0.0.1:${anthropicPort}`;
  await waitFor("fake Anthropic", 60, async () => (await fetch(`${anthropicUrl}/__test/requests`)).ok);

  // The server and the suites share this environment. Nothing real is reachable:
  // no Resend, OneSignal, Apple or Stripe key, a fake Stripe, a throwaway database.
  const env: Record<string, string> = {
    ...(process.env as Record<string, string>),
    NODE_ENV: "test",
    TZ: "UTC",
    PORT: String(apiPort),
    DATABASE_URL: databaseUrl,
    TEST_DATABASE_URL: databaseUrl,
    TEST_API_URL: apiUrl,
    TEST_WS_URL: `ws://127.0.0.1:${apiPort}/ws`,
    APP_URL: apiUrl,
    PUBLIC_BASE_URL: apiUrl,
    JWT_SECRET: hex(),
    ADMIN_JWT_SECRET: hex(),
    ADMIN_EMAIL: "admin@example.com",
    ADMIN_PASSWORD: `it-${hex(8)}`,
    DATA_ENCRYPTION_KEY: base64(),
    MEDIA_SIGNING_KEY: base64(),
    DOC_FINGERPRINT_KEY: base64(),
    UPLOADS_DIR: uploads,
    // The task of the minute (Boosts that ended, Boosts programmed by the members) ticks every second.
    BOOST_END_SWEEP_MS: "1000",
    // Cheap proof of work for the web sign-in suites (the test expects 8 in the public config).
    WEB_POW_DIFFICULTY: "8",
    STRIPE_SECRET_KEY: `sk_test_${hex(12)}`,
    STRIPE_WEBHOOK_SECRET: stripeSecret,
    STRIPE_API_BASE: stripeUrl,
    FAKE_STRIPE_URL: stripeUrl,
    ...FAKE_PRICE_ENV,
    OPENPANEL_API_URL: openPanelUrl,
    OPENPANEL_CLIENT_ID: "it-client",
    OPENPANEL_CLIENT_SECRET: `it-secret-${hex(8)}`,
    ANALYTICS_ID_KEY: hex(),
    ANALYTICS_ENV: "test",
    FAKE_OPENPANEL_URL: openPanelUrl,
    // The concierge assistant talks to a fake Anthropic: nothing real is reachable.
    ANTHROPIC_API_KEY: `fake-${hex(8)}`,
    ANTHROPIC_API_URL: `${anthropicUrl}/v1/messages`,
    FAKE_ANTHROPIC_URL: anthropicUrl,
  };
  for (const name of ["RESEND_API_KEY", "ONESIGNAL_REST_API_KEY"]) delete env[name];

  const server = Bun.spawn(["bun", "src/index.ts"], {
    cwd: root,
    env,
    stdout: Bun.file(join(logDir, "server.log")),
    stderr: Bun.file(join(logDir, "server.log")),
  });
  cleanups.push(async () => {
    server.kill();
    await server.exited;
  });
  await waitFor("the API server", 120, async () => (await fetch(`${apiUrl}/api/health`)).ok);

  const requested = process.argv.slice(2);
  const files = requested.length > 0 ? requested : [...new Bun.Glob("tests/*.test.ts").scanSync({ cwd: root })].sort().map((file) => `./${file}`);
  const run = Bun.spawn(["bun", "test", "--timeout", "30000", ...files], { cwd: root, env, stdout: "pipe", stderr: "pipe" });
  const log = Bun.file(join(logDir, "integ.log")).writer();
  const pump = async (stream: ReadableStream<Uint8Array>): Promise<void> => {
    for await (const chunk of stream) {
      process.stdout.write(chunk);
      log.write(chunk);
    }
  };
  await Promise.all([pump(run.stdout), pump(run.stderr)]);
  await log.end();
  const code = await run.exited;
  console.log(`\nlogs: ${logDir}/ (server.log, stripe.log, anthropic.log, integ.log)`);
  return code;
}

let exitCode = 1;
try {
  exitCode = await main();
} catch (error: unknown) {
  console.error(error instanceof Error ? error.message : error);
} finally {
  await cleanUp();
}
process.exit(exitCode);
