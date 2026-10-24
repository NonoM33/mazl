import { describe, expect, test } from "bun:test";
import { browserLabel } from "../../src/features/web-session/domain/browser-label";

const CHROME_MAC =
  "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/130.0.0.0 Safari/537.36";
const FIREFOX_WIN = "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:132.0) Gecko/20100101 Firefox/132.0";
const SAFARI_MAC =
  "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.1 Safari/605.1.15";
const EDGE_WIN =
  "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/130.0.0.0 Safari/537.36 Edg/130.0.0.0";

describe("browserLabel", () => {
  test("names the common desktop browsers", () => {
    expect(browserLabel(CHROME_MAC)).toBe("Chrome sur macOS");
    expect(browserLabel(FIREFOX_WIN)).toBe("Firefox sur Windows");
    expect(browserLabel(SAFARI_MAC)).toBe("Safari sur macOS");
    expect(browserLabel(EDGE_WIN)).toBe("Edge sur Windows");
  });

  test("falls back for unknown or missing agents", () => {
    expect(browserLabel("curl/8.4.0")).toBe("Navigateur inconnu");
    expect(browserLabel("")).toBe("Navigateur inconnu");
    expect(browserLabel(undefined)).toBe("Navigateur inconnu");
  });

  test("a known browser on an unknown system keeps its name", () => {
    expect(browserLabel("Mozilla/5.0 Firefox/132.0")).toBe("Firefox");
  });
});
