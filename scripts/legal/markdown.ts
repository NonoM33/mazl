// A small, strict Markdown renderer for the legal sources in docs/legal/. It
// handles exactly what those files use (headings, paragraphs, lists, tables,
// quotes, emphasis, code, links) and refuses what it does not know, so that a
// typo in a source fails the build instead of shipping a broken page.

export interface Heading {
  readonly level: 2 | 3;
  readonly number: string;
  readonly title: string;
  readonly id: string;
}

export interface RenderedMarkdown {
  readonly html: string;
  readonly headings: readonly Heading[];
  // Number of "[À COMPLÉTER : …]" marks left in the source.
  readonly todoCount: number;
  readonly words: number;
}

export class MarkdownError extends Error {
  constructor(message: string) {
    super(`Legal markdown: ${message}`);
    this.name = "MarkdownError";
  }
}

const NBSP = " ";
const TODO_MARK = /\[À COMPLÉTER[^\]]*\]/g;
const LINK = /\[([^\]]+)\]\(([^)\s]+)\)/g;
const AUTO_LINK = /(https?:\/\/[^\s<>()]+[^\s<>().,;:])|([\w.+-]+@[\w-]+(?:\.[\w-]+)+)/g;
const SAFE_HREF = /^(\/[\w\-./#?=&]*|https:\/\/[^\s"<>]+|mailto:[^\s"<>]+)$/;

function escapeHtml(text: string): string {
  return text.replaceAll("&", "&amp;").replaceAll("<", "&lt;").replaceAll(">", "&gt;").replaceAll('"', "&quot;");
}

// French typography: no line break before ":" ";" "!" "?" "%" "€" or inside « ».
function typography(text: string): string {
  return text.replace(/\s+([:;!?»%€])/g, `${NBSP}$1`).replace(/«\s+/g, `«${NBSP}`);
}

class Placeholders {
  private readonly values: string[] = [];
  put(html: string): string {
    this.values.push(html);
    return `\u0000${(this.values.length - 1).toString()}\u0000`;
  }
  restore(text: string): string {
    let result = text;
    // Placeholders may nest (a link around emphasis): resolve until none is left.
    while (result.includes("\u0000")) {
      result = result.replace(/\u0000(\d+)\u0000/g, (_whole, index: string) => this.values[Number(index)] ?? "");
    }
    return result;
  }
}

export function renderInline(raw: string): { html: string; todos: number } {
  const hold = new Placeholders();
  let todos = 0;
  let text = raw.replace(/`([^`]+)`/g, (_whole, code: string) => hold.put(`<code>${escapeHtml(code)}</code>`));
  text = typography(escapeHtml(text));
  text = text.replace(TODO_MARK, (mark) => {
    todos += 1;
    return hold.put(`<mark class="todo">${mark}</mark>`);
  });
  text = text.replace(LINK, (_whole, label: string, href: string) => {
    const target = href.replaceAll("&amp;", "&");
    if (!SAFE_HREF.test(target)) throw new MarkdownError(`unsafe link target: ${target}`);
    const external = target.startsWith("https://");
    const attributes = external ? ' rel="noopener noreferrer"' : "";
    return hold.put(`<a href="${escapeHtml(target)}"${attributes}>${renderInlineEmphasis(label)}</a>`);
  });
  text = text.replace(AUTO_LINK, (match: string, url: string | undefined) => {
    const target = url === undefined ? `mailto:${match}` : match;
    const attributes = url === undefined ? "" : ' rel="noopener noreferrer"';
    return hold.put(`<a href="${target}"${attributes}>${match}</a>`);
  });
  text = renderInlineEmphasis(text);
  return { html: hold.restore(text), todos };
}

function renderInlineEmphasis(text: string): string {
  return text.replace(/\*\*(.+?)\*\*/g, "<strong>$1</strong>").replace(/\*(.+?)\*/g, "<em>$1</em>");
}

function plainText(markdown: string): string {
  return markdown.replace(/`/g, "").replace(/\*+/g, "").replace(/\[([^\]]+)\]\([^)]*\)/g, "$1");
}

const HEADING_NUMBER = /^(\d+(?:\.\d+)*)\.?\s+(.+)$/;

function slug(text: string): string {
  return text
    .normalize("NFD")
    .replace(/[̀-ͯ]/g, "")
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-|-$/g, "");
}

function parseHeading(level: 2 | 3, text: string, taken: Set<string>): Heading {
  const match = HEADING_NUMBER.exec(text);
  const number = match?.[1] ?? "";
  const title = match?.[2] ?? text;
  const base = number === "" ? slug(title) : `art-${number.replaceAll(".", "-")}`;
  if (base === "" || taken.has(base)) throw new MarkdownError(`duplicate or empty heading id for "${text}"`);
  taken.add(base);
  return { level, number, title, id: base };
}

function renderHeading(heading: Heading): string {
  const tag = `h${heading.level.toString()}`;
  const number = heading.number === "" ? "" : `<span class="num">${heading.number}</span> `;
  const title = renderInline(heading.title).html;
  const anchor = `<a class="anchor" href="#${heading.id}" aria-label="Lien vers cette section"><span aria-hidden="true">#</span></a>`;
  return `<${tag} id="${heading.id}">${number}${title}${anchor}</${tag}>`;
}

function renderTable(rows: readonly string[], caption: string): { html: string; todos: number } {
  const cells = (line: string): string[] => line.trim().replace(/^\|/, "").replace(/\|$/, "").split("|").map((cell) => cell.trim());
  const [headerLine, separator, ...bodyLines] = rows;
  if (headerLine === undefined || separator === undefined || !/^\|?[\s:|-]+\|?$/.test(separator)) throw new MarkdownError("a table needs a header and a separator row");
  const header = cells(headerLine);
  let todos = 0;
  const cell = (tag: "th" | "td", content: string, label = ""): string => {
    const inline = renderInline(content);
    todos += inline.todos;
    if (tag === "th") return `<th scope="col" role="columnheader">${inline.html}</th>`;
    // On a narrow screen each row becomes a card: the cell carries its column name.
    const named = label === "" ? "" : ` data-label="${escapeHtml(plainText(label))}"`;
    return `<td role="cell"${named}>${inline.html}</td>`;
  };
  const body = bodyLines.map((line) => {
    const values = cells(line);
    if (values.length !== header.length) throw new MarkdownError(`table row has ${values.length.toString()} cells, expected ${header.length.toString()}: ${line.slice(0, 60)}`);
    return `<tr role="row">${values.map((value, column) => cell("td", value, column === 0 ? "" : (header[column] ?? ""))).join("")}</tr>`;
  });
  const html = `<div class="table-wrap" role="region" tabindex="0" aria-label="${escapeHtml(`Tableau : ${caption}`)}"><table role="table"><thead role="rowgroup"><tr role="row">${header.map((value) => cell("th", value)).join("")}</tr></thead><tbody role="rowgroup">${body.join("")}</tbody></table></div>`;
  return { html, todos };
}

export function renderMarkdown(source: string): RenderedMarkdown {
  const lines = source.split("\n");
  const out: string[] = [];
  const headings: Heading[] = [];
  const taken = new Set<string>();
  let todoCount = 0;
  let context = "";

  const inline = (text: string): string => {
    const rendered = renderInline(text);
    todoCount += rendered.todos;
    return rendered.html;
  };

  let index = 0;
  while (index < lines.length) {
    const line = lines[index] ?? "";
    if (line.trim() === "") {
      index += 1;
      continue;
    }
    const heading = /^(#{2,3}) (.+)$/.exec(line);
    if (heading) {
      const parsed = parseHeading(heading[1]?.length === 2 ? 2 : 3, heading[2] ?? "", taken);
      headings.push(parsed);
      context = parsed.title;
      todoCount += renderInline(parsed.title).todos;
      out.push(renderHeading(parsed));
      index += 1;
      continue;
    }
    if (/^#/.test(line)) throw new MarkdownError(`only ## and ### headings are allowed: ${line}`);
    if (line.startsWith("|")) {
      const rows: string[] = [];
      while (index < lines.length && (lines[index] ?? "").startsWith("|")) rows.push(lines[index++] ?? "");
      const table = renderTable(rows, plainText(context));
      todoCount += table.todos;
      out.push(table.html);
      continue;
    }
    if (line.startsWith(">")) {
      const quoted: string[] = [];
      while (index < lines.length && (lines[index] ?? "").startsWith(">")) quoted.push((lines[index++] ?? "").replace(/^>\s?/, ""));
      out.push(`<blockquote><p>${inline(quoted.join(" ").trim())}</p></blockquote>`);
      continue;
    }
    const listKind = /^- /.test(line) ? "ul" : /^\d+\. /.test(line) ? "ol" : null;
    if (listKind !== null) {
      const marker = listKind === "ul" ? /^- / : /^\d+\. /;
      const items: string[] = [];
      while (index < lines.length && marker.test(lines[index] ?? "")) items.push(`<li>${inline((lines[index++] ?? "").replace(marker, ""))}</li>`);
      out.push(`<${listKind}>${items.join("")}</${listKind}>`);
      continue;
    }
    const paragraph: string[] = [];
    while (index < lines.length && (lines[index] ?? "").trim() !== "" && !/^(#|\||>|- |\d+\. )/.test(lines[index] ?? "")) paragraph.push((lines[index++] ?? "").trim());
    out.push(`<p>${inline(paragraph.join(" "))}</p>`);
  }

  const words = plainText(source).split(/\s+/).filter((word) => word !== "").length;
  return { html: out.join("\n"), headings, todoCount, words };
}
