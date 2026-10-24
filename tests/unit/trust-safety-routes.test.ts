import { createHash } from "node:crypto";
import { describe, expect, test } from "bun:test";
import { buildStatement } from "../../src/features/trust-safety/domain/statement";
import { as, harness, NOW, report, type Harness } from "./trust-safety-fakes";

const BASE = "http://test/api/backoffice";

interface Envelope {
  success: boolean;
  error?: string;
  message?: string;
  data?: Record<string, unknown>;
}

async function call(h: Harness, path: string, init: RequestInit): Promise<{ status: number; body: Envelope; response: Response; text: string }> {
  const response = await h.app.request(`${BASE}${path}`, init);
  const text = await response.text();
  return { status: response.status, body: text.startsWith("{") ? (JSON.parse(text) as Envelope) : { success: false }, response, text };
}

const sanctionBody = (kind: string, extra: Record<string, unknown> = {}) => ({
  outcome: "actioned",
  note: "Constat après lecture",
  sanction: { kind, ground: "harassment", facts: "Messages insultants répétés.", ...extra },
});

function withReports(): Harness {
  const h = harness();
  h.world.reports = [
    report(1, { reason: "spam", createdAt: new Date("2026-10-24T01:00:00Z") }),
    report(2, { reason: "underage", createdAt: new Date("2026-10-24T09:00:00Z") }),
    report(3, { reason: "harassment", createdAt: new Date("2026-10-23T09:00:00Z") }),
    report(4, { reason: "harassment", createdAt: new Date("2026-10-24T02:00:00Z") }),
  ];
  return h;
}

describe("authentication and permissions", () => {
  const routes: ReadonlyArray<readonly [string, string, string, unknown?]> = [
    ["GET", "/reports", "analyst"],
    ["GET", "/reports/1", "analyst"],
    ["POST", "/reports/1/assign", "support", { to: "me" }],
    ["POST", "/reports/1/decision", "support", { outcome: "dismissed", note: "ras ras" }],
    ["GET", "/reports/1/conversation?justification=une+raison+valable", "support"],
    ["GET", "/members?q=jeanne", "analyst"],
    ["GET", "/members/1", "analyst"],
    ["POST", "/members/1/sanctions", "support", { kind: "warning", ground: "harassment", facts: "Des faits précis ici", note: "note" }],
    ["POST", "/sanctions/1/revoke", "support", { note: "erreur" }],
    ["GET", "/appeals", "moderator"],
    ["POST", "/appeals/1/decision", "moderator", { outcome: "upheld", note: "ok ok" }],
    ["GET", "/authorities", "moderator"],
    ["POST", "/authorities", "moderator", {}],
    ["GET", "/verification/queue", "moderator"],
  ];
  for (const [method, path, lackingRole, body] of routes) {
    test(`${method} ${path.split("?")[0]}: 401 without session, 403 for ${lackingRole}`, async () => {
      const h = withReports();
      const init = (headers: Record<string, string>): RequestInit => ({ method, headers: { ...headers, "content-type": "application/json" }, body: body === undefined ? undefined : JSON.stringify(body) });
      expect((await call(h, path, init({}))).status).toBe(401);
      expect((await call(h, path, init({ "x-test-email": "s@example.com", "x-test-role": lackingRole }))).status).toBe(403);
    });
  }

  test("dashboard and transparency need a session", async () => {
    const h = harness();
    expect((await call(h, "/dashboard", {})).status).toBe(401);
    expect((await call(h, "/transparency?from=2026-10-01&to=2026-10-02", {})).status).toBe(401);
  });
});

describe("report queue", () => {
  test("sorted by priority, then oldest due date, with counts", async () => {
    const h = withReports();
    const { status, body } = await call(h, "/reports", as("m@example.com", "moderator"));
    expect(status).toBe(200);
    const data = body.data as { reports: Array<{ id: number }>; total: number; counts: Record<string, number> };
    // underage P1 (due 13:00); harassment P2 id3 (due 23-10 09:00+24h) before id4; spam P4.
    expect(data.reports.map((r) => r.id)).toEqual([2, 3, 4, 1]);
    expect(data.total).toBe(4);
    expect(data.counts).toEqual({ P1: 1, P2: 2, P3: 0, P4: 1 });
  });

  test("pagination and priority filter", async () => {
    const h = withReports();
    const page = await call(h, "/reports?limit=2&offset=1", as("m@example.com", "moderator"));
    expect((page.body.data as { reports: Array<{ id: number }> }).reports.map((r) => r.id)).toEqual([3, 4]);
    const p2 = await call(h, "/reports?priority=P2", as("m@example.com", "moderator"));
    expect((p2.body.data as { total: number }).total).toBe(2);
  });

  test("invalid query is a 400, unknown id a 404", async () => {
    const h = withReports();
    expect((await call(h, "/reports?limit=0", as("m@example.com", "moderator"))).status).toBe(400);
    expect((await call(h, "/reports?priority=P9", as("m@example.com", "moderator"))).status).toBe(400);
    const missing = await call(h, "/reports/999", as("m@example.com", "moderator"));
    expect(missing.status).toBe(404);
    expect(missing.body.success).toBe(false);
    expect((await call(h, "/reports/abc", as("m@example.com", "moderator"))).status).toBe(404);
  });

  test("assign is audited and puts the report in review", async () => {
    const h = withReports();
    const result = await call(h, "/reports/1/assign", as("m@example.com", "moderator", { to: "me" }));
    expect(result.status).toBe(200);
    expect((result.body.data as { assignedTo: string; status: string }).assignedTo).toBe("m@example.com");
    expect((result.body.data as { status: string }).status).toBe("in_review");
    expect(h.audit.map((e) => e.action)).toEqual(["report.assign"]);
    expect(h.audit[0]?.actor).toBe("m@example.com");
  });
});

describe("decision", () => {
  test("a ban without sanctions.ban is refused, and nothing is written", async () => {
    const h = withReports();
    const result = await call(h, "/reports/1/decision", as("m@example.com", "moderator", sanctionBody("ban")));
    expect(result.status).toBe(403);
    expect(h.world.sanctions).toHaveLength(0);
    expect(h.world.reports.find((r) => r.id === 1)?.status).toBe("pending");
    expect(h.calls).toEqual([]);
  });

  test("an admin may ban: account banned, sockets closed, audited", async () => {
    const h = withReports();
    const result = await call(h, "/reports/1/decision", as("a@example.com", "admin", sanctionBody("ban")));
    expect(result.status).toBe(200);
    expect(h.calls).toEqual(["ban:101", "onDisabled:101"]);
    expect(h.audit.map((e) => e.action)).toEqual(["report.decide", "sanction.issue"]);
  });

  test("a moderator may suspend: account disabled; clear code returned once, only its hash stored", async () => {
    const h = withReports();
    const result = await call(h, "/reports/1/decision", as("m@example.com", "moderator", sanctionBody("suspension", { durationDays: 7 })));
    expect(result.status).toBe(200);
    const data = result.body.data as { appealCode: string; sanction: { kind: string; endsAt: string; statement: { reference: string; automatedDecision: boolean } } };
    expect(data.sanction.kind).toBe("suspension");
    expect(data.sanction.endsAt).toBe("2026-10-31T12:00:00.000Z");
    expect(data.sanction.statement.automatedDecision).toBe(false);
    expect(data.appealCode).toMatch(/^[0-9A-Z]{4}-[0-9A-Z]{4}-[0-9A-Z]{4}$/);
    const stored = h.world.sanctions[0];
    expect(stored?.appealCodeHash).toBe(createHash("sha256").update(data.appealCode.replace(/-/g, "")).digest("hex"));
    expect(JSON.stringify(stored)).not.toContain(data.appealCode);
    expect(h.calls).toEqual(["disable:101", "onDisabled:101"]);
    expect(h.notices).toEqual([`issued:101:${data.appealCode}`]);
  });

  test("a suspension without duration, and a dismissal with a sanction, are 400", async () => {
    const h = withReports();
    expect((await call(h, "/reports/1/decision", as("m@example.com", "moderator", sanctionBody("suspension")))).status).toBe(400);
    const dismissed = { outcome: "dismissed", note: "Rien à signaler", sanction: { kind: "warning", ground: "harassment", facts: "Des faits précis." } };
    expect((await call(h, "/reports/1/decision", as("m@example.com", "moderator", dismissed))).status).toBe(400);
    expect((await call(h, "/reports/1/decision", as("m@example.com", "moderator", { outcome: "dismissed", note: "x" }))).status).toBe(400);
  });

  test("deciding twice is a 409", async () => {
    const h = withReports();
    const body = { outcome: "dismissed", note: "Rien à signaler" };
    expect((await call(h, "/reports/1/decision", as("m@example.com", "moderator", body))).status).toBe(200);
    const again = await call(h, "/reports/1/decision", as("m@example.com", "moderator", body));
    expect(again.status).toBe(409);
    expect(again.body.error).toBe("already_decided");
  });

  test("revoking a suspension re-enables the account; revoking twice is a 409", async () => {
    const h = withReports();
    await call(h, "/reports/1/decision", as("m@example.com", "moderator", sanctionBody("suspension", { durationDays: 7 })));
    h.calls.length = 0;
    const revoked = await call(h, "/sanctions/1/revoke", as("m@example.com", "moderator", { note: "Erreur de personne" }));
    expect(revoked.status).toBe(200);
    expect(h.calls).toEqual(["enable:101"]);
    expect(h.audit.at(-1)?.action).toBe("sanction.revoke");
    expect((await call(h, "/sanctions/1/revoke", as("m@example.com", "moderator", { note: "Erreur de personne" }))).status).toBe(409);
  });

  test("a direct ban needs sanctions.ban too; the sanction is audited", async () => {
    const h = harness();
    const body = { kind: "ban", ground: "scam_or_fraud", facts: "Demandes d'argent répétées.", note: "Preuves au dossier" };
    expect((await call(h, "/members/5/sanctions", as("m@example.com", "moderator", body))).status).toBe(403);
    const done = await call(h, "/members/5/sanctions", as("a@example.com", "admin", body));
    expect(done.status).toBe(201);
    expect((done.body.data as { appealCode: string }).appealCode).toBeTruthy();
    expect(h.audit.at(-1)?.action).toBe("sanction.issue");
    expect((await call(h, "/members/5000/sanctions", as("a@example.com", "admin", body))).status).toBe(404);
  });
});

describe("conversation read", () => {
  test("the justification is mandatory: 400 without it or too short", async () => {
    const h = withReports();
    expect((await call(h, "/reports/1/conversation", as("m@example.com", "moderator"))).status).toBe(400);
    expect((await call(h, "/reports/1/conversation?justification=court", as("m@example.com", "moderator"))).status).toBe(400);
    expect((await call(h, `/reports/1/conversation?justification=${"x".repeat(501)}`, as("m@example.com", "moderator"))).status).toBe(400);
    expect(h.audit).toHaveLength(0);
  });

  test("a valid read is audited with the justification and the report id", async () => {
    const h = withReports();
    const result = await call(h, "/reports/1/conversation?justification=Verifier+les+insultes+signalees", as("m@example.com", "moderator"));
    expect(result.status).toBe(200);
    const entry = h.audit[0];
    expect(entry?.action).toBe("conversation.read");
    expect(entry?.justification).toBe("Verifier les insultes signalees");
    expect(entry?.details).toMatchObject({ reportId: 1 });
    expect(entry?.actor).toBe("m@example.com");
  });
});

describe("member file", () => {
  test("reading a file is audited; an unknown member is a 404", async () => {
    const h = harness();
    expect((await call(h, "/members/7", as("m@example.com", "moderator"))).status).toBe(200);
    expect(h.audit.map((e) => e.action)).toEqual(["member.read"]);
    expect(h.audit[0]?.targetId).toBe("7");
    expect((await call(h, "/members/7000", as("m@example.com", "moderator"))).status).toBe(404);
    expect(h.audit).toHaveLength(1);
  });
});

describe("appeals", () => {
  async function suspended(h: Harness) {
    const result = await call(h, "/members/5/sanctions", as("a@example.com", "admin", { kind: "suspension", ground: "harassment", facts: "Messages insultants répétés.", durationDays: 10, note: "Après relecture" }));
    const data = result.body.data as { appealCode: string; sanction: { id: number; statement: { reference: string } } };
    return { code: data.appealCode, reference: data.sanction.statement.reference, id: data.sanction.id };
  }
  const publicAppeal = (h: Harness, body: unknown, ip = "203.0.113.5") =>
    h.app.request("http://test/api/appeals", { method: "POST", headers: { "content-type": "application/json", "x-forwarded-for": ip }, body: JSON.stringify(body) });
  const message = "Je conteste cette décision, il s'agit d'une erreur.";

  test("public: a wrong code and an unknown reference get the same answer, and create nothing", async () => {
    const h = harness();
    const { reference } = await suspended(h);
    const wrong = await publicAppeal(h, { reference, appealCode: "AAAA-AAAA-AAAA", message });
    const unknown = await publicAppeal(h, { reference: "MZ-2026-ZZZZZZ", appealCode: "AAAA-AAAA-AAAA", message });
    expect(wrong.status).toBe(202);
    expect(unknown.status).toBe(202);
    expect(await wrong.text()).toBe(await unknown.text());
    expect(h.world.appeals).toHaveLength(0);
  });

  test("public: the right pair files the appeal; a second one is a 409; case and dashes do not matter", async () => {
    const h = harness();
    const { reference, code } = await suspended(h);
    const ok = await publicAppeal(h, { reference, appealCode: code.toLowerCase().replace(/-/g, " "), message });
    expect(ok.status).toBe(202);
    expect(h.world.appeals).toHaveLength(1);
    expect((await publicAppeal(h, { reference, appealCode: code, message })).status).toBe(409);
  });

  test("public: the message must be 10 to 2000 characters", async () => {
    const h = harness();
    const { reference, code } = await suspended(h);
    expect((await publicAppeal(h, { reference, appealCode: code, message: "court" })).status).toBe(400);
    expect((await publicAppeal(h, { reference, appealCode: code, message: "x".repeat(2001) })).status).toBe(400);
  });

  test("public: limited to 5 per hour per address", async () => {
    const h = harness();
    for (let attempt = 0; attempt < 5; attempt += 1) {
      expect((await publicAppeal(h, { reference: "MZ-2026-ZZZZZZ", appealCode: "AAAA", message }, "198.51.100.9")).status).toBe(202);
    }
    expect((await publicAppeal(h, { reference: "MZ-2026-ZZZZZZ", appealCode: "AAAA", message }, "198.51.100.9")).status).toBe(429);
    expect((await publicAppeal(h, { reference: "MZ-2026-ZZZZZZ", appealCode: "AAAA", message }, "198.51.100.10")).status).toBe(202);
  });

  test("public: after six months the appeal is refused", async () => {
    const h = harness();
    const issuedAt = new Date("2026-01-10T10:00:00Z");
    const statement = buildStatement({ reference: "MZ-2026-OLD123".replace("O", "0"), kind: "warning", ground: "harassment", facts: "Faits anciens connus.", startsAt: issuedAt, endsAt: null, origin: "member_report", issuedAt });
    const code = "ABCD-EFGH-JKMN";
    h.world.addSanction({ memberId: 5, kind: "warning", ground: "harassment", startsAt: issuedAt, endsAt: null, decidedBy: "a@example.com", reportId: null, statement, appealCodeHash: createHash("sha256").update("ABCDEFGHJKMN").digest("hex"), note: null });
    expect(NOW.getTime()).toBeGreaterThan(issuedAt.getTime() + 180 * 86_400_000);
    const late = await publicAppeal(h, { reference: statement.reference, appealCode: code, message });
    expect(late.status).toBe(409);
  });

  test("the author of the sanction cannot decide the appeal: same_decider", async () => {
    const h = harness();
    const { reference, code, id } = await suspended(h);
    await publicAppeal(h, { reference, appealCode: code, message });
    const appealId = h.world.appeals[0]?.id;
    const decision = { outcome: "overturned", note: "Erreur manifeste" };
    const same = await call(h, `/appeals/${appealId}/decision`, as("a@example.com", "admin", decision));
    expect(same.status).toBe(409);
    expect(same.body.error).toBe("same_decider");
    expect(h.world.appeals[0]?.status).toBe("pending");
    h.calls.length = 0;
    const other = await call(h, `/appeals/${appealId}/decision`, as("b@example.com", "admin", decision));
    expect(other.status).toBe(200);
    expect(h.world.sanctions.find((s) => s.id === id)?.revokedAt).not.toBeNull();
    expect(h.calls).toEqual(["enable:5"]);
    expect(h.notices.at(-1)).toBe("appeal:5:overturned");
    expect(h.audit.at(-1)?.action).toBe("appeal.decide");
    expect((await call(h, `/appeals/${appealId}/decision`, as("b@example.com", "admin", decision))).status).toBe(409);
  });
});

describe("transparency and authorities", () => {
  test("CSV export: RFC 4180", async () => {
    const h = harness();
    const result = await call(h, "/transparency?from=2026-10-01&to=2026-10-24&format=csv", as("an@example.com", "analyst"));
    expect(result.status).toBe(200);
    expect(result.response.headers.get("content-type")).toBe("text/csv; charset=utf-8");
    expect(result.text.startsWith("section,key,value\r\n")).toBe(true);
    expect(result.text.endsWith("\r\n")).toBe(true);
    expect(result.text).toContain("notices_received,harassment,2\r\n");
    expect(result.text).toContain("notices,median_handling_hours,3.5\r\n");
    expect(result.text).toContain("appeals,median_hours,\r\n");
  });

  test("period must be valid", async () => {
    const h = harness();
    expect((await call(h, "/transparency?from=2026-10-24&to=2026-10-01", as("an@example.com", "analyst"))).status).toBe(400);
    expect((await call(h, "/transparency?from=nope&to=2026-10-01", as("an@example.com", "analyst"))).status).toBe(400);
    const json = await call(h, "/transparency?from=2026-10-01&to=2026-10-24", as("an@example.com", "analyst"));
    expect(json.status).toBe(200);
    expect((json.body.data as { automatedDecisions: number }).automatedDecisions).toBe(0);
  });

  test("an authority request is created and audited", async () => {
    const h = harness();
    const body = { kind: "judicial_requisition", authority: "Parquet de Paris", reference: "2026/123", scope: "Données de connexion d'un membre", memberId: 5 };
    const created = await call(h, "/authorities", as("a@example.com", "admin", body));
    expect(created.status).toBe(201);
    expect(h.audit.at(-1)?.action).toBe("authority.create");
    expect((await call(h, "/authorities", as("a@example.com", "admin", { kind: "x" }))).status).toBe(400);
  });
});
