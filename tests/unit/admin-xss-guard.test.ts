import { describe, expect, test } from "bun:test";
import { existsSync, readdirSync, readFileSync } from "node:fs";
import { join } from "node:path";
import { scanScript, stringChunks, type Violation } from "./admin-xss-scan";

// Static guard of the admin console against stored XSS. A test cannot load the page
// without a browser, so the rule is enforced on the source: see admin-xss-scan.ts
// for R1..R5. Adding a new `${value}` in markup without html`` breaks this test.

const PUBLIC_DIR = join(import.meta.dir, "../../public");

function inlineScripts(htmlSource: string): Array<{ code: string; attrs: string }> {
  const scripts: Array<{ code: string; attrs: string }> = [];
  for (const m of htmlSource.matchAll(/<script\b([^>]*)>([\s\S]*?)<\/script>/gi)) {
    const attrs = m[1] ?? "";
    if (!/\bsrc\s*=/.test(attrs)) scripts.push({ code: m[2] ?? "", attrs });
  }
  return scripts;
}

function format(file: string, violations: Violation[]): string[] {
  return violations.map((v) => `${file}:${v.line} ${v.rule} ${v.message}: ${v.snippet}`);
}

const publicFiles = readdirSync(PUBLIC_DIR).filter((f) => f.endsWith(".js") || f.endsWith(".html"));

describe("the scanner itself catches the attacks (it is not decorative)", () => {
  test.each([
    ["R1", "el.innerHTML = `<td>${v.email}</td>`;"],
    ["R1", "const row = `<div>${x}</div>`; list.push(row);"],
    ["R2", "el.innerHTML = '<p>Erreur: ' + e.message + '</p>';"],
    ["R3", "el.innerHTML = someVariable;"],
    ["R3", "el.insertAdjacentHTML('beforeend', fragment);"],
    ["R3", "document.write(location.hash);"],
    ["R4", "el.innerHTML = html`<button onclick=\"del(${id})\">x</button>`;"],
    ["R5", "el.innerHTML = html`<img src=\"${u.picture}\">`;"],
    ["R5", "el.innerHTML = html`<a href=\"${u.site}\">x</a>`;"],
    ["R5", "el.innerHTML = html`<a href=\"javascript:${u.site}\">x</a>`;"],
  ])("%s: %s", (rule, code) => {
    const found = scanScript(code).map((v) => v.rule);
    expect(found).toContain(rule as Violation["rule"]);
  });

  test("accepts the safe forms", () => {
    const safe = [
      "el.innerHTML = '<p>fixe</p>';",
      "el.innerHTML = '';",
      "el.innerHTML = html`<td>${v.email}</td>`;",
      "el.innerHTML = html`<img src=\"${safeUrl(u.picture)}\" alt=\"${u.name}\">`;",
      "el.innerHTML = html`<a href=\"/api/admin/documents/${d.id}/file\">x</a>`;",
      "el.innerHTML = html`<ul>${items.map((i) => html`<li data-id=\"${i.id}\">${i.name}</li>`)}</ul>`;",
      "toast.textContent = `Campagne envoyée à ${n} destinataires`;",
      "const url = `/api/admin/users/${id}/ban`;",
    ];
    for (const code of safe) expect(scanScript(code), code).toEqual([]);
  });
});

describe("public pages: no markup is built from unescaped data", () => {
  test("the public directory is the one we think it is", () => {
    expect(publicFiles).toContain("admin.html");
    expect(publicFiles).toContain("verify.js");
    expect(existsSync(join(PUBLIC_DIR, "admin-escape.js"))).toBe(true);
  });

  test.each(publicFiles)("%s", (file) => {
    const source = readFileSync(join(PUBLIC_DIR, file), "utf8");
    const scripts = file.endsWith(".html") ? inlineScripts(source).map((s) => s.code) : [source];
    const violations = scripts.flatMap((code) => scanScript(code, file));
    expect(format(file, violations)).toEqual([]);
  });

  test("a stale admin.js that nothing loads and that stored the password is gone", () => {
    expect(publicFiles).not.toContain("admin.js");
  });
});

describe("admin pages: the html`` tag really comes from admin-escape.js", () => {
  test.each(["admin.html", "verify.html"])("%s imports what it uses", (file) => {
    const source = readFileSync(join(PUBLIC_DIR, file), "utf8");
    const scriptSources = [...source.matchAll(/<script\b([^>]*)>([\s\S]*?)<\/script>/gi)];
    const usesHtmlTag = inlineScripts(source).some((s) => /\bhtml`/.test(s.code));
    const externalModules = scriptSources.filter((m) => /\bsrc\s*=/.test(m[1] ?? "")).map((m) => m[1] ?? "");
    if (file === "admin.html") {
      expect(usesHtmlTag).toBe(true);
      const inline = inlineScripts(source).find((s) => /\bhtml`/.test(s.code))!;
      expect(inline.attrs).toMatch(/type\s*=\s*["']module["']/);
      expect(inline.code).toMatch(/from\s+['"]\/admin-escape\.js['"]/);
    } else {
      expect(usesHtmlTag).toBe(false);
      expect(externalModules.length).toBeGreaterThan(0);
    }
  });

  test("verify.js, loaded as a module, imports the tag it uses", () => {
    const verifyJs = readFileSync(join(PUBLIC_DIR, "verify.js"), "utf8");
    if (/\bhtml`/.test(verifyJs)) expect(verifyJs).toMatch(/from\s+['"]\/admin-escape\.js['"]/);
    const verifyHtml = readFileSync(join(PUBLIC_DIR, "verify.html"), "utf8");
    expect(verifyHtml).toMatch(/<script[^>]*type\s*=\s*["']module["'][^>]*src\s*=\s*["']\/verify\.js["']|<script[^>]*src\s*=\s*["']\/verify\.js["'][^>]*type\s*=\s*["']module["']/);
  });
});

