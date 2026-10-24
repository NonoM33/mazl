import { afterAll, beforeAll, describe, expect, test } from "bun:test";
import type { Browser } from "playwright";
import { launch, open, signedIn } from "./support/browser";
import { capture } from "./support/capture";
import { createMember, type Member } from "./support/seed";

// The screens that cross the whole site: the art. 9 consent, the Shabbat
// pause (browser clock set to a Friday evening in Paris), the discreet mode
// and the keyboard help. Each is checked, then captured in both themes.

let browser: Browser;
let lea: Member;
let nina: Member;
const THEMES = ["light", "dark"] as const;

beforeAll(async () => {
  browser = await launch();
  lea = await createMember({ name: "Léa", gender: "female", birthdate: "1994-03-12", city: "Paris 11e", latitude: 48.8566, longitude: 2.3522, photos: 2 });
  nina = await createMember({ name: "Nina", gender: "female", birthdate: "1995-01-20", city: "Paris", latitude: 48.85, longitude: 2.35, photos: 1, consent: false });
});
afterAll(async () => { await browser.close(); });

describe("screens across the site", () => {
  test("the consent screen asks before any religious data, in both themes", async () => {
    for (const theme of THEMES) {
      const { page, context } = await signedIn(browser, nina, { theme });
      await open(page, "/");
      await page.getByRole("heading", { name: "Votre pratique religieuse, avec votre accord" }).waitFor();
      await capture(page, "24-consentement", theme);
      await context.close();
    }
  });

  test("on Friday evening in Paris the Shabbat pause covers the site, until the member continues", async () => {
    for (const theme of THEMES) {
      const { page, context } = await signedIn(browser, lea, { theme });
      await context.addInitScript({ content: `localStorage.setItem("mazl.shabbat", ${JSON.stringify(JSON.stringify({ enabled: true, includeHolidays: true, bufferMin: 18 }))});` });
      await page.clock.install({ time: new Date("2026-10-30T20:30:00+01:00") });
      await open(page, "/");
      await page.getByTestId("shabbat-screen").waitFor();
      expect(await page.getByRole("heading", { name: "Chabbat Chalom" }).isVisible()).toBe(true);
      await capture(page, "25-pause-shabbat", theme);
      await page.getByRole("button", { name: "Continuer quand même" }).click();
      await page.getByRole("navigation", { name: "Navigation principale" }).waitFor();
      await context.close();
    }
  });

  test("Escape twice hides everything behind a neutral page, and back", async () => {
    const { page, context } = await signedIn(browser, lea);
    await open(page, "/profil");
    await page.keyboard.press("Escape");
    await page.keyboard.press("Escape");
    await page.getByTestId("discreet-screen").waitFor();
    expect(await page.title()).toBe("Notes");
    expect(await page.locator("img").count()).toBe(0);
    await capture(page, "26-mode-discret", "light");
    await page.keyboard.press("Escape");
    await page.keyboard.press("Escape");
    await page.getByRole("navigation", { name: "Navigation principale" }).waitFor();
    expect(await page.title()).not.toBe("Notes");
    await context.close();
  });

  test("« ? » lists the keyboard shortcuts", async () => {
    for (const theme of THEMES) {
      const { page, context } = await signedIn(browser, lea, { theme });
      await open(page, "/decouvrir");
      await page.keyboard.press("?");
      await page.getByRole("dialog", { name: "Raccourcis clavier" }).waitFor();
      await capture(page, "27-raccourcis", theme);
      await context.close();
    }
  });
});
