import { describe, expect, test } from "bun:test";
import { FrontConfigError, readFrontConfig } from "../../web/front/config";

// The website container refuses to start on wrong settings (docs/deploy/README.md).

const valid = {
  API_UPSTREAM: "http://mazl-api-internal:3000",
  WEB_ORIGIN: "https://mazl.app",
  PUBLIC_BASE_URL: "https://api.mazl.app",
};

describe("website container settings", () => {
  test("a complete environment gives the defaults for the rest", () => {
    const config = readFrontConfig(valid);
    expect(config.port).toBe(8080);
    expect(config.trustedProxies).toEqual(["private_ranges"]);
    expect(config.apiUpstream.origin).toBe("http://mazl-api-internal:3000");
    expect(config.webOrigin.origin).toBe("https://mazl.app");
    expect(config.apiOrigin.origin).toBe("https://api.mazl.app");
  });

  test("a trailing slash on an origin is accepted, a path is not", () => {
    expect(readFrontConfig({ ...valid, WEB_ORIGIN: "https://mazl.app/" }).webOrigin.origin).toBe("https://mazl.app");
    expect(() => readFrontConfig({ ...valid, API_UPSTREAM: "http://api:3000/base" })).toThrow(FrontConfigError);
  });

  test.each(["API_UPSTREAM", "WEB_ORIGIN", "PUBLIC_BASE_URL"])("%s is required", (name) => {
    expect(() => readFrontConfig({ ...valid, [name]: "" })).toThrow(`${name} is required`);
    expect(() => readFrontConfig({ ...valid, [name]: undefined })).toThrow(`${name} is required`);
  });

  test("the API host must differ from the site host, or the staff redirects would loop", () => {
    expect(() => readFrontConfig({ ...valid, PUBLIC_BASE_URL: "https://mazl.app" })).toThrow("another host");
  });

  test("an upstream that is not http(s), or carries credentials or a query, is refused", () => {
    for (const bad of ["ftp://api:3000", "api:3000", "http://user:pw@api:3000", "http://api:3000?x=1", "not a url"]) {
      expect(() => readFrontConfig({ ...valid, API_UPSTREAM: bad })).toThrow(FrontConfigError);
    }
  });

  test("the port must be a real port", () => {
    expect(readFrontConfig({ ...valid, PORT: "9000" }).port).toBe(9000);
    for (const bad of ["0", "70000", "abc", "80.5"]) expect(() => readFrontConfig({ ...valid, PORT: bad })).toThrow("PORT");
  });

  test("trusted proxies accept private_ranges and addresses, nothing that could reach the Caddyfile", () => {
    expect(readFrontConfig({ ...valid, TRUSTED_PROXIES: "private_ranges, 203.0.113.0/24 2001:db8::/32" }).trustedProxies).toEqual([
      "private_ranges", "203.0.113.0/24", "2001:db8::/32",
    ]);
    for (const bad of ["private_ranges }", "evil.example", "10.0.0.1;rm", "{env.X}"]) {
      expect(() => readFrontConfig({ ...valid, TRUSTED_PROXIES: bad })).toThrow("TRUSTED_PROXIES");
    }
  });
});
