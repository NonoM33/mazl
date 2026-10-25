import { randomBytes } from "node:crypto";
import postgres from "postgres";

// A database of its own inside the throwaway Postgres of the integration run
// (TEST_DATABASE_URL), for suites that must start from nothing or may destroy
// data: the shared test database holds what the other suites rely on.

export interface ScratchDatabase {
  readonly url: string;
  drop(): Promise<void>;
}

export async function createScratchDatabase(): Promise<ScratchDatabase> {
  const base = process.env.TEST_DATABASE_URL;
  if (base === undefined) throw new Error("TEST_DATABASE_URL is required (run bun scripts/test-integration.ts)");
  const name = `scratch_${randomBytes(6).toString("hex")}`;
  const admin = postgres(base, { max: 1, onnotice: () => undefined });
  await admin.unsafe(`CREATE DATABASE ${name}`);
  const url = new URL(base);
  url.pathname = `/${name}`;
  return {
    url: url.toString(),
    drop: async () => {
      await admin.unsafe(`DROP DATABASE IF EXISTS ${name} WITH (FORCE)`);
      await admin.end({ timeout: 2 });
    },
  };
}

// Runs a TypeScript snippet with the repository as working directory, against the given database.
export async function runBun(args: readonly string[], env: Record<string, string>): Promise<{ code: number; out: string }> {
  const proc = Bun.spawn(["bun", ...args], {
    cwd: new URL("../../", import.meta.url).pathname,
    env: { ...(process.env as Record<string, string>), ...env },
    stdout: "pipe",
    stderr: "pipe",
  });
  const [out, err, code] = await Promise.all([new Response(proc.stdout).text(), new Response(proc.stderr).text(), proc.exited]);
  return { code, out: `${out}${err}` };
}

// Creates the schema (initDb) the way a boot of the API does, under the given NODE_ENV.
export function bootSchema(url: string, nodeEnv: string): Promise<{ code: number; out: string }> {
  const script = "import { initDb, sql } from './src/db'; await initDb(); await sql.end();";
  return runBun(["-e", script], { NODE_ENV: nodeEnv, DATABASE_URL: url });
}

// Boots the real API on the given database (every feature creates its tables, as
// in a deployment), waits until it answers, then stops it. The secrets come from
// the environment of the integration run.
export async function bootServerSchema(url: string, nodeEnv: string): Promise<void> {
  const probe = Bun.serve({ port: 0, fetch: () => new Response("") });
  const port = probe.port;
  await probe.stop(true);
  const server = Bun.spawn(["bun", "src/index.ts"], {
    cwd: new URL("../../", import.meta.url).pathname,
    env: { ...(process.env as Record<string, string>), NODE_ENV: nodeEnv, DATABASE_URL: url, PORT: String(port) },
    stdout: "ignore",
    stderr: "ignore",
  });
  try {
    for (let attempt = 0; attempt < 120; attempt += 1) {
      try {
        if ((await fetch(`http://127.0.0.1:${port}/api/health`)).ok) return;
      } catch {
        // not listening yet
      }
      await Bun.sleep(250);
    }
    throw new Error("the API did not start on the scratch database");
  } finally {
    server.kill();
    await server.exited;
  }
}
