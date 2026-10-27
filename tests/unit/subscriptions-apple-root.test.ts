import { createHash } from "node:crypto";
import { describe, expect, test } from "bun:test";
import { APPLE_ROOT_CA_G3_DER } from "../../src/features/subscriptions/infra/apple-root-ca";
import { extensionOids } from "../../src/features/subscriptions/infra/der-extensions";
import { readProductPolicy } from "../../src/features/subscriptions/infra/config";

describe("embedded Apple Root CA - G3", () => {
  test("matches the SHA-256 fingerprint published by Apple", () => {
    const fingerprint = createHash("sha256")
      .update(APPLE_ROOT_CA_G3_DER)
      .digest("hex")
      .toUpperCase()
      .match(/../g)
      ?.join(":");
    expect(fingerprint).toBe("63:34:3A:BF:B8:9A:6A:03:EB:B5:7E:9B:3F:5F:A7:BE:7C:4F:5C:75:6F:30:17:B3:A8:C4:88:C3:65:3E:91:79");
  });

  test("the DER walker reads the standard extensions of a real certificate (RFC 5280 OIDs)", () => {
    const oids = extensionOids(APPLE_ROOT_CA_G3_DER);
    expect([...oids].sort()).toEqual(["2.5.29.14", "2.5.29.15", "2.5.29.19"]); // SKI, keyUsage, basicConstraints
  });

  test("returns no extension for garbage", () => {
    expect(extensionOids(new Uint8Array([1, 2, 3])).size).toBe(0);
    expect(extensionOids(new Uint8Array()).size).toBe(0);
  });
});

describe("readProductPolicy", () => {
  test("defaults to the MAZL bundle and the one-month product", () => {
    expect(readProductPolicy({})).toEqual({ bundleId: "com.mazl.app", productIds: ["com.mazl.app.plus.1m", "com.mazl.app.plus.3m", "com.mazl.app.plus.6m", "com.mazl.app.plus.12m", "com.mazl.app.couple.1m"], allowSandbox: true });
  });

  test("reads a comma separated list, trimming blanks", () => {
    const policy = readProductPolicy({ APPLE_BUNDLE_ID: "com.example.app", APPLE_PRODUCT_IDS: " a.1m, b.12m ,," });
    expect(policy).toEqual({ bundleId: "com.example.app", productIds: ["a.1m", "b.12m"], allowSandbox: true });
  });
});
