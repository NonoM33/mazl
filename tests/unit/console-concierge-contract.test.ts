// Anti-dérive : la console et sa maquette parlent EXACTEMENT le format du contrat docs/couple/ESPACE-COUPLE.md §7.
// Les schémas ci-dessous sont écrits d'après le contrat, pas d'après la maquette : renommer un champ dans la maquette,
// dans les types ou dans un corps de requête fait échouer ce test. Les schémas sont stricts (aucune clé en trop).
import { describe, expect, test } from "bun:test";
import { Hono } from "hono";
import { z } from "zod";
import { registerConciergeMock } from "../../console/dev/mock-concierge";
import { SECTIONS } from "../../console/src/app/permissions";
import { CONCIERGE_PATH, conciergeApi } from "../../console/src/concierge/api";
import { assignRequest, closeRequest, markBookedRequest, staffMessageRequest, staffNoteRequest } from "../../console/src/concierge/request-bodies";
import { REQUEST_STATUSES, STAFF_MESSAGE_MAX, STAFF_NOTE_MAX } from "../../console/src/concierge/types";
import { createApiClient, type ApiResult } from "../../console/src/shared/api/client";
import type { MeDto } from "../../console/src/shared/api/contracts";

// ---- Schémas d'après le contrat §7 ----------------------------------------------------------------------------------
// concierge_requests : id, couple_id, created_by, title, brief, wanted_at date|null, city, constraints jsonb,
// status "new"|"proposed"|"chosen"|"booked"|"closed"|"cancelled", options jsonb [{ title, details, priceHint }],
// chosen_index int|null, staff_note, assigned_to, created_at, updated_at. Le staff ne voit ni couple_id ni created_by.
const status = z.enum(["new", "proposed", "chosen", "booked", "closed", "cancelled"]);
const day = z.string().regex(/^\d{4}-\d{2}-\d{2}$/);
const instant = z.string().datetime();
const option = z.object({ title: z.string().min(1), details: z.string().min(1), priceHint: z.string() }).strict();
const couple = z.object({ firstNames: z.array(z.string().min(1)).min(1).max(2), months: z.number().int().nonnegative() }).strict();

const request = z
  .object({
    id: z.number().int().positive(),
    title: z.string().min(1),
    brief: z.string(),
    wantedAt: day.nullable(),
    city: z.string().nullable(),
    constraints: z.object({ kosher: z.boolean().optional(), budget: z.string().optional() }).strict(),
    status,
    options: z.array(option).max(3),
    chosenIndex: z.number().int().min(0).max(2).nullable(),
    staffNote: z.string().max(STAFF_NOTE_MAX),
    assignedTo: z.string().nullable(),
    createdAt: instant,
    updatedAt: instant,
  })
  .strict();

// concierge_messages : id, request_id, role "member"|"assistant"|"staff", author_id|null, text, created_at.
const message = z.object({ id: z.number().int().positive(), role: z.enum(["member", "assistant", "staff"]), authorId: z.number().int().nullable(), text: z.string().min(1), createdAt: instant }).strict();

// Liste du couple : { id, title, status, wantedAt, updatedAt, step: 1..3 } ; la liste staff y ajoute assignedTo et couple.
const listItem = z.object({ id: z.number().int().positive(), title: z.string().min(1), status, wantedAt: day.nullable(), updatedAt: instant, step: z.union([z.literal(1), z.literal(2), z.literal(3)]), assignedTo: z.string().nullable(), couple }).strict();
const listResponse = z.object({ requests: z.array(listItem) }).strict();
const detailResponse = z.object({ request, couple, messages: z.array(message) }).strict();
const errorEnvelope = z.object({ success: z.literal(false), error: z.string().min(1), message: z.string().optional() }).strict();

// Corps d'écriture : PATCH { status?, staffNote?, assignedTo? }, POST messages { text }.
const patchBody = z
  .object({ status: z.enum(["booked", "closed"]).optional(), staffNote: z.string().max(STAFF_NOTE_MAX).optional(), assignedTo: z.string().min(1).nullable().optional() })
  .strict()
  .refine((body) => Object.keys(body).length > 0, "au moins un champ");
const messageBody = z.object({ text: z.string().min(1).max(STAFF_MESSAGE_MAX) }).strict();

// ---- Client branché sur la maquette ---------------------------------------------------------------------------------
interface Exchange {
  readonly method: string;
  readonly path: string;
  readonly status: number;
  readonly requestBody: unknown;
  readonly payload: unknown;
}

const BASE = "/api/backoffice";

function meFor(permissions: readonly string[]): MeDto {
  return { email: "gestion@example.com", role: "admin", roleLabel: "Administrateur", permissions: permissions as MeDto["permissions"], mfa: true, mfaEnrolled: true, mfaRequired: true };
}

function consoleFor(permissions: readonly string[] = ["concierge.manage"]): { readonly store: ReturnType<typeof conciergeApi>; readonly exchanges: Exchange[] } {
  const root = new Hono();
  const api = new Hono();
  registerConciergeMock(api, () => meFor(permissions));
  root.route(BASE, api);
  const exchanges: Exchange[] = [];
  const client = createApiClient({
    getToken: () => "jeton-de-test",
    onUnauthorized: () => undefined,
    onMfaRequired: () => undefined,
    fetch: async (input, init) => {
      const url = new URL(input, "http://localhost");
      const response = await root.request(`${url.pathname}${url.search}`, init);
      const copy = response.clone();
      exchanges.push({ method: init?.method ?? "GET", path: url.pathname.replace(BASE, ""), status: response.status, requestBody: typeof init?.body === "string" ? (JSON.parse(init.body) as unknown) : undefined, payload: await copy.json() });
      return response;
    },
  });
  return { store: conciergeApi(client), exchanges };
}

const ok = <T>(result: ApiResult<T>): T => {
  if (!result.ok) throw new Error(`échec inattendu ${String(result.status)} ${result.code} : ${result.message}`);
  return result.data;
};
const failed = <T>(result: ApiResult<T>): { status: number; code: string } => {
  if (result.ok) throw new Error("un échec était attendu");
  return { status: result.status, code: result.code };
};

function expectShape(schema: z.ZodType, value: unknown, where: string): void {
  const parsed = schema.safeParse(value);
  if (!parsed.success) throw new Error(`${where} : ${parsed.error.issues.map((issue) => `${issue.path.join(".")} ${issue.message}`).join(" ; ")}`);
}

describe("la maquette de la conciergerie rend les formes du contrat §7", () => {
  test("parcours complet : chaque réponse et chaque corps passent les schémas du contrat", async () => {
    const { store, exchanges } = consoleFor();

    const everything = ok(await store.list());
    expect(everything.requests.length).toBeGreaterThanOrEqual(6);
    for (const status of REQUEST_STATUSES) expect(everything.requests.some((row) => row.status === status)).toBe(true);
    expect(ok(await store.list("chosen")).requests.every((row) => row.status === "chosen")).toBe(true);

    const chosen = ok(await store.list("chosen")).requests[0];
    if (chosen === undefined) throw new Error("une demande avec idée choisie est attendue");
    const detail = ok(await store.get(chosen.id));
    expect(detail.request.chosenIndex).not.toBeNull();
    expect(detail.messages.map((entry) => entry.role)).toContain("assistant");

    ok(await store.patch(chosen.id, staffNoteRequest("Appeler le traiteur avant midi.")));
    ok(await store.patch(chosen.id, assignRequest("admin@example.com")));
    ok(await store.patch(chosen.id, assignRequest(null)));
    const afterMessage = ok(await store.sendMessage(chosen.id, staffMessageRequest("Bonne nouvelle, tout est possible pour vendredi.")));
    expect(afterMessage.messages.at(-1)?.role).toBe("staff");
    const booked = ok(await store.patch(chosen.id, markBookedRequest()));
    expect(booked.request.status).toBe("booked");
    expect(ok(await store.patch(chosen.id, closeRequest())).request.status).toBe("closed");

    expect(exchanges.length).toBeGreaterThan(8);
    for (const exchange of exchanges) {
      const where = `${exchange.method} ${exchange.path} (${String(exchange.status)})`;
      const payload = exchange.payload as { success: boolean; data: unknown };
      if (exchange.status >= 400) {
        expectShape(errorEnvelope, payload, where);
        continue;
      }
      expect(payload.success).toBe(true);
      expectShape(exchange.method === "GET" && exchange.path === CONCIERGE_PATH ? listResponse : detailResponse, payload.data, where);
      if (exchange.requestBody !== undefined) expectShape(exchange.method === "PATCH" ? patchBody : messageBody, exchange.requestBody, `${where} (corps)`);
    }
  });

  test("les erreurs documentées par le contrat : 404, 400, 409, 403", async () => {
    const { store, exchanges } = consoleFor();
    expect(failed(await store.get(9999))).toEqual({ status: 404, code: "concierge_not_found" });
    expect(failed(await store.sendMessage(1, { text: "" }))).toEqual({ status: 400, code: "invalid_body" });
    expect(failed(await store.sendMessage(1, { text: "x".repeat(STAFF_MESSAGE_MAX + 1) }))).toEqual({ status: 400, code: "invalid_body" });
    expect(failed(await store.patch(1, {}))).toEqual({ status: 400, code: "invalid_body" });
    // Une demande « new » ne peut pas être marquée réservée ; une demande close n'accepte plus de message.
    expect(failed(await store.patch(1, markBookedRequest()))).toEqual({ status: 409, code: "invalid_transition" });
    const closed = ok(await store.list("closed")).requests[0];
    if (closed === undefined) throw new Error("une demande close est attendue");
    expect(failed(await store.sendMessage(closed.id, { text: "Encore un mot" }))).toEqual({ status: 409, code: "concierge_closed" });
    expect(failed(await store.patch(closed.id, closeRequest()))).toEqual({ status: 409, code: "invalid_transition" });
    for (const exchange of exchanges.filter((entry) => entry.status >= 400)) expectShape(errorEnvelope, exchange.payload, `${exchange.method} ${exchange.path}`);
  });

  test("sans la permission concierge.manage, toutes les routes rendent 403", async () => {
    const { store } = consoleFor(["dashboard.read"]);
    expect(failed(await store.list())).toEqual({ status: 403, code: "forbidden" });
    expect(failed(await store.get(1))).toEqual({ status: 403, code: "forbidden" });
    expect(failed(await store.patch(1, closeRequest()))).toEqual({ status: 403, code: "forbidden" });
    expect(failed(await store.sendMessage(1, { text: "bonjour" }))).toEqual({ status: 403, code: "forbidden" });
  });

  test("la maquette garde sous la limite de 3 idées et ne montre que prénoms et durée du couple", async () => {
    const { store } = consoleFor();
    for (const row of ok(await store.list()).requests) {
      const detail = ok(await store.get(row.id));
      expect(detail.request.options.length).toBeLessThanOrEqual(3);
      expect(Object.keys(detail.couple).sort()).toEqual(["firstNames", "months"]);
      expect(Object.keys(detail.request)).not.toContain("coupleId");
      expect(Object.keys(detail.request)).not.toContain("createdBy");
    }
  });

  test("les schémas du test détectent un champ renommé", () => {
    const base = { id: 1, title: "t", status: "new", wantedAt: null, updatedAt: "2026-10-27T09:00:00.000Z", step: 1, assignedTo: null, couple: { firstNames: ["Léa"], months: 3 } };
    expect(listItem.safeParse(base).success).toBe(true);
    expect(listItem.safeParse({ ...base, wanted_at: null }).success).toBe(false);
    expect(listItem.safeParse({ ...base, status: "nouvelle" }).success).toBe(false);
    expect(patchBody.safeParse({ staff_note: "x" }).success).toBe(false);
    expect(patchBody.safeParse({ status: "chosen" }).success).toBe(false);
    expect(messageBody.safeParse({ message: "x" }).success).toBe(false);
  });
});

describe("la section dans la console", () => {
  test("« Conciergerie » exige la permission concierge.manage", () => {
    const section = SECTIONS.find((entry) => entry.id === "conciergerie");
    expect(section?.permission).toBe("concierge.manage");
    expect(section?.implemented).toBe(true);
  });
});
