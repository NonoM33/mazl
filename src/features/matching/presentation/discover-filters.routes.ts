import type { Hono, MiddlewareHandler } from "hono";
import { z } from "zod";
import type { AppVariables } from "../../../shared/http/middleware";
import { parseBody } from "../../../shared/http/validation";
import type { DiscoverFiltersService } from "../application/discover-filters-service";
import type { DiscoverFilters } from "../domain/discover-filters";

type AppEnv = { Variables: AppVariables };

export interface DiscoverFiltersRouteDeps {
  readonly authenticate: MiddlewareHandler<AppEnv>;
  readonly filters: Pick<DiscoverFiltersService, "read" | "update">;
}

// Answers are the stored free texts of the profile (profiles.denomination is a
// VARCHAR(50)); a handful of choices per criterion is all the app offers.
const MAX_ANSWER_LENGTH = 50;
const MAX_ANSWERS = 12;
const answers = z.array(z.string().max(MAX_ANSWER_LENGTH)).max(MAX_ANSWERS).nullable().optional();

// PUT /api/discover/filters. Unknown fields are refused: the old « études »,
// « taille » and « en ligne » filters do not exist and must not look accepted.
const filtersPatchSchema = z
  .object({
    denominations: answers,
    kashrutLevels: answers,
    shabbatObservances: answers,
    onlyVerified: z.boolean().optional(),
    onlyWithPhoto: z.boolean().optional(),
  })
  .strict();

// The JSON of CONTRAT v1 §2: the same keys, lists as arrays or null.
function filtersJson(filters: DiscoverFilters) {
  return {
    denominations: filters.denominations,
    kashrutLevels: filters.kashrutLevels,
    shabbatObservances: filters.shabbatObservances,
    onlyVerified: filters.onlyVerified,
    onlyWithPhoto: filters.onlyWithPhoto,
  };
}

const STATUS = { plus_required: 402, religious_consent_required: 409 } as const;

export function registerDiscoverFiltersRoutes(app: Hono<AppEnv>, deps: DiscoverFiltersRouteDeps): void {
  const { authenticate, filters } = deps;

  app.get("/api/discover/filters", authenticate, async (c) => {
    try {
      const { filters: stored, plus } = await filters.read(c.get("userId"));
      return c.json({ success: true, filters: filtersJson(stored), plus });
    } catch (error: unknown) {
      console.error("Discover filters read error:", error);
      return c.json({ success: false, error: "Failed to get filters" }, 500);
    }
  });

  app.put("/api/discover/filters", authenticate, async (c) => {
    const body = await parseBody(filtersPatchSchema, c);
    if (!body.ok) return c.json({ success: false, error: body.error }, 400);
    try {
      const result = await filters.update(c.get("userId"), body.data);
      if (!result.ok) return c.json({ success: false, error: result.error }, STATUS[result.error]);
      return c.json({ success: true, filters: filtersJson(result.filters) });
    } catch (error: unknown) {
      console.error("Discover filters update error:", error);
      return c.json({ success: false, error: "Failed to save filters" }, 500);
    }
  });
}
