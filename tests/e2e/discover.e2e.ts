import { afterAll, beforeAll, describe, expect, test } from "bun:test";
import type { Browser, Page } from "playwright";
import { launch, open } from "./support/browser";
import { capture } from "./support/capture";
import { sessionCache, until } from "./support/discover-seed";
import { db, makePlus } from "./support/seed";
import { seedWorld, type World } from "./support/world";

let browser: Browser;
let world: World;

beforeAll(async () => {
  browser = await launch();
  world = await seedWorld();
}, 120_000);
afterAll(async () => { await browser.close(); });

const changed = (page: Page, from: string) => until(() => frontName(page), (name) => name !== from);

const front = (page: Page) => page.locator(".deck-front article");
const frontName = async (page: Page): Promise<string> => {
  const label = await front(page).first().getAttribute("aria-label");
  return (label ?? "").replace("Carte de ", "");
};
const swipeRow = async (target: string) => {
  const rows = await db<{ action: string }[]>`
    SELECT s.action FROM swipes s JOIN profiles p ON p.user_id = s.target_user_id
    WHERE s.user_id = ${world.lea.id} AND p.display_name = ${target}`;
  return rows[0]?.action ?? null;
};

const sessionFor = sessionCache(() => browser, () => world.lea);

async function openDeck(theme: "light" | "dark" = "light") {
  const session = await sessionFor(theme);
  await open(session.page, "/decouvrir");
  await front(session.page).first().waitFor();
  return session;
}

describe("Découvrir", () => {
  for (const theme of ["light", "dark"] as const) {
    test(`Léa sees her candidates, with the profile beside the card (${theme})`, async () => {
      const { page, errors } = await openDeck(theme);
      const name = await frontName(page);
      expect(world.candidates.map((member) => member.name).concat(world.likers.map((member) => member.name))).toContain(name);
      await expect(page.getByRole("article", { name: `Profil de ${name}` }).isVisible()).resolves.toBe(true);
      await expect(page.getByRole("button", { name: "Super Like" }).isVisible()).resolves.toBe(true);
      await capture(page, "03-decouvrir", theme);
      expect(errors).toEqual([]);
    });
  }

  test("→ likes: the next card comes up and the like is recorded", async () => {
    const { page } = await openDeck();
    const first = await frontName(page);
    await page.keyboard.press("ArrowRight");
    await changed(page, first);
    await until(() => swipeRow(first), (row) => row === "like");
  });

  test("← passes, Z brings the card back before anything is sent", async () => {
    const { page } = await openDeck();
    const first = await frontName(page);
    await page.keyboard.press("ArrowLeft");
    await changed(page, first);
    await page.getByText("Profil passé").waitFor();
    await page.keyboard.press("z");
    await until(() => frontName(page), (name) => name === first);
    await page.waitForTimeout(5600);
    expect(await swipeRow(first)).toBeNull();
  });

  test("a pass that is not undone is sent after five seconds", async () => {
    const { page } = await openDeck();
    const first = await frontName(page);
    await page.keyboard.press("ArrowLeft");
    expect(await swipeRow(first)).toBeNull();
    await until(() => swipeRow(first), (row) => row === "pass", 9000);
  });

  test("leaving the page sends the pending pass at once", async () => {
    const { page } = await openDeck();
    const first = await frontName(page);
    await page.keyboard.press("ArrowLeft");
    await page.getByRole("link", { name: "Accueil", exact: true }).click();
    await until(() => swipeRow(first), (row) => row === "pass", 2500);
  });

  test("I opens the detail of the profile and closes it", async () => {
    const { page } = await openDeck();
    const name = await frontName(page);
    await page.keyboard.press("i");
    await page.getByRole("dialog", { name: `Détail du profil de ${name}` }).waitFor();
    await page.keyboard.press("i");
    await page.getByRole("dialog").waitFor({ state: "detached" });
  });

  test("a click on the right half shows the next photo", async () => {
    const { page } = await openDeck();
    const lit = (nth: number) => page.locator(`.deck-front .photo-dots span:nth-child(${nth}).on`).count();
    expect(await lit(1)).toBe(1);
    await page.keyboard.press(" ");
    await until(() => lit(2), (count) => count === 1);
    await page.locator(".deck-front .deck-hit-prev").click();
    await until(() => lit(1), (count) => count === 1);
  });

  test("liking someone who already liked Léa opens the match sheet, then the conversation", async () => {
    const { page } = await openDeck();
    const likers = world.likers.map((member) => member.name);
    for (let turn = 0; turn < 40; turn += 1) {
      const name = await frontName(page);
      if (likers.includes(name)) {
        await page.keyboard.press("ArrowRight");
        await page.getByRole("dialog", { name: "C'est un match" }).waitFor();
        await page.getByText(`${name} et vous vous êtes plu.`).waitFor();
        await page.waitForTimeout(1400);
        await capture(page, "05-match", "light");
        await page.getByRole("button", { name: "Envoyer un message" }).click();
        await page.waitForURL(/\/app\/messages\/\d+$/);
          return;
      }
      await page.keyboard.press("ArrowLeft");
      await changed(page, name);
    }
    throw new Error("no liker came up in the deck");
  });

  test("saving the preferences sends them and reloads the lot", async () => {
    const { page } = await openDeck();
    await page.getByRole("button", { name: "Hommes" }).click();
    await page.locator("#distance").fill("35");
    const saved = page.waitForRequest((request) => request.method() === "PUT" && request.url().endsWith("/api/profile"));
    const reloaded = page.waitForRequest((request) => request.method() === "GET" && request.url().includes("/api/discover"));
    await page.getByRole("button", { name: "Enregistrer" }).click();
    expect(JSON.parse((await saved).postData() ?? "{}")).toMatchObject({ lookingFor: "male", distanceMax: 35 });
    await reloaded;
    const [row] = await db<{ distance_max: number; looking_for: string }[]>`SELECT distance_max, looking_for FROM profiles WHERE user_id = ${world.lea.id}`;
    expect(row).toMatchObject({ distance_max: 35, looking_for: "male" });
  });

  test("the advanced filters are locked without mazl+ and narrow the lot with it", async () => {
    const locked = await openDeck();
    await expect(locked.page.locator("#filter-denomination").isDisabled()).resolves.toBe(true);
    await expect(locked.page.getByRole("link", { name: "Découvrir mazl+" }).isVisible()).resolves.toBe(true);

    await makePlus(world.lea);
    for (const theme of ["light", "dark"] as const) {
      const { page } = await openDeck(theme);
      await expect(page.locator("#filter-denomination").isEnabled()).resolves.toBe(true);
      await page.locator("#filter-denomination").selectOption("Massorti");
      await until(async () => page.locator(".deck-front .tag", { hasText: "Massorti" }).count(), (count) => count === 1);
      expect(await page.getByRole("complementary", { name: "Profil" }).getByText("Massorti").count()).toBeGreaterThan(0);
      await capture(page, "04-decouvrir-filtres-mazlplus", theme);
    }
  });
});
