import { describe, expect, test } from "bun:test";
import { parseFetchTarget, type TargetRefusal } from "../../src/features/chat/domain/fetch-target";

// CONTRAT.md §0.5: http/https only, ports 80 and 443 only, no credentials.

function ok(raw: string) {
  const parsed = parseFetchTarget(raw);
  if (!parsed.ok) throw new Error(`expected ${raw} to be accepted, got ${parsed.reason}`);
  return parsed.target;
}

describe("accepted", () => {
  test("https on the default port", () => {
    expect(ok("https://example.com/a/b?x=1#frag")).toEqual({
      secure: true, hostname: "example.com", port: 443, hostHeader: "example.com", path: "/a/b?x=1",
    });
  });
  test("http on the default port", () => {
    const t = ok("http://Example.COM");
    expect([t.secure, t.hostname, t.port, t.path]).toEqual([false, "example.com", 80, "/"]);
  });
  test("explicit 80 and 443, on either scheme", () => {
    expect(ok("http://example.com:80/").port).toBe(80);
    expect(ok("https://example.com:443/").port).toBe(443);
    const odd = ok("http://example.com:443/");
    expect([odd.secure, odd.port, odd.hostHeader]).toEqual([false, 443, "example.com:443"]);
    expect(ok("https://example.com:80/").port).toBe(80);
  });
  test("a public IP literal is parsed as such", () => {
    expect(ok("http://8.8.8.8/x").hostname).toBe("8.8.8.8");
    expect(ok("https://[2606:4700:4700::1111]/").hostname).toBe("2606:4700:4700::1111");
    expect(ok("https://[2606:4700:4700::1111]/").hostHeader).toBe("[2606:4700:4700::1111]");
  });
});

describe("refused", () => {
  const cases: Array<[string, TargetRefusal]> = [
    ["ftp://example.com/", "bad_scheme"],
    ["file:///etc/passwd", "bad_scheme"],
    ["gopher://example.com/", "bad_scheme"],
    ["javascript:alert(1)", "bad_scheme"],
    ["data:text/html,hi", "bad_scheme"],
    ["http://example.com:8080/", "bad_port"],
    ["https://example.com:22/", "bad_port"],
    ["http://example.com:6379/", "bad_port"],
    ["http://user:pw@example.com/", "credentials"],
    ["http://user@example.com/", "credentials"],
    ["not a url", "invalid"],
    ["", "invalid"],
    ["http://", "invalid"],
    ["http://exa mple.com/", "invalid"],
  ];
  for (const [raw, reason] of cases) {
    test(`${JSON.stringify(raw)} -> ${reason}`, () => {
      expect(parseFetchTarget(raw)).toEqual({ ok: false, reason });
    });
  }

  test("a URL longer than 2048 characters is refused", () => {
    expect(parseFetchTarget(`https://example.com/${"a".repeat(2100)}`)).toEqual({ ok: false, reason: "invalid" });
  });
});

describe("alternative spellings of loopback are normalised so the IP guard sees them", () => {
  const spellings = [
    ["http://2130706433/", "127.0.0.1"],
    ["http://0x7f000001/", "127.0.0.1"],
    ["http://0x7f.0.0.1/", "127.0.0.1"],
    ["http://0177.0.0.1/", "127.0.0.1"],
    ["http://127.1/", "127.0.0.1"],
    ["http://017700000001/", "127.0.0.1"],
    ["http://[::1]/", "::1"],
    ["http://[0:0:0:0:0:0:0:1]/", "::1"],
    ["http://[::ffff:127.0.0.1]/", "::ffff:7f00:1"],
    ["http://169.254.169.254./", "169.254.169.254"],
  ] as const;
  for (const [raw, hostname] of spellings) {
    test(`${raw} -> ${hostname}`, () => {
      const parsed = parseFetchTarget(raw);
      expect(parsed.ok && parsed.target.hostname).toBe(hostname);
    });
  }
});
