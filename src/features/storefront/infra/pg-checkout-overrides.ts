import type { Sql } from "postgres";
import type { CheckoutOverrides } from "../../billing-web/application/ports";

// What the web checkout takes from the storefront: the Stripe price chosen in the catalogue
// and the promotion code of the campaign that is live now (the database clock decides).
export class PgCheckoutOverrides implements CheckoutOverrides {
  constructor(private readonly sql: Sql) {}

  async priceIdFor(productId: string): Promise<string | undefined> {
    const [row] = await this.sql<{ stripe_price_id: string | null }[]>`
      SELECT stripe_price_id FROM storefront_products WHERE product_id = ${productId}
    `;
    return row?.stripe_price_id ?? undefined;
  }

  async promotionCodeFor(productId: string): Promise<string | undefined> {
    const [row] = await this.sql<{ promotion_code_id: string }[]>`
      SELECT promotion ->> 'promotionCodeId' AS promotion_code_id
      FROM storefront_campaigns c, jsonb_array_elements(c.stripe -> 'promotions') AS promotion
      WHERE c.status = 'scheduled' AND c.starts_at <= now() AND c.ends_at > now()
        AND promotion ->> 'productId' = ${productId}
      ORDER BY c.starts_at DESC
      LIMIT 1
    `;
    return row?.promotion_code_id;
  }
}
