// Renders docs/legal/*.md into the static pages public/<slug>.html, served by
// the API process and by the website container (web/Dockerfile). The Markdown
// files are the source of truth; a test fails when a page is out of date.
//   bun scripts/legal/build.ts            writes the pages
//   bun scripts/legal/build.ts --check    exits 1 when a page is out of date
import { readFile, writeFile } from "node:fs/promises";
import { join } from "node:path";
import { LEGAL_SLUGS, loadDocuments, type LegalSlug } from "./document";
import { renderPage } from "./page";

const root = join(import.meta.dir, "..", "..");

export async function renderLegalPages(sourceDirectory = join(root, "docs", "legal")): Promise<Readonly<Record<LegalSlug, string>>> {
  const documents = await loadDocuments(sourceDirectory);
  const pages = Object.fromEntries(documents.map((document) => [document.slug, renderPage(document, documents)]));
  return pages as Record<LegalSlug, string>;
}

if (import.meta.main) {
  const check = process.argv.includes("--check");
  const pages = await renderLegalPages();
  let stale = 0;
  for (const slug of LEGAL_SLUGS) {
    const path = join(root, "public", `${slug}.html`);
    const html = pages[slug];
    if (check) {
      const current = await readFile(path, "utf8").catch(() => "");
      if (current !== html) {
        console.error(`public/${slug}.html is out of date: run "bun run legal:build"`);
        stale += 1;
      }
    } else {
      await writeFile(path, html);
      console.log(`public/${slug}.html  ${(html.length / 1024).toFixed(1)} kB`);
    }
  }
  if (stale > 0) process.exit(1);
}
