import { afterAll, beforeAll, describe, expect, test } from "bun:test";
import { Hono } from "hono";
import postgres from "postgres";
import type { Sql } from "postgres";
import type { AuditEntryInput } from "../src/features/audit/application/ports";
import type { AccountEnforcement } from "../src/features/trust-safety/application/ports";
import { activeRestrictionSql } from "../src/features/trust-safety/infra/schema";
import { createTrustSafetyModule, type TrustSafetyModule } from "../src/features/trust-safety/trust-safety.module";
import { as, fakeRequirePermission } from "./unit/trust-safety-fakes";

// Integration against a throwaway Postgres whose base schema was created by the
// real server (see the task notes). Skipped when TEST_DATABASE_URL is absent.
const url = process.env.TEST_DATABASE_URL;
const BASE = "http://test/api/backoffice";
const HOUR = 3_600_000;

interface Envelope {
  success: boolean;
  error?: string;
  data?: Record<string, unknown>;
}

describe.skipIf(!url)("trust & safety on Postgres", () => {
  let sql: Sql;
  let mod: TrustSafetyModule;
  let app: Hono;
  const audit: AuditEntryInput[] = [];
  const effects: string[] = [];
  let seq = 0;

  const enforcement: AccountEnforcement = {
    disable: async (id) => {
      effects.push(`disable:${id}`);
      await sql`UPDATE users SET is_active = false WHERE id = ${id}`;
    },
    ban: async (id) => {
      effects.push(`ban:${id}`);
      await sql`UPDATE users SET is_active = false WHERE id = ${id}`;
    },
    enable: async (id) => {
      effects.push(`enable:${id}`);
      await sql`UPDATE users SET is_active = true WHERE id = ${id}`;
    },
    onDisabled: async (id) => void effects.push(`closed:${id}`),
  };

  beforeAll(async () => {
    if (!url) return;
    const host = new URL(url).hostname;
    if (host !== "127.0.0.1" && host !== "localhost") throw new Error("refusing to wipe a non-local database");
    sql = postgres(url, { onnotice: () => undefined });
    mod = createTrustSafetyModule({
      sql,
      enforcement,
      requirePermission: fakeRequirePermission,
      audit: { record: async (entry) => (audit.push(entry), { ...entry, id: audit.length, createdAt: "", previousHash: "", hash: "" }) },
    });
    await mod.ensureSchema();
    await mod.ensureSchema();
    await sql`DELETE FROM authority_requests`;
    await sql`DELETE FROM messages`;
    await sql`DELETE FROM conversations`;
    await sql`DELETE FROM matches`;
    await sql`DELETE FROM waitlist`;
    await sql`DELETE FROM users`;
    app = new Hono();
    mod.register(app);
  });

  afterAll(async () => {
    if (sql) await sql.end();
  });

  async function user(label: string, options: { name?: string; ageDays?: number } = {}): Promise<number> {
    seq += 1;
    const tag = `${label}-${seq}-${Math.random().toString(36).slice(2, 8)}`;
    const created = new Date(Date.now() - (options.ageDays ?? 60) * 24 * HOUR);
    const [row] = await sql`
      INSERT INTO users (email, name, provider, provider_id, created_at) VALUES (${`${tag}@example.com`}, ${tag}, 'test', ${tag}, ${created}) RETURNING id`;
    const id = Number(row?.id);
    await sql`INSERT INTO profiles (user_id, display_name) VALUES (${id}, ${options.name ?? `Membre ${tag}`})`;
    return id;
  }

  async function addReport(reported: number, reason: string, hoursAgo: number, extra: { status?: string; reporter?: number | null; messageId?: number | null } = {}): Promise<number> {
    const [row] = await sql`
      INSERT INTO reports (reporter_id, reported_user_id, reason, details, status, created_at, message_id)
      VALUES (${extra.reporter ?? null}, ${reported}, ${reason}, ${"détails " + reason}, ${extra.status ?? "pending"}, ${new Date(Date.now() - hoursAgo * HOUR)}, ${extra.messageId ?? null})
      RETURNING id`;
    return Number(row?.id);
  }

  async function api(path: string, init: RequestInit): Promise<{ status: number; body: Envelope; text: string }> {
    const response = await app.request(`${BASE}${path}`, init);
    const text = await response.text();
    return { status: response.status, body: text.startsWith("{") ? (JSON.parse(text) as Envelope) : { success: false }, text };
  }

  const mod1 = as("mod@example.com", "moderator");
  const admin = (body?: unknown) => as("admin@example.com", "admin", body);
  const active = async (id: number) => (await sql`SELECT is_active FROM users WHERE id = ${id}`)[0]?.is_active === true;

  test("the schema is idempotent and adds what the contract needs", async () => {
    const columns = await sql`SELECT column_name FROM information_schema.columns WHERE table_name = 'reports'`;
    const names = columns.map((c) => c.column_name);
    expect(names).toEqual(expect.arrayContaining(["assigned_to", "assigned_at", "decision_note"]));
    const tables = await sql`SELECT table_name FROM information_schema.tables WHERE table_name IN ('member_sanctions','sanction_appeals','authority_requests')`;
    expect(tables).toHaveLength(3);
    await expect(sql`INSERT INTO member_sanctions (user_id, kind, ground, starts_at, decided_by, statement, appeal_code_hash) VALUES (1, 'nope', 'x', now(), 'a', '{}', 'h')`).rejects.toThrow();
  });

  test("the queue is sorted by priority then due date, paginated, and maps legacy statuses", async () => {
    await sql`DELETE FROM reports`;
    const ids = {
      spam: await addReport(await user("a"), "spam", 1),
      underage: await addReport(await user("b"), "underage", 3),
      late: await addReport(await user("c"), "harassment", 30),
      recent: await addReport(await user("d"), "harassment", 2),
      photo: await addReport(await user("e"), "fake_profile", 1),
      legacy: await addReport(await user("f"), "scam", 5, { status: "handled" }),
      unknownReason: await addReport(await user("g"), "weird_value", 1),
    };
    const all = await api("/reports", mod1);
    const data = all.body.data as { reports: Array<{ id: number; priority: string; status: string; reason: string; overdue: boolean }>; total: number; counts: Record<string, number>; overdue: number };
    expect(data.reports.map((r) => r.id)).toEqual([ids.underage, ids.late, ids.recent, ids.photo, ids.spam, ids.unknownReason].sort((a, b) => order(a) - order(b)));
    function order(id: number): number {
      return [ids.underage, ids.late, ids.recent, ids.photo, ids.spam, ids.unknownReason].indexOf(id);
    }
    expect(data.total).toBe(6);
    expect(data.counts).toEqual({ P1: 1, P2: 2, P3: 1, P4: 2 });
    expect(data.overdue).toBe(1);
    expect(data.reports.find((r) => r.id === ids.unknownReason)?.reason).toBe("other");
    const page = await api("/reports?limit=2&offset=2", mod1);
    expect((page.body.data as { reports: Array<{ id: number }> }).reports.map((r) => r.id)).toEqual([ids.recent, ids.photo]);
    const actioned = await api("/reports?status=actioned", mod1);
    const rows = (actioned.body.data as { reports: Array<{ id: number; status: string }> }).reports;
    expect(rows.map((r) => r.id)).toEqual([ids.legacy]);
    expect(rows[0]?.status).toBe("actioned");
    const mine = await api("/reports/" + ids.spam + "/assign", as("mod@example.com", "moderator", { to: "me" }));
    expect((mine.body.data as { status: string; assignedTo: string }).assignedTo).toBe("mod@example.com");
    const assigned = await api("/reports?assigned=me", mod1);
    expect((assigned.body.data as { reports: Array<{ id: number }> }).reports.map((r) => r.id)).toEqual([ids.spam]);
    const unassigned = await api("/reports?assigned=none", mod1);
    expect((unassigned.body.data as { total: number }).total).toBe(5);
  });

  test("escalation: three open reports on one member raise the priority", async () => {
    await sql`DELETE FROM reports`;
    const target = await user("esc");
    const first = await addReport(target, "fake_profile", 1);
    await addReport(target, "spam", 2);
    await addReport(target, "spam", 3);
    const detail = await api(`/reports/${first}`, mod1);
    const report = detail.body.data as { priority: string; otherOpenReports: number; memberHistory: { reports: unknown[] }; suggestedSanction: string };
    expect(report.priority).toBe("P2");
    expect(report.otherOpenReports).toBe(2);
    expect(report.memberHistory.reports).toHaveLength(3);
    expect(report.suggestedSanction).toBe("warning");
  });

  test("a decision is one transaction: report, sanction, account effect, audit", async () => {
    await sql`DELETE FROM reports`;
    const target = await user("tx");
    const reportId = await addReport(target, "harassment", 1);
    audit.length = 0;
    const body = { outcome: "actioned", note: "Constat après relecture", sanction: { kind: "suspension", ground: "harassment", facts: "Messages insultants répétés.", durationDays: 3 } };
    const result = await api(`/reports/${reportId}/decision`, as("mod@example.com", "moderator", body));
    expect(result.status).toBe(200);
    const data = result.body.data as { appealCode: string; sanction: { id: number } };
    const [stored] = await sql`SELECT status, handled_by, decision_note, handled_at FROM reports WHERE id = ${reportId}`;
    expect(stored?.status).toBe("actioned");
    expect(stored?.handled_by).toBe("mod@example.com");
    expect(stored?.decision_note).toBe("Constat après relecture");
    expect(stored?.handled_at).not.toBeNull();
    const [sanction] = await sql`SELECT kind, report_id, appeal_code_hash, statement FROM member_sanctions WHERE id = ${data.sanction.id}`;
    expect(sanction?.kind).toBe("suspension");
    expect(sanction?.report_id).toBe(reportId);
    expect(JSON.stringify(sanction)).not.toContain(data.appealCode);
    expect(sanction?.appeal_code_hash).toMatch(/^[0-9a-f]{64}$/);
    expect(sanction?.statement.automatedDecision).toBe(false);
    expect(await active(target)).toBe(false);
    expect(audit.map((e) => e.action)).toEqual(["report.decide", "sanction.issue"]);
    const again = await api(`/reports/${reportId}/decision`, as("mod@example.com", "moderator", body));
    expect(again.status).toBe(409);
  });

  test("a failure while closing the report rolls the sanction back", async () => {
    const target = await user("rollback");
    const reportId = await addReport(target, "spam", 1);
    await sql.unsafe(`
      CREATE OR REPLACE FUNCTION ts_test_boom() RETURNS trigger AS $$ BEGIN
        IF NEW.decision_note = 'boom note' THEN RAISE EXCEPTION 'boom'; END IF; RETURN NEW; END; $$ LANGUAGE plpgsql;
      DROP TRIGGER IF EXISTS ts_test_boom ON reports;
      CREATE TRIGGER ts_test_boom BEFORE UPDATE ON reports FOR EACH ROW EXECUTE FUNCTION ts_test_boom();`);
    try {
      const body = { outcome: "actioned", note: "boom note", sanction: { kind: "warning", ground: "commercial_spam", facts: "Messages répétés non sollicités." } };
      const result = await api(`/reports/${reportId}/decision`, as("mod@example.com", "moderator", body));
      expect(result.status).toBe(500);
    } finally {
      await sql.unsafe("DROP TRIGGER IF EXISTS ts_test_boom ON reports; DROP FUNCTION IF EXISTS ts_test_boom()");
    }
    expect((await sql`SELECT COUNT(*)::int AS n FROM member_sanctions WHERE user_id = ${target}`)[0]?.n).toBe(0);
    expect((await sql`SELECT status FROM reports WHERE id = ${reportId}`)[0]?.status).toBe("pending");
  });

  test("suspension disables the account, expiry re-enables it once", async () => {
    const target = await user("susp");
    const issued = await api(`/members/${target}/sanctions`, admin({ kind: "suspension", ground: "harassment", facts: "Messages insultants répétés.", durationDays: 2, note: "Après relecture" }));
    const id = (issued.body.data as { sanction: { id: number } }).sanction.id;
    expect(await active(target)).toBe(false);
    expect(await mod.reactivateExpiredSuspensions()).toBe(0);
    expect(await active(target)).toBe(false);
    await sql`UPDATE member_sanctions SET ends_at = now() - interval '1 minute' WHERE id = ${id}`;
    effects.length = 0;
    expect(await mod.reactivateExpiredSuspensions()).toBe(1);
    expect(effects).toEqual([`enable:${target}`]);
    expect(await active(target)).toBe(true);
    expect(await mod.reactivateExpiredSuspensions()).toBe(0);
    // Disabled again for another reason later: the old suspension must not undo it.
    await sql`UPDATE users SET is_active = false WHERE id = ${target}`;
    expect(await mod.reactivateExpiredSuspensions()).toBe(0);
    expect(await active(target)).toBe(false);
  });

  test("an expired suspension does not re-enable a member who is banned or still suspended", async () => {
    const banned = await user("banned");
    await api(`/members/${banned}/sanctions`, admin({ kind: "suspension", ground: "harassment", facts: "Messages insultants répétés.", durationDays: 1, note: "Après relecture" }));
    await api(`/members/${banned}/sanctions`, admin({ kind: "ban", ground: "scam_or_fraud", facts: "Demandes d'argent répétées.", note: "Après relecture" }));
    await sql`UPDATE member_sanctions SET ends_at = now() - interval '1 minute' WHERE user_id = ${banned} AND kind = 'suspension'`;
    await mod.reactivateExpiredSuspensions();
    expect(await active(banned)).toBe(false);

    const twice = await user("twice");
    await api(`/members/${twice}/sanctions`, admin({ kind: "suspension", ground: "harassment", facts: "Messages insultants répétés.", durationDays: 1, note: "Après relecture" }));
    await api(`/members/${twice}/sanctions`, admin({ kind: "suspension", ground: "harassment", facts: "Messages insultants répétés.", durationDays: 30, note: "Après relecture" }));
    await sql`UPDATE member_sanctions SET ends_at = now() - interval '1 minute' WHERE user_id = ${twice} AND ends_at < now() + interval '2 days'`;
    await mod.reactivateExpiredSuspensions();
    expect(await active(twice)).toBe(false);
  });

  test("the sweeper runs the expiry periodically and stops", async () => {
    const target = await user("sweep");
    const issued = await api(`/members/${target}/sanctions`, admin({ kind: "suspension", ground: "harassment", facts: "Messages insultants répétés.", durationDays: 1, note: "Après relecture" }));
    await sql`UPDATE member_sanctions SET ends_at = now() - interval '1 minute' WHERE id = ${(issued.body.data as { sanction: { id: number } }).sanction.id}`;
    const stop = mod.startSweeper(20);
    await Bun.sleep(300);
    stop();
    expect(await active(target)).toBe(true);
  });

  test("revoking a suspension lifts it and re-enables the account", async () => {
    const target = await user("lift");
    const issued = await api(`/members/${target}/sanctions`, admin({ kind: "suspension", ground: "harassment", facts: "Messages insultants répétés.", durationDays: 20, note: "Après relecture" }));
    const id = (issued.body.data as { sanction: { id: number } }).sanction.id;
    const revoked = await api(`/sanctions/${id}/revoke`, as("mod@example.com", "moderator", { note: "Erreur d'identité" }));
    expect(revoked.status).toBe(200);
    expect(await active(target)).toBe(true);
    expect((await sql`SELECT revoked_by, revoke_note FROM member_sanctions WHERE id = ${id}`)[0]).toMatchObject({ revoked_by: "mod@example.com", revoke_note: "Erreur d'identité" });
    expect((await api(`/sanctions/${id}/revoke`, as("mod@example.com", "moderator", { note: "Erreur d'identité" }))).status).toBe(409);
    const standing = await sql`SELECT 1 FROM member_sanctions WHERE id = ${id} AND ${sql.unsafe(activeRestrictionSql)}`;
    expect(standing).toHaveLength(0);
  });

  test("activeRestrictionSql selects a standing restriction only", async () => {
    const target = await user("restrict");
    const issued = await api(`/members/${target}/sanctions`, admin({ kind: "restriction", ground: "fake_profile", facts: "Informations de profil trompeuses.", durationDays: 5, note: "Après relecture" }));
    const id = (issued.body.data as { sanction: { id: number } }).sanction.id;
    expect(await active(target)).toBe(true);
    const standing = await sql`SELECT 1 FROM member_sanctions WHERE id = ${id} AND ${sql.unsafe(activeRestrictionSql)}`;
    expect(standing).toHaveLength(1);
    await sql`UPDATE member_sanctions SET ends_at = now() - interval '1 second' WHERE id = ${id}`;
    expect(await sql`SELECT 1 FROM member_sanctions WHERE id = ${id} AND ${sql.unsafe(activeRestrictionSql)}`).toHaveLength(0);
  });

  test("public appeal: valid pair files it, wrong code and unknown reference are indistinguishable, the file is unique", async () => {
    const target = await user("appeal");
    const issued = await api(`/members/${target}/sanctions`, admin({ kind: "warning", ground: "harassment", facts: "Messages insultants répétés.", note: "Après relecture" }));
    const data = issued.body.data as { appealCode: string; sanction: { id: number; statement: { reference: string } } };
    const post = (body: unknown, ip: string) =>
      app.request("http://test/api/appeals", { method: "POST", headers: { "content-type": "application/json", "x-forwarded-for": ip }, body: JSON.stringify(body) });
    const message = "Je conteste, je n'ai insulté personne.";
    const wrong = await post({ reference: data.sanction.statement.reference, appealCode: "0000-0000-0000", message }, "192.0.2.1");
    const unknown = await post({ reference: "MZ-2026-000000", appealCode: "0000-0000-0000", message }, "192.0.2.2");
    expect(wrong.status).toBe(202);
    expect(unknown.status).toBe(202);
    expect(await wrong.text()).toBe(await unknown.text());
    expect((await sql`SELECT COUNT(*)::int AS n FROM sanction_appeals WHERE sanction_id = ${data.sanction.id}`)[0]?.n).toBe(0);
    const good = await post({ reference: data.sanction.statement.reference, appealCode: data.appealCode, message }, "192.0.2.3");
    expect(good.status).toBe(202);
    expect((await sql`SELECT status, user_id FROM sanction_appeals WHERE sanction_id = ${data.sanction.id}`)[0]).toMatchObject({ status: "pending", user_id: target });
    expect((await post({ reference: data.sanction.statement.reference, appealCode: data.appealCode, message }, "192.0.2.4")).status).toBe(409);
    const listed = await api("/appeals?status=pending", as("b@example.com", "admin"));
    expect((listed.body.data as { appeals: Array<{ sanctionId: number }> }).appeals.map((a) => a.sanctionId)).toContain(data.sanction.id);
    const appealId = Number((await sql`SELECT id FROM sanction_appeals WHERE sanction_id = ${data.sanction.id}`)[0]?.id);
    const same = await api(`/appeals/${appealId}/decision`, as("admin@example.com", "admin", { outcome: "overturned", note: "Erreur manifeste" }));
    expect(same.status).toBe(409);
    const decided = await api(`/appeals/${appealId}/decision`, as("b@example.com", "admin", { outcome: "overturned", note: "Erreur manifeste" }));
    expect(decided.status).toBe(200);
    expect((await sql`SELECT revoked_at FROM member_sanctions WHERE id = ${data.sanction.id}`)[0]?.revoked_at).not.toBeNull();
  });

  test("conversation: photo and voice content is hidden, the reported message is flagged, the read is audited", async () => {
    const reporter = await user("r");
    const reported = await user("x");
    const [match] = await sql`INSERT INTO matches (user1_id, user2_id) VALUES (${reporter}, ${reported}) RETURNING id`;
    const [conversation] = await sql`INSERT INTO conversations (match_id, user1_id, user2_id) VALUES (${match?.id}, ${reporter}, ${reported}) RETURNING id`;
    const conversationId = Number(conversation?.id);
    const insert = async (sender: number, type: string, content: string) =>
      Number((await sql`INSERT INTO messages (conversation_id, sender_id, content, type) VALUES (${conversationId}, ${sender}, ${content}, ${type}) RETURNING id`)[0]?.id);
    await insert(reporter, "text", "Bonjour");
    const bad = await insert(reported, "text", "Un message secret insultant");
    await insert(reported, "photo", "storage/key-secret.jpg");
    await insert(reported, "voice", "storage/key-voice.m4a");
    const reportId = await addReport(reported, "harassment", 1, { reporter, messageId: bad });
    audit.length = 0;
    const result = await api(`/reports/${reportId}/conversation?justification=Lecture+du+fil+signale`, mod1);
    expect(result.status).toBe(200);
    const convo = result.body.data as { conversationId: number; messages: Array<{ id: number; type: string; content: string | null; reported: boolean }> };
    expect(convo.conversationId).toBe(conversationId);
    expect(convo.messages.map((m) => m.type)).toEqual(["text", "text", "photo", "voice"]);
    expect(convo.messages.filter((m) => m.type !== "text").every((m) => m.content === null)).toBe(true);
    expect(convo.messages.find((m) => m.id === bad)?.reported).toBe(true);
    expect(result.text).not.toContain("key-secret");
    expect(audit).toHaveLength(1);
    expect(audit[0]).toMatchObject({ action: "conversation.read", justification: "Lecture du fil signale", details: { reportId } });
    expect(JSON.stringify(audit[0])).not.toContain("secret");
    const detail = await api(`/reports/${reportId}`, mod1);
    expect((detail.body.data as { reportedMessage: { content: string } }).reportedMessage.content).toBe("Un message secret insultant");
    // No message attached: the conversation between the two members is found.
    const bare = await addReport(reported, "spam", 1, { reporter });
    const found = await api(`/reports/${bare}/conversation?justification=Lecture+du+fil+entre+eux`, mod1);
    expect((found.body.data as { conversationId: number }).conversationId).toBe(conversationId);
  });

  test("member search by exact id, name and e-mail; wildcards are literal; the file is audited", async () => {
    const id = await user("search", { name: "Jeanne Exemplaire" });
    const email = (await sql`SELECT email FROM users WHERE id = ${id}`)[0]?.email;
    const byId = await api(`/members?q=${id}`, mod1);
    expect((byId.body.data as { members: Array<{ id: number }> }).members.map((m) => m.id)).toEqual([id]);
    const byName = await api("/members?q=jeanne%20exemp", mod1);
    expect((byName.body.data as { members: Array<{ id: number }> }).members.map((m) => m.id)).toContain(id);
    const byMail = await api(`/members?q=${encodeURIComponent(String(email).slice(0, 12).toUpperCase())}`, mod1);
    expect((byMail.body.data as { members: Array<{ id: number }> }).members.map((m) => m.id)).toContain(id);
    const wildcard = await api("/members?q=%25", mod1);
    expect((wildcard.body.data as { total: number }).total).toBe(0);
    audit.length = 0;
    const file = await api(`/members/${id}`, mod1);
    const member = (file.body.data as { member: { email: string; displayName: string; active: boolean } }).member;
    expect(member.email).toBe(email);
    expect(member.active).toBe(true);
    expect(audit.map((e) => e.action)).toEqual(["member.read"]);
    expect((await api("/members/99999999", mod1)).status).toBe(404);
  });

  test("transparency counts the period only; CSV export", async () => {
    await sql`DELETE FROM reports`;
    await sql`DELETE FROM member_sanctions`;
    await sql`DELETE FROM authority_requests`;
    const target = await user("transp");
    const inside = await addReport(target, "harassment", 24 * 5);
    await addReport(target, "scam", 24 * 5);
    await addReport(target, "spam", 24 * 40);
    const day = (hoursAgo: number) => new Date(Date.now() - hoursAgo * HOUR).toISOString().slice(0, 10);
    await api(`/reports/${inside}/decision`, as("mod@example.com", "moderator", { outcome: "actioned", note: "Constat fait", sanction: { kind: "warning", ground: "harassment", facts: "Messages insultants répétés." } }));
    await api("/authorities", admin({ kind: "pharos", authority: "PHAROS", reference: "P-1", scope: "Signalement de contenu", status: "answered" }));
    const query = `from=${day(24 * 10)}&to=${day(0)}`;
    const json = await api(`/transparency?${query}`, as("an@example.com", "analyst"));
    const report = json.body.data as { noticesReceived: Record<string, number>; noticesActioned: number; sanctionsByKind: Record<string, number>; sanctionsByGround: Record<string, number>; authorityRequests: Record<string, number>; automatedDecisions: number; medianHandlingHours: number | null };
    expect(report.noticesReceived).toMatchObject({ harassment: 1, scam: 1, spam: 0 });
    expect(report.noticesActioned).toBe(1);
    expect(report.sanctionsByKind).toMatchObject({ warning: 1, ban: 0 });
    expect(report.sanctionsByGround.harassment).toBe(1);
    expect(report.authorityRequests.pharos).toBe(1);
    expect(report.automatedDecisions).toBe(0);
    expect(report.medianHandlingHours).toBeGreaterThan(100);
    const csv = await app.request(`${BASE}/transparency?${query}&format=csv`, as("an@example.com", "analyst"));
    expect(csv.headers.get("content-type")).toBe("text/csv; charset=utf-8");
    const body = await csv.text();
    expect(body.startsWith("section,key,value\r\n")).toBe(true);
    expect(body).toContain("notices_received,harassment,1\r\n");
  });

  test("authority requests: create, update, list", async () => {
    const target = await user("auth");
    const created = await api("/authorities", admin({ kind: "judicial_requisition", authority: "Parquet de Paris", reference: "2026/777", scope: "Données de connexion", memberId: target, dueAt: "2026-12-01" }));
    expect(created.status).toBe(201);
    const id = (created.body.data as { id: number }).id;
    const patched = await app.request(`${BASE}/authorities/${id}`, { method: "PATCH", headers: { "x-test-email": "admin@example.com", "x-test-role": "admin", "content-type": "application/json" }, body: JSON.stringify({ status: "in_progress", notes: "En cours" }) });
    expect(patched.status).toBe(200);
    const listed = await api("/authorities?status=in_progress", admin());
    expect((listed.body.data as { requests: Array<{ id: number; notes: string }> }).requests.find((r) => r.id === id)?.notes).toBe("En cours");
    const missing = await app.request(`${BASE}/authorities/99999`, { method: "PATCH", headers: { "x-test-email": "admin@example.com", "x-test-role": "admin", "content-type": "application/json" }, body: JSON.stringify({ status: "answered" }) });
    expect(missing.status).toBe(404);
  });

  test("dashboard and verification queue answer with the contract shapes", async () => {
    const target = await user("dash");
    await addReport(target, "underage", 1);
    const dashboard = await api("/dashboard", as("an@example.com", "analyst"));
    expect(dashboard.status).toBe(200);
    const figures = dashboard.body.data as { reports: { open: number; byPriority: Record<string, number>; daily: unknown[] }; sanctions30d: Record<string, number>; members: { total: number } };
    expect(figures.reports.open).toBeGreaterThanOrEqual(1);
    expect(figures.reports.byPriority.P1).toBeGreaterThanOrEqual(1);
    expect(figures.reports.daily).toHaveLength(30);
    expect(Object.keys(figures.sanctions30d).sort()).toEqual(["ban", "restriction", "suspension", "warning"]);
    expect(figures.members.total).toBeGreaterThan(0);

    const [row] = await sql`SELECT email FROM users WHERE id = ${target}`;
    await sql`INSERT INTO waitlist (email, token, verification_status, documents_submitted_at) VALUES (${row?.email}, 'tok', 'submitted', now())`;
    const queue = await api("/verification/queue", as("v@example.com", "verifier"));
    const items = (queue.body.data as { items: Array<{ memberId: number; kind: string; status: string }> }).items;
    expect(items.find((item) => item.memberId === target)).toMatchObject({ kind: "documents", status: "submitted" });
  });
});
