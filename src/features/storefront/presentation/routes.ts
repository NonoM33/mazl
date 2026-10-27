import type { Context, Env, Hono } from "hono";
import { Hono as HonoApp } from "hono";
import type { ZodType } from "zod";
import type { RequirePermission, StaffVariables } from "../../staff/application/ports";
import { currentStaff } from "../../staff/application/ports";
import type { CatalogService } from "../application/catalog-service";
import type { CampaignService } from "../application/campaign-service";
import { buildPublicStorefront } from "../application/public-storefront";
import type { StorefrontRepository } from "../application/repository";
import type { CampaignInput } from "../domain/campaign";
import type { CampaignEdit } from "../domain/campaign-rules";
import {
  CampaignNotEditableError,
  CampaignNotFoundError,
  CampaignOverlapError,
  CampaignStateError,
  InvalidCampaignError,
  InvalidPriceChangeError,
  ProductNotFoundError,
  StoreCallError,
  StoreNotConfiguredError,
} from "../domain/errors";
import { negotiateLanguage } from "../domain/languages";
import { toCampaignDto, toPresetDto, toProductDisplayDto, toProductViewDto } from "./dto";
import { buildOpenApi } from "./openapi";
import { honoPath, OPERATIONS, PUBLIC_PATH, type OperationSpec } from "./operations";
import { applePriceBody, campaignBody, campaignIdParam, campaignPatchBody, productPatchBody, territoryQuery, webPriceBody, yearQuery } from "./schemas";

type Ctx = Context<{ Variables: StaffVariables }>;
type Status = 200 | 201 | 400 | 404 | 409 | 500 | 502 | 503;

export interface StorefrontRouteDeps {
  readonly requirePermission: RequirePermission;
  readonly catalog: CatalogService;
  readonly campaigns: CampaignService;
  readonly repository: StorefrontRepository;
  readonly now: () => Date;
  // False in production: the document of the admin routes is not distributed there.
  readonly exposeOpenApi: boolean;
}

const ok = <T>(c: Ctx, data: T, status: 200 | 201 = 200): Response => c.json({ success: true as const, data }, status);
const fail = (c: Ctx, status: Exclude<Status, 200 | 201>, error: string, message?: string): Response =>
  c.json({ success: false as const, error, ...(message === undefined ? {} : { message }) }, status);

type Parsed<T> = { readonly ok: true; readonly data: T } | { readonly ok: false; readonly message: string };

async function readBody<T>(c: Ctx, schema: ZodType<T>): Promise<Parsed<T>> {
  let raw: unknown;
  try {
    raw = await c.req.json();
  } catch {
    return { ok: false, message: "corps JSON illisible" };
  }
  const parsed = schema.safeParse(raw);
  if (parsed.success) return { ok: true, data: parsed.data };
  const issue = parsed.error.issues[0];
  const path = issue?.path.join(".") ?? "";
  return { ok: false, message: `${path === "" ? "" : `${path}: `}${issue?.message ?? "invalide"}` };
}

function failure(c: Ctx, error: unknown): Response {
  if (error instanceof InvalidCampaignError) return fail(c, 400, error.code, error.message);
  if (error instanceof InvalidPriceChangeError) return fail(c, 400, error.code, error.message);
  if (error instanceof ProductNotFoundError || error instanceof CampaignNotFoundError) return fail(c, 404, error.code);
  if (error instanceof CampaignOverlapError || error instanceof CampaignNotEditableError || error instanceof CampaignStateError) {
    return fail(c, 409, error.code, error.message);
  }
  if (error instanceof StoreNotConfiguredError) return fail(c, 503, error.code, error.message);
  if (error instanceof StoreCallError) return fail(c, 502, error.code, error.message);
  console.error("Storefront request failed:", error instanceof Error ? error.name : "unknown");
  return fail(c, 500, "internal_error");
}

function toInput(body: ReturnType<typeof campaignBody.parse>): CampaignInput {
  return { ...body, startsAt: new Date(body.startsAt), endsAt: new Date(body.endsAt) };
}

function toEdit(body: ReturnType<typeof campaignPatchBody.parse>): CampaignEdit {
  const { startsAt, endsAt, ...rest } = body;
  return {
    ...rest,
    ...(startsAt === undefined ? {} : { startsAt: new Date(startsAt) }),
    ...(endsAt === undefined ? {} : { endsAt: new Date(endsAt) }),
  };
}

// GET /api/storefront: public, no authentication, cached for a minute.
export function registerPublicStorefrontRoute<E extends Env>(app: Hono<E>, deps: Pick<StorefrontRouteDeps, "repository" | "now">): void {
  app.get(PUBLIC_PATH, async (c) => {
    try {
      const data = await buildPublicStorefront(deps.repository, deps.now(), negotiateLanguage(c.req.header("Accept-Language")));
      c.header("Cache-Control", "public, max-age=60");
      // The texts depend on the language the member asked for.
      c.header("Vary", "Accept-Language");
      return c.json({ success: true as const, data });
    } catch (error: unknown) {
      console.error("Public storefront failed:", error instanceof Error ? error.name : "unknown");
      return c.json({ success: false as const, error: "internal_error" }, 500);
    }
  });
}

// /api/backoffice/storefront/*: the staff routes, each guarded by ONE permission.
export function registerStorefrontAdminRoutes(app: Hono<{ Variables: StaffVariables }>, deps: StorefrontRouteDeps): void {
  const router = new HonoApp<{ Variables: StaffVariables }>();
  const { catalog, campaigns } = deps;
  const spec = (operationId: string): OperationSpec => {
    const found = OPERATIONS.find((operation) => operation.operationId === operationId);
    if (found === undefined) throw new Error(`No operation ${operationId}`);
    return found;
  };
  const guard = (operationId: string) => {
    const permission = spec(operationId).permission;
    if (permission === null) throw new Error(`${operationId} is public`);
    return deps.requirePermission(permission);
  };
  const path = (operationId: string): string => honoPath(spec(operationId).path);
  const productId = (c: Ctx): string => c.req.param("productId") ?? "";

  router.get(path("storefrontListProducts"), guard("storefrontListProducts"), async (c) => {
    try {
      return ok(c, { products: (await catalog.listProducts()).map(toProductViewDto) });
    } catch (error: unknown) {
      return failure(c, error);
    }
  });

  router.patch(path("storefrontUpdateProduct"), guard("storefrontUpdateProduct"), async (c) => {
    const body = await readBody(c, productPatchBody);
    if (!body.ok) return fail(c, 400, "invalid_body", body.message);
    try {
      return ok(c, toProductDisplayDto(await catalog.updateProduct(currentStaff(c).email, productId(c), body.data)));
    } catch (error: unknown) {
      return failure(c, error);
    }
  });

  router.get(path("storefrontApplePricePoints"), guard("storefrontApplePricePoints"), async (c) => {
    const territory = territoryQuery.safeParse(c.req.query("territory") ?? "FRA");
    if (!territory.success) return fail(c, 400, "invalid_query", "territory: trois lettres majuscules");
    try {
      const pricePoints = await catalog.applePricePoints(productId(c), territory.data);
      return ok(c, { productId: productId(c), territory: territory.data, pricePoints: pricePoints.map((point) => ({ ...point })) });
    } catch (error: unknown) {
      return failure(c, error);
    }
  });

  router.post(path("storefrontApplePrice"), guard("storefrontApplePrice"), async (c) => {
    const body = await readBody(c, applePriceBody);
    if (!body.ok) return fail(c, 400, "invalid_body", body.message);
    try {
      const result = await catalog.changeApplePrice(currentStaff(c).email, productId(c), body.data);
      return ok(c, { dryRun: result.dryRun, plan: { ...result.plan, changes: result.plan.changes.map((change) => ({ ...change })) } });
    } catch (error: unknown) {
      return failure(c, error);
    }
  });

  router.post(path("storefrontWebPrice"), guard("storefrontWebPrice"), async (c) => {
    const body = await readBody(c, webPriceBody);
    if (!body.ok) return fail(c, 400, "invalid_body", body.message);
    try {
      const actor = currentStaff(c).email;
      const result = await catalog.changeWebPrice(actor, productId(c), body.data);
      const product = await deps.repository.getProduct(productId(c));
      if (product === null) throw new ProductNotFoundError(productId(c));
      return ok(c, { price: { ...result.price }, previousPriceId: result.previousPriceId, product: toProductDisplayDto(product) });
    } catch (error: unknown) {
      return failure(c, error);
    }
  });

  router.get(path("storefrontListCampaigns"), guard("storefrontListCampaigns"), async (c) => {
    const rawYear = c.req.query("year");
    const year = rawYear === undefined ? undefined : yearQuery.safeParse(rawYear);
    if (year !== undefined && !year.success) return fail(c, 400, "invalid_query", "year: de 2020 à 2100");
    try {
      const list = await campaigns.list(year?.data);
      const now = deps.now();
      return ok(c, { campaigns: list.map((campaign) => toCampaignDto(campaign, now)) });
    } catch (error: unknown) {
      return failure(c, error);
    }
  });

  router.post(path("storefrontCreateCampaign"), guard("storefrontCreateCampaign"), async (c) => {
    const body = await readBody(c, campaignBody);
    if (!body.ok) return fail(c, 400, "invalid_body", body.message);
    try {
      return ok(c, toCampaignDto(await campaigns.create(currentStaff(c).email, toInput(body.data)), deps.now()), 201);
    } catch (error: unknown) {
      return failure(c, error);
    }
  });

  // Declared before /campaigns/:id so that "presets" is never read as an id.
  router.get(path("storefrontCampaignPresets"), guard("storefrontCampaignPresets"), async (c) => {
    const year = yearQuery.safeParse(c.req.query("year"));
    if (!year.success) return fail(c, 400, "invalid_query", "year: de 2020 à 2100");
    try {
      return ok(c, { year: year.data, presets: (await campaigns.presets(year.data)).map(toPresetDto) });
    } catch (error: unknown) {
      return failure(c, error);
    }
  });

  const campaignId = (c: Ctx): number | null => {
    const parsed = campaignIdParam.safeParse(c.req.param("id"));
    return parsed.success ? parsed.data : null;
  };

  router.patch(path("storefrontUpdateCampaign"), guard("storefrontUpdateCampaign"), async (c) => {
    const id = campaignId(c);
    if (id === null) return fail(c, 404, "campaign_not_found");
    const body = await readBody(c, campaignPatchBody);
    if (!body.ok) return fail(c, 400, "invalid_body", body.message);
    try {
      return ok(c, toCampaignDto(await campaigns.update(currentStaff(c).email, id, toEdit(body.data)), deps.now()));
    } catch (error: unknown) {
      return failure(c, error);
    }
  });

  router.post(path("storefrontPublishCampaign"), guard("storefrontPublishCampaign"), async (c) => {
    const id = campaignId(c);
    if (id === null) return fail(c, 404, "campaign_not_found");
    try {
      return ok(c, toCampaignDto(await campaigns.publish(currentStaff(c).email, id), deps.now()));
    } catch (error: unknown) {
      return failure(c, error);
    }
  });

  router.post(path("storefrontCancelCampaign"), guard("storefrontCancelCampaign"), async (c) => {
    const id = campaignId(c);
    if (id === null) return fail(c, 404, "campaign_not_found");
    try {
      return ok(c, toCampaignDto(await campaigns.cancel(currentStaff(c).email, id), deps.now()));
    } catch (error: unknown) {
      return failure(c, error);
    }
  });

  router.get(path("storefrontOpenApi"), guard("storefrontOpenApi"), (c) => {
    if (!deps.exposeOpenApi) return fail(c, 404, "not_found");
    return c.json(buildOpenApi());
  });

  app.route("/", router);
}
