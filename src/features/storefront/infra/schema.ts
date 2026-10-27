import type { Sql } from "postgres";
import { CATALOG_PRODUCTS } from "../domain/products";

const SCHEMA_LOCK = 724_002;

// Called at start-up, idempotent. The catalogue starts with one row per product
// of the web offers, in their order; staff edit it afterwards.
export async function ensureStorefrontSchema(sql: Sql): Promise<void> {
  await sql.begin(async (transaction) => {
    const tx = transaction as unknown as Sql;
    await tx`SELECT pg_advisory_xact_lock(${SCHEMA_LOCK})`;
    await tx`
      CREATE TABLE IF NOT EXISTS storefront_products (
        product_id TEXT PRIMARY KEY,
        visible BOOLEAN NOT NULL DEFAULT true,
        sort_order INTEGER NOT NULL,
        featured BOOLEAN NOT NULL DEFAULT false,
        highlight JSONB,
        stripe_price_id TEXT,
        updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
        updated_by TEXT
      )
    `;
    await tx`
      CREATE TABLE IF NOT EXISTS storefront_campaigns (
        id SERIAL PRIMARY KEY,
        theme_id TEXT NOT NULL,
        name TEXT NOT NULL,
        starts_at TIMESTAMPTZ NOT NULL,
        ends_at TIMESTAMPTZ NOT NULL,
        texts JSONB NOT NULL,
        targets JSONB NOT NULL,
        change_app_icon BOOLEAN NOT NULL DEFAULT true,
        status TEXT NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'scheduled', 'cancelled')),
        apple JSONB NOT NULL DEFAULT '{"codes":[],"error":null}',
        stripe JSONB NOT NULL DEFAULT '{"promotions":[],"error":null}',
        created_by TEXT NOT NULL,
        created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
        updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
        CHECK (ends_at > starts_at)
      )
    `;
    await tx`CREATE INDEX IF NOT EXISTS idx_storefront_campaigns_status ON storefront_campaigns (status, starts_at)`;
    await tx`
      CREATE TABLE IF NOT EXISTS storefront_price_changes (
        id BIGSERIAL PRIMARY KEY,
        created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
        actor TEXT NOT NULL,
        product_id TEXT NOT NULL,
        platform TEXT NOT NULL CHECK (platform IN ('apple', 'web')),
        territory TEXT,
        old_price TEXT,
        new_price TEXT NOT NULL,
        currency TEXT,
        effective_date DATE,
        result TEXT NOT NULL CHECK (result IN ('applied', 'failed')),
        error TEXT
      )
    `;
    await tx`CREATE INDEX IF NOT EXISTS idx_storefront_price_changes_product ON storefront_price_changes (product_id, created_at DESC)`;
    for (const product of CATALOG_PRODUCTS) {
      await tx`
        INSERT INTO storefront_products (product_id, visible, sort_order, featured)
        VALUES (${product.productId}, true, ${product.defaultSortOrder}, ${product.defaultFeatured})
        ON CONFLICT (product_id) DO NOTHING
      `;
    }
  });
}
