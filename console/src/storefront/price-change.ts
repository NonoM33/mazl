// Changement de prix : formats, comparaison pays par pays et explication en clair avant confirmation. Fonctions pures.
import { parisToday } from "./paris-time";
import { applePrices } from "./product-view";
import type { ApplePlanDto, ApplePriceChangeDto, ProductDto, StorePriceDto } from "./types";

export const TERRITORY_NAMES: Readonly<Record<string, string>> = { FRA: "France", USA: "États-Unis", GBR: "Royaume-Uni", ISR: "Israël", CAN: "Canada" };
export const territoryName = (code: string): string => TERRITORY_NAMES[code] ?? code;

/** « 44.99 » + « EUR » → « 44,99 € ». */
export function formatMoney(amount: string | number, currency: string): string {
  const value = typeof amount === "number" ? amount : Number(amount);
  if (Number.isNaN(value)) return "—";
  try {
    return new Intl.NumberFormat("fr-FR", { style: "currency", currency, currencyDisplay: "narrowSymbol" }).format(value);
  } catch {
    return `${value.toFixed(2)} ${currency}`.trim();
  }
}

export const formatCents = (cents: number, currency: string): string => formatMoney(cents / 100, currency);

export function applePrice(product: Pick<ProductDto, "prices">, territory: string): StorePriceDto | undefined {
  return applePrices(product).find((price) => price.territory === territory);
}

export type Direction = "up" | "down" | "same";

export function direction(from: string | null, to: string): Direction {
  if (from === null) return "same";
  const a = Number(from);
  const b = Number(to);
  if (b > a) return "up";
  return b < a ? "down" : "same";
}

export interface ChangeLine {
  readonly territory: string;
  readonly country: string;
  readonly before: string;
  readonly after: string;
  readonly direction: Direction;
}

/** `currencyOf` : devise d'un pays (le serveur donne les montants du plan sans devise ; elle se lit sur les prix actuels du produit). */
export function changeLines(changes: readonly ApplePriceChangeDto[], currencyOf: (territory: string) => string | null): readonly ChangeLine[] {
  return changes.map((change) => ({
    territory: change.territory,
    country: territoryName(change.territory),
    before: change.from === null ? "—" : formatMoney(change.from, currencyOf(change.territory) ?? ""),
    after: formatMoney(change.to, currencyOf(change.territory) ?? ""),
    direction: direction(change.from, change.to),
  }));
}

/** Sens global du changement, jugé sur la France (prix de base) ; « same » si rien ne bouge. */
export function planDirection(plan: Pick<ApplePlanDto, "changes">): Direction {
  const base = plan.changes.find((change) => change.territory === "FRA") ?? plan.changes[0];
  return base === undefined ? "same" : direction(base.from, base.to);
}

/** Les phrases à montrer avant « Confirmer », selon le sens du changement et le choix de conserver le prix des abonnés. */
export function explainApplePlan(plan: Pick<ApplePlanDto, "changes" | "preserveCurrentPrice" | "startDate">, isSubscription: boolean): readonly string[] {
  const sens = planDirection(plan);
  const lines: string[] = [];
  if (sens === "same") lines.push("Ce palier est le prix actuel : rien ne change.");
  if (isSubscription && sens === "down") lines.push("C'est une baisse : elle s'applique à tous les abonnés, au prochain renouvellement de chacun. Les nouveaux abonnés paient le nouveau prix dès la date d'effet.");
  if (isSubscription && sens === "up" && plan.preserveCurrentPrice) lines.push("C'est une hausse, et les abonnés actuels gardent leur prix. Seuls les nouveaux abonnés paient le nouveau prix, à partir de la date d'effet.");
  if (isSubscription && sens === "up" && !plan.preserveCurrentPrice) lines.push("C'est une hausse sans conservation du prix : Apple demande l'accord de chaque abonné actuel. Un abonné qui ne l'accepte pas voit son abonnement s'arrêter à la fin de sa période en cours.");
  if (!isSubscription && sens !== "same") lines.push("Achat à l'unité : le nouveau prix vaut pour tous les achats futurs. Il n'y a pas d'abonnés à ménager.");
  if (sens !== "same") lines.push(`Apple applique le changement à la date d'effet choisie (${formatIsoDay(plan.startDate)}), qui ne peut pas être dans le passé. La propagation dans les boutiques prend quelques heures.`);
  if (sens !== "same") lines.push("Les autres pays suivent la conversion d'Apple : leurs prix sont ceux du tableau ci-dessus.");
  return lines;
}

/** AAAA-MM-JJ → « 14 févr. 2027 ». */
export function formatIsoDay(day: string): string {
  const match = /^(\d{4})-(\d{2})-(\d{2})$/.exec(day);
  if (match === null) return day;
  return new Intl.DateTimeFormat("fr-FR", { timeZone: "UTC", day: "numeric", month: "short", year: "numeric" }).format(Date.UTC(Number(match[1]), Number(match[2]) - 1, Number(match[3])));
}

function isRealDay(day: string): boolean {
  const match = /^(\d{4})-(\d{2})-(\d{2})$/.exec(day);
  if (match === null) return false;
  const [year, month, date] = [Number(match[1]), Number(match[2]), Number(match[3])];
  const check = new Date(Date.UTC(year, month - 1, date));
  return check.getUTCFullYear() === year && check.getUTCMonth() === month - 1 && check.getUTCDate() === date;
}

/** Date d'effet : AAAA-MM-JJ, aujourd'hui (Paris) ou plus tard. */
export function validateStartDate(day: string, now: Date = new Date()): string | null {
  if (!isRealDay(day)) return "Choisissez la date d'effet.";
  return day < parisToday(now) ? "La date d'effet ne peut pas être dans le passé." : null;
}

export const WEB_CURRENCIES = ["EUR", "USD", "GBP", "ILS", "CAD"] as const;
export const WEB_AMOUNT_MAX_CENTS = 100_000_00;

/** « 44,99 » ou « 44.99 » → 4499. Deux décimales au plus, strictement positif. */
export function parseAmountToCents(text: string): number | null {
  const normalized = text.trim().replace(/\s/g, "").replace(",", ".");
  if (!/^\d+(\.\d{1,2})?$/.test(normalized)) return null;
  const cents = Math.round(Number(normalized) * 100);
  return cents > 0 && cents <= WEB_AMOUNT_MAX_CENTS ? cents : null;
}

export function validateWebPrice(amountText: string, currency: string): { readonly ok: true; readonly amountCents: number } | { readonly ok: false; readonly error: string } {
  const cents = parseAmountToCents(amountText);
  if (cents === null) return { ok: false, error: "Saisissez un montant positif avec deux décimales au plus (ex. 44,99)." };
  if (!(WEB_CURRENCIES as readonly string[]).includes(currency)) return { ok: false, error: "Choisissez une devise de la liste." };
  return { ok: true, amountCents: cents };
}
