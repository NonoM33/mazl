import { afterAll, beforeAll, describe, expect, test } from "bun:test";
import type { Browser } from "playwright";
import { launch, open, signedIn } from "./support/browser";
import { capture } from "./support/capture";
import { BASE_URL } from "./support/env";
import { createEvent, createMember, db } from "./support/seed";
import { seedWorld, type World } from "./support/world";

let browser: Browser;
let world: World;

beforeAll(async () => {
  browser = await launch();
  world = await seedWorld();
});
afterAll(async () => { await browser.close(); });

describe("événements", () => {
  for (const theme of ["light", "dark"] as const) {
    test(`la liste montre les trois événements, avec date, lieu, prix et places (${theme})`, async () => {
      const { page, context, errors } = await signedIn(browser, world.lea, { theme });
      await open(page, "/evenements");
      await page.getByRole("heading", { name: "Événements", level: 1 }).waitFor();
      const cards = page.getByRole("link", { name: /Shabbat dinner|Soirée jeux|Balade guidée/ });
      await expect(cards.count()).resolves.toBeGreaterThanOrEqual(3);
      const dinner = page.getByRole("link", { name: /Shabbat dinner des 25-35 ans/ }).first();
      await expect(dinner.getByText("35,00 €").isVisible()).resolves.toBe(true);
      await expect(dinner.getByText("40 places restantes").isVisible()).resolves.toBe(true);
      await expect(page.getByRole("link", { name: /Balade guidée/ }).first().getByText("Gratuit").isVisible()).resolves.toBe(true);
      await capture(page, "18-evenements", theme);
      expect(errors).toEqual([]);
      await context.close();
    });
  }

  test("s'inscrire puis se désinscrire, le décompte suit", async () => {
    const { page, context, errors } = await signedIn(browser, world.lea);
    await open(page, `/evenements/${world.events[0]}`);
    await page.getByRole("heading", { name: "Shabbat dinner des 25-35 ans", level: 1 }).waitFor();
    await page.getByRole("button", { name: "Je m'inscris" }).click();
    await page.getByText("Vous êtes inscrit(e) à cet événement.").waitFor();
    await expect(page.getByText("1 inscrit · 39 places restantes").isVisible()).resolves.toBe(true);
    await capture(page, "19-evenement-detail", "light");
    await page.reload();
    await page.getByRole("button", { name: "Annuler mon inscription" }).waitFor();
    await page.getByRole("button", { name: "Annuler mon inscription" }).click();
    await page.getByRole("button", { name: "Je m'inscris" }).waitFor();
    await expect(page.getByText("0 inscrit · 40 places restantes").isVisible()).resolves.toBe(true);
    expect(errors).toEqual([]);
    await context.close();
  });

  test("le détail en sombre", async () => {
    const { page, context } = await signedIn(browser, world.lea, { theme: "dark" });
    await open(page, `/evenements/${world.events[1]}`);
    await page.getByRole("heading", { name: "Soirée jeux de société", level: 1 }).waitFor();
    await capture(page, "19-evenement-detail", "dark");
    await context.close();
  });

  test("un événement complet affiche « Complet » et ne s'accepte pas", async () => {
    const id = await createEvent({ title: "Cercle de lecture", description: "Une seule place, déjà prise.", type: "social", location: "Paris 5e", address: "Librairie", inDays: 4, time: "19:00", price: 0, maxAttendees: 1 });
    const other = await createMember({ name: "Samuel", gender: "male", birthdate: "1990-01-10", city: "Paris", latitude: 48.85, longitude: 2.35, photos: 1 });
    const joined = await fetch(`${BASE_URL}/api/events/${id}/rsvp`, { method: "POST", headers: { Authorization: `Bearer ${other.token}`, "Content-Type": "application/json" }, body: JSON.stringify({ status: "going" }) });
    expect(joined.ok).toBe(true);
    const { page, context } = await signedIn(browser, world.lea);
    await open(page, `/evenements/${id}`);
    await page.getByRole("heading", { name: "Cercle de lecture", level: 1 }).waitFor();
    await expect(page.getByRole("button", { name: "Complet" }).isDisabled()).resolves.toBe(true);
    await context.close();
  });

  test("une inscription refusée par le serveur est dite en français (événement passé)", async () => {
    const id = await createEvent({ title: "Vernissage", description: "Déjà fini.", type: "social", location: "Paris 2e", address: "Galerie", inDays: 3, time: "19:00", price: 0, maxAttendees: 10 });
    const { page, context } = await signedIn(browser, world.lea);
    await open(page, `/evenements/${id}`);
    await page.getByRole("button", { name: "Je m'inscris" }).waitFor();
    await db`UPDATE events SET date = CURRENT_DATE - 1 WHERE id = ${id}`;
    await page.getByRole("button", { name: "Je m'inscris" }).click();
    await page.getByRole("status").getByText("Événement passé").waitFor();
    await context.close();
  });

  test("un événement inconnu dit « Événement introuvable »", async () => {
    const { page, context } = await signedIn(browser, world.lea);
    await open(page, "/evenements/999999");
    await page.getByRole("heading", { name: "Événement introuvable" }).first().waitFor();
    await context.close();
  });
});
