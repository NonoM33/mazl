import { describe, expect, test } from "bun:test";
import { InvalidParamsError, NoAbTestError, VariantIsActiveError, VersionNotFoundError } from "../../src/features/matching/application/errors";
import { previewRanking } from "../../src/features/matching/application/preview";
import { MatchingTuning } from "../../src/features/matching/application/tuning";
import { DEFAULT_PARAMS } from "../../src/features/matching/domain/params";
import { setParam } from "../../src/features/matching/domain/validate-params";
import { FakeAudit, InMemoryParams } from "./support/matching-fakes";

const ACTOR = "admin@example.com";

function setup() {
  const params = new InMemoryParams();
  const audit = new FakeAudit();
  return { params, audit, tuning: new MatchingTuning({ params, audit }) };
}

describe("versions", () => {
  test("a valid version is stored with the active one as parent and audited", async () => {
    const { tuning, audit } = setup();
    const version = await tuning.createVersion(ACTOR, { params: setParam(DEFAULT_PARAMS, "boost.factor", 2), note: "boost plus fort", activate: false });
    expect(version.parentId).toBe(1);
    expect(version.author).toBe(ACTOR);
    expect(audit.entries.map((e) => e.action)).toEqual(["matching.version.create"]);
    expect(audit.entries[0]?.targetId).toBe(String(version.id));
  });

  test("out-of-bounds parameters are refused and nothing is stored", async () => {
    const { tuning, params, audit } = setup();
    const invalid = setParam(DEFAULT_PARAMS, "boost.factor", 99);
    await expect(tuning.createVersion(ACTOR, { params: invalid, note: "trop", activate: true })).rejects.toBeInstanceOf(InvalidParamsError);
    expect(params.versions).toHaveLength(1);
    expect(audit.entries).toHaveLength(0);
  });

  test("create + activate publishes the version and audits both steps", async () => {
    const { tuning, params, audit } = setup();
    const version = await tuning.createVersion(ACTOR, { params: DEFAULT_PARAMS, note: "publication", activate: true });
    expect(params.activeId).toBe(version.id);
    expect(audit.entries.map((e) => e.action)).toEqual(["matching.version.create", "matching.activate"]);
    expect(audit.entries[1]?.details).toEqual({ versionId: version.id, previousVersionId: 1 });
  });

  test("rollback is an activation of an older version and keeps the history", async () => {
    const { tuning, params, audit } = setup();
    const v2 = await tuning.createVersion(ACTOR, { params: DEFAULT_PARAMS, note: "version deux", activate: true });
    await tuning.activate(ACTOR, 1, "retour arrière");
    expect(params.activeId).toBe(1);
    expect(params.activations.map((a) => a.versionId)).toEqual([1, v2.id, 1]);
    expect(audit.entries.at(-1)).toMatchObject({ action: "matching.activate", details: { versionId: 1, previousVersionId: v2.id } });
  });

  test("activating an unknown version fails without audit", async () => {
    const { tuning, audit } = setup();
    await expect(tuning.activate(ACTOR, 42, "x")).rejects.toBeInstanceOf(VersionNotFoundError);
    expect(audit.entries).toHaveLength(0);
  });
});

describe("A/B test", () => {
  test("start and stop are audited", async () => {
    const { tuning, audit } = setup();
    const v2 = await tuning.createVersion(ACTOR, { params: DEFAULT_PARAMS, note: "variante", activate: false });
    await tuning.startAbTest(ACTOR, v2.id, 20);
    await tuning.stopAbTest(ACTOR);
    expect(audit.entries.slice(1).map((e) => e.action)).toEqual(["matching.ab.start", "matching.ab.stop"]);
    expect(audit.entries[1]?.details).toEqual({ variantId: v2.id, sharePercent: 20 });
  });

  test("the active version cannot be its own variant", async () => {
    const { tuning } = setup();
    await expect(tuning.startAbTest(ACTOR, 1, 10)).rejects.toBeInstanceOf(VariantIsActiveError);
  });

  test("stopping when nothing runs fails without audit", async () => {
    const { tuning, audit } = setup();
    await expect(tuning.stopAbTest(ACTOR)).rejects.toBeInstanceOf(NoAbTestError);
    expect(audit.entries).toHaveLength(0);
  });

  test("activating the running variant ends the test and says so in the audit", async () => {
    const { tuning, params, audit } = setup();
    const v2 = await tuning.createVersion(ACTOR, { params: DEFAULT_PARAMS, note: "variante", activate: false });
    await tuning.startAbTest(ACTOR, v2.id, 30);
    await tuning.activate(ACTOR, v2.id, "la variante gagne");
    expect(params.ab).toBeNull();
    expect(audit.entries.at(-1)?.action).toBe("matching.ab.stop");
  });
});

describe("preview", () => {
  const input = { params: DEFAULT_PARAMS, seed: 11, viewer: 3 };

  test("deterministic: same input, same output", () => {
    expect(previewRanking(input)).toEqual(previewRanking(input));
  });

  test("a different seed gives another population", () => {
    expect(previewRanking({ ...input, seed: 12 }).population).not.toEqual(previewRanking(input).population);
  });

  test("compareWith produces a second ranking, absent otherwise", () => {
    expect(previewRanking(input).compare).toBeNull();
    const withCompare = previewRanking({ ...input, compareWith: setParam(DEFAULT_PARAMS, "boost.factor", 1.5) });
    expect(withCompare.compare).not.toBeNull();
  });

  test("labels name every synthetic person", () => {
    const out = previewRanking({ ...input, size: 40 });
    expect(Object.keys(out.labels)).toHaveLength(40);
  });

  test("a viewer index outside the population is refused", () => {
    expect(() => previewRanking({ ...input, viewer: 999 })).toThrow();
  });

  test("invalid compareWith names the field", () => {
    try {
      previewRanking({ ...input, compareWith: setParam(DEFAULT_PARAMS, "boost.factor", 99) });
      throw new Error("should have failed");
    } catch (error: unknown) {
      expect(error).toBeInstanceOf(InvalidParamsError);
      expect((error as InvalidParamsError).message).toContain("compareWith");
    }
  });

  test("the use case holds no member repository: only the params repository and the audit", () => {
    const { tuning, params } = setup();
    const reads = params.stateReads;
    tuning.preview(input);
    expect(params.stateReads).toBe(reads);
  });
});
