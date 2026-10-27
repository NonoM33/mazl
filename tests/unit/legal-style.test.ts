import { describe, expect, test } from "bun:test";
import { readFileSync } from "node:fs";
import { join } from "node:path";

// The legal pages share the showcase's tokens and must stay readable (WCAG AA)
// in both colour schemes. The contrast formula is the WCAG 2.x definition,
// written here from the specification, not taken from the page.

const root = join(import.meta.dir, "..", "..");
const legal = readFileSync(join(root, "public/legal.css"), "utf8");
const tokens = readFileSync(join(root, "landing/src/styles/tokens.css"), "utf8");

function declarations(css: string, selectorStart: RegExp): Record<string, string> {
  const block = selectorStart.exec(css)?.[0] ?? "";
  return Object.fromEntries([...block.matchAll(/--([\w-]+):\s*([^;]+);/g)].map((match) => [match[1] ?? "", (match[2] ?? "").trim()]));
}

const showcase = declarations(tokens, /:root\s*\{[^}]*\}/);
const light = declarations(legal, /:root\s*\{[^}]*\}/);
const dark = { ...light, ...declarations(legal, /@media \(prefers-color-scheme: dark\)\s*\{\s*:root\s*\{[^}]*\}/) };

function luminance(hex: string): number {
  const channels = [1, 3, 5].map((start) => parseInt(hex.slice(start, start + 2), 16) / 255);
  const [r = 0, g = 0, b = 0] = channels.map((value) => (value <= 0.03928 ? value / 12.92 : ((value + 0.055) / 1.055) ** 2.4));
  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
}

function contrast(foreground: string, background: string): number {
  const [high, low] = [luminance(foreground), luminance(background)].sort((a, b) => b - a);
  return ((high ?? 0) + 0.05) / ((low ?? 0) + 0.05);
}

describe("legal pages: the showcase's tokens", () => {
  test("the light palette is the showcase's, value for value", () => {
    for (const name of ["ink", "paper", "mist", "hairline", "muted", "tekhelet", "tekhelet-light", "tekhelet-dark", "sans", "mono", "nav-h"]) {
      expect([name, light[name]]).toEqual([name, showcase[name]]);
    }
  });

  test("the fonts are the showcase's Geist files, served from /l/fonts and nothing external", () => {
    for (const file of ["Geist-400.ttf", "Geist-500.ttf", "Geist-600.ttf", "Geist-700.ttf", "GeistMono-400.ttf", "GeistMono-500.ttf"]) expect(legal).toContain(`/l/fonts/${file}`);
    expect(legal).not.toMatch(/https?:\/\//);
    expect(legal).not.toContain("@import");
  });

  test("the sheet answers the system colour scheme and reduced motion, and prints", () => {
    expect(legal).toContain("color-scheme: light dark");
    expect(legal).toContain("@media (prefers-color-scheme: dark)");
    expect(legal).toContain("@media (prefers-reduced-motion: reduce)");
    expect(legal).toContain("@media print");
  });
});

describe("legal pages: contrast (WCAG AA)", () => {
  const pairs: ReadonlyArray<readonly [string, string, string]> = [
    ["ink", "paper", "text"],
    ["muted", "paper", "secondary text"],
    ["muted", "mist", "secondary text on a card"],
    ["tekhelet", "paper", "links and article numbers"],
    ["tekhelet", "mist", "article numbers on a card"],
    ["todo-ink", "todo-bg", "the À COMPLÉTER mark"],
  ];

  for (const [scheme, palette] of [["light", light], ["dark", dark]] as const) {
    for (const [foreground, background, what] of pairs) {
      test(`${scheme}: ${what} is at least 4.5:1`, () => {
        const ratio = contrast(palette[foreground] ?? "", palette[background] ?? "");
        expect([what, ratio >= 4.5]).toEqual([what, true]);
      });
    }
    test(`${scheme}: the focus ring is at least 3:1 against the page`, () => {
      expect(contrast(palette["tekhelet-light"] ?? "", palette["paper"] ?? "")).toBeGreaterThanOrEqual(3);
    });
  }
});
