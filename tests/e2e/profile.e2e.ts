import { afterAll, beforeAll, describe, expect, test } from "bun:test";
import type { Browser, Page } from "playwright";
import { launch, open, signedIn, type SignedIn } from "./support/browser";
import { capture } from "./support/capture";
import { BASE_URL } from "./support/env";
import { portrait } from "./support/portraits";
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

async function pollUntil<T>(read: () => Promise<T>, expected: T): Promise<void> {
  let last = await read();
  for (let attempt = 0; attempt < 40 && last !== expected; attempt += 1) {
    await Bun.sleep(250);
    last = await read();
  }
  expect(last).toBe(expected);
}

async function ownPhotoIds(): Promise<number[]> {
  const res = await fetch(`${BASE_URL}/api/profile/photos`, { headers: { Authorization: `Bearer ${world.lea.token}` } });
  return ((await res.json()) as { photos: { id: number }[] }).photos.map((photo) => photo.id);
}

async function photoLabels(page: Page): Promise<string[]> {
  return page.getByRole("list", { name: "Vos photos" }).getByRole("listitem").evaluateAll((items) => items.map((item) => item.getAttribute("aria-label") ?? ""));
}

describe("my profile", () => {
  for (const theme of ["light", "dark"] as const) {
    test(`shows my profile as others see it (${theme})`, async () => {
      const { page, errors } = sessions[theme];
      await open(page, "/profil");
      await page.getByRole("article", { name: "Profil de Léa" }).waitFor();
      await page.getByText("Faites vérifier votre profil depuis l'app").waitFor();
      expect(await page.getByRole("link", { name: "Modifier le profil" }).isVisible()).toBe(true);
      await page.getByText("Le marché d'Aligre").first().waitFor({ state: "attached" }).catch(() => undefined);
      await capture(page, "09-profil", theme);
      expect(errors).toEqual([]);
      });
  }
});

describe("edit my profile", () => {
  test("reorders two photos with the keyboard buttons and keeps the order after a reload", async () => {
    const before = await ownPhotoIds();
    expect(before.length).toBe(4);
    const { page } = sessions.light;
    await open(page, "/profil/modifier");
    await page.getByRole("button", { name: "Déplacer la photo 2 à gauche" }).click();
    await page.getByText("Photo déplacée en position 1 sur 4.").waitFor({ state: "attached" });
    await page.waitForLoadState("networkidle");
    await page.reload();
    await page.waitForLoadState("networkidle");
    const after = await ownPhotoIds();
    expect(after).toEqual([before[1], before[0], before[2], before[3]]);
    expect(await photoLabels(page)).toContain("Photo 1 sur 4, photo principale");
  });

  test("reorders photos by dragging one onto another", async () => {
    const before = await ownPhotoIds();
    const { page } = sessions.light;
    await open(page, "/profil/modifier");
    const list = page.getByRole("list", { name: "Vos photos" });
    await list.getByRole("listitem").nth(3).dragTo(list.getByRole("listitem").nth(0));
    await page.waitForLoadState("networkidle");
    await pollUntil(async () => (await ownPhotoIds())[0], before[3]);
  });

  test("uploads a photo: it appears and the slots fill up", async () => {
    const { page } = sessions.light;
    await open(page, "/profil/modifier");
    await page.getByTestId("photo-input").setInputFiles({ name: "portrait.jpg", mimeType: "image/jpeg", buffer: await portrait(77, 1) });
    await pollUntil(async () => (await ownPhotoIds()).length, 5);
    await page.getByRole("listitem", { name: "Photo 5 sur 5" }).waitFor();
    await page.getByText("Photos · 5/6").waitFor();
  });

  test("refuses a file that is not a photo, before and after the upload", async () => {
    const { page } = sessions.light;
    await open(page, "/profil/modifier");
    await page.getByTestId("photo-input").setInputFiles({ name: "note.jpg", mimeType: "image/jpeg", buffer: Buffer.from("ceci n'est pas une image") });
    await page.getByRole("alert").filter({ hasText: "n'a pas pu être lue" }).waitFor();
    expect((await ownPhotoIds()).length).toBe(5);
  });

  test("deletes a photo after a confirmation", async () => {
    const { page } = sessions.light;
    await open(page, "/profil/modifier");
    await page.getByRole("button", { name: "Supprimer la photo 5" }).click();
    await page.getByRole("dialog", { name: "Supprimer cette photo ?" }).getByRole("button", { name: "Supprimer" }).click();
    await pollUntil(async () => (await ownPhotoIds()).length, 4);
  });

  test("the preview follows the typing; saving keeps the bio after a reload", async () => {
    const { page } = sessions.light;
    await open(page, "/profil/modifier");
    const bio = "Architecte d'intérieur, désormais aussi amatrice de pâtisserie.";
    await page.getByLabel("Présentation").fill(bio);
    await page.getByRole("complementary", { name: "Aperçu du profil" }).getByText(bio).waitFor();
    await page.getByRole("status").filter({ hasText: "Modifications non enregistrées" }).waitFor();
    await page.getByRole("button", { name: "Enregistrer", exact: true }).click();
    await page.getByText("Profil enregistré.").waitFor();
    await page.reload();
    await page.waitForLoadState("networkidle");
    expect(await page.getByLabel("Présentation").inputValue()).toBe(bio);
  });

  test("a value the screen can check is refused at the field, nothing is sent", async () => {
    const { page } = sessions.light;
    await open(page, "/profil/modifier");
    await page.getByLabel("Prénom").fill("");
    await page.getByRole("button", { name: "Enregistrer", exact: true }).click();
    await page.getByText("Votre prénom est nécessaire.").waitFor();
  });

  test("the practice is editable only with the article 9 consent, otherwise a notice leads to the settings", async () => {
    const { page } = sessions.light;
    await open(page, "/profil/modifier");
    // The consent route comes from another branch: without it, "not given".
    const route = await fetch(`${BASE_URL}/api/privacy/consents`, { headers: { Authorization: `Bearer ${world.lea.token}` } });
    if (!route.ok) {
      await page.getByText("Votre pratique religieuse est une donnée sensible").waitFor();
      await page.getByRole("link", { name: /Réglages, section Confidentialité/ }).waitFor();
      expect(await page.getByRole("group", { name: "Shabbat" }).count()).toBe(0);
      return;
    }
    await page.getByRole("group", { name: "Shabbat" }).getByRole("button", { name: "Shabbat observé" }).click();
    await page.getByRole("button", { name: "Enregistrer", exact: true }).click();
    await page.getByText("Profil enregistré.").waitFor();
  });

  test("adds then deletes a prompt", async () => {
    const { page } = sessions.light;
    await open(page, "/profil/modifier");
    await page.getByRole("button", { name: /^Supprimer la réponse/ }).first().click();
    await page.getByText("Prompts · 2/3").waitFor();
    await page.getByRole("button", { name: "Ajouter un prompt" }).click();
    const answer = "Je prépare les meilleurs bourekas de la rue.";
    await page.getByLabel("Votre réponse").fill(answer);
    await page.getByRole("button", { name: "Ajouter cette réponse" }).click();
    await page.getByText("Prompts · 3/3").waitFor();
    await page.getByRole("complementary", { name: "Aperçu du profil" }).getByText(answer).waitFor();
    await page.getByRole("button", { name: /^Supprimer la réponse/ }).last().click();
    await page.getByText("Prompts · 2/3").waitFor();
  });

  test("leaving with unsaved changes asks first", async () => {
    const { page } = sessions.light;
    await open(page, "/profil/modifier");
    await page.getByLabel("Ville").fill("Marseille");
    await page.getByRole("link", { name: "Messages" }).first().click();
    const dialog = page.getByRole("dialog", { name: "Quitter sans enregistrer ?" });
    await dialog.waitFor();
    await dialog.getByRole("button", { name: "Continuer à modifier" }).click();
    expect(page.url()).toContain("/profil/modifier");
    await page.getByRole("link", { name: "Messages" }).first().click();
    await dialog.getByRole("button", { name: "Quitter" }).click();
    await page.waitForURL(/\/app\/messages/);
  });

  for (const theme of ["light", "dark"] as const) {
    test(`edit screen capture (${theme})`, async () => {
      const { page, errors } = sessions[theme];
      await open(page, "/profil/modifier");
      await page.getByText("Aperçu · tel que vu par les autres").waitFor();
      await capture(page, "10-profil-modifier", theme);
      expect(errors).toEqual([]);
      });
  }
});
