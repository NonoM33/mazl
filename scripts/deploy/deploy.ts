// Deploys the MAZL API through Coolify with no data at risk:
//   bun scripts/deploy/deploy.ts stg
//   bun scripts/deploy/deploy.ts prod [git-ref]   (default: origin/main)
// 1. production only: a fresh database backup must SUCCEED first, or nothing is deployed;
// 2. production only: the API follows the `production` branch, which only this script moves,
//    AFTER the backup (a push to main never redeploys the production API by itself);
// 3. one deployment at a time on the server (two builds at once take Traefik down);
// 4. after the deploy, /api/health must answer 200 six times in a row.
// COOLIFY_URL and COOLIFY_API_KEY come from the environment, never from this file.

const TARGETS = {
  stg: { app: "d4ks8s0o8s0csck4848o8c4g", health: "https://stg-api.mazl.157.180.43.90.sslip.io/api/health", backup: null },
  prod: {
    app: "fo884sk40o4gww4skksosw0w",
    health: "https://api.mazl.app/api/health",
    backup: { database: "w8w0s8gs8g4gsw4kk4ocs0g8", config: "sddndjuc8pf5x8pvnblbseib" },
  },
} as const;

type Target = keyof typeof TARGETS;

const base = process.env.COOLIFY_URL;
const token = process.env.COOLIFY_API_KEY;
const target = process.argv[2] as Target | undefined;
if (!base || !token || !target || !(target in TARGETS)) {
  console.error("usage: COOLIFY_URL=... COOLIFY_API_KEY=... bun scripts/deploy/deploy.ts stg|prod");
  process.exit(2);
}
const settings = TARGETS[target];

async function coolify<T>(method: string, path: string, body?: unknown): Promise<T> {
  const res = await fetch(`${base}/api/v1${path}`, {
    method,
    headers: { Authorization: `Bearer ${token}`, "Content-Type": "application/json" },
    body: body === undefined ? undefined : JSON.stringify(body),
  });
  if (!res.ok) throw new Error(`Coolify ${method} ${path}: ${res.status} ${await res.text()}`);
  return (await res.json()) as T;
}

const sleep = (ms: number) => new Promise((resolve) => setTimeout(resolve, ms));

interface Execution { readonly status: string; readonly created_at: string; readonly size?: number }
interface BackupConfig { readonly uuid: string; readonly executions?: readonly Execution[] }

async function freshBackup(database: string, config: string): Promise<void> {
  const startedAt = Date.now();
  await coolify("PATCH", `/databases/${database}/backups/${config}`, { backup_now: true });
  for (let i = 0; i < 60; i++) {
    await sleep(5000);
    const configs = await coolify<BackupConfig[]>("GET", `/databases/${database}/backups`);
    const runs = configs.find((c) => c.uuid === config)?.executions ?? [];
    // Only a run started by THIS request counts, never an older one.
    const latest = runs.find((run) => Date.parse(`${run.created_at.replace(" ", "T")}`) >= startedAt - 5_000);
    if (latest?.status === "success") { console.log(`backup ok (${latest.size ?? "?"} bytes)`); return; }
    if (latest?.status === "failed") throw new Error("database backup FAILED: nothing deployed");
  }
  throw new Error("database backup did not finish in 5 minutes: nothing deployed");
}

async function waitQueueEmpty(): Promise<void> {
  for (let i = 0; i < 120; i++) {
    const running = await coolify<unknown[]>("GET", "/deployments");
    if (running.length === 0) return;
    await sleep(10_000);
  }
  throw new Error("another deployment is still running after 20 minutes");
}

interface Deployment { readonly deployment_uuid: string }

// Moves the production branch; the GitHub webhook may queue the deployment itself.
async function moveProductionBranch(ref: string): Promise<void> {
  const run = async (...args: string[]) => {
    const proc = Bun.spawn(["git", ...args], { stdout: "pipe", stderr: "pipe" });
    if ((await proc.exited) !== 0) throw new Error(`git ${args.join(" ")}: ${await new Response(proc.stderr).text()}`);
  };
  await run("fetch", "--quiet", "origin");
  await run("push", "--quiet", "origin", `${ref}:refs/heads/production`);
  console.log(`production branch -> ${ref}`);
}

interface AppDeployments { readonly deployments?: readonly (Deployment & { readonly created_at: string })[] }

// The deployment the webhook queued for this push, if any (else the script queues one).
async function webhookDeployment(app: string, pushedAt: number): Promise<string | undefined> {
  for (let i = 0; i < 6; i++) {
    await sleep(5000);
    const history = await coolify<AppDeployments>("GET", `/deployments/applications/${app}?take=1`);
    const latest = history.deployments?.[0];
    if (latest && Date.parse(latest.created_at) >= pushedAt - 5_000) return latest.deployment_uuid;
  }
  return undefined;
}

async function deploy(app: string, alreadyQueued?: string): Promise<void> {
  let id = alreadyQueued;
  if (!id) {
    const queued = await coolify<{ deployments: { deployment_uuid: string }[] }>("POST", `/deploy?uuid=${app}`);
    id = queued.deployments[0]?.deployment_uuid;
  }
  if (!id) throw new Error("Coolify did not queue the deployment");
  for (let i = 0; i < 120; i++) {
    await sleep(10_000);
    const { status } = await coolify<{ status: string }>("GET", `/deployments/${id}`);
    if (status === "finished") return;
    if (status === "failed" || status.startsWith("cancelled")) throw new Error(`deployment ${id} ${status} (the previous container keeps running)`);
  }
  throw new Error(`deployment ${id} still running after 20 minutes`);
}

async function healthy(url: string): Promise<void> {
  let streak = 0;
  for (let i = 0; i < 30 && streak < 6; i++) {
    const ok = await fetch(url).then((r) => r.ok, () => false);
    streak = ok ? streak + 1 : 0;
    await sleep(3000);
  }
  if (streak < 6) throw new Error(`${url} did not answer 200 six times in a row`);
  console.log("health ok (6/6)");
}

try {
  await waitQueueEmpty();
  let queued: string | undefined;
  if (settings.backup) {
    await freshBackup(settings.backup.database, settings.backup.config);
    const pushedAt = Date.now();
    await moveProductionBranch(process.argv[3] ?? "origin/main");
    queued = await webhookDeployment(settings.app, pushedAt);
  }
  await deploy(settings.app, queued);
  await healthy(settings.health);
  console.log(`${target}: deployed`);
} catch (error: unknown) {
  console.error(`${target}: ${error instanceof Error ? error.message : String(error)}`);
  process.exit(1);
}
