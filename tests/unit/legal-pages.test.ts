import { beforeAll, describe, expect, test } from "bun:test";
import { readFile } from "node:fs/promises";
import { join } from "node:path";
import { LEGAL_PAGES } from "../../src/features/web-app/site-rules";
import { LEGAL_SLUGS, type LegalSlug } from "../../scripts/legal/document";
import { renderLegalPages } from "../../scripts/legal/build";

const root = join(import.meta.dir, "..", "..");
const read = (path: string): Promise<string> => readFile(join(root, path), "utf8");
const visible = (html: string): string => html.replace(/<[^>]+>/g, " ").replace(/&nbsp;| | /g, " ").replace(/\s+/g, " ");

let rendered: Readonly<Record<LegalSlug, string>>;
const sources = {} as Record<LegalSlug, string>;

beforeAll(async () => {
  rendered = await renderLegalPages();
  for (const slug of LEGAL_SLUGS) sources[slug] = await read(`docs/legal/${slug}.md`);
});

describe("legal pages: generated from docs/legal and served", () => {
  test("the site serves exactly the five documents", () => {
    expect([...LEGAL_PAGES]).toEqual([...LEGAL_SLUGS]);
  });

  test("public/<page>.html is the rendering of its Markdown source (run `bun run legal:build` after editing docs/legal)", async () => {
    for (const slug of LEGAL_SLUGS) expect([slug, await read(`public/${slug}.html`) === rendered[slug]]).toEqual([slug, true]);
  });
});

describe("legal pages: structure", () => {
  test("each page is French, has one h1, a title, a canonical address and a skip link", () => {
    for (const slug of LEGAL_SLUGS) {
      const html = rendered[slug];
      expect(html).toContain('<html lang="fr">');
      expect(html.match(/<h1[\s>]/g)?.length).toBe(1);
      expect(html).toMatch(/<title>[^<]+ — MAZL<\/title>/);
      expect(html).toContain(`<link rel="canonical" href="https://mazl.app/${slug}" />`);
      expect(html).toContain('<a class="skip" href="#contenu">');
      expect(html).toContain('id="contenu"');
      expect(html).toMatch(/<meta name="description" content="[^"]{60,}/);
    }
  });

  test("headings never skip a level: every h3 follows an h2", () => {
    for (const slug of LEGAL_SLUGS) {
      const levels = [...rendered[slug].matchAll(/<h([1-6])[\s>]/g)].map((match) => Number(match[1]));
      let previous = 0;
      for (const level of levels) {
        expect([slug, level - previous <= 1]).toEqual([slug, true]);
        previous = level;
      }
    }
  });

  test("every link of the table of contents points to a heading of the page, and ids are unique", () => {
    for (const slug of LEGAL_SLUGS) {
      const html = rendered[slug];
      const ids = [...html.matchAll(/\sid="([^"]+)"/g)].map((match) => match[1] ?? "");
      expect(new Set(ids).size).toBe(ids.length);
      const targets = [...html.matchAll(/href="#([^"]+)"/g)].map((match) => match[1] ?? "");
      expect(targets.length).toBeGreaterThan(5);
      for (const target of targets) expect([slug, target, ids.includes(target)]).toEqual([slug, target, true]);
    }
  });

  test("each page shows its version date and links to the four others and to the home page", () => {
    for (const slug of LEGAL_SLUGS) {
      const html = rendered[slug];
      expect(html).toMatch(/<time datetime="2026-10-27">27 octobre 2026<\/time>/);
      expect(html).toContain('href="/"');
      for (const other of LEGAL_SLUGS.filter((entry) => entry !== slug)) expect([slug, other, html.includes(`href="/${other}"`)]).toEqual([slug, other, true]);
      expect(html).toContain('aria-current="page"');
    }
  });

  test("no script, no inline style, no external stylesheet, font, image or frame: the strict CSP allows nothing else", () => {
    for (const slug of LEGAL_SLUGS) {
      const html = rendered[slug];
      expect(html).not.toMatch(/<script|<style|<iframe|<img|<link[^>]+rel="preload"/);
      expect(html).not.toMatch(/\sstyle="/);
      expect(html).not.toMatch(/\son[a-z]+="/);
      for (const link of html.matchAll(/<link [^>]*href="([^"]+)"/g)) expect([slug, link[1], /^\/[^/]|^https:\/\/mazl\.app\//.test(link[1] ?? "")]).toEqual([slug, link[1], true]);
      expect(html.match(/<link[^>]+rel="stylesheet"[^>]*>/g)).toEqual(['<link rel="stylesheet" href="/legal.css" />']);
    }
  });

  test("external links open safely", () => {
    for (const slug of LEGAL_SLUGS) {
      for (const link of rendered[slug].matchAll(/<a [^>]*href="https:\/\/[^"]+"[^>]*>/g)) expect([slug, link[0], /rel="noopener/.test(link[0])]).toEqual([slug, link[0], true]);
    }
  });
});

describe("legal pages: nothing is invented", () => {
  test("every [À COMPLÉTER] mark of a source reaches its page, is counted for the reader and is announced in A_COMPLETER.md", async () => {
    const todo = await read("docs/legal/A_COMPLETER.md");
    for (const slug of LEGAL_SLUGS) {
      const marks = sources[slug].match(/\[À COMPLÉTER[^\]]*\]/g)?.length ?? 0;
      const shown = rendered[slug].match(/<mark class="todo">\[À COMPLÉTER/g)?.length ?? 0;
      // The notice at the top of the page shows one more, as an example of the mark.
      expect([slug, shown - 1]).toEqual([slug, marks]);
      expect(rendered[slug]).toContain(`<span class="notice__count">${marks.toString()}</span>`);
      if (marks > 0) expect([slug, todo.includes(`\`${slug}.md\``)]).toEqual([slug, true]);
    }
  });

  // The sole trader's SIREN and telephone, given by Renaud on 2026-10-28, are
  // the only numbers allowed, and only in the legal notice.
  const PUBLISHER_SIREN = "822 073 706";
  const PUBLISHER_PHONE = "+1 343 495 6005";

  test("no number other than the publisher's SIREN and telephone has been written in", () => {
    for (const slug of LEGAL_SLUGS) {
      const text =
        slug === "mentions-legales"
          ? sources[slug].replace(`SIREN ${PUBLISHER_SIREN}`, "SIREN").replace(`Téléphone : ${PUBLISHER_PHONE}`, "Téléphone :")
          : sources[slug];
      expect(text).not.toMatch(/\b\d{3} ?\d{3} ?\d{3}( ?\d{5})?\b/);
      expect(text).not.toMatch(/\bFR ?\d{2} ?\d{9}\b/);
      expect(text).not.toMatch(/\bIBAN\b/i);
      expect(text).not.toMatch(/\+?\d{2}[ .]?\d(?:[ .]?\d{2}){4}\b/);
    }
  });

  // The publisher (a sole trader, given by Renaud on 2026-10-28) is named; the
  // address and company number he has not given yet stay visible marks.
  test("the legal notice names the sole trader and still marks what he has not given", () => {
    const notice = sources["mentions-legales"];
    expect(notice).toContain("- Éditeur : Renaud Cosson, entrepreneur individuel (EI)");
    expect(notice).toContain("Le directeur de la publication est Renaud Cosson");
    expect(notice).toContain(`- Immatriculation : SIREN ${PUBLISHER_SIREN}`);
    expect(notice).toContain("- Adresse : 116 avenue John Fitzgerald Kennedy, 92160 Antony, France");
    expect(notice).toContain(`- Téléphone : ${PUBLISHER_PHONE}`);
    for (const field of ["- TVA :"]) {
      const line = notice.split("\n").find((entry) => entry.startsWith(field)) ?? "";
      expect([field, /\[À COMPLÉTER/.test(line)]).toEqual([field, true]);
    }
  });
});

describe("legal pages: substance", () => {
  const prices = async (): Promise<Record<string, string>> => {
    const asc = await read("docs/premium/APP-STORE-CONNECT.md");
    const found: Record<string, string> = {};
    for (const line of asc.split("\n")) {
      const product = /`(com\.mazl\.app\.[a-z0-9.]+)`/.exec(line)?.[1];
      const price = /(\d+,\d{2}) €/.exec(line)?.[1];
      if (product !== undefined && price !== undefined) found[product] = price;
    }
    return found;
  };

  test("the prices of the CGV are those of App Store Connect (docs/premium/APP-STORE-CONNECT.md)", async () => {
    const asc = await prices();
    expect(Object.keys(asc).sort()).toEqual(["com.mazl.app.boost.1", "com.mazl.app.boost.3", "com.mazl.app.plus.12m", "com.mazl.app.plus.1m", "com.mazl.app.plus.3m", "com.mazl.app.plus.6m", "com.mazl.app.superlikes.15", "com.mazl.app.superlikes.5"]);
    const sales = visible(rendered.cgv);
    const row = (offer: string, duration: string, price: string): string => `${offer} ${duration} ${price} €`;
    expect(sales).toContain(row("mazl+", "1 mois", asc["com.mazl.app.plus.1m"] ?? "?"));
    expect(sales).toContain(row("mazl+", "3 mois", asc["com.mazl.app.plus.3m"] ?? "?"));
    expect(sales).toContain(row("mazl+", "6 mois", asc["com.mazl.app.plus.6m"] ?? "?"));
    expect(sales).toContain(row("mazl+", "12 mois (payés d'avance)", asc["com.mazl.app.plus.12m"] ?? "?"));
    expect(sales).toContain(row("Boost", "1 Boost", asc["com.mazl.app.boost.1"] ?? "?"));
    expect(sales).toContain(row("Boosts", "3 Boosts", asc["com.mazl.app.boost.3"] ?? "?"));
    expect(sales).toContain(row("Super Likes", "5 Super Likes", asc["com.mazl.app.superlikes.5"] ?? "?"));
    expect(sales).toContain(row("Super Likes", "15 Super Likes", asc["com.mazl.app.superlikes.15"] ?? "?"));
  });

  test("MAZL Couple: 29,99 € a month for two, one pays and both benefit, mazl+ included", () => {
    const sales = visible(rendered.cgv);
    expect(sales).toContain("MAZL Couple, pour deux 1 mois 29,99 €");
    expect(sales).toMatch(/Un seul des deux membres le souscrit et le paie/);
    expect(sales).toMatch(/les deux en profitent/);
    expect(sales).toMatch(/avantages de l'abonnement mazl\+/);
  });

  test("the CGV carry the consumer-law essentials", () => {
    const sales = visible(rendered.cgv);
    for (const expected of ["L221-28", "L221-18", "renouvelle automatiquement", "24 heures avant la fin de la période", "Stripe", "App Store", "médiateur de la consommation", "garantie légale de conformité", "code d'offre Apple", "code promotionnel", "30 jours"]) {
      expect([expected, sales.includes(expected)]).toEqual([expected, true]);
    }
  });

  test("the CGU carry the age rule, the identity check and the DSA duties", () => {
    const terms = visible(rendered.cgu);
    for (const expected of ["18 ans", "puce électronique (NFC)", "selfie", "2022/2065", "point de contact", "exposé des motifs", "six mois", "Arcom", "article 21", "assistant automatique", "intelligence artificielle", "ne réserve rien", "droit français", "médiateur de la consommation"]) {
      expect([expected, terms.includes(expected)]).toEqual([expected, true]);
    }
  });

  test("the privacy policy names the sensitive data, the processors, the rights and the supervisory authority", () => {
    const policy = visible(rendered.confidentialite);
    for (const expected of ["article 9", "consentement explicite", "pratique religieuse", "OpenPanel", "Anthropic", "Stripe", "Hetzner", "APNs", "Resend", "CNIL", "portabilité", "clauses contractuelles types", "jamais conservée", "Helsinki"]) {
      expect([expected, policy.includes(expected)]).toEqual([expected, true]);
    }
  });

  test("the legal notice names the host and the DSA contact point; the cookie policy lists the session cookie", () => {
    const notice = visible(rendered["mentions-legales"]);
    for (const expected of ["Hetzner Online GmbH", "Industriestr. 25", "Directeur de la publication", "2004-575", "règlement (UE) 2022/2065"]) expect([expected, notice.includes(expected)]).toEqual([expected, true]);
    const cookies = visible(rendered.cookies);
    for (const expected of ["__Host-mazl_web", "HttpOnly", "strictement nécessaire", "mesure d'audience", "Refuser"]) expect([expected, cookies.includes(expected)]).toEqual([expected, true]);
  });

  test("the cookie names written in the policy are the ones the code uses", async () => {
    const cookie = await read("src/features/web-session/presentation/cookie.ts");
    expect(cookie).toContain('COOKIE_NAME = "__Host-mazl_web"');
    expect(cookie).toContain("HttpOnly; Secure; SameSite=Strict");
    const theme = await read("web/src/shared/lib/theme.ts");
    const shabbat = await read("web/src/features/shabbat/shabbat-settings.ts");
    expect(theme).toContain('KEY = "mazl.theme"');
    expect(shabbat).toContain('KEY = "mazl.shabbat"');
    expect(visible(rendered.cookies)).toContain("mazl.theme");
    expect(visible(rendered.cookies)).toContain("mazl.shabbat");
  });
});
