// Captures de la maquette (1440×900) → docs/backoffice/captures/maquette-*.png
// Prérequis : `bun run console:mock` dans un autre terminal. Playwright vient de PLAYWRIGHT_MODULE_DIR
// (par défaut le dossier où il est déjà installé sur ce poste) ou d'un `require("playwright")` ordinaire.
import { createRequire } from "node:module";
import { join } from "node:path";
import type { Browser, Page } from "playwright";

const BASE = process.env["CONSOLE_URL"] ?? "http://localhost:3470";
const OUT = join(import.meta.dir, "..", "..", "docs", "backoffice", "captures");
const moduleDir = process.env["PLAYWRIGHT_MODULE_DIR"] ?? "/Users/nono/.hermes/hermes-agent/";

interface Launcher {
  launch: (options?: { executablePath?: string }) => Promise<Browser>;
}

function loadPlaywright(): { chromium: Launcher } {
  try {
    return createRequire(join(moduleDir, "x.js"))("playwright");
  } catch {
    return createRequire(import.meta.url)("playwright");
  }
}

const { chromium } = loadPlaywright();

// `chromium.launch()` d'abord ; si le navigateur de cette version de Playwright n'est pas installé,
// repli sur un Chromium déjà présent dans le cache de Playwright.
async function launch(): Promise<Browser> {
  try {
    return await chromium.launch();
  } catch (error) {
    const cache = join(process.env["HOME"] ?? "", "Library", "Caches", "ms-playwright");
    for (const entry of await Array.fromAsync(new Bun.Glob("chromium-*/chrome-mac/Chromium.app/Contents/MacOS/Chromium").scan({ cwd: cache }))) {
      return chromium.launch({ executablePath: join(cache, entry) });
    }
    throw error;
  }
}

const browser = await launch();

async function shot(page: Page, name: string): Promise<void> {
  await page.waitForTimeout(350);
  await page.screenshot({ path: join(OUT, `maquette-${name}.png`) });
  console.log(`maquette-${name}.png`);
}

async function typeCode(page: Page, code: string): Promise<void> {
  const first = page.getByLabel("Chiffre 1 sur 6");
  await first.click();
  await page.keyboard.type(code, { delay: 40 });
}

try {
  const context = await browser.newContext({ viewport: { width: 1440, height: 900 }, locale: "fr-FR", colorScheme: "light" });
  const page = await context.newPage();
  page.on("pageerror", (error) => console.error("[erreur page]", error.message));
  page.on("console", (message) => message.type() === "error" && console.error("[console]", message.text()));

  await page.goto(`${BASE}/console`);
  await page.getByRole("heading", { name: "Connexion à la console" }).waitFor();
  await shot(page, "01-connexion");

  await page.getByLabel("Adresse e-mail").fill("admin@example.com");
  await page.getByLabel("Mot de passe").fill("demo");
  await page.getByRole("button", { name: "Se connecter" }).click();
  await page.getByRole("heading", { name: "Code de vérification" }).waitFor();
  await typeCode(page, "482");
  await shot(page, "02-code-mfa");
  await page.keyboard.type("916", { delay: 40 });
  await page.getByRole("heading", { name: "Tableau de bord", level: 1 }).waitFor();
  await page.waitForSelector(".chart-svg");
  await shot(page, "03-tableau-de-bord");

  await page.goto(`${BASE}/console#/signalements`);
  await page.waitForSelector("table.table tbody tr");
  await shot(page, "04-signalements");

  await page.locator("table.table tbody tr", { hasText: "Non assigné" }).first().click();
  await page.getByRole("dialog", { name: /Signalement n°/ }).waitFor();
  await page.waitForSelector(".panel-title");
  await shot(page, "05-detail-signalement");

  await page.getByRole("button", { name: "Lire la conversation" }).first().click();
  await page.getByRole("dialog", { name: "Lire la conversation signalée" }).waitFor();
  await page.getByLabel("Motif de la lecture").fill("Vérifier le contexte du message signalé avant de décider.");
  await shot(page, "06-modale-motif");
  await page.getByRole("button", { name: "Lire la conversation" }).last().click();
  await page.waitForSelector(".chat");
  await shot(page, "07-conversation");
  await page.getByRole("button", { name: "Fermer", exact: true }).last().click();

  await page.getByRole("button", { name: "M'assigner" }).click();
  await page.getByText("Signalement assigné à vous.").waitFor();
  await page.getByLabel("Sanctionner").check();
  await page.getByLabel("Suspension").check();
  await page.getByLabel("Motif normalisé de la décision").selectOption("scam_or_fraud");
  await page.getByLabel("Durée (jours)").fill("14");
  await page.getByLabel("Faits communiqués au membre").fill("Plusieurs messages demandant un virement d'argent à d'autres membres, puis une invitation à poursuivre sur une messagerie extérieure.");
  await page.getByLabel("Note interne (obligatoire)").fill("Récidive probable : trois signaux concordants, voir l'historique.");
  await page.locator(".drawer-body").evaluate((element) => element.scrollTo({ top: element.scrollHeight }));
  await shot(page, "08-formulaire-decision");
  await page.getByRole("button", { name: "Relire l'exposé des motifs" }).click();
  await page.waitForSelector(".statement");
  await page.locator(".drawer-body").evaluate((element) => element.scrollTo({ top: element.scrollHeight }));
  await shot(page, "09-apercu-expose");
  await page.getByRole("button", { name: "Valider la décision" }).click();
  await page.waitForSelector(".appeal-card");
  await page.locator(".drawer-body").evaluate((element) => element.scrollTo({ top: 0 }));
  await shot(page, "10-code-contestation");

  await page.goto(`${BASE}/console#/membres`);
  await page.getByLabel("Rechercher un membre").fill("Jeanne");
  await page.waitForSelector("table.table tbody tr");
  await shot(page, "11-recherche-membres");
  await page.locator("table.table tbody tr").first().click();
  await page.getByRole("heading", { name: "Identité" }).waitFor();
  await shot(page, "12-fiche-membre");

  // Algorithme : comprendre, régler (avec simulation), historique, lecture seule.
  await page.goto(`${BASE}/console#/algorithme`);
  await page.reload();
  await page.getByRole("heading", { name: /Réglages actifs/ }).waitFor();
  await shot(page, "16-algorithme-comprendre");
  await page.locator("#e-multiplicateurs").scrollIntoViewIfNeeded();
  await page.locator(".content").evaluate((element) => element.scrollTo({ top: element.scrollTop + 300 }));
  await shot(page, "17-algorithme-multiplicateurs");

  await page.goto(`${BASE}/console#/algorithme?onglet=regler`);
  await page.getByRole("heading", { name: "Simulation en direct" }).waitFor();
  await page.getByRole("textbox", { name: "Distance", exact: true }).fill("7");
  await page.getByRole("textbox", { name: "Cashrout", exact: true }).fill("2");
  await page.getByLabel("Mode de réciprocité").selectOption("geometric");
  await page.waitForSelector(".sim-list");
  await page.locator('section[aria-label="Vos réglages"] .sim-row').nth(1).click();
  await page.waitForSelector(".sim-detail");
  await page.locator(".content").evaluate((element) => element.scrollTo({ top: 0 }));
  await page.locator(".tune-sim").evaluate((element) => element.scrollTo({ top: 0 }));
  await shot(page, "18-algorithme-regler");
  await page.locator(".tune-sim").evaluate((element) => element.scrollTo({ top: element.scrollHeight }));
  await shot(page, "19-algorithme-detail-score");
  await page.getByRole("textbox", { name: "Distance « mi-score »" }).fill("900");
  await page.locator(".spec.has-error").first().scrollIntoViewIfNeeded();
  await shot(page, "20-algorithme-erreur-bornes");
  await page.getByRole("textbox", { name: "Distance « mi-score »" }).fill("40");
  await page.getByLabel("Note de version (obligatoire)").fill("Plus de poids à la distance et réciprocité géométrique, à essayer.");
  await page.getByLabel("Note de version (obligatoire)").scrollIntoViewIfNeeded();
  await shot(page, "21-algorithme-enregistrer");

  await page.goto(`${BASE}/console#/algorithme?onglet=historique`);
  await page.waitForSelector("table.table tbody tr");
  await shot(page, "22-algorithme-historique");
  await page.locator("table.table tbody tr").nth(2).click();
  await page.getByRole("dialog", { name: /Version n°/ }).waitFor();
  await shot(page, "23-algorithme-version");
  await page.keyboard.press("Escape");

  const reader = await browser.newContext({ viewport: { width: 1440, height: 900 }, locale: "fr-FR", colorScheme: "light" });
  const analyst = await reader.newPage();
  await analyst.goto(`${BASE}/console`);
  await analyst.getByLabel("Adresse e-mail").fill("analyste@example.com");
  await analyst.getByLabel("Mot de passe").fill("demo");
  await analyst.getByRole("button", { name: "Se connecter" }).click();
  await analyst.getByRole("heading", { name: "Code de vérification" }).waitFor();
  await typeCode(analyst, "482916");
  await analyst.getByRole("heading", { name: "Tableau de bord", level: 1 }).waitFor();
  await analyst.goto(`${BASE}/console#/algorithme?onglet=regler`);
  await analyst.getByText("Lecture seule.").waitFor();
  await analyst.waitForSelector(".sim-list");
  await shot(analyst, "24-algorithme-lecture-seule");
  await analyst.goto(`${BASE}/console#/algorithme?onglet=historique`);
  await analyst.waitForSelector("table.table tbody tr");
  await shot(analyst, "25-algorithme-historique-lecture-seule");

  await page.goto(`${BASE}/console#/`);
  await page.emulateMedia({ colorScheme: "dark" });
  await page.waitForSelector(".chart-svg");
  await shot(page, "13-tableau-de-bord-sombre");
  await page.goto(`${BASE}/console#/signalements`);
  await page.waitForSelector("table.table tbody tr");
  await page.locator("table.table tbody tr").nth(1).click();
  await page.waitForSelector(".panel-title");
  await shot(page, "14-signalements-sombre");

  await page.goto(`${BASE}/console#/algorithme?onglet=regler`);
  await page.waitForSelector(".sim-list");
  await shot(page, "26-algorithme-regler-sombre");

  const second = await browser.newContext({ viewport: { width: 1440, height: 900 }, locale: "fr-FR", colorScheme: "light" });
  const enrol = await second.newPage();
  await enrol.goto(`${BASE}/console`);
  await enrol.getByLabel("Adresse e-mail").fill("nouveau@example.com");
  await enrol.getByLabel("Mot de passe").fill("demo");
  await enrol.getByRole("button", { name: "Se connecter" }).click();
  await enrol.getByRole("heading", { name: "Activez la double authentification" }).waitFor();
  await enrol.waitForSelector(".secret");
  await shot(enrol, "15-enrolement-mfa");
} finally {
  await browser.close();
}
