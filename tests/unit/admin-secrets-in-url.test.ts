import { describe, expect, test } from "bun:test";
import { readFileSync } from "node:fs";
import { join } from "node:path";
import { stringChunks } from "./admin-xss-scan";

// The admin JWT used to be appended to the URL of identity-document downloads
// (?token=...), which copies it into server logs, proxies and browser history.
// The console must send it in the Authorization header and show the file from a
// short-lived blob: URL instead.

const PUBLIC_DIR = join(import.meta.dir, "../../public");

function inlineScripts(htmlSource: string): string[] {
  return [...htmlSource.matchAll(/<script\b([^>]*)>([\s\S]*?)<\/script>/gi)]
    .filter((m) => !/\bsrc\s*=/.test(m[1] ?? ""))
    .map((m) => m[2] ?? "");
}

describe("admin console: secrets never travel in a URL", () => {
  test.each(["admin.html", "admin-login.html"])("%s builds no URL carrying a token or a password", (file) => {
    const source = readFileSync(join(PUBLIC_DIR, file), "utf8");
    const chunks = inlineScripts(source).flatMap(stringChunks);
    const leaking = chunks.filter((chunk) => /[?&](?:token|password|access_token|jwt)=/i.test(chunk));
    expect(leaking).toEqual([]);
  });

  test("identity documents are fetched with an Authorization header and shown from a blob URL", () => {
    const source = readFileSync(join(PUBLIC_DIR, "admin.html"), "utf8");
    expect(source).toMatch(/\/api\/admin\/documents\/['"`]?\s*\+?\s*encodeURIComponent\(docId\)\s*\+\s*['"`]\/file/);
    expect(source).toMatch(/Authorization['"]?\s*:\s*['"]Bearer ['"]\s*\+\s*adminToken/);
    expect(source).toMatch(/URL\.createObjectURL/);
    expect(source).toMatch(/URL\.revokeObjectURL/);
  });
});
