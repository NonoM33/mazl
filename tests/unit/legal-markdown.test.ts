import { describe, expect, test } from "bun:test";
import { MarkdownError, renderInline, renderMarkdown } from "../../scripts/legal/markdown";
import { parseDocument } from "../../scripts/legal/document";

describe("legal markdown: headings", () => {
  test("numbered headings get stable ids, numbers and a table of contents entry", () => {
    const { html, headings } = renderMarkdown("## 1. Qui sommes-nous\n\n### 4.2 Inscription et connexion\n\n## 12. Suspension\n");
    expect(headings).toEqual([
      { level: 2, number: "1", title: "Qui sommes-nous", id: "art-1" },
      { level: 3, number: "4.2", title: "Inscription et connexion", id: "art-4-2" },
      { level: 2, number: "12", title: "Suspension", id: "art-12" },
    ]);
    expect(html).toContain('<h2 id="art-1"><span class="num">1</span> Qui sommes-nous');
    expect(html).toContain('<h3 id="art-4-2">');
  });

  test("a duplicated heading number is refused instead of producing two identical ids", () => {
    expect(() => renderMarkdown("## 1. A\n\n## 1. B\n")).toThrow(MarkdownError);
  });

  test("a level-one heading in a source is refused: the title comes from the front matter", () => {
    expect(() => renderMarkdown("# Titre\n")).toThrow(MarkdownError);
  });
});

describe("legal markdown: inline", () => {
  test("[À COMPLÉTER : …] becomes a visible mark and is counted", () => {
    const { html, todos } = renderInline("Siège : [À COMPLÉTER : adresse] et [À COMPLÉTER : SIREN]");
    expect(todos).toBe(2);
    expect(html.match(/<mark class="todo">/g)?.length).toBe(2);
  });

  test("text is escaped, so a source cannot inject markup", () => {
    expect(renderInline("a <script>alert(1)</script> & b").html).toBe("a &lt;script&gt;alert(1)&lt;/script&gt; &amp; b");
  });

  test("French punctuation never starts a line: a no-break space goes before : ; ! ? and € and inside « »", () => {
    const { html } = renderInline("Voir « ceci » : 19,99 € !");
    expect(html).toBe("Voir « ceci » : 19,99 € !".replace(" : ", " : "));
  });

  test("links to the site, to https pages and to mailto are kept; the others are refused", () => {
    expect(renderInline("[CGV](/cgv)").html).toBe('<a href="/cgv">CGV</a>');
    expect(renderInline("[CNIL](https://www.cnil.fr)").html).toContain('rel="noopener noreferrer"');
    expect(() => renderInline("[x](javascript:alert(1))")).toThrow(MarkdownError);
    expect(() => renderInline("[x](http://example.com)")).toThrow(MarkdownError);
  });

  test("a bare web address and a bare e-mail address become links, without the final dot", () => {
    const { html } = renderInline("Écrivez à hello@mazl.app ou lisez https://mazl.app.");
    expect(html).toContain('<a href="mailto:hello@mazl.app">hello@mazl.app</a>');
    expect(html).toContain('<a href="https://mazl.app" rel="noopener noreferrer">https://mazl.app</a>.');
  });

  test("code is shown as is, emphasis and strong work, even inside a link", () => {
    expect(renderInline("`a*b*`").html).toBe("<code>a*b*</code>");
    expect(renderInline("**gras** et *italique*").html).toBe("<strong>gras</strong> et <em>italique</em>");
    expect(renderInline("[**CGU**](/cgu)").html).toBe('<a href="/cgu"><strong>CGU</strong></a>');
  });
});

describe("legal markdown: blocks", () => {
  test("lists, quotes and paragraphs", () => {
    const { html } = renderMarkdown("Intro\nsur deux lignes.\n\n- un\n- deux\n\n1. premier\n2. second\n\n> **Note.** Texte\n> suite\n");
    expect(html).toContain("<p>Intro sur deux lignes.</p>");
    expect(html).toContain("<ul><li>un</li><li>deux</li></ul>");
    expect(html).toContain("<ol><li>premier</li><li>second</li></ol>");
    expect(html).toContain("<blockquote><p><strong>Note.</strong> Texte suite</p></blockquote>");
  });

  test("a table keeps its header, names each cell after its column for the phone layout, and is labelled by its section", () => {
    const { html } = renderMarkdown("## 3. Prix\n\n| Offre | Prix |\n|---|---|\n| mazl+ | 19,99 € |\n");
    expect(html).toContain('<th scope="col" role="columnheader">Offre</th>');
    expect(html).toContain('<td role="cell">mazl+</td>');
    expect(html).toContain('<td role="cell" data-label="Prix">19,99 €</td>');
    expect(html).toContain('aria-label="Tableau : Prix"');
  });

  test("a row with the wrong number of cells is refused", () => {
    expect(() => renderMarkdown("| A | B |\n|---|---|\n| 1 |\n")).toThrow(MarkdownError);
  });
});

describe("legal markdown: front matter", () => {
  const valid = "---\nslug: cgu\ntitle: T\nnav: N\ndescription: D\nlead: L\nversion: 2026-10-27\nstatus: projet\n---\n## 1. A\n";

  test("a complete document parses", () => {
    expect(parseDocument(valid)).toMatchObject({ slug: "cgu", version: "2026-10-27", status: "projet" });
  });

  test("an unknown slug, a missing field, a bad date or a bad status are refused", () => {
    expect(() => parseDocument(valid.replace("slug: cgu", "slug: autre"))).toThrow(MarkdownError);
    expect(() => parseDocument(valid.replace("lead: L\n", ""))).toThrow(MarkdownError);
    expect(() => parseDocument(valid.replace("2026-10-27", "27/10/2026"))).toThrow(MarkdownError);
    expect(() => parseDocument(valid.replace("status: projet", "status: draft"))).toThrow(MarkdownError);
  });
});
