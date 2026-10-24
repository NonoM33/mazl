import type { AuditLog } from "../../audit/application/ports";
import { DEFAULT_PARAMS, NUMERIC_PARAMS, type MatchingParams, type NumericParamSpec } from "../domain/params";
import { validateParams } from "../domain/validate-params";
import { InvalidParamsError } from "./errors";
import { previewRanking, type PreviewInput, type PreviewOutput } from "./preview";
import type { AbTest, ParamsRepository, ParamsVersion, VersionListing } from "./ports";

export interface MatchingOverview {
  readonly active: ParamsVersion;
  readonly abTest: AbTest | null;
  readonly specs: readonly NumericParamSpec[];
  readonly defaults: MatchingParams;
}

export interface CreateVersionInput {
  readonly params: unknown;
  readonly note: string;
  readonly activate: boolean;
}

export interface TuningDeps {
  readonly params: ParamsRepository;
  readonly audit: AuditLog;
}

// The staff use cases of the tuning screen. Every change is audited; the actor
// is the e-mail of the staff member.
export class MatchingTuning {
  constructor(private readonly deps: TuningDeps) {}

  async overview(): Promise<MatchingOverview> {
    const state = await this.deps.params.getState();
    return { active: state.active, abTest: state.abTest, specs: NUMERIC_PARAMS, defaults: DEFAULT_PARAMS };
  }

  listVersions(page: { readonly limit: number; readonly offset: number }): Promise<{ readonly versions: readonly VersionListing[]; readonly total: number }> {
    return this.deps.params.listVersions(page);
  }

  async createVersion(actor: string, input: CreateVersionInput): Promise<ParamsVersion> {
    const validation = validateParams(input.params);
    if (!validation.ok) throw new InvalidParamsError(validation.errors);
    const parent = (await this.deps.params.getState()).active;
    const version = await this.deps.params.createVersion({ params: validation.params, note: input.note, author: actor, parentId: parent.id });
    await this.deps.audit.record({
      actor,
      action: "matching.version.create",
      targetType: "matching_params",
      targetId: String(version.id),
      details: { versionId: version.id, parentId: parent.id, activate: input.activate },
    });
    if (input.activate) await this.activate(actor, version.id, input.note);
    return version;
  }

  // Also the rollback: activating an older version is a plain activation.
  async activate(actor: string, versionId: number, note: string): Promise<void> {
    const outcome = await this.deps.params.activate(versionId, actor, note);
    await this.deps.audit.record({
      actor,
      action: "matching.activate",
      targetType: "matching_params",
      targetId: String(versionId),
      details: { versionId, previousVersionId: outcome.previousVersionId },
    });
    if (outcome.abTestEnded) {
      await this.deps.audit.record({
        actor,
        action: "matching.ab.stop",
        targetType: "matching_params",
        targetId: String(versionId),
        details: { variantId: versionId, reason: "variant_activated" },
      });
    }
  }

  async startAbTest(actor: string, variantId: number, sharePercent: number): Promise<void> {
    await this.deps.params.startAbTest(variantId, sharePercent, actor);
    await this.deps.audit.record({
      actor,
      action: "matching.ab.start",
      targetType: "matching_params",
      targetId: String(variantId),
      details: { variantId, sharePercent },
    });
  }

  async stopAbTest(actor: string): Promise<void> {
    const { abTest } = await this.deps.params.getState();
    await this.deps.params.stopAbTest();
    await this.deps.audit.record({
      actor,
      action: "matching.ab.stop",
      targetType: "matching_params",
      targetId: abTest === null ? null : String(abTest.variant.id),
      details: { variantId: abTest?.variant.id ?? null, reason: "stopped" },
    });
  }

  // Synthetic people only: this use case has no access to the member base.
  preview(input: PreviewInput): PreviewOutput {
    return previewRanking(input);
  }
}
