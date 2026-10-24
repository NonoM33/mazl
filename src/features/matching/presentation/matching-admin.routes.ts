import type { Context, Hono } from "hono";
import type { ZodType } from "zod";
import type { AuditLog } from "../../audit/application/ports";
import type { RequirePermission, StaffVariables } from "../../staff/application/ports";
import { currentStaff } from "../../staff/application/ports";
import { parseId, parsePage } from "../../../shared/http/validation";
import {
  CorruptVersionError,
  InvalidParamsError,
  InvalidPreviewError,
  NoAbTestError,
  VariantIsActiveError,
  VersionNotFoundError,
} from "../application/errors";
import type { MatchingTuning } from "../application/tuning";
import type { MatchingStateDto, PreviewRequest, PreviewResponse, VersionPageDto, ParamsVersionDto } from "./dto";
import { abTestBody, activateBody, createVersionBody, previewBody } from "./matching-admin.schemas";

type App = Hono<{ Variables: StaffVariables }>;
type Ctx = Context<{ Variables: StaffVariables }>;

export interface MatchingAdminDeps {
  readonly requirePermission: RequirePermission;
  // The tuning use cases audit by themselves; kept in the deps so that the
  // module wiring states what the routes rely on.
  readonly audit: AuditLog;
  readonly tuning: MatchingTuning;
}

const VERSIONS_DEFAULT_LIMIT = 20;
const VERSIONS_MAX_LIMIT = 100;

const ok = <T>(c: Ctx, data: T, status: 200 | 201 = 200) => c.json({ success: true as const, data }, status);
const fail = (c: Ctx, status: 400 | 404 | 409 | 500, error: string, message?: string) =>
  c.json({ success: false as const, error, ...(message === undefined ? {} : { message }) }, status);

async function body<T>(c: Ctx, schema: ZodType<T>): Promise<{ readonly ok: true; readonly data: T } | { readonly ok: false }> {
  let raw: unknown;
  try {
    raw = await c.req.json();
  } catch {
    return { ok: false };
  }
  const parsed = schema.safeParse(raw);
  return parsed.success ? { ok: true, data: parsed.data } : { ok: false };
}

function failure(c: Ctx, error: unknown): Response {
  if (error instanceof InvalidParamsError) return fail(c, 400, "invalid_params", error.problems.join(" ; "));
  if (error instanceof InvalidPreviewError) return fail(c, 400, "invalid_preview", error.message);
  if (error instanceof VersionNotFoundError) return fail(c, 404, "version_not_found");
  if (error instanceof NoAbTestError) return fail(c, 404, "no_ab_test");
  if (error instanceof VariantIsActiveError) return fail(c, 409, "variant_is_active", error.message);
  if (error instanceof CorruptVersionError) {
    console.error("Matching: corrupt parameter version", error.versionId, error.problems);
    return fail(c, 500, "corrupt_version", error.message);
  }
  console.error("Matching back-office request failed:", error instanceof Error ? error.message : "unknown");
  return fail(c, 500, "internal_error");
}

export function registerMatchingAdminRoutes(app: App, deps: MatchingAdminDeps): void {
  const { requirePermission, tuning } = deps;
  const read = requirePermission("matching.read");
  const tune = requirePermission("matching.tune");
  const base = "/api/backoffice/matching";

  app.get(base, read, async (c) => {
    try {
      const overview = await tuning.overview();
      const data: MatchingStateDto = overview;
      return ok(c, data);
    } catch (error: unknown) {
      return failure(c, error);
    }
  });

  app.get(`${base}/versions`, read, async (c) => {
    try {
      const page = parsePage(c.req.query("limit"), c.req.query("offset"), { defaultLimit: VERSIONS_DEFAULT_LIMIT, maxLimit: VERSIONS_MAX_LIMIT });
      const data: VersionPageDto = await tuning.listVersions(page);
      return ok(c, data);
    } catch (error: unknown) {
      return failure(c, error);
    }
  });

  app.post(`${base}/versions`, tune, async (c) => {
    const parsed = await body(c, createVersionBody);
    if (!parsed.ok) return fail(c, 400, "invalid_body");
    try {
      const data: ParamsVersionDto = await tuning.createVersion(currentStaff(c).email, {
        params: parsed.data.params,
        note: parsed.data.note,
        activate: parsed.data.activate ?? false,
      });
      return ok(c, data, 201);
    } catch (error: unknown) {
      return failure(c, error);
    }
  });

  app.post(`${base}/versions/:id/activate`, tune, async (c) => {
    const id = parseId(c.req.param("id"));
    if (id === null) return fail(c, 404, "version_not_found");
    const parsed = await body(c, activateBody);
    if (!parsed.ok) return fail(c, 400, "invalid_body");
    try {
      await tuning.activate(currentStaff(c).email, id, parsed.data.note);
      return ok(c, await tuning.overview());
    } catch (error: unknown) {
      return failure(c, error);
    }
  });

  app.post(`${base}/ab-test`, tune, async (c) => {
    const parsed = await body(c, abTestBody);
    if (!parsed.ok) return fail(c, 400, "invalid_body");
    try {
      await tuning.startAbTest(currentStaff(c).email, parsed.data.variantId, parsed.data.sharePercent);
      return ok(c, await tuning.overview());
    } catch (error: unknown) {
      return failure(c, error);
    }
  });

  app.delete(`${base}/ab-test`, tune, async (c) => {
    try {
      await tuning.stopAbTest(currentStaff(c).email);
      return ok(c, await tuning.overview());
    } catch (error: unknown) {
      return failure(c, error);
    }
  });

  app.post(`${base}/preview`, read, async (c) => {
    const parsed = await body(c, previewBody);
    if (!parsed.ok) return fail(c, 400, "invalid_body");
    try {
      const request: Omit<PreviewRequest, "params" | "compareWith"> & { params: unknown; compareWith?: unknown } = parsed.data;
      const data: PreviewResponse = tuning.preview(request);
      return ok(c, data);
    } catch (error: unknown) {
      return failure(c, error);
    }
  });
}
