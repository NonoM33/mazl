import { afterAll, beforeAll, describe, expect, test } from "bun:test";
import type { Browser, Page } from "playwright";
import { launch, open, signedIn } from "./support/browser";
import { capture } from "./support/capture";
import { BASE_URL } from "./support/env";
import { createMember, grantReligiousConsent, type Member } from "./support/seed";

let browser: Browser;

beforeAll(async () => { browser = await launch(); });
afterAll(async () => { await browser.close(); });

const newMember = async (name: string): Promise<Member> => {
  const member = await createMember({ name, gender: "female", birthdate: "1993-04-02", city: "Paris", latitude: 48.85, longitude: 2.35, photos: 1 });
  await grantReligiousConsent(member);
  return member;
};

async function payWithFakeStripe(page: Page): Promise<void> {
  const pay = page.getByRole("button", { name: "Payer avec Stripe" });
  expect(await pay.isDisabled()).toBe(true);
  await page.getByRole("checkbox", { name: /renonce expressément/ }).check();
  expect(await pay.isDisabled()).toBe(false);
  await pay.click();
  await page.waitForURL(/\/pay\//);
  await page.locator("#pay").click();
  await page.waitForURL(/\/app\/premium\?checkout=success/);
}

describe("mazl+", () => {
  test("the offers show with TTC prices and the 3 months highlighted", async () => {
    const member = await newMember("Rachel");
    for (const theme of ["light", "dark"] as const) {
      const { page, context, errors } = await signedIn(browser, member, { theme });
      await open(page, "/premium");
      await page.getByRole("radio", { name: /3 mois/ }).waitFor();
      expect(await page.getByRole("radio", { name: /3 mois/ }).getAttribute("aria-checked")).toBe("true");
      expect(await page.getByRole("radio", { name: /3 mois/ }).innerText()).toMatch(/44,99\s€\sTTC/);
      expect(await page.getByRole("radio", { name: /3 mois/ }).innerText()).toMatch(/soit 15,00\s€ \/ mois/);
      expect(await page.getByRole("checkbox", { name: /renonce expressément/ }).isChecked()).toBe(false);
      expect(await page.getByRole("button", { name: "Payer avec Stripe" }).isDisabled()).toBe(true);
      await capture(page, "16-premium", theme);
      expect(errors).toEqual([]);
      await context.close();
    }
  });

  test("three months: tick the waiver, pay at the fake Stripe, come back active", async () => {
    const member = await newMember("Dina");
    for (const theme of ["light", "dark"] as const) {
      const { page, context } = await signedIn(browser, member, { theme });
      await open(page, "/premium");
      if (theme === "light") {
        await page.getByRole("radio", { name: /3 mois/ }).click();
        await payWithFakeStripe(page);
      }
      await page.getByText("mazl+ est actif").waitFor({ timeout: 35_000 });
      await page.getByRole("button", { name: "Gérer ou résilier" }).waitFor();
      await capture(page, "17-premium-actif", theme);
      await context.close();
    }
  });

  test("a pack of 5 Super Likes adds 5 purchased Super Likes", async () => {
    const member = await newMember("Esther");
    const { page, context } = await signedIn(browser, member);
    await open(page, "/premium");
    await page.getByRole("radio", { name: /^5 Super Likes/ }).click();
    await payWithFakeStripe(page);
    let balance = 0;
    for (let attempt = 0; attempt < 20 && balance !== 5; attempt += 1) {
      const res = await fetch(`${BASE_URL}/api/credits`, { headers: { Authorization: `Bearer ${member.token}` } });
      balance = ((await res.json()) as { credits: { super_like: { purchased_balance: number } } }).credits.super_like.purchased_balance;
      if (balance !== 5) await Bun.sleep(1000);
    }
    expect(balance).toBe(5);
    await context.close();
  });
});
