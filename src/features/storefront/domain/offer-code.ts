import { parisDay } from "./paris-time";
import type { ThemeId } from "./themes";

// Prefix of the custom offer code Apple shows to members (A-Z0-9, 6 to 64 characters with the year).
const CODE_PREFIX: Readonly<Record<ThemeId, string>> = {
  valentine: "VALENTIN",
  tu_bav: "TUBAV",
  rosh_hashana: "ROSH",
  hanukkah: "HANOUCCA",
  christmas: "NOEL",
  new_year: "NOUVELAN",
  purim: "POURIM",
  passover: "PESSAH",
  mothers_day: "MAMAN",
  summer: "VACANCES",
  black_friday: "BLACKFRIDAY",
};

const CODE_PATTERN = /^[A-Z0-9]{6,64}$/;

export function isValidOfferCode(code: string): boolean {
  return CODE_PATTERN.test(code);
}

export interface OfferCodeRequest {
  readonly themeId: ThemeId;
  // The campaign's last day gives the year: VALENTIN27 ends in February 2027.
  readonly endsAt: Date;
  // Set when a campaign has several subscriptions: each one needs its own code (VALENTIN27M3).
  readonly months: number | null;
  readonly taken: ReadonlySet<string>;
}

export function generateOfferCode(request: OfferCodeRequest): string {
  const year = parisDay(new Date(request.endsAt.getTime() - 1)).slice(2, 4);
  const base = `${CODE_PREFIX[request.themeId]}${year}${request.months === null ? "" : `M${String(request.months)}`}`;
  if (!request.taken.has(base)) return base;
  // A code is never reused, even from a cancelled campaign: B, C, … then B1, B2…
  for (let attempt = 0; attempt < 26 * 100; attempt += 1) {
    const letter = String.fromCharCode(66 + (attempt % 25));
    const suffix = attempt < 25 ? letter : `${letter}${String(Math.floor(attempt / 25))}`;
    const candidate = `${base}${suffix}`;
    if (!request.taken.has(candidate)) return candidate;
  }
  throw new Error("No free offer code");
}
