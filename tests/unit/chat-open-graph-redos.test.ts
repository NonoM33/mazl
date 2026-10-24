import { describe, expect, test } from "bun:test";
import { parseOpenGraph } from "../../src/features/chat/domain/open-graph";

// Security: a hostile page (the link preview fetches up to 512 KiB of whatever
// a user links to) must not stall the event loop, which the whole server shares.
// Each input below is exactly the size the fetcher lets through.

const PAGE_BYTES = 512 * 1024;
const BUDGET_MS = 100;

function fill(unit: string): string {
  return unit.repeat(Math.ceil(PAGE_BYTES / unit.length)).slice(0, PAGE_BYTES);
}

function elapsedMs(work: () => unknown): number {
  const started = performance.now();
  work();
  return performance.now() - started;
}

const HOSTILE_PAGES: ReadonlyArray<readonly [string, string]> = [
  ["<title repeated, never closed with >", fill("<title")],
  ["<title attributes repeated, never closed with >", fill("<title a=b ")],
  ["<TITLE repeated in upper case", fill("<TITLE")],
  ["a single <meta whose attribute name never ends", `<meta ${"a".repeat(PAGE_BYTES - 7)}>`],
  ["many <meta tags with a 2000-letter attribute name", fill(`<meta ${"a".repeat(2000)}>`)],
  ["many <meta tags with a 2000-letter name and no closing >", fill(`<meta ${"a".repeat(2000)}`)],
  ["many <meta tags full of names and spaces", fill(`<meta ${"a ".repeat(1000)}>`)],
  ["many empty <meta> tags", fill("<meta>")],
  ["<meta with an unterminated quote, repeated", fill('<meta content="')],
  ["<script repeated, never closed", fill("<script")],
  ["<!-- repeated, never closed", fill("<!--")],
  ["</title followed by spaces, repeated", `<title>${fill("</title    ")}`.slice(0, PAGE_BYTES)],
];

describe("parseOpenGraph on hostile 512 KiB pages", () => {
  for (const [name, page] of HOSTILE_PAGES) {
    test(`${name} is handled in under ${BUDGET_MS} ms`, () => {
      expect(page.length).toBe(PAGE_BYTES);
      expect(elapsedMs(() => parseOpenGraph(page))).toBeLessThan(BUDGET_MS);
    });
  }

  test("a hostile tail does not hide the title that comes first", () => {
    const page = `<html><head><title>Vrai titre</title></head>${fill("<title")}`;
    expect(parseOpenGraph(page).title).toBe("Vrai titre");
  });

  test("attributes are still read around a very long attribute name", () => {
    const page = `<meta ${"a".repeat(1500)} property="og:title" content="Après">`;
    expect(parseOpenGraph(page).title).toBe("Après");
  });
});
