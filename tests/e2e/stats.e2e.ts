import { afterAll, beforeAll, describe, expect, test } from "bun:test";
import type { Browser } from "playwright";
import { launch, open, signedIn, type SignedIn } from "./support/browser";
import { capture } from "./support/capture";
import { seedWorld, type World } from "./support/world";

let browser: Browser;
let world: World;
let sessions: Record<"light" | "dark", SignedIn>;

beforeAll(async () => {
  browser = await launch();
  world = await seedWorld();
  // One sign-in per theme: the pairing route is rate limited per member.
  sessions = { light: await signedIn(browser, world.lea), dark: await signedIn(browser, world.lea, { theme: "dark" }) };
});
afterAll(async () => { await browser.close(); });

describe("statistics", () => {
  test("shows the real numbers of the seeded world", async () => {
    const { page } = sessions.light;
    await open(page, "/statistiques");
    await page.getByRole("group", { name: "Likes reçus" }).getByText("3", { exact: true }).waitFor();
    await page.getByRole("group", { name: "Matchs" }).getByText("2", { exact: true }).waitFor();
    await page.getByRole("group", { name: "Conversations actives" }).getByText("1", { exact: true }).waitFor();
    await page.getByRole("group", { name: "Messages non lus" }).getByText("3", { exact: true }).waitFor();
    await page.getByText("ne sont pas encore mesurés").waitFor();
  });

  test("lists what is missing from the profile and leads to the editor", async () => {
    const { page } = sessions.light;
    await open(page, "/statistiques");
    const progress = page.getByRole("progressbar", { name: "Complétude du profil" });
    await progress.waitFor();
    // 4 of 6 photos, 3 of 3 prompts, bio, practice: only verification is complete-less.
    expect(Number(await progress.getAttribute("aria-valuenow"))).toBe(Math.round(((4 / 6 + 1 + 1 + 1 + 0) / 5) * 100));
    await page.getByText("Ajoutez 2 photos.").waitFor();
    await page.getByRole("link", { name: "Compléter" }).first().click();
    await page.waitForURL(/\/app\/profil\/modifier$/);
  });

  for (const theme of ["light", "dark"] as const) {
    test(`capture (${theme})`, async () => {
      const { page, errors } = sessions[theme];
      await open(page, "/statistiques");
      await page.getByRole("progressbar", { name: "Complétude du profil" }).waitFor();
      await capture(page, "11-statistiques", theme);
      expect(errors).toEqual([]);
      });
  }
});
