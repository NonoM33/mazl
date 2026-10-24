import type { Page } from "playwright";
import { CAPTURES_DIR } from "./env";

// Screenshots for docs/web/captures: `<number>-<screen>-<theme>.png`.
export async function capture(page: Page, name: string, theme: "light" | "dark"): Promise<void> {
  await page.waitForLoadState("networkidle");
  await page.evaluate("document.fonts.ready.then(() => true)");
  await page.waitForTimeout(400);
  await page.screenshot({ path: `${CAPTURES_DIR}${name}-${theme === "light" ? "clair" : "sombre"}.png` });
}
