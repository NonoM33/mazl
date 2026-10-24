export type PlanType = "monthly" | "two_month" | "three_month" | "six_month" | "yearly" | "unknown";

const PLAN_BY_MONTHS: Readonly<Record<number, PlanType>> = {
  1: "monthly",
  2: "two_month",
  3: "three_month",
  6: "six_month",
  12: "yearly",
};

const PRODUCT_ID_PATTERN = /^com\.mazl\.app\.plus\.(\d{1,2})m$/;

// Product ids look like com.mazl.app.plus.<n>m, n being the duration in months.
export function planTypeForProduct(productId: string): PlanType {
  const months = PRODUCT_ID_PATTERN.exec(productId)?.[1];
  if (months === undefined) return "unknown";
  return PLAN_BY_MONTHS[Number(months)] ?? "unknown";
}
