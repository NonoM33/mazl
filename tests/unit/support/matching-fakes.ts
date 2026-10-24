import { createMiddleware } from "hono/factory";
import type { AuditEntry, AuditEntryInput, AuditLog } from "../../../src/features/audit/application/ports";
import { NoAbTestError, VariantIsActiveError, VersionNotFoundError } from "../../../src/features/matching/application/errors";
import type {
  ActivationOutcome,
  CandidateSet,
  CandidateSource,
  FeedHydrator,
  FeedProfile,
  MatchingState,
  NewVersion,
  ParamsRepository,
  ParamsVersion,
  VersionListing,
} from "../../../src/features/matching/application/ports";
import { DEFAULT_PARAMS } from "../../../src/features/matching/domain/params";
import type { Permission } from "../../../src/features/staff/domain/roles";
import type { RequirePermission, StaffVariables } from "../../../src/features/staff/application/ports";

export class InMemoryParams implements ParamsRepository {
  readonly versions: ParamsVersion[] = [
    { id: 1, params: DEFAULT_PARAMS, note: "Paramètres initiaux", author: "system", createdAt: "2026-01-01T00:00:00.000Z", parentId: null },
  ];
  readonly activations: Array<{ versionId: number; by: string; note: string }> = [{ versionId: 1, by: "system", note: "Paramètres initiaux" }];
  activeId = 1;
  ab: { variantId: number; share: number; by: string } | null = null;
  stateReads = 0;

  async createVersion(input: NewVersion): Promise<ParamsVersion> {
    const version = { id: this.versions.length + 1, ...input, createdAt: "2026-02-01T00:00:00.000Z" };
    this.versions.push(version);
    return version;
  }

  async listVersions(page: { limit: number; offset: number }) {
    const sorted = [...this.versions].sort((a, b) => b.id - a.id);
    const rows: VersionListing[] = sorted.slice(page.offset, page.offset + page.limit).map((v) => ({ ...v, activatedAt: null }));
    return { versions: rows, total: this.versions.length };
  }

  async getVersion(id: number): Promise<ParamsVersion | null> {
    return this.versions.find((v) => v.id === id) ?? null;
  }

  async getState(): Promise<MatchingState> {
    this.stateReads++;
    const active = this.mustFind(this.activeId);
    const abTest = this.ab === null ? null : { variant: this.mustFind(this.ab.variantId), sharePercent: this.ab.share, startedAt: "2026-02-02T00:00:00.000Z", startedBy: this.ab.by };
    return { active, activatedAt: "2026-02-01T00:00:00.000Z", activatedBy: "system", abTest };
  }

  async activate(versionId: number, by: string, note: string): Promise<ActivationOutcome> {
    this.mustFind(versionId);
    const previousVersionId = this.activeId;
    this.activeId = versionId;
    this.activations.push({ versionId, by, note });
    const abTestEnded = this.ab?.variantId === versionId;
    if (abTestEnded) this.ab = null;
    return { previousVersionId, abTestEnded };
  }

  async startAbTest(variantId: number, sharePercent: number, by: string): Promise<void> {
    this.mustFind(variantId);
    if (variantId === this.activeId) throw new VariantIsActiveError(variantId);
    this.ab = { variantId, share: sharePercent, by };
  }

  async stopAbTest(): Promise<void> {
    if (this.ab === null) throw new NoAbTestError();
    this.ab = null;
  }

  private mustFind(id: number): ParamsVersion {
    const found = this.versions.find((v) => v.id === id);
    if (found === undefined) throw new VersionNotFoundError(id);
    return found;
  }
}

export class FakeAudit implements AuditLog {
  readonly entries: AuditEntryInput[] = [];
  async record(entry: AuditEntryInput): Promise<AuditEntry> {
    this.entries.push(entry);
    return { ...entry, id: this.entries.length, createdAt: "2026-02-01T00:00:00.000Z", previousHash: "", hash: "" };
  }
  async list(): Promise<{ entries: readonly AuditEntry[]; total: number }> {
    return { entries: [], total: 0 };
  }
  async verify(): Promise<never> {
    throw new Error("not used");
  }
}

export class FakeCandidates implements CandidateSource {
  loads = 0;
  constructor(private readonly set: CandidateSet | null) {}
  async load(): Promise<CandidateSet | null> {
    this.loads++;
    return this.set;
  }
}

export class FakeHydrator implements FeedHydrator {
  readonly asked: Array<readonly number[]> = [];
  async profilesForFeed(userIds: readonly number[]): Promise<readonly FeedProfile[]> {
    this.asked.push(userIds);
    return userIds.map((id) => ({ user_id: id, display_name: `M${id}` }));
  }
}

// A staff guard double: the role is read from the x-role header.
// No header: 401. A role not in `allowed`: 403.
export function fakeRequirePermission(allowed: Readonly<Record<string, readonly Permission[]>>): RequirePermission {
  return (permission) =>
    createMiddleware<{ Variables: StaffVariables }>(async (c, next) => {
      const role = c.req.header("x-role");
      if (role === undefined) return c.json({ success: false, error: "unauthorized" }, 401);
      if (!(allowed[role] ?? []).includes(permission)) return c.json({ success: false, error: "forbidden" }, 403);
      c.set("staff", { email: `${role}@example.com`, role: "analyst", mfa: true });
      await next();
      return undefined;
    });
}
