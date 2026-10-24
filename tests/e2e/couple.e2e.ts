import { afterAll, beforeAll, describe, expect, test } from "bun:test";
import type { Browser, Page } from "playwright";
import { launch, open, signedIn } from "./support/browser";
import { capture } from "./support/capture";
import { BASE_URL } from "./support/env";
import { seedCoupleContent } from "./support/couple-seed";
import { createMember, match, type Member } from "./support/seed";
import { seedWorld, type World } from "./support/world";

let browser: Browser;
let world: World;

const auth = (member: Member) => ({ Authorization: `Bearer ${member.token}`, "Content-Type": "application/json" });
const call = async <T>(member: Member, method: string, path: string, body?: unknown): Promise<T> => {
  const res = await fetch(`${BASE_URL}${path}`, { method, headers: auth(member), body: body === undefined ? undefined : JSON.stringify(body) });
  if (!res.ok) throw new Error(`${method} ${path} → ${res.status}`);
  return (await res.json()) as T;
};
const spec = (name: string, gender: "male" | "female") => ({ name, gender, birthdate: "1992-05-05", city: "Paris", latitude: 48.85, longitude: 2.35, photos: 1 });
async function matchedPair(a: string, b: string): Promise<readonly [Member, Member]> {
  const first = await createMember(spec(a, "female"));
  const second = await createMember(spec(b, "male"));
  await match(first, second);
  return [first, second];
}
const nav = (page: Page) => page.getByRole("navigation", { name: "Navigation principale" });

beforeAll(async () => {
  browser = await launch();
  world = await seedWorld();
  await seedCoupleContent();
});
afterAll(async () => { await browser.close(); });

describe("navigation du couple", () => {
  test("Myriam, en couple, a la navigation du couple et /decouvrir la ramène à /couple", async () => {
    const { page, context, errors } = await signedIn(browser, world.couple.myriam);
    await open(page, "/");
    await nav(page).getByRole("link", { name: "Notre espace" }).waitFor();
    await expect(nav(page).getByRole("link", { name: "Découvrir" }).count()).resolves.toBe(0);
    await open(page, "/decouvrir");
    await page.waitForURL(/\/app\/couple$/);
    expect(errors).toEqual([]);
    await context.close();
  });
});

describe("Notre espace", () => {
  test("répondre à la question du jour ; la réponse du partenaire n'apparaît que quand les deux ont répondu", async () => {
    const { myriam, daniel } = world.couple;
    const { page, context, errors } = await signedIn(browser, myriam);
    await open(page, "/couple");
    await page.getByRole("heading", { name: "Daniel", level: 2 }).waitFor();
    await page.getByLabel("Votre réponse").fill("Un marché le dimanche matin.");
    await page.getByRole("button", { name: "Répondre" }).click();
    await page.getByText("En attente de la réponse de Daniel.").waitFor();
    const { couple } = await call<{ couple: { id: number } }>(daniel, "GET", "/api/couple");
    const { question } = await call<{ question: { id: number } }>(daniel, "GET", `/api/couple/${couple.id}/question`);
    await call(daniel, "POST", `/api/couple/${couple.id}/question/${question.id}/answer`, { answer: "Une librairie, sans hésiter." });
    await page.reload();
    await page.getByText("Une librairie, sans hésiter.").waitFor();
    await expect(page.getByText("Un marché le dimanche matin.").isVisible()).resolves.toBe(true);
    expect(errors).toEqual([]);
    await context.close();
  });

  test("ajouter une date, un souvenir et un rêve", async () => {
    const { page, context } = await signedIn(browser, world.couple.myriam);
    await open(page, "/couple");
    await page.getByRole("button", { name: "Ajouter une date" }).click();
    await page.getByLabel("Titre", { exact: true }).fill("Notre premier dîner");
    await page.getByLabel("Date", { exact: true }).fill("2025-03-14");
    await page.getByRole("dialog").getByRole("button", { name: "Ajouter" }).click();
    await page.getByText("Notre premier dîner").waitFor();
    await page.getByRole("button", { name: "Ajouter un souvenir" }).click();
    await page.getByLabel("Titre", { exact: true }).fill("Le marché d'Aligre");
    await page.getByLabel("Description", { exact: true }).fill("On y a mangé nos premiers bourekas.");
    await page.getByRole("dialog").getByRole("button", { name: "Ajouter" }).click();
    await page.getByText("On y a mangé nos premiers bourekas.").waitFor();
    await page.getByLabel("Liste de rêves").getByRole("button", { name: "Ajouter" }).click();
    await page.getByLabel("Ce que vous voulez vivre ensemble").fill("Un week-end à Lisbonne");
    await page.getByRole("dialog").getByRole("button", { name: "Ajouter" }).click();
    await page.getByText("Un week-end à Lisbonne").waitFor();
    await page.reload();
    await page.getByText("Notre premier dîner").waitFor();
    await capture(page, "20-couple-espace", "light");
    await context.close();
  });

  test("l'espace en sombre", async () => {
    const { page, context } = await signedIn(browser, world.couple.myriam, { theme: "dark" });
    await open(page, "/couple");
    await page.getByText("Notre premier dîner").waitFor();
    await capture(page, "20-couple-espace", "dark");
    await context.close();
  });

  test("changer le statut de la relation", async () => {
    const { page, context } = await signedIn(browser, world.couple.myriam);
    await open(page, "/couple");
    await page.getByRole("button", { name: "Fiancés" }).click();
    await page.getByRole("button", { name: "Fiancés", pressed: true }).waitFor();
    await context.close();
  });
});

describe("activités, calendrier, événements", () => {
  for (const theme of ["light", "dark"] as const) {
    test(`activités : enregistrer, passer, retrouver dans « Enregistrées » (${theme})`, async () => {
      const { page, context } = await signedIn(browser, world.couple.daniel, { theme });
      await open(page, "/couple/activites");
      await page.getByRole("heading", { name: theme === "light" ? "Atelier de poterie à deux" : "Dîner casher aux chandelles" }).waitFor();
      await capture(page, "21-couple-activites", theme);
      if (theme === "light") {
        await page.getByRole("listitem").filter({ hasText: "Atelier de poterie à deux" }).getByRole("button", { name: "Enregistrer" }).click();
        await page.getByRole("listitem").filter({ hasText: "Balade en kayak" }).getByRole("button", { name: "Passer" }).click();
        await page.getByRole("heading", { name: "Balade en kayak sur la Marne" }).waitFor({ state: "detached" });
      }
      if (theme === "light") {
        await page.getByRole("tab", { name: "Enregistrées" }).click();
        await page.getByRole("heading", { name: "Atelier de poterie à deux" }).waitFor();
      }
      await context.close();
    });

    test(`calendrier : fêtes à venir et dates du couple (${theme})`, async () => {
      const { page, context } = await signedIn(browser, world.couple.myriam, { theme });
      await open(page, "/couple/calendrier");
      await expect(page.getByRole("region", { name: "Prochaines fêtes" }).getByRole("listitem").count()).resolves.toBeGreaterThanOrEqual(5);
      await page.getByText("Notre premier dîner").waitFor();
      await capture(page, "22-couple-calendrier", theme);
      await context.close();
    });
  }

  test("événements du couple : s'inscrire, retrouver dans « Mes inscriptions », annuler", async () => {
    const { page, context } = await signedIn(browser, world.couple.daniel);
    await open(page, "/couple/evenements");
    const brunch = page.getByRole("listitem").filter({ hasText: "Brunch du dimanche en couple" });
    await brunch.getByRole("button", { name: "S'inscrire" }).click();
    await brunch.getByRole("button", { name: "Annuler l'inscription" }).waitFor();
    await expect(page.getByRole("listitem").filter({ hasText: "Week-end en Normandie" }).getByRole("button", { name: "Paiement requis" }).isDisabled()).resolves.toBe(true);
    await capture(page, "23-couple-evenements", "light");
    await page.getByRole("tab", { name: "Mes inscriptions" }).click();
    await page.getByRole("heading", { name: "Brunch du dimanche en couple" }).waitFor();
    await page.getByRole("button", { name: "Annuler l'inscription" }).click();
    await page.getByRole("button", { name: "Oui, annuler" }).click();
    await page.getByText("Aucune inscription").waitFor();
    await context.close();
  });
});

describe("demande de mode couple", () => {
  test("la demande reçue s'accepte depuis la bannière : Mazel Tov, puis navigation du couple", async () => {
    const [sender, receiver] = await matchedPair("Alma", "Gabin");
    await call(sender, "POST", "/api/couple/request", { target_user_id: receiver.id });
    const { page, context, errors } = await signedIn(browser, receiver);
    await open(page, "/");
    await page.getByText("Alma souhaite activer le mode couple avec vous").waitFor();
    await page.getByRole("button", { name: "Accepter" }).click();
    await page.getByRole("heading", { name: "Mazel Tov" }).waitFor();
    await nav(page).getByRole("link", { name: "Notre espace" }).waitFor();
    expect(errors).toEqual([]);
    await context.close();
  });

  test("l'émetteur voit « Demande envoyée » et peut l'annuler", async () => {
    const [sender, receiver] = await matchedPair("Ilana", "Tom");
    await call(sender, "POST", "/api/couple/request", { target_user_id: receiver.id });
    const { page, context } = await signedIn(browser, sender);
    await open(page, "/");
    await page.getByText("Demande envoyée à Tom").waitFor();
    await page.getByRole("button", { name: "Annuler la demande" }).click();
    await page.getByText("Demande envoyée à Tom").waitFor({ state: "detached" });
    await context.close();
  });

  test("refuser (« Non merci ») fait disparaître la bannière sans créer de couple", async () => {
    const [sender, receiver] = await matchedPair("Rina", "Ethan");
    await call(sender, "POST", "/api/couple/request", { target_user_id: receiver.id });
    const { page, context } = await signedIn(browser, receiver);
    await open(page, "/");
    await page.getByRole("button", { name: "Non merci" }).click();
    await page.getByText("Rina souhaite activer le mode couple avec vous").waitFor({ state: "detached" });
    await expect(nav(page).getByRole("link", { name: "Découvrir" }).isVisible()).resolves.toBe(true);
    await context.close();
  });

  test("quitter le mode couple met fin au couple pour les deux", async () => {
    const [first, second] = await matchedPair("Dalia", "Noé");
    const { request } = await call<{ request: { id: number } }>(first, "POST", "/api/couple/request", { target_user_id: second.id });
    await call(second, "PUT", `/api/couple/request/${request.id}`, { action: "accept" });
    const { page, context } = await signedIn(browser, first);
    await open(page, "/couple");
    await page.getByRole("button", { name: "Quitter le mode couple" }).click();
    await page.getByRole("dialog").getByRole("button", { name: "Quitter le mode couple" }).click();
    await nav(page).getByRole("link", { name: "Découvrir" }).waitFor();
    const after = await call<{ couple: unknown }>(second, "GET", "/api/couple");
    expect(after.couple).toBeNull();
    await context.close();
  });
});
