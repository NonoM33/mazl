import { afterAll, beforeAll, describe, expect, test } from "bun:test";
import type { Browser } from "playwright";
import { launch, open, signedIn } from "./support/browser";
import { capture } from "./support/capture";
import { BASE_URL } from "./support/env";
import { createMember, grantReligiousConsent, type Member } from "./support/seed";

let browser: Browser;
let member: Member;

// The export route belongs to another branch: without it, that test is skipped.
const exportExists = (await fetch(`${BASE_URL}/api/users/me/export`)).status !== 404;

beforeAll(async () => {
  browser = await launch();
  member = await createMember({ name: "Sarah", gender: "female", birthdate: "1993-04-02", city: "Paris", latitude: 48.85, longitude: 2.35, photos: 1 });
  await grantReligiousConsent(member);
});
afterAll(async () => { await browser.close(); });

describe("settings", () => {
  test("the sections show, the theme can be dark, and the screens are captured", async () => {
    const other = await signedIn(browser, member);
    await open(other.page, "/");
    for (const theme of ["light", "dark"] as const) {
      const { page, context, errors } = await signedIn(browser, member, { theme });
      await open(page, "/reglages");
      for (const title of ["Compte", "Apparence", "Pause Shabbat", "Mode discret", "Ordinateurs connectés", "Confidentialité", "Vérification", "mazl+", "Supprimer mon compte"]) {
        await page.getByRole("heading", { name: title, exact: true }).first().waitFor();
      }
      await page.getByText(member.email).waitFor();
      await capture(page, "14-reglages", theme);
      await page.locator("#ordinateurs").scrollIntoViewIfNeeded();
      await page.evaluate("document.getElementById('ordinateurs')?.scrollIntoView({ block: 'start' })");
      await page.getByText("Cet ordinateur").first().waitFor();
      await capture(page, "15-reglages-ordinateurs", theme);
      expect(errors).toEqual([]);
      await context.close();
    }
    await other.context.close();
  });

  test("choosing the dark theme applies it", async () => {
    const { page, context } = await signedIn(browser, member, { theme: "light" });
    await open(page, "/reglages");
    await page.getByRole("radio", { name: "Sombre" }).click();
    expect(await page.evaluate<string>("document.documentElement.dataset.theme")).toBe("dark");
    await context.close();
  });

  test("revoking the other computers signs the first one out", async () => {
    const first = await signedIn(browser, member);
    const second = await signedIn(browser, member);
    await open(first.page, "/reglages");
    await open(second.page, "/reglages#ordinateurs");
    await second.page.getByRole("button", { name: "Déconnecter les autres ordinateurs" }).click();
    await second.page.getByRole("button", { name: "Déconnecter les autres ordinateurs" }).waitFor({ state: "detached" });
    await first.page.reload();
    await first.page.waitForURL(/\/app\/connexion$/);
    await open(second.page, "/reglages");
    await second.page.getByText("Cet ordinateur").first().waitFor();
    await first.context.close();
    await second.context.close();
  });

  test.skipIf(!exportExists)("the export downloads a file that names itself", async () => {
    const { page, context } = await signedIn(browser, member);
    await open(page, "/reglages");
    const download = page.waitForEvent("download");
    await page.getByRole("button", { name: "Télécharger mes données (JSON)" }).click();
    const file = await (await download).createReadStream();
    const chunks: Buffer[] = [];
    for await (const chunk of file) chunks.push(Buffer.from(chunk as Buffer));
    expect(Buffer.concat(chunks).toString("utf8")).toContain("mazl-export");
    await context.close();
  });
});
