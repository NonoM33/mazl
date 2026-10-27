import type { Sql } from "postgres";
import type { Campaign, CampaignInput, StoredCampaignStatus } from "../domain/campaign";
import { CampaignNotFoundError, CampaignOverlapError, ProductNotFoundError } from "../domain/errors";
import type { LocalizedText } from "../domain/languages";
import type { ProductDisplay } from "../domain/products";
import { isThemeId } from "../domain/themes";
import type { CampaignStatePatch, PriceChangeEntry, ProductPatch, StorefrontRepository } from "../application/repository";
import { parseAppleState, parseStripeState, parseTargets, parseTexts } from "./campaign-json";
import { z } from "zod";

const OVERLAP_LOCK = 724_003;

interface ProductRow {
  readonly product_id: string;
  readonly visible: boolean;
  readonly sort_order: number;
  readonly featured: boolean;
  readonly highlight: unknown;
  readonly stripe_price_id: string | null;
  readonly updated_at: Date;
  readonly updated_by: string | null;
}

interface CampaignRow {
  readonly id: number;
  readonly theme_id: string;
  readonly name: string;
  readonly starts_at: Date;
  readonly ends_at: Date;
  readonly texts: unknown;
  readonly targets: unknown;
  readonly change_app_icon: boolean;
  readonly status: StoredCampaignStatus;
  readonly apple: unknown;
  readonly stripe: unknown;
  readonly created_by: string;
  readonly created_at: Date;
  readonly updated_at: Date;
}

const highlightSchema = z.object({ fr: z.string(), en: z.string().optional(), he: z.string().optional(), es: z.string().optional(), ru: z.string().optional() });

function toProduct(row: ProductRow): ProductDisplay {
  return {
    productId: row.product_id,
    visible: row.visible,
    sortOrder: row.sort_order,
    featured: row.featured,
    highlight: row.highlight === null ? null : (highlightSchema.parse(row.highlight) as LocalizedText),
    stripePriceId: row.stripe_price_id,
    updatedAt: row.updated_at,
    updatedBy: row.updated_by,
  };
}

function toCampaign(row: CampaignRow): Campaign {
  if (!isThemeId(row.theme_id)) throw new Error(`storefront_campaigns ${String(row.id)} has an unknown theme ${row.theme_id}`);
  return {
    id: row.id,
    themeId: row.theme_id,
    name: row.name,
    startsAt: row.starts_at,
    endsAt: row.ends_at,
    texts: parseTexts(row.texts),
    targets: parseTargets(row.targets),
    changeAppIcon: row.change_app_icon,
    status: row.status,
    apple: parseAppleState(row.apple),
    stripe: parseStripeState(row.stripe),
    createdBy: row.created_by,
    createdAt: row.created_at,
    updatedAt: row.updated_at,
  };
}

// postgres.js types a transaction handle as non-callable; it is the same tag.
function inTransaction<T>(sql: Sql, work: (tx: Sql) => Promise<T>): Promise<T> {
  return sql.begin((transaction) => work(transaction as unknown as Sql)) as Promise<T>;
}

export class PgStorefrontRepository implements StorefrontRepository {
  constructor(private readonly sql: Sql) {}

  async listProducts(): Promise<readonly ProductDisplay[]> {
    const rows = await this.sql<ProductRow[]>`SELECT * FROM storefront_products ORDER BY sort_order, product_id`;
    return rows.map(toProduct);
  }

  async getProduct(productId: string): Promise<ProductDisplay | null> {
    const [row] = await this.sql<ProductRow[]>`SELECT * FROM storefront_products WHERE product_id = ${productId}`;
    return row === undefined ? null : toProduct(row);
  }

  async updateProduct(productId: string, patch: ProductPatch, by: string): Promise<ProductDisplay> {
    const [row] = await this.sql<ProductRow[]>`
      UPDATE storefront_products SET
        visible = ${patch.visible ?? this.sql`visible`},
        sort_order = ${patch.sortOrder ?? this.sql`sort_order`},
        featured = ${patch.featured ?? this.sql`featured`},
        highlight = ${patch.highlight === undefined ? this.sql`highlight` : patch.highlight === null ? null : this.sql.json(JSON.parse(JSON.stringify(patch.highlight)))},
        updated_at = now(),
        updated_by = ${by}
      WHERE product_id = ${productId}
      RETURNING *
    `;
    if (row === undefined) throw new ProductNotFoundError(productId);
    return toProduct(row);
  }

  async setStripePriceId(productId: string, priceId: string, by: string): Promise<ProductDisplay> {
    const [row] = await this.sql<ProductRow[]>`
      UPDATE storefront_products SET stripe_price_id = ${priceId}, updated_at = now(), updated_by = ${by}
      WHERE product_id = ${productId}
      RETURNING *
    `;
    if (row === undefined) throw new ProductNotFoundError(productId);
    return toProduct(row);
  }

  async listCampaigns(range?: { readonly from: Date; readonly to: Date }): Promise<readonly Campaign[]> {
    const rows =
      range === undefined
        ? await this.sql<CampaignRow[]>`SELECT * FROM storefront_campaigns ORDER BY starts_at, id`
        : await this.sql<CampaignRow[]>`
            SELECT * FROM storefront_campaigns WHERE starts_at < ${range.to} AND ends_at > ${range.from} ORDER BY starts_at, id
          `;
    return rows.map(toCampaign);
  }

  async getCampaign(id: number): Promise<Campaign | null> {
    const [row] = await this.sql<CampaignRow[]>`SELECT * FROM storefront_campaigns WHERE id = ${id}`;
    return row === undefined ? null : toCampaign(row);
  }

  async insertCampaign(input: CampaignInput, by: string): Promise<Campaign> {
    const [row] = await this.sql<CampaignRow[]>`
      INSERT INTO storefront_campaigns (theme_id, name, starts_at, ends_at, texts, targets, change_app_icon, created_by)
      VALUES (${input.themeId}, ${input.name.trim()}, ${input.startsAt}, ${input.endsAt},
              ${this.sql.json(JSON.parse(JSON.stringify(input.texts)))}, ${this.sql.json(JSON.parse(JSON.stringify(input.targets)))},
              ${input.changeAppIcon}, ${by})
      RETURNING *
    `;
    if (row === undefined) throw new Error("Campaign not created");
    return toCampaign(row);
  }

  async updateCampaign(id: number, input: CampaignInput): Promise<Campaign> {
    const [row] = await this.sql<CampaignRow[]>`
      UPDATE storefront_campaigns SET
        theme_id = ${input.themeId}, name = ${input.name.trim()}, starts_at = ${input.startsAt}, ends_at = ${input.endsAt},
        texts = ${this.sql.json(JSON.parse(JSON.stringify(input.texts)))}, targets = ${this.sql.json(JSON.parse(JSON.stringify(input.targets)))},
        change_app_icon = ${input.changeAppIcon}, updated_at = now()
      WHERE id = ${id}
      RETURNING *
    `;
    if (row === undefined) throw new CampaignNotFoundError(id);
    return toCampaign(row);
  }

  async saveCampaignState(id: number, patch: CampaignStatePatch): Promise<Campaign> {
    return inTransaction(this.sql, async (tx) => {
      // Two publications at the same time cannot both find the slot free.
      await tx`SELECT pg_advisory_xact_lock(${OVERLAP_LOCK})`;
      const [current] = await tx<CampaignRow[]>`SELECT * FROM storefront_campaigns WHERE id = ${id} FOR UPDATE`;
      if (current === undefined) throw new CampaignNotFoundError(id);
      if (patch.status === "scheduled") {
        const [clash] = await tx<{ id: number }[]>`
          SELECT id FROM storefront_campaigns
          WHERE status = 'scheduled' AND id <> ${id} AND starts_at < ${current.ends_at} AND ends_at > ${current.starts_at}
          LIMIT 1
        `;
        if (clash !== undefined) throw new CampaignOverlapError(clash.id);
      }
      const apple = patch.apple === undefined ? current.apple : patch.apple;
      const stripe = patch.stripe === undefined ? current.stripe : patch.stripe;
      const [row] = await tx<CampaignRow[]>`
        UPDATE storefront_campaigns SET
          status = ${patch.status ?? current.status},
          apple = ${tx.json(JSON.parse(JSON.stringify(apple)))},
          stripe = ${tx.json(JSON.parse(JSON.stringify(stripe)))},
          updated_at = now()
        WHERE id = ${id}
        RETURNING *
      `;
      if (row === undefined) throw new CampaignNotFoundError(id);
      return toCampaign(row);
    });
  }

  async scheduledCampaigns(): Promise<readonly Campaign[]> {
    const rows = await this.sql<CampaignRow[]>`SELECT * FROM storefront_campaigns WHERE status = 'scheduled' ORDER BY starts_at, id`;
    return rows.map(toCampaign);
  }

  async takenOfferCodes(): Promise<ReadonlySet<string>> {
    const rows = await this.sql<{ code: string }[]>`
      SELECT jsonb_array_elements(apple -> 'codes') ->> 'customCode' AS code FROM storefront_campaigns
    `;
    return new Set(rows.map((row) => row.code));
  }

  async recordPriceChange(entry: PriceChangeEntry): Promise<void> {
    await this.sql`
      INSERT INTO storefront_price_changes (actor, product_id, platform, territory, old_price, new_price, currency, effective_date, result, error)
      VALUES (${entry.actor}, ${entry.productId}, ${entry.platform}, ${entry.territory}, ${entry.oldPrice}, ${entry.newPrice},
              ${entry.currency}, ${entry.effectiveDate}, ${entry.result}, ${entry.error})
    `;
  }
}
