// Synthetic examples of the storefront API. No real person, domain, token or price list:
// a test checks each one against the schema it illustrates and scans them for anything real.

const PLUS_3M = "com.mazl.app.plus.3m";

export const productDisplayExample = {
  productId: PLUS_3M,
  visible: true,
  sortOrder: 1,
  featured: true,
  highlight: { fr: "Le plus choisi", en: "Most popular" },
  stripePriceId: "price_example_plus_3m",
  updatedAt: "2027-01-15T10:00:00.000Z",
  updatedBy: "staff@example.com",
};

export const productViewExample = {
  ...productDisplayExample,
  kind: "subscription" as const,
  months: 3,
  effectiveStripePriceId: "price_example_plus_3m",
  prices: {
    apple: {
      status: "ok" as const,
      items: [
        { territory: "FRA", currency: "EUR", customerPrice: "24.99" },
        { territory: "USA", currency: "USD", customerPrice: "26.99" },
      ],
    },
    web: { status: "ok" as const, items: [{ priceId: "price_example_plus_3m", amountCents: 2499, currency: "eur" }] },
  },
};

export const campaignExample = {
  id: 12,
  themeId: "valentine" as const,
  name: "Saint-Valentin 2027",
  startsAt: "2027-02-06T23:00:00.000Z",
  endsAt: "2027-02-14T23:00:00.000Z",
  status: "scheduled" as const,
  texts: {
    fr: { title: "Pour deux", subtitle: "Offrez-vous mazl+ à prix doux.", cta: "J'en profite" },
    en: { title: "For two", subtitle: "Treat yourself to mazl+ for less.", cta: "Get the offer" },
  },
  targets: [{ productId: PLUS_3M, discountPercent: 30 }],
  changeAppIcon: true,
  apple: { codes: [{ productId: PLUS_3M, offerCodeId: "offer_code_example_1", customCodeId: "custom_code_example_1", customCode: "VALENTIN27" }], error: null },
  stripe: { promotions: [{ productId: PLUS_3M, couponId: "coupon_example_1", promotionCodeId: "promo_example_1" }], error: null },
  createdBy: "staff@example.com",
  createdAt: "2027-01-10T09:00:00.000Z",
  updatedAt: "2027-01-12T14:30:00.000Z",
};

export const campaignDraftExample = {
  ...campaignExample,
  status: "draft" as const,
  apple: { codes: [], error: null },
  stripe: { promotions: [], error: null },
};

export const campaignCancelledExample = { ...campaignExample, status: "cancelled" as const };

export const campaignRequestExample = {
  themeId: "valentine",
  name: "Saint-Valentin 2027",
  startsAt: "2027-02-07T00:00:00+01:00",
  endsAt: "2027-02-15T00:00:00+01:00",
  texts: campaignExample.texts,
  targets: [{ productId: PLUS_3M, discountPercent: 30 }],
  changeAppIcon: true,
};

export const presetExample = {
  themeId: "valentine" as const,
  glyph: "heart",
  accent: "#E5484D",
  name: "valentine 2027",
  eventStart: "2027-02-14",
  eventEnd: "2027-02-14",
  startsAt: "2027-02-06T23:00:00.000Z",
  endsAt: "2027-02-14T23:00:00.000Z",
  past: false,
  existing: [{ id: 12, name: "Saint-Valentin 2027", status: "scheduled" }],
  conflicts: [],
  overlapsThemes: [],
};

export const applePlanExample = {
  productId: PLUS_3M,
  startDate: "2027-03-01",
  preserveCurrentPrice: true,
  changes: [
    { territory: "FRA", from: "24.99", to: "26.99", pricePointId: "price_point_example_2" },
    { territory: "USA", from: "26.99", to: "28.99", pricePointId: "price_point_example_3" },
  ],
};

export const publicStorefrontExample = {
  serverTime: "2027-02-10T09:00:00.000Z",
  products: [
    { productId: "com.mazl.app.plus.1m", visible: true, sortOrder: 0, featured: false, highlight: null },
    { productId: PLUS_3M, visible: true, sortOrder: 1, featured: true, highlight: "Le plus choisi" },
  ],
  campaign: {
    id: 12,
    themeId: "valentine" as const,
    accent: "#E5484D",
    glyph: "heart",
    startsAt: "2027-02-06T23:00:00.000Z",
    endsAt: "2027-02-14T23:00:00.000Z",
    title: "Pour deux",
    subtitle: "Offrez-vous mazl+ à prix doux.",
    cta: "J'en profite",
    targets: [{ productId: PLUS_3M, discountPercent: 30, iosOfferCode: "VALENTIN27", webPromotion: true }],
  },
  appIcon: "AppIcon-valentine",
  nextChangeAt: "2027-02-15T00:00:00+01:00",
};
