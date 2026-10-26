// Serveur de maquette : sert la console (buildConsole) et répond à /api/backoffice/* avec des données
// synthétiques, sans base ni réseau. Lancement : `bun run console:mock` (port 3470).
//
// Comptes de la maquette (mot de passe « demo ») :
//   admin@example.com       super-administrateur, code à 6 chiffres accepté : tout sauf 000000
//   moderation@example.com  modérateur
//   support@example.com     support (lecture seule)
//   analyste@example.com    analyste (algorithme en lecture seule : matching.read sans matching.tune)
//   nouveau@example.com     session directe sans second facteur → écran d'enrôlement
import { Hono } from "hono";
import { buildConsole } from "../../src/features/console/console.bundle";
import { registerConsoleRoutes } from "../../src/features/console/console.routes";
import { ROLE_LABELS, ROLE_PERMISSIONS, type StaffRole } from "../../src/features/staff/domain/roles";
import type { MeDto, Priority, ReportStatus } from "../src/shared/api/contracts";
import { registerMatchingMock } from "./mock-matching";
import { conversationFor, dashboard, memberFile, members, memberRef, reportDetail, reports, silhouetteSvg, type MockReport } from "./mock-data";

const PORT = Number(process.env["PORT"] ?? 3470);
const ACCOUNTS: Readonly<Record<string, StaffRole>> = {
  "admin@example.com": "super_admin",
  "moderation@example.com": "moderator",
  "support@example.com": "support",
  "nouveau@example.com": "moderator",
  "analyste@example.com": "analyst",
};

const sessions = new Map<string, MeDto>();
const challenges = new Map<string, string>();
const ok = <T,>(data: T): { success: true; data: T } => ({ success: true, data });
const fail = (error: string, message?: string): { success: false; error: string; message?: string } => (message === undefined ? { success: false, error } : { success: false, error, message });

function meFor(email: string, mfa: boolean): MeDto {
  const role: StaffRole = ACCOUNTS[email] ?? "support";
  return { email, role, roleLabel: ROLE_LABELS[role], permissions: ROLE_PERMISSIONS[role], mfa, mfaEnrolled: mfa, mfaRequired: true };
}

const app = new Hono();
const api = new Hono();

function bearer(header: string | undefined): MeDto | null {
  const token = header?.startsWith("Bearer ") ? header.slice(7) : null;
  return token === null ? null : (sessions.get(token) ?? null);
}

function startSession(me: MeDto): { kind: "session"; token: string; me: MeDto } {
  const token = `mock-${crypto.randomUUID()}`;
  sessions.set(token, me);
  return { kind: "session", token, me };
}

api.post("/auth/password", async (c) => {
  const body = (await c.req.json()) as { email?: string; password?: string };
  const email = (body.email ?? "").toLowerCase();
  if (ACCOUNTS[email] === undefined || body.password !== "demo") return c.json(fail("invalid_credentials"), 401);
  if (email === "nouveau@example.com") return c.json(ok(startSession(meFor(email, false))));
  const challenge = `chal-${crypto.randomUUID()}`;
  challenges.set(challenge, email);
  return c.json(ok({ kind: "mfa_challenge" as const, challenge }));
});
api.post("/auth/google", async (c) => {
  const body = (await c.req.json()) as { credential?: string };
  return body.credential === undefined || body.credential.length < 10 ? c.json(fail("invalid_credentials"), 401) : c.json(ok(startSession(meFor("admin@example.com", true))));
});
api.post("/auth/mfa", async (c) => {
  const body = (await c.req.json()) as { challenge?: string; code?: string };
  const email = challenges.get(body.challenge ?? "");
  if (email === undefined) return c.json(fail("invalid_code"), 401);
  if (body.code === "000000") return c.json(fail("invalid_code", "Code incorrect ou expiré."), 401);
  return c.json(ok(startSession(meFor(email, true))));
});

api.use("*", async (c, next) => {
  const me = bearer(c.req.header("Authorization"));
  if (me === null) return c.json(fail("unauthorized"), 401);
  c.set("me" as never, me as never);
  await next();
});
const meOf = (c: { get: (key: never) => unknown }): MeDto => c.get("me" as never) as MeDto;

api.get("/me", (c) => c.json(ok(meOf(c))));
api.post("/mfa/enroll", (c) => c.json(ok({ secret: "JBSWY3DPEHPK3PXPJBSWY3DPEHPK3PXP", otpauthUri: "otpauth://totp/mazl-staff:nouveau%40example.com?secret=JBSWY3DPEHPK3PXPJBSWY3DPEHPK3PXP&issuer=mazl-staff" })));
api.post("/mfa/confirm", async (c) => {
  const body = (await c.req.json()) as { code?: string };
  if (body.code === "000000") return c.json(fail("invalid_code"), 401);
  return c.json(ok(startSession(meFor(meOf(c).email, true))));
});

api.get("/dashboard", (c) => c.json(ok(dashboard())));

const isOpen = (status: ReportStatus): boolean => status === "pending" || status === "in_review";
api.get("/reports", (c) => {
  const me = meOf(c);
  const { status, priority, assigned, reason, limit = "25", offset = "0" } = c.req.query();
  const open = reports.filter((report) => isOpen(report.status));
  const counts = { P1: 0, P2: 0, P3: 0, P4: 0 } satisfies Record<Priority, number>;
  for (const report of open) counts[report.priority] += 1;
  const filtered = reports.filter(
    (report) =>
      (status === undefined || status === "" ? isOpen(report.status) : report.status === status) &&
      (priority === undefined || priority === "" || report.priority === priority) &&
      (reason === undefined || reason === "" || report.reason === reason) &&
      (assigned === "me" ? report.assignedTo === me.email : assigned === "none" ? report.assignedTo === null : true),
  );
  const start = Number(offset);
  return c.json(ok({ reports: filtered.slice(start, start + Number(limit)), total: filtered.length, counts, overdue: open.filter((report) => report.overdue).length }));
});

const findReport = (id: string): MockReport | undefined => reports.find((report) => report.id === Number(id));
api.get("/reports/:id", (c) => {
  const report = findReport(c.req.param("id"));
  return report === undefined ? c.json(fail("not_found"), 404) : c.json(ok(reportDetail(report)));
});
api.get("/reports/:id/conversation", (c) => {
  const report = findReport(c.req.param("id"));
  const justification = c.req.query("justification") ?? "";
  if (report === undefined) return c.json(fail("not_found"), 404);
  if (justification.trim().length < 10) return c.json(fail("justification_required", "Un motif de 10 caractères minimum est exigé."), 400);
  return c.json(ok(conversationFor(report)));
});
function patchReport(report: MockReport, changes: Partial<MockReport>): void {
  const index = reports.indexOf(report);
  reports[index] = { ...report, ...changes };
}
api.post("/reports/:id/assign", (c) => {
  const report = findReport(c.req.param("id"));
  if (report === undefined) return c.json(fail("not_found"), 404);
  patchReport(report, { assignedTo: meOf(c).email, status: "in_review" });
  return c.json(ok({}));
});
api.post("/reports/:id/decision", async (c) => {
  const report = findReport(c.req.param("id"));
  if (report === undefined) return c.json(fail("not_found"), 404);
  const body = (await c.req.json()) as { outcome: "dismissed" | "actioned"; note: string };
  patchReport(report, { status: body.outcome, decisionNote: body.note, handledBy: meOf(c).email, handledAt: new Date().toISOString() });
  return c.json(ok(body.outcome === "actioned" ? { reference: `EXP-2026-${report.id}`, appealCode: "K7QM-4XD9-RT2B" } : {}));
});

api.get("/members", (c) => {
  const q = (c.req.query("q") ?? "").toLowerCase().trim();
  const found = members.filter((member) => String(member.id) === q || member.displayName.toLowerCase().includes(q) || member.email.includes(q));
  return c.json(ok({ members: found.slice(0, 30).map((member) => ({ id: member.id, displayName: member.displayName, email: member.email, photoUrl: memberRef(member).photoUrl, active: member.active, verification: member.verification })), total: found.length }));
});
api.get("/members/:id", (c) => {
  const member = members.find((candidate) => candidate.id === Number(c.req.param("id")));
  return member === undefined ? c.json(fail("not_found"), 404) : c.json(ok(memberFile(member)));
});
api.post("/members/:id/sanctions", (c) => c.json(ok({ reference: "EXP-2026-0001", appealCode: "H2NV-8PLC-5WJA" })));

registerMatchingMock(api, meOf);

app.route("/api/backoffice", api);
app.get("/mock/photos/:name", (c) => {
  const seed = Number.parseInt(c.req.param("name"), 10);
  return new Response(silhouetteSvg(Number.isNaN(seed) ? 0 : seed), { headers: { "Content-Type": "image/svg+xml", "Cache-Control": "public, max-age=3600" } });
});
app.get("/", (c) => c.redirect("/console"));
registerConsoleRoutes(app, { build: () => buildConsole({ development: true }), development: true });

Bun.serve({ port: PORT, fetch: app.fetch });
console.log(`Console de maquette : http://localhost:${PORT}/console  (comptes : admin@example.com / moderation@example.com / support@example.com / nouveau@example.com, mot de passe « demo »)`);
