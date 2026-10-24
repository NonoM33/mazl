import { afterAll, beforeAll, describe, expect, test } from "bun:test";
import type { Browser } from "playwright";
import { launch, open } from "./support/browser";
import { capture } from "./support/capture";
import { sessionCache, until } from "./support/discover-seed";
import { db } from "./support/seed";
import { seedWorld, type World } from "./support/world";

let browser: Browser;
let world: World;

beforeAll(async () => {
  browser = await launch();
  world = await seedWorld();
}, 120_000);
afterAll(async () => { await browser.close(); });

const sessionFor = sessionCache(() => browser, () => world.lea);

describe("Accueil", () => {
  for (const theme of ["light", "dark"] as const) {
    test(`greets Léa, lists the daily picks and the shortcuts (${theme})`, async () => {
      const { page, errors } = await sessionFor(theme);
      await open(page, "/");
      await page.getByRole("heading", { name: "Bonjour Léa" }).waitFor();
      await page.getByRole("heading", { name: "Sélections du jour" }).waitFor();
      expect(await page.locator(".pick-tile").count()).toBe(5);
      await expect(page.getByText(/Mis à jour dans \d\d:\d\d:\d\d/).isVisible()).resolves.toBe(true);
      await expect(page.getByRole("region", { name: "Le mot du Shadchan" }).isVisible()).resolves.toBe(true);
      await expect(page.locator("a.shortcut", { hasText: "Likes" }).isVisible()).resolves.toBe(true);
      await expect(page.getByText("Vérifiez votre profil depuis l'app").isVisible()).resolves.toBe(true);
      await capture(page, "02-accueil", theme);
      expect(errors).toEqual([]);
    });
  }

  test("the Shadchan names only what Léa really shares", async () => {
    const { page } = await sessionFor("light");
    await open(page, "/");
    const text = (await page.getByRole("region", { name: "Le mot du Shadchan" }).innerText()).replace(/\s+/g, " ");
    expect(text).toMatch(/Vous partagez : (Massorti|Cacher à la maison|Shabbat en partie)/);
  });

  test("a pick opens its profile and Like records the swipe", async () => {
    const { page } = await sessionFor("light");
    await open(page, "/");
    const tile = page.locator(".pick-tile").first();
    const name = ((await tile.getAttribute("aria-label")) ?? "").replace("Voir le profil de ", "");
    await tile.click();
    await page.getByRole("dialog").getByRole("article", { name: `Profil de ${name}` }).waitFor();
    await page.getByRole("dialog").getByRole("button", { name: "Like" }).click();
    await page.getByRole("dialog").waitFor({ state: "detached" }).catch(() => undefined);
    await until(async () => {
      const rows = await db<{ action: string }[]>`SELECT s.action FROM swipes s JOIN profiles p ON p.user_id = s.target_user_id WHERE s.user_id = ${world.lea.id} AND p.display_name = ${name}`;
      return rows[0]?.action ?? null;
    }, (action) => action === "like");
  });
});
