import type { AuditLog } from "../../audit/application/ports";
import { InvalidPriceChangeError, ProductNotFoundError } from "../domain/errors";
import { addDays, parisDay, parseDay } from "../domain/paris-time";
import { APPLE_TERRITORIES, catalogProduct, type CatalogProduct, type ProductDisplay } from "../domain/products";
import type { AppStorePricing, ApplePriceChangePlan, ApplePricePoint, StorePrice, WebPrice, WebPricing } from "./ports";
import type { ProductPatch, StorefrontRepository } from "./repository";
import { callStore, describeFailure } from "./store-call";

export type StorePricesView<T> = { readonly status: "ok"; readonly items: readonly T[] } | { readonly status: "unavailable"; readonly error: string };

export interface ProductView extends ProductDisplay {
  readonly kind: CatalogProduct["kind"];
  readonly months: number | null;
  // The Stripe price in use: the catalogue's own, or the environment variable's.
  readonly effectiveStripePriceId: string | null;
  readonly prices: {
    readonly apple: StorePricesView<StorePrice>;
    readonly web: StorePricesView<WebPrice>;
  };
}

export interface ApplePriceRequest {
  readonly pricePointId: string;
  readonly startDate: string;
  readonly preserveCurrentPrice: boolean;
  readonly dryRun: boolean;
}

export interface WebPriceRequest {
  readonly amountCents: number;
  readonly currency: string;
}

export interface CatalogDeps {
  readonly repository: StorefrontRepository;
  readonly apple: AppStorePricing;
  readonly web: WebPricing;
  readonly audit: AuditLog;
  readonly env: Readonly<Record<string, string | undefined>>;
  readonly now: () => Date;
}

const MIN_WEB_AMOUNT_CENTS = 50;
const MAX_WEB_AMOUNT_CENTS = 1_000_000;
const MAX_PRICE_HORIZON_DAYS = 730;

// The Stripe price a product is sold with on the web: the catalogue's, else the environment's.
export function effectiveStripePriceId(product: ProductDisplay, env: Readonly<Record<string, string | undefined>>): string | null {
  if (product.stripePriceId !== null) return product.stripePriceId;
  const spec = catalogProduct(product.productId);
  const fromEnv = spec === undefined ? undefined : env[spec.priceEnv]?.trim();
  return fromEnv === undefined || fromEnv === "" ? null : fromEnv;
}

const decimal = (cents: number): string => (cents / 100).toFixed(2);

export class CatalogService {
  constructor(private readonly deps: CatalogDeps) {}

  async listProducts(): Promise<readonly ProductView[]> {
    const products = await this.deps.repository.listProducts();
    return Promise.all(products.map((product) => this.view(product)));
  }

  async updateProduct(actor: string, productId: string, patch: ProductPatch): Promise<ProductDisplay> {
    const updated = await this.deps.repository.updateProduct(productId, patch, actor);
    await this.deps.audit.record({
      actor,
      action: "storefront.product.update",
      targetType: "storefront_product",
      targetId: productId,
      details: { fields: Object.keys(patch).filter((key) => patch[key as keyof ProductPatch] !== undefined) },
    });
    return updated;
  }

  async applePricePoints(productId: string, territory: string): Promise<readonly ApplePricePoint[]> {
    this.requireProduct(productId);
    return callStore("apple", () => this.deps.apple.pricePoints(productId, territory));
  }

  // Two steps: dryRun answers what each country would pay, nothing is written;
  // the real call plans again (the plan may be stale) and writes.
  async changeApplePrice(actor: string, productId: string, request: ApplePriceRequest): Promise<{ readonly dryRun: boolean; readonly plan: ApplePriceChangePlan }> {
    this.requireProduct(productId);
    this.checkStartDate(request.startDate);
    const plan = await callStore("apple", () =>
      this.deps.apple.planPriceChange(productId, request.pricePointId, request.startDate, request.preserveCurrentPrice),
    );
    if (request.dryRun) return { dryRun: true, plan };
    try {
      await callStore("apple", () => this.deps.apple.applyPriceChange(plan));
    } catch (error: unknown) {
      await this.journalApple(actor, plan, "failed", describeFailure(error));
      await this.auditApple(actor, productId, request, plan, "failed");
      throw error;
    }
    await this.journalApple(actor, plan, "applied", null);
    await this.auditApple(actor, productId, request, plan, "applied");
    return { dryRun: false, plan };
  }

  // A Stripe price never changes: a new one is created, then the catalogue points to it.
  async changeWebPrice(actor: string, productId: string, request: WebPriceRequest): Promise<{ readonly price: WebPrice; readonly previousPriceId: string | null }> {
    const spec = this.requireProduct(productId);
    if (!Number.isInteger(request.amountCents) || request.amountCents < MIN_WEB_AMOUNT_CENTS || request.amountCents > MAX_WEB_AMOUNT_CENTS) {
      throw new InvalidPriceChangeError(`amountCents must be an integer from ${String(MIN_WEB_AMOUNT_CENTS)} to ${String(MAX_WEB_AMOUNT_CENTS)}`);
    }
    const product = await this.deps.repository.getProduct(productId);
    if (product === null) throw new ProductNotFoundError(productId);
    const previousPriceId = effectiveStripePriceId(product, this.deps.env);
    const previous = previousPriceId === null ? null : await this.previousWebPrice(previousPriceId);
    const currency = request.currency.toLowerCase();
    const today = parisDay(this.deps.now());
    const entry = {
      actor,
      productId,
      platform: "web" as const,
      territory: null,
      oldPrice: previous === null ? null : decimal(previous.amountCents),
      newPrice: decimal(request.amountCents),
      currency: currency.toUpperCase(),
      effectiveDate: today,
    };
    let price: WebPrice;
    try {
      price = await callStore("stripe", () => this.deps.web.createPrice(productId, request.amountCents, currency, spec.months));
      await this.deps.repository.setStripePriceId(productId, price.priceId, actor);
    } catch (error: unknown) {
      await this.deps.repository.recordPriceChange({ ...entry, result: "failed", error: describeFailure(error) });
      await this.deps.audit.record({
        actor,
        action: "storefront.price.web",
        targetType: "storefront_product",
        targetId: productId,
        details: { result: "failed", amountCents: request.amountCents, currency },
      });
      throw error;
    }
    await this.deps.repository.recordPriceChange({ ...entry, result: "applied", error: null });
    await this.deps.audit.record({
      actor,
      action: "storefront.price.web",
      targetType: "storefront_product",
      targetId: productId,
      details: { result: "applied", previousPriceId, priceId: price.priceId, amountCents: request.amountCents, currency },
    });
    return { price, previousPriceId };
  }

  private requireProduct(productId: string): CatalogProduct {
    const spec = catalogProduct(productId);
    if (spec === undefined) throw new ProductNotFoundError(productId);
    return spec;
  }

  private checkStartDate(startDate: string): void {
    const today = parisDay(this.deps.now());
    const parsed = parseDay(startDate);
    const valid = /^\d{4}-\d{2}-\d{2}$/.test(startDate) && parisDay(new Date(Date.UTC(parsed.year, parsed.month - 1, parsed.day, 12))) === startDate;
    if (!valid) throw new InvalidPriceChangeError("startDate must be a real date, YYYY-MM-DD");
    if (startDate < today) throw new InvalidPriceChangeError("startDate cannot be in the past");
    if (startDate > addDays(today, MAX_PRICE_HORIZON_DAYS)) throw new InvalidPriceChangeError("startDate is too far ahead");
  }

  private async previousWebPrice(priceId: string): Promise<{ amountCents: number } | null> {
    try {
      const price = await this.deps.web.currentPrice(priceId);
      return { amountCents: price.amountCents };
    } catch {
      return null;
    }
  }

  private async journalApple(actor: string, plan: ApplePriceChangePlan, result: "applied" | "failed", error: string | null): Promise<void> {
    for (const change of plan.changes) {
      await this.deps.repository.recordPriceChange({
        actor,
        productId: plan.productId,
        platform: "apple",
        territory: change.territory,
        oldPrice: change.from,
        newPrice: change.to,
        currency: null,
        effectiveDate: plan.startDate,
        result,
        error,
      });
    }
  }

  private async auditApple(actor: string, productId: string, request: ApplePriceRequest, plan: ApplePriceChangePlan, result: string): Promise<void> {
    await this.deps.audit.record({
      actor,
      action: "storefront.price.apple",
      targetType: "storefront_product",
      targetId: productId,
      details: {
        result,
        pricePointId: request.pricePointId,
        startDate: plan.startDate,
        preserveCurrentPrice: plan.preserveCurrentPrice,
        territories: plan.changes.length,
      },
    });
  }

  private async view(product: ProductDisplay): Promise<ProductView> {
    const spec = catalogProduct(product.productId);
    const priceId = effectiveStripePriceId(product, this.deps.env);
    const [apple, web] = await Promise.all([
      this.collect(() => this.deps.apple.currentPrices(product.productId, APPLE_TERRITORIES), "apple"),
      priceId === null ? Promise.resolve<StorePricesView<WebPrice>>({ status: "ok", items: [] }) : this.collect(async () => [await this.deps.web.currentPrice(priceId)], "stripe"),
    ]);
    return { ...product, kind: spec?.kind ?? "credits", months: spec?.months ?? null, effectiveStripePriceId: priceId, prices: { apple, web } };
  }

  private async collect<T>(call: () => Promise<readonly T[]>, store: "apple" | "stripe"): Promise<StorePricesView<T>> {
    try {
      return { status: "ok", items: await callStore(store, call) };
    } catch (error: unknown) {
      return { status: "unavailable", error: error instanceof Error && "code" in error && typeof error.code === "string" ? error.code : "store_error" };
    }
  }
}

