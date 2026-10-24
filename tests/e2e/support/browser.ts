import { chromium, type Browser, type BrowserContext, type Page } from "playwright";
import { solve } from "../../../web/src/features/auth/pow-solver";
import { BASE_URL } from "./env";
import type { Member } from "./seed";

// Signs a browser in through the real QR flow: the "phone" (the member's
// mobile JWT) scans and approves, the poll sets the web session cookie, which
// is handed to the browser context.

export async function launch(): Promise<Browser> {
  return chromium.launch();
}

// Each sign-in comes from its own documentation address (RFC 5737), so the
// per-address limits of the sign-in routes do not stop a long suite.
let addressSeed = 0;
const nextAddress = () => `198.51.100.${(addressSeed++ % 250) + 1}`;

async function webSessionCookie(member: Member): Promise<string> {
  const from = { "X-Forwarded-For": nextAddress() };
  const post = (path: string, body: unknown, headers: Record<string, string> = {}) =>
    fetch(`${BASE_URL}${path}`, { method: "POST", headers: { "Content-Type": "application/json", ...from, ...headers }, body: JSON.stringify(body) });
  const challenge = (await (await post("/api/web/auth/challenge", {})).json()) as { challenge: string; difficulty: number };
  const nonce = await solve(challenge.challenge, challenge.difficulty);
  const created = (await (await post("/api/web/auth/qr", { pow: { challenge: challenge.challenge, nonce } }, { "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) Chrome/140.0 Safari/537.36" })).json()) as { pairing: { id: string; code: string; browser_secret: string } };
  const phone = { Authorization: `Bearer ${member.token}` };
  const scanned = await post("/api/web/pairings/scan", { code: created.pairing.code }, phone);
  if (!scanned.ok) throw new Error(`scan failed ${scanned.status}`);
  const approved = await post(`/api/web/pairings/${created.pairing.id}/approve`, {}, phone);
  if (!approved.ok) throw new Error(`approve failed ${approved.status}`);
  const poll = await fetch(`${BASE_URL}/api/web/auth/qr/${created.pairing.id}`, { headers: { "X-Pairing-Secret": created.pairing.browser_secret, ...from } });
  const cookie = poll.headers.get("set-cookie") ?? "";
  const value = /__Host-mazl_web=([^;]+)/.exec(cookie)?.[1];
  if (!value) throw new Error(`no session cookie (${poll.status})`);
  return value;
}

export interface SignedIn { readonly context: BrowserContext; readonly page: Page; readonly errors: string[] }

export async function signedIn(browser: Browser, member: Member, options: { theme?: "light" | "dark"; width?: number; height?: number } = {}): Promise<SignedIn> {
  const context = await browser.newContext({
    viewport: { width: options.width ?? 1440, height: options.height ?? 900 },
    colorScheme: options.theme ?? "light",
    locale: "fr-FR",
    timezoneId: "Europe/Paris",
    deviceScaleFactor: 2,
  });
  await context.addCookies([{ name: "__Host-mazl_web", value: await webSessionCookie(member), domain: new URL(BASE_URL).hostname, path: "/", httpOnly: true, secure: true, sameSite: "Strict" }]);
  // Keep Shabbat from covering the screens when the suite runs on a Friday night.
  await context.addInitScript({ content: `localStorage.setItem("mazl.shabbat", ${JSON.stringify(JSON.stringify({ enabled: false, includeHolidays: true, bufferMin: 18 }))});` });
  const page = await context.newPage();
  const errors: string[] = [];
  page.on("pageerror", (error) => errors.push(String(error)));
  return { context, page, errors };
}

export async function open(page: Page, path: string): Promise<void> {
  await page.goto(`${BASE_URL}/app${path === "/" ? "" : path}`);
  await page.waitForLoadState("networkidle");
}
