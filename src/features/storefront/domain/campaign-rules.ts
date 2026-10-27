import { CampaignNotEditableError, CampaignOverlapError, InvalidCampaignError } from "./errors";
import { campaignStatus, type Campaign, type CampaignInput, type CampaignText } from "./campaign";
import { LANGUAGES } from "./languages";
import { catalogProduct } from "./products";
import { isThemeId } from "./themes";

export const MAX_CAMPAIGN_DAYS = 45;
export const MIN_DISCOUNT_PERCENT = 5;
export const MAX_DISCOUNT_PERCENT = 90;
export const MAX_NAME_LENGTH = 80;
const DAY_MS = 86_400_000;
const LIMITS = { title: 60, subtitle: 140, cta: 30 } as const;

function textProblems(language: string, text: CampaignText): string[] {
  const problems: string[] = [];
  for (const field of ["title", "subtitle", "cta"] as const) {
    const value = text[field].trim();
    if (value === "") problems.push(`texts.${language}.${field} is empty`);
    else if (value.length > LIMITS[field]) problems.push(`texts.${language}.${field} is longer than ${String(LIMITS[field])} characters`);
  }
  return problems;
}

// Every business rule of a campaign, independent of the others. Returns the
// problems found (empty when valid).
export function campaignProblems(input: CampaignInput): string[] {
  const problems: string[] = [];
  if (!isThemeId(input.themeId)) problems.push(`unknown theme ${input.themeId}`);
  const name = input.name.trim();
  if (name === "" || name.length > MAX_NAME_LENGTH) problems.push(`name must have 1 to ${String(MAX_NAME_LENGTH)} characters`);
  if (Number.isNaN(input.startsAt.getTime()) || Number.isNaN(input.endsAt.getTime())) {
    problems.push("startsAt and endsAt must be valid dates");
  } else if (input.endsAt <= input.startsAt) {
    problems.push("endsAt must be after startsAt");
  } else if (input.endsAt.getTime() - input.startsAt.getTime() > MAX_CAMPAIGN_DAYS * DAY_MS) {
    problems.push(`a campaign lasts ${String(MAX_CAMPAIGN_DAYS)} days at most`);
  }
  for (const language of LANGUAGES) {
    const text = input.texts[language];
    if (text !== undefined) problems.push(...textProblems(language, text));
  }
  if (input.targets.length === 0) problems.push("a campaign targets at least one product");
  const seen = new Set<string>();
  for (const target of input.targets) {
    if (catalogProduct(target.productId) === undefined) problems.push(`unknown product ${target.productId}`);
    if (seen.has(target.productId)) problems.push(`product ${target.productId} is targeted twice`);
    seen.add(target.productId);
    if (!Number.isInteger(target.discountPercent) || target.discountPercent < MIN_DISCOUNT_PERCENT || target.discountPercent > MAX_DISCOUNT_PERCENT) {
      problems.push(`discountPercent of ${target.productId} must be an integer from ${String(MIN_DISCOUNT_PERCENT)} to ${String(MAX_DISCOUNT_PERCENT)}`);
    }
  }
  return problems;
}

export function assertValidCampaign(input: CampaignInput): void {
  const problems = campaignProblems(input);
  if (problems.length > 0) throw new InvalidCampaignError(problems);
}

function overlaps(a: { readonly startsAt: Date; readonly endsAt: Date }, b: { readonly startsAt: Date; readonly endsAt: Date }): boolean {
  return a.startsAt < b.endsAt && b.startsAt < a.endsAt;
}

// Two scheduled campaigns never overlap. `others` may hold any campaign: only the scheduled ones count.
export function assertNoOverlap(candidate: { readonly id: number | null; readonly startsAt: Date; readonly endsAt: Date }, others: readonly Campaign[]): void {
  const clash = others.find((other) => other.status === "scheduled" && other.id !== candidate.id && overlaps(candidate, other));
  if (clash !== undefined) throw new CampaignOverlapError(clash.id);
}

export type CampaignEdit = Partial<Omit<CampaignInput, "themeId">> & { readonly themeId?: CampaignInput["themeId"] };

function toInput(campaign: Campaign): CampaignInput {
  return {
    themeId: campaign.themeId,
    name: campaign.name,
    startsAt: campaign.startsAt,
    endsAt: campaign.endsAt,
    texts: campaign.texts,
    targets: campaign.targets,
    changeAppIcon: campaign.changeAppIcon,
  };
}

const DISPLAY_FIELDS = ["name", "texts", "changeAppIcon"] as const;

// What an edit is allowed to change, by state:
//  - draft: everything;
//  - scheduled, not started: name, texts, icon (dates, theme and targets are tied to the codes created at the stores: cancel and recreate);
//  - live: only an earlier end;
//  - ended / cancelled: nothing.
export function applyEdit(campaign: Campaign, edit: CampaignEdit, now: Date): CampaignInput {
  const state = campaignStatus(campaign, now);
  const changed = (Object.keys(edit) as (keyof CampaignEdit)[]).filter((key) => edit[key] !== undefined);
  if (state === "ended" || state === "cancelled") throw new CampaignNotEditableError(`A ${state} campaign cannot be edited`);
  if (state === "live") {
    if (changed.some((key) => key !== "endsAt")) throw new CampaignNotEditableError("A live campaign can only be ended earlier or cancelled");
    const endsAt = edit.endsAt;
    if (endsAt === undefined) throw new InvalidCampaignError(["nothing to change"]);
    if (endsAt >= campaign.endsAt) throw new CampaignNotEditableError("A live campaign can only end earlier");
    if (endsAt <= now) throw new InvalidCampaignError(["endsAt must be in the future (cancel the campaign to stop it now)"]);
    return { ...toInput(campaign), endsAt };
  }
  if (state === "scheduled") {
    const locked = changed.filter((key) => !(DISPLAY_FIELDS as readonly string[]).includes(key));
    if (locked.length > 0) {
      throw new CampaignNotEditableError(`A scheduled campaign keeps its ${locked.join(", ")}: cancel it and create another one`);
    }
  }
  const next: CampaignInput = {
    themeId: edit.themeId ?? campaign.themeId,
    name: edit.name ?? campaign.name,
    startsAt: edit.startsAt ?? campaign.startsAt,
    endsAt: edit.endsAt ?? campaign.endsAt,
    texts: edit.texts ?? campaign.texts,
    targets: edit.targets ?? campaign.targets,
    changeAppIcon: edit.changeAppIcon ?? campaign.changeAppIcon,
  };
  assertValidCampaign(next);
  return next;
}
