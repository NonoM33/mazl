// Open Graph extraction from the head of an HTML page. A tolerant scanner, not
// a parser: it only looks at <meta> and <title> tags, after removing comments,
// scripts and styles. Everything it returns is plain text with bounded length.

export interface OpenGraph {
  title?: string;
  description?: string;
  imageUrl?: string;
  siteName?: string;
}

const MAX_TITLE = 200;
const MAX_DESCRIPTION = 300;
const MAX_SITE_NAME = 100;
const MAX_IMAGE_URL = 2048;

const NAMED_ENTITIES: Readonly<Record<string, string>> = {
  amp: "&", lt: "<", gt: ">", quot: '"', apos: "'", nbsp: " ", hellip: "…", mdash: "—", ndash: "–",
  rsquo: "’", lsquo: "‘", ldquo: "“", rdquo: "”", laquo: "«", raquo: "»", copy: "©", euro: "€",
  eacute: "é", egrave: "è", ecirc: "ê", euml: "ë", agrave: "à", acirc: "â", ccedil: "ç", ocirc: "ô",
  ugrave: "ù", ucirc: "û", icirc: "î", iuml: "ï",
};

function decodeEntities(text: string): string {
  return text.replace(/&(#x[0-9a-f]{1,6}|#\d{1,7}|[a-z]{2,8});/gi, (whole, body: string) => {
    if (body.startsWith("#")) {
      const code = body[1]?.toLowerCase() === "x" ? parseInt(body.slice(2), 16) : parseInt(body.slice(1), 10);
      return Number.isInteger(code) && code > 31 && code <= 0x10ffff && !(code >= 0xd800 && code <= 0xdfff)
        ? String.fromCodePoint(code)
        : "";
    }
    return NAMED_ENTITIES[body.toLowerCase()] ?? whole;
  });
}

// Visible plain text: entities decoded, any remaining tag removed, control
// characters dropped, whitespace collapsed, length bounded (in characters).
function clean(raw: string, maxLength: number): string | undefined {
  const text = decodeEntities(raw.slice(0, maxLength * 8))
    .replace(/<[^>]*>/g, " ")
    .replace(/[\u0000-\u001f\u007f-\u009f]/g, " ")
    .replace(/\s+/g, " ")
    .trim();
  if (text === "") return undefined;
  const letters = Array.from(text);
  return letters.length <= maxLength ? text : letters.slice(0, maxLength).join("");
}

const ATTRIBUTE = /([a-zA-Z_:][-a-zA-Z0-9_:.]*)\s*=\s*(?:"([^"]*)"|'([^']*)'|([^\s"'>]+))/g;

const MAX_TAG_LENGTH = 2048;
const MAX_META_TAGS = 300;
// Total characters the tag scanner may look at: hostile pages cannot make the
// scan quadratic, they only lose their own tags.
const SCAN_BUDGET = 1_500_000;

// Removes every block between `open` and `close` (both global). An unclosed
// block swallows the rest of the text. Each search resumes where the last one
// ended, so the work stays linear.
function removeBlocks(html: string, open: RegExp, close: RegExp): string {
  let out = "";
  let from = 0;
  for (;;) {
    open.lastIndex = from;
    const opened = open.exec(html);
    if (opened === null) return out + html.slice(from);
    out += `${html.slice(from, opened.index)} `;
    close.lastIndex = opened.index + opened[0].length;
    const closed = close.exec(html);
    if (closed === null) return out;
    from = closed.index + closed[0].length;
  }
}

// The text of a tag starting at `start`, up to its closing `>` outside quotes,
// or null when there is none within MAX_TAG_LENGTH.
function tagAt(html: string, start: number): string | null {
  let quote = "";
  const limit = Math.min(html.length, start + MAX_TAG_LENGTH);
  for (let at = start; at < limit; at++) {
    const char = html[at];
    if (quote !== "") {
      if (char === quote) quote = "";
    } else if (char === '"' || char === "'") {
      quote = char;
    } else if (char === ">") {
      return html.slice(start, at + 1);
    }
  }
  return null;
}

function metaTags(html: string): Array<{ key: string; content: string }> {
  const out: Array<{ key: string; content: string }> = [];
  const open = /<meta\b/gi;
  let budget = SCAN_BUDGET;
  for (let found = open.exec(html); found !== null && out.length < MAX_META_TAGS && budget > 0; found = open.exec(html)) {
    const tag = tagAt(html, found.index);
    budget -= tag === null ? MAX_TAG_LENGTH : tag.length;
    if (tag === null) continue;
    open.lastIndex = found.index + tag.length;
    const attributes = new Map<string, string>();
    for (const attribute of tag.matchAll(ATTRIBUTE)) {
      const name = (attribute[1] ?? "").toLowerCase();
      if (!attributes.has(name)) attributes.set(name, attribute[2] ?? attribute[3] ?? attribute[4] ?? "");
    }
    const key = (attributes.get("property") ?? attributes.get("name") ?? "").toLowerCase();
    const content = attributes.get("content");
    if (key !== "" && content !== undefined) out.push({ key, content });
  }
  return out;
}

// Content of the first <title>, or undefined when it is not closed.
function titleOf(html: string): string | undefined {
  const open = /<title\b[^>]*>/i.exec(html);
  if (open === null) return undefined;
  const from = open.index + open[0].length;
  const close = /<\/title\s*>/i.exec(html.slice(from));
  return close === null ? undefined : html.slice(from, from + close.index);
}

export function parseOpenGraph(html: string): OpenGraph {
  const source = removeBlocks(
    removeBlocks(removeBlocks(html, /<!--/g, /-->/g), /<script\b/gi, /<\/script\s*>/gi),
    /<style\b/gi,
    /<\/style\s*>/gi,
  );
  const metas = metaTags(source);
  const pick = (...keys: string[]): string | undefined => {
    for (const key of keys) {
      const found = metas.find((meta) => meta.key === key);
      if (found !== undefined) return found.content;
    }
    return undefined;
  };

  const title = clean(pick("og:title", "twitter:title") ?? titleOf(source) ?? "", MAX_TITLE);
  const description = clean(pick("og:description", "twitter:description", "description") ?? "", MAX_DESCRIPTION);
  const siteName = clean(pick("og:site_name") ?? "", MAX_SITE_NAME);
  const image = decodeEntities(pick("og:image", "og:image:url", "twitter:image") ?? "").trim();

  const result: OpenGraph = {};
  if (title !== undefined) result.title = title;
  if (description !== undefined) result.description = description;
  if (image !== "" && image.length <= MAX_IMAGE_URL) result.imageUrl = image;
  if (siteName !== undefined) result.siteName = siteName;
  return result;
}
