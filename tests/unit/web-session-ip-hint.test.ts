import { describe, expect, test } from "bun:test";
import { maskedAddress } from "../../src/features/web-session/domain/ip-hint";

// Security review B6: the phone shows where the sign-in request comes from,
// without keeping or showing a full address.
describe("masked address of the browser", () => {
  test("IPv4 keeps its first three parts", () => {
    expect(maskedAddress("198.51.100.42")).toBe("198.51.100.x");
    expect(maskedAddress("::ffff:203.0.113.7")).toBe("203.0.113.x");
  });

  test("IPv6 keeps its first three groups", () => {
    expect(maskedAddress("2001:db8:85a3:8d3:1319:8a2e:370:7348")).toBe("2001:db8:85a3::");
    expect(maskedAddress("2001:db8::1")).toBe("2001:db8::");
  });

  test("anything else gives no hint", () => {
    expect(maskedAddress("unknown")).toBeNull();
    expect(maskedAddress("")).toBeNull();
    expect(maskedAddress("<script>")).toBeNull();
  });
});
