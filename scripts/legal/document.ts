import { readFile } from "node:fs/promises";
import { join } from "node:path";
import { MarkdownError, renderMarkdown, type RenderedMarkdown } from "./markdown";

// The legal documents, in the order of the navigation and of the footer.
export const LEGAL_SLUGS = ["cgu", "cgv", "confidentialite", "mentions-legales", "cookies"] as const;
export type LegalSlug = (typeof LEGAL_SLUGS)[number];

export interface LegalDocument {
  readonly slug: LegalSlug;
  readonly title: string;
  readonly nav: string;
  readonly description: string;
  readonly lead: string;
  // ISO date (YYYY-MM-DD) of the version shown to readers.
  readonly version: string;
  // "projet": waiting for legal validation; "en vigueur": validated.
  readonly status: "projet" | "en vigueur";
  readonly body: RenderedMarkdown;
}

const FRONT_KEYS = ["slug", "title", "nav", "description", "lead", "version", "status"] as const;

export function parseDocument(source: string): LegalDocument {
  const match = /^---\n([\s\S]*?)\n---\n([\s\S]*)$/.exec(source);
  if (!match) throw new MarkdownError("missing front matter");
  const fields = new Map<string, string>();
  for (const line of (match[1] ?? "").split("\n")) {
    const separator = line.indexOf(":");
    if (separator < 1) throw new MarkdownError(`bad front matter line: ${line}`);
    fields.set(line.slice(0, separator).trim(), line.slice(separator + 1).trim());
  }
  const field = (key: (typeof FRONT_KEYS)[number]): string => {
    const value = fields.get(key);
    if (value === undefined || value === "") throw new MarkdownError(`front matter lacks "${key}"`);
    return value;
  };
  const slug = field("slug");
  if (!LEGAL_SLUGS.some((known) => known === slug)) throw new MarkdownError(`unknown document slug: ${slug}`);
  const version = field("version");
  if (!/^\d{4}-\d{2}-\d{2}$/.test(version)) throw new MarkdownError(`version must be YYYY-MM-DD: ${version}`);
  const status = field("status");
  if (status !== "projet" && status !== "en vigueur") throw new MarkdownError(`unknown status: ${status}`);
  return {
    slug: slug as LegalSlug,
    title: field("title"),
    nav: field("nav"),
    description: field("description"),
    lead: field("lead"),
    version,
    status,
    body: renderMarkdown(match[2] ?? ""),
  };
}

export async function loadDocuments(directory: string): Promise<readonly LegalDocument[]> {
  return Promise.all(
    LEGAL_SLUGS.map(async (slug) => {
      const document = parseDocument(await readFile(join(directory, `${slug}.md`), "utf8"));
      if (document.slug !== slug) throw new MarkdownError(`${slug}.md declares slug ${document.slug}`);
      return document;
    }),
  );
}
