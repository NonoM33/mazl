import { afterAll, beforeAll, describe, expect, test } from "bun:test";
import type { Browser } from "playwright";
import { launch, open, signedIn } from "./support/browser";
import { capture } from "./support/capture";
import { BASE_URL } from "./support/env";
import { createMember, grantReligiousConsent, type Member } from "./support/seed";

let browser: Browser;
let member: Member;

beforeAll(async () => {
  browser = await launch();
  member = await createMember({ name: "Sarah", gender: "female", birthdate: "1993-04-02", city: "Paris", latitude: 48.85, longitude: 2.35, photos: 1 });
  await grantReligiousConsent(member);
});
afterAll(async () => { await browser.close(); });

describe("sign-in", () => {
  for (const theme of ["light", "dark"] as const) {
    test(`a signed-out visitor gets the QR sign-in page (${theme})`, async () => {
      const context = await browser.newContext({ viewport: { width: 1440, height: 900 }, colorScheme: theme, locale: "fr-FR", deviceScaleFactor: 2 });
      const page = await context.newPage();
      await page.goto(`${BASE_URL}/app/messages`);
      await page.waitForURL(/\/app\/connexion$/);
      await page.getByRole("img", { name: /QR code de connexion/ }).waitFor();
      await capture(page, "01-connexion", theme);
      await context.close();
    });
  }

  test("the phone approves the pairing and the browser enters the connected space", async () => {
    const { page, context, errors } = await signedIn(browser, member);
    await open(page, "/");
    await expect(page.getByRole("navigation", { name: "Navigation principale" }).isVisible()).resolves.toBe(true);
    expect(errors).toEqual([]);
    await context.close();
  });

  test("a member who never answered meets the art. 9 consent first; refusing is a real option", async () => {
    const fresh = await createMember({ name: "Nina", gender: "female", birthdate: "1995-01-20", city: "Paris", latitude: 48.85, longitude: 2.35, photos: 1, consent: false });
    const { page, context } = await signedIn(browser, fresh);
    await open(page, "/");
    await page.getByRole("heading", { name: "Votre pratique religieuse, avec votre accord" }).waitFor();
    const accept = page.getByRole("button", { name: "J'accepte" });
    expect(await accept.isDisabled()).toBe(true);
    await page.getByRole("button", { name: "Continuer sans" }).click();
    await page.getByRole("navigation", { name: "Navigation principale" }).waitFor();
    const consents = await page.request.get(`${BASE_URL}/api/privacy/consents`, { headers: { "X-Mazl-Web": "1" } });
    expect(((await consents.json()) as { consents: { religious_data: { granted: boolean } } }).consents.religious_data.granted).toBe(false);
    await context.close();
  });

  test("signing out ends the web session: the next visit is the sign-in page", async () => {
    const { page, context } = await signedIn(browser, member);
    await open(page, "/reglages");
    const response = await page.request.post(`${BASE_URL}/api/web/auth/logout`, { headers: { "X-Mazl-Web": "1", Origin: BASE_URL }, data: {} });
    expect(response.ok()).toBe(true);
    await open(page, "/");
    await page.waitForURL(/\/app\/connexion$/);
    await context.close();
  });
});
