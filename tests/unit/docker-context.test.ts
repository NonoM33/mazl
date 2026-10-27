import { describe, expect, test } from "bun:test";
import { readdirSync, readFileSync, statSync } from "node:fs";
import { dirname, join, relative, resolve } from "node:path";

// 2026-10-27: the storefront imported docs/storefront/themes.json, which .dockerignore left out of
// the image; the staging container crashed at start ("Cannot find module"). Every file the server
// imports from outside src/ must reach the Docker build context.
const ROOT = resolve(import.meta.dir, "../..");

function sourceFiles(dir: string): string[] {
  return readdirSync(dir).flatMap((name) => {
    const path = join(dir, name);
    return statSync(path).isDirectory() ? sourceFiles(path) : /\.(ts|tsx)$/.test(name) ? [path] : [];
  });
}

// .dockerignore with the subset this repository uses: "dir/", "name", "*.ext" and "!path" negations,
// the last matching line deciding.
function ignored(path: string, lines: readonly string[]): boolean {
  let result = false;
  for (const line of lines) {
    const negate = line.startsWith("!");
    const pattern = negate ? line.slice(1) : line;
    const matches = pattern.startsWith("*.")
      ? path.endsWith(pattern.slice(1))
      : pattern.endsWith("/")
        ? path.startsWith(pattern) || path.split("/").includes(pattern.slice(0, -1))
        : path === pattern || path.startsWith(`${pattern}/`);
    if (matches) result = !negate;
  }
  return result;
}

describe("Docker build context", () => {
  test("every file src/ imports from outside src/ is sent to the image", () => {
    const lines = readFileSync(join(ROOT, ".dockerignore"), "utf8")
      .split("\n")
      .map((line) => line.trim())
      .filter((line) => line !== "" && !line.startsWith("#"));
    const outside: string[] = [];
    for (const file of sourceFiles(join(ROOT, "src"))) {
      for (const match of readFileSync(file, "utf8").matchAll(/from\s+["'](\.{1,2}\/[^"']+)["']/g)) {
        const target = relative(ROOT, resolve(dirname(file), match[1] ?? ""));
        if (!target.startsWith("src/") && !target.startsWith("..")) outside.push(target);
      }
    }
    expect(outside.length).toBeGreaterThan(0);
    expect(outside.filter((target) => ignored(target, lines))).toEqual([]);
  });
});
