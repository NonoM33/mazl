import { afterAll, beforeAll, describe, expect, test } from "bun:test";
import type { Browser } from "playwright";
import { launch, open, signedIn } from "./support/browser";
import { capture } from "./support/capture";
import { makePlus } from "./support/seed";
import { seedWorld, type World } from "./support/world";

let browser: Browser;
let world: World;

beforeAll(async () => {
  browser = await launch();
  world = await seedWorld();
});
afterAll(async () => { await browser.close(); });

const cards = (page: import("playwright").Page) => page.getByRole("list", { name: "Ils vous ont aimé" }).getByRole("listitem");

describe("likes without mazl+", () => {
  for (const theme of ["light", "dark"] as const) {
    test(`three likes are blurred and show a first name only (${theme})`, async () => {
      const { page, context, errors } = await signedIn(browser, world.lea, { theme });
      await open(page, "/likes");
      await cards(page).first().waitFor();
      expect(await cards(page).count()).toBe(3);
      expect(await page.getByRole("tab", { name: "Ils vous ont aimé · 3" }).isVisible()).toBe(true);
      // The server sends no photo without mazl+ (docs/web/adr/W11): no image at all.
      expect(await page.locator("ul[aria-label] li img").count()).toBe(0);
      const text = (await cards(page).allInnerTexts()).join(" ");
      expect(text).toMatch(/Jonas|Ilan|Gabriel/);
      expect(text).not.toMatch(/\d{2}/);
      expect(await page.getByRole("link", { name: "Voir qui vous a aimé" }).getAttribute("href")).toBe("/app/premium");
      await capture(page, "12-likes", theme);
      expect(errors).toEqual([]);
      await context.close();
    });
  }

  test("the visitors tab is honest: visits are not measured", async () => {
    const { page, context } = await signedIn(browser, world.lea);
    await open(page, "/likes");
    await page.getByRole("tab", { name: "Visiteurs" }).click();
    await page.getByText("Les visites de profil ne sont pas encore mesurées.").waitFor();
    await context.close();
  });
});

describe("likes with mazl+", () => {
  test("photos are sharp and liking a liker makes a match", async () => {
    await makePlus(world.lea);
    for (const theme of ["light", "dark"] as const) {
      const { page, context } = await signedIn(browser, world.lea, { theme });
      await open(page, "/likes");
      await cards(page).first().waitFor();
      const filter = await page.evaluate<string>("getComputedStyle(document.querySelector('ul[aria-label] li img')).filter");
      expect(filter).toBe("none");
      expect(await page.getByRole("link", { name: "Voir qui vous a aimé" }).count()).toBe(0);
      await capture(page, "13-likes-mazlplus", theme);
      await context.close();
    }
    const { page, context } = await signedIn(browser, world.lea);
    await open(page, "/likes");
    await page.getByRole("button", { name: /Voir le profil de Jonas/ }).click();
    const dialog = page.getByRole("dialog");
    await dialog.getByRole("button", { name: "Like", exact: true }).click();
    await dialog.getByText("C'est un match").waitFor();
    const href = await dialog.getByRole("link", { name: "Envoyer un message" }).getAttribute("href");
    expect(href).toMatch(/^\/app\/messages\/\d+$/);
    await context.close();
  });
});
