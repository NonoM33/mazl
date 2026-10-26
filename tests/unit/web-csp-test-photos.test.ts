import { expect, test } from "bun:test";
import { webSecurityHeaders } from "../../src/features/web-app/security-headers";

// Seen on 2026-10-26: on mazl.app the test profiles showed grey squares, the
// Content-Security-Policy refused their stock photos.
test("the web client may show the stock photos of the test profiles, and only images from there", () => {
  const csp = webSecurityHeaders(true, null)["Content-Security-Policy"] ?? "";
  const imgSrc = csp.split(";").map((part) => part.trim()).find((part) => part.startsWith("img-src")) ?? "";
  expect(imgSrc).toContain("https://images.unsplash.com");
  const connectSrc = csp.split(";").map((part) => part.trim()).find((part) => part.startsWith("connect-src")) ?? "";
  expect(connectSrc).not.toContain("unsplash");
});
