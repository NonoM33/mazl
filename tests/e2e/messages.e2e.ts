import { afterAll, beforeAll, describe, expect, test } from "bun:test";
import type { Browser, Page } from "playwright";
import { launch, open, signedIn } from "./support/browser";
import { capture } from "./support/capture";
import { BASE_URL } from "./support/env";
import { say } from "./support/seed";
import { seedWorld, type World } from "./support/world";

let browser: Browser;
let world: World;

beforeAll(async () => {
  browser = await launch();
  world = await seedWorld();
});
afterAll(async () => { await browser.close(); });

const noamRow = (page: Page) => page.getByRole("button", { name: /^Noam/ });
const thread = (page: Page) => page.getByRole("region", { name: /Conversation avec Noam/ });
const bubbleOf = (page: Page, text: string) => page.locator(".msg", { hasText: text });

async function unreadFromApi(): Promise<number> {
  const res = await fetch(`${BASE_URL}/api/conversations`, { headers: { Authorization: `Bearer ${world.lea.token}` } });
  const body = (await res.json()) as { conversations: { id: number; unreadCount: number }[] };
  return body.conversations.find((item) => item.id === world.noamConversation)?.unreadCount ?? -1;
}

describe("messages", () => {
  test("the list shows the unread badge, new matches and conversations", async () => {
    const { page, context } = await signedIn(browser, world.lea);
    await open(page, "/messages");
    await page.getByText("Nouveaux · 1").waitFor();
    await page.getByText("Conversations · 1").waitFor();
    await noamRow(page).waitFor();
    expect(await noamRow(page).getAttribute("aria-label")).toContain("3 non lus");
    await page.getByRole("button", { name: /^Adam/ }).waitFor();
    await context.close();
  });

  test("opening Noam's conversation marks it read", async () => {
    expect(await unreadFromApi()).toBe(3);
    const { page, context } = await signedIn(browser, world.lea);
    await open(page, "/messages");
    await noamRow(page).click();
    await page.waitForURL(new RegExp(`/app/messages/${world.noamConversation}$`));
    await thread(page).getByText("Le fromager du fond").waitFor();
    await page.waitForFunction(async (id) => {
      const res = await fetch("/api/conversations", { headers: { "X-Mazl-Web": "1" } });
      const body = (await res.json()) as { conversations: { id: number; unreadCount: number }[] };
      return body.conversations.find((item) => item.id === id)?.unreadCount === 0;
    }, world.noamConversation);
    expect(await noamRow(page).getAttribute("aria-label")).not.toContain("non lu");
    await context.close();
  });

  // Captures come before the tests that change the conversation.
  for (const theme of ["light", "dark"] as const) {
    test(`screenshots: conversation, search and actions (${theme})`, async () => {
      const { page, context, errors } = await signedIn(browser, world.lea, { theme });
      await open(page, `/messages/${world.noamConversation}`);
      await thread(page).getByText("Le fromager du fond").waitFor();
      await capture(page, "06-messages", theme);

      await page.keyboard.press("Control+k");
      await page.keyboard.type("Ad");
      await page.getByRole("button", { name: /^Adam/ }).waitFor();
      await capture(page, "07-messages-recherche", theme);
      await page.keyboard.press("Escape");

      await bubbleOf(page, "Le fromager du fond").hover();
      await page.getByRole("button", { name: "Plus d'actions" }).first().click();
      await page.getByRole("menu", { name: "Actions sur le message" }).waitFor();
      await capture(page, "08-messages-actions", theme);
      expect(errors).toEqual([]);
      await context.close();
    });
  }

  test("a sent message appears at once and is stored", async () => {
    const { page, context } = await signedIn(browser, world.lea);
    await open(page, `/messages/${world.noamConversation}`);
    const box = page.getByRole("textbox", { name: "Votre message" });
    await box.fill("Plutôt marché, sans hésiter.");
    const stored = page.waitForResponse((r) => r.request().method() === "POST" && r.url().endsWith(`/api/conversations/${world.noamConversation}/messages`));
    await box.press("Enter");
    await thread(page).getByText("Plutôt marché, sans hésiter.").waitFor({ timeout: 1500 });
    expect((await stored).status()).toBe(200);
    const res = await fetch(`${BASE_URL}/api/conversations/${world.noamConversation}/messages?limit=30`, { headers: { Authorization: `Bearer ${world.lea.token}` } });
    const body = (await res.json()) as { messages: { content: string }[] };
    expect(body.messages.some((message) => message.content === "Plutôt marché, sans hésiter.")).toBe(true);
    await context.close();
  });

  test("a message sent by Noam through the API shows up in real time", async () => {
    const { page, context } = await signedIn(browser, world.lea);
    await open(page, `/messages/${world.noamConversation}`);
    await thread(page).getByText("Le fromager du fond").waitFor();
    await Bun.sleep(1500); // let the socket connect
    await say(world.noam, world.noamConversation, "Je réserve une table pour dimanche ?");
    await thread(page).getByText("Je réserve une table pour dimanche ?").waitFor({ timeout: 8000 });
    await context.close();
  });

  test("Cmd/Ctrl+K searches by name only", async () => {
    const { page, context } = await signedIn(browser, world.lea);
    await open(page, "/messages");
    await page.keyboard.press("Control+k");
    await page.keyboard.type("Ad");
    await page.getByRole("button", { name: /^Adam/ }).waitFor();
    expect(await noamRow(page).count()).toBe(0);
    await page.keyboard.press("Escape");
    await noamRow(page).waitFor();
    await page.keyboard.press("Control+k");
    await page.keyboard.type("marché");
    expect(await page.getByRole("button", { name: /^(Noam|Adam)/ }).count()).toBe(0);
    await context.close();
  });

  test("reacting with a heart, then unsending my own message", async () => {
    const { page, context } = await signedIn(browser, world.lea);
    await open(page, `/messages/${world.noamConversation}`);
    const theirs = bubbleOf(page, "Le fromager du fond");
    await theirs.hover();
    await theirs.getByRole("button", { name: "Réagir ❤️" }).click();
    await theirs.getByRole("img", { name: /Réactions : ❤️ 1/ }).waitFor();

    const mine = bubbleOf(page, "Plutôt marché, sans hésiter.");
    await mine.hover();
    await mine.getByRole("button", { name: "Plus d'actions" }).click();
    await page.getByRole("menuitem", { name: "Retirer" }).click();
    await thread(page).getByText("Message retiré").waitFor();
    await context.close();
  });

  test("an unknown conversation says so", async () => {
    const { page, context } = await signedIn(browser, world.lea);
    await open(page, "/messages/999999");
    await page.getByText("Conversation introuvable").waitFor();
    await context.close();
  });
});
