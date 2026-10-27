import { APP_STORE_URL } from "../../landing/config";
import type { LegalDocument } from "./document";
import type { Heading } from "./markdown";

// One legal page: the same shell as the showcase (landing/), with the reading
// layout of a document. No script: the page works as plain HTML, and its
// stylesheet (public/legal.css) shares the showcase's tokens.

const MONTHS = ["janvier", "février", "mars", "avril", "mai", "juin", "juillet", "août", "septembre", "octobre", "novembre", "décembre"] as const;
const SITE = "https://mazl.app";
const READING_WORDS_PER_MINUTE = 200;

export function formatFrenchDate(iso: string): string {
  const [year, month, day] = iso.split("-").map(Number);
  const name = MONTHS[(month ?? 1) - 1];
  if (year === undefined || day === undefined || name === undefined) throw new Error(`Bad date: ${iso}`);
  return `${day === 1 ? "1er" : day.toString()} ${name} ${year.toString()}`;
}

const escapeAttribute = (value: string): string => value.replaceAll("&", "&amp;").replaceAll('"', "&quot;").replaceAll("<", "&lt;");
const escapeText = (value: string): string => value.replaceAll("&", "&amp;").replaceAll("<", "&lt;").replaceAll(">", "&gt;");
const NBSP = " ";
const typo = (value: string): string => value.replace(/\s+([:;!?»%€])/g, `${NBSP}$1`).replace(/«\s+/g, `«${NBSP}`);

function tocList(headings: readonly Heading[]): string {
  const items: string[] = [];
  let open = false;
  for (const heading of headings) {
    const label = `${heading.number === "" ? "" : `<span class="toc__num">${heading.number}</span>`}${escapeText(typo(heading.title))}`;
    const link = `<a href="#${heading.id}">${label}</a>`;
    if (heading.level === 2) {
      if (open) items.push("</ol></li>");
      items.push(`<li>${link}`);
      items.push("<ol>");
      open = true;
    } else {
      items.push(`<li class="toc__sub">${link}</li>`);
    }
  }
  if (open) items.push("</ol></li>");
  // Sections without sub-sections keep no empty list.
  return `<ol>${items.join("").replaceAll("<ol></ol>", "")}</ol>`;
}

function documentLinks(documents: readonly LegalDocument[], current: LegalDocument): string {
  return documents
    .map((entry) => `<a href="/${entry.slug}"${entry.slug === current.slug ? ' aria-current="page"' : ""}>${escapeText(entry.nav)}</a>`)
    .join("");
}

function relatedCards(documents: readonly LegalDocument[], current: LegalDocument): string {
  return documents
    .filter((entry) => entry.slug !== current.slug)
    .map(
      (entry) =>
        `<li><a class="card" href="/${entry.slug}"><span class="mono-label">${escapeText(entry.nav)}</span><span class="card__title">${escapeText(typo(entry.title))}</span><span class="card__text">${escapeText(typo(entry.lead))}</span></a></li>`,
    )
    .join("");
}

export function renderPage(document: LegalDocument, documents: readonly LegalDocument[]): string {
  const title = `${document.title} — MAZL`;
  const url = `${SITE}/${document.slug}`;
  const minutes = Math.max(1, Math.round(document.body.words / READING_WORDS_PER_MINUTE));
  const articles = document.body.headings.filter((heading) => heading.level === 2).length;
  const toc = tocList(document.body.headings);
  const draft =
    document.status === "projet"
      ? `<aside class="notice" role="note"><p><strong>Version en cours de validation juridique.</strong> ${
          document.body.todoCount === 0
            ? "Aucune information n'est encore à compléter."
            : `<span class="notice__count">${document.body.todoCount.toString()}</span> information${document.body.todoCount > 1 ? "s" : ""} de l'éditeur reste${document.body.todoCount > 1 ? "nt" : ""} à compléter : elles sont repérées en <mark class="todo">[À COMPLÉTER&nbsp;: …]</mark> dans le texte.`
        }</p></aside>`
      : "";

  return `<!doctype html>
<html lang="fr">
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover" />
    <title>${escapeText(title)}</title>
    <meta name="description" content="${escapeAttribute(document.description)}" />
    <meta name="robots" content="index,follow" />
    <meta name="color-scheme" content="light dark" />
    <meta name="theme-color" content="#FFFFFF" media="(prefers-color-scheme: light)" />
    <meta name="theme-color" content="#0B0B0F" media="(prefers-color-scheme: dark)" />
    <meta name="referrer" content="strict-origin-when-cross-origin" />
    <meta property="og:type" content="article" />
    <meta property="og:site_name" content="MAZL" />
    <meta property="og:locale" content="fr_FR" />
    <meta property="og:title" content="${escapeAttribute(title)}" />
    <meta property="og:description" content="${escapeAttribute(document.description)}" />
    <meta property="og:url" content="${url}" />
    <link rel="canonical" href="${url}" />
    <link rel="icon" type="image/svg+xml" href="/favicon.svg" />
    <link rel="stylesheet" href="/legal.css" />
  </head>
  <body>
    <a class="skip" href="#contenu">Aller au contenu</a>

    <header class="nav" id="nav">
      <div class="nav__inner">
        <a class="wordmark" href="/" aria-label="MAZL, accueil">mazl<span>.</span></a>
        <nav class="nav__links" aria-label="Documents juridiques">${documentLinks(documents, document)}</nav>
        <div class="nav__actions">
          <a class="btn btn--small btn--ink" href="${APP_STORE_URL}" rel="noopener">Télécharger</a>
        </div>
      </div>
    </header>

    <main id="contenu">
      <header class="doc-head wrap">
        <p class="eyebrow">(Document juridique)</p>
        <h1 class="display">${escapeText(typo(document.title))}<span class="dot">.</span></h1>
        <p class="lead">${escapeText(typo(document.lead))}</p>
        <p class="doc-meta mono-label">
          <span>Version du <time datetime="${document.version}">${formatFrenchDate(document.version)}</time></span>
          <span>${articles.toString()} articles</span>
          <span>${minutes.toString()}${NBSP}min de lecture</span>
        </p>
        ${draft}
      </header>

      <div class="doc wrap">
        <aside class="toc toc--side" aria-label="Sommaire">
          <p class="mono-label toc__title">Sommaire</p>
          <nav aria-label="Sommaire du document">${toc}</nav>
        </aside>
        <details class="toc toc--inline">
          <summary>Sommaire</summary>
          <nav aria-label="Sommaire du document (téléphone)">${toc}</nav>
        </details>
        <article class="prose">
${document.body.html}
        </article>
      </div>

      <section class="related wrap" aria-labelledby="autres-documents">
        <h2 class="mono-label" id="autres-documents">Les autres documents</h2>
        <ul class="related__list">${relatedCards(documents, document)}</ul>
      </section>
    </main>

    <footer class="footer">
      <div class="wrap footer__inner">
        <a class="wordmark wordmark--small" href="/" aria-label="MAZL, accueil">mazl<span>.</span></a>
        <nav class="footer__links" aria-label="Informations légales">${documentLinks(documents, document)}<a href="mailto:hello@mazl.app">Contact</a></nav>
        <p class="footer__copy">© MAZL</p>
      </div>
    </footer>
  </body>
</html>
`;
}
