import { describe, expect, test } from "bun:test";
import { exportMessage, exportOutcome } from "../../web/src/features/settings/export-outcome";

describe("export outcome", () => {
  test("429 is the daily limit", () => {
    expect(exportOutcome(429)).toBe("rate_limited");
    expect(exportMessage("rate_limited")).toContain("3 exports par jour au plus");
  });
  test("200 downloads, 404 is unavailable, others fail", () => {
    expect(exportOutcome(200)).toBe("done");
    expect(exportOutcome(404)).toBe("unavailable");
    expect(exportOutcome(500)).toBe("failed");
  });
});
