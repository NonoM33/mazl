import type { Sql } from "postgres";
import { CorruptVersionError, InvalidParamsError, NoAbTestError, VariantIsActiveError, VersionNotFoundError } from "../application/errors";
import type {
  ActivationOutcome,
  MatchingState,
  NewVersion,
  ParamsRepository,
  ParamsVersion,
  VersionListing,
} from "../application/ports";
import { inTransaction } from "./schema";
import { validateParams } from "../domain/validate-params";

// Other instances do not see a write made here: they re-read after this delay.
export const STATE_CACHE_TTL_MS = 30_000;

interface VersionRow {
  readonly id: number;
  readonly params: unknown;
  readonly note: string;
  readonly author: string;
  readonly parent_id: number | null;
  readonly created_at: Date;
}

interface StateRow {
  readonly activated_at: Date;
  readonly activated_by: string;
  readonly active_version_id: number;
  readonly ab_variant_id: number | null;
  readonly ab_share_percent: number | null;
  readonly ab_started_at: Date | null;
  readonly ab_started_by: string | null;
}

// Nothing leaves the database without going through validateParams: a stored
// version outside the bounds is an explicit error, never executed.
function toVersion(row: VersionRow): ParamsVersion {
  const checked = validateParams(row.params);
  if (!checked.ok) throw new CorruptVersionError(row.id, checked.errors);
  return {
    id: row.id,
    params: checked.params,
    note: row.note,
    author: row.author,
    createdAt: row.created_at.toISOString(),
    parentId: row.parent_id,
  };
}

export class PgParamsRepository implements ParamsRepository {
  private cached: { readonly state: MatchingState; readonly at: number } | null = null;

  constructor(
    private readonly sql: Sql,
    private readonly clock: () => number = Date.now,
  ) {}

  async createVersion(input: NewVersion): Promise<ParamsVersion> {
    const checked = validateParams(input.params);
    if (!checked.ok) throw new InvalidParamsError(checked.errors);
    const [row] = await this.sql<VersionRow[]>`
      INSERT INTO matching_param_versions (params, note, author, parent_id)
      VALUES (${this.sql.json(JSON.parse(JSON.stringify(checked.params)))}, ${input.note}, ${input.author}, ${input.parentId})
      RETURNING id, params, note, author, parent_id, created_at
    `;
    if (row === undefined) throw new Error("Version not created");
    return toVersion(row);
  }

  async listVersions(page: { readonly limit: number; readonly offset: number }) {
    const rows = await this.sql<(VersionRow & { activated_at: Date | null })[]>`
      SELECT v.id, v.params, v.note, v.author, v.parent_id, v.created_at,
             (SELECT max(a.activated_at) FROM matching_activations a WHERE a.version_id = v.id) AS activated_at
      FROM matching_param_versions v
      ORDER BY v.id DESC
      LIMIT ${page.limit} OFFSET ${page.offset}
    `;
    const [count] = await this.sql<{ n: number }[]>`SELECT count(*)::int AS n FROM matching_param_versions`;
    const versions: VersionListing[] = rows.map((row) => ({
      ...toVersion(row),
      activatedAt: row.activated_at === null ? null : row.activated_at.toISOString(),
    }));
    return { versions, total: count?.n ?? 0 };
  }

  async getVersion(id: number): Promise<ParamsVersion | null> {
    const [row] = await this.sql<VersionRow[]>`SELECT v.id, v.params, v.note, v.author, v.parent_id, v.created_at FROM matching_param_versions v WHERE v.id = ${id}`;
    return row === undefined ? null : toVersion(row);
  }

  async getState(): Promise<MatchingState> {
    const hit = this.cached;
    if (hit !== null && this.clock() - hit.at < STATE_CACHE_TTL_MS) return hit.state;
    const state = await this.readState();
    this.cached = { state, at: this.clock() };
    return state;
  }

  async activate(versionId: number, by: string, note: string): Promise<ActivationOutcome> {
    try {
      return await inTransaction(this.sql, async (tx) => {
        const [target] = await tx<{ id: number }[]>`SELECT id FROM matching_param_versions WHERE id = ${versionId}`;
        if (target === undefined) throw new VersionNotFoundError(versionId);
        const [current] = await tx<{ active_version_id: number; ab_variant_id: number | null }[]>`
          SELECT active_version_id, ab_variant_id FROM matching_state WHERE id = 1 FOR UPDATE
        `;
        if (current === undefined) throw new Error("matching_state missing: ensureMatchingSchema was not run");
        const abTestEnded = current.ab_variant_id === versionId;
        await tx`
          UPDATE matching_state SET active_version_id = ${versionId}, activated_at = now(), activated_by = ${by}
          WHERE id = 1
        `;
        if (abTestEnded) {
          await tx`
            UPDATE matching_state SET ab_variant_id = NULL, ab_share_percent = NULL, ab_started_at = NULL, ab_started_by = NULL
            WHERE id = 1
          `;
        }
        await tx`INSERT INTO matching_activations (version_id, activated_by, note) VALUES (${versionId}, ${by}, ${note})`;
        return { previousVersionId: current.active_version_id, abTestEnded };
      });
    } finally {
      this.cached = null;
    }
  }

  async startAbTest(variantId: number, sharePercent: number, by: string): Promise<void> {
    try {
      await inTransaction(this.sql, async (tx) => {
        const [target] = await tx<{ id: number }[]>`SELECT id FROM matching_param_versions WHERE id = ${variantId}`;
        if (target === undefined) throw new VersionNotFoundError(variantId);
        const [current] = await tx<{ active_version_id: number }[]>`SELECT active_version_id FROM matching_state WHERE id = 1 FOR UPDATE`;
        if (current === undefined) throw new Error("matching_state missing: ensureMatchingSchema was not run");
        if (current.active_version_id === variantId) throw new VariantIsActiveError(variantId);
        await tx`
          UPDATE matching_state SET ab_variant_id = ${variantId}, ab_share_percent = ${sharePercent},
            ab_started_at = now(), ab_started_by = ${by}
          WHERE id = 1
        `;
      });
    } finally {
      this.cached = null;
    }
  }

  async stopAbTest(): Promise<void> {
    try {
      const stopped = await this.sql`
        UPDATE matching_state SET ab_variant_id = NULL, ab_share_percent = NULL, ab_started_at = NULL, ab_started_by = NULL
        WHERE id = 1 AND ab_variant_id IS NOT NULL
      `;
      if (stopped.count === 0) throw new NoAbTestError();
    } finally {
      this.cached = null;
    }
  }

  private async readState(): Promise<MatchingState> {
    const [state] = await this.sql<StateRow[]>`SELECT * FROM matching_state WHERE id = 1`;
    if (state === undefined) throw new Error("matching_state missing: ensureMatchingSchema was not run");
    const active = await this.requireVersion(state.active_version_id);
    const abTest =
      state.ab_variant_id === null || state.ab_share_percent === null || state.ab_started_at === null || state.ab_started_by === null
        ? null
        : {
            variant: await this.requireVersion(state.ab_variant_id),
            sharePercent: state.ab_share_percent,
            startedAt: state.ab_started_at.toISOString(),
            startedBy: state.ab_started_by,
          };
    return { active, activatedAt: state.activated_at.toISOString(), activatedBy: state.activated_by, abTest };
  }

  private async requireVersion(id: number): Promise<ParamsVersion> {
    const version = await this.getVersion(id);
    if (version === null) throw new VersionNotFoundError(id);
    return version;
  }
}
