// Captures de la maquette via file:// (Playwright, WebGL logiciel).
const { chromium } = require("/Users/nono/.hermes/hermes-agent/node_modules/playwright");
const path = require("node:path");
const url = "file://" + path.join(__dirname, "mazl-vitrine-maquette.html");
const out = (n) => path.join(__dirname, "captures", n);
(async () => {
  const browser = await chromium.launch({ args: ["--use-gl=angle", "--use-angle=swiftshader", "--enable-unsafe-swiftshader"] });
  const errors = [];
  const reqs = [];
  const page = await browser.newPage({ viewport: { width: 1440, height: 900 } });
  page.on("pageerror", (e) => errors.push(String(e)));
  page.on("console", (m) => { if (m.type() === "error") errors.push(m.text()); });
  page.on("request", (r) => { if (!r.url().startsWith("file:") && !r.url().startsWith("data:")) reqs.push(r.url()); });
  await page.goto(url);
  await page.waitForTimeout(3500);
  await page.screenshot({ path: out("desktop-01-hero.png") });
  const shots = [["desktop-02-hero-fil", 1100, null], ["desktop-03-verification", null, "#verification"], ["desktop-04-compatibilite", null, "#compatibilite"], ["desktop-05-chabbat", null, "#chabbat"], ["desktop-06-parcours", null, "#couple"], ["desktop-07-pied", "end", null]];
  for (const [name, y, sel] of shots) {
    if (sel) await page.evaluate((s) => { document.documentElement.style.scrollBehavior = "auto"; const el = document.querySelector(s); window.scrollTo(0, el.getBoundingClientRect().top + window.scrollY - 40); }, sel);
    else await page.evaluate((v) => { document.documentElement.style.scrollBehavior = "auto"; window.scrollTo(0, v === "end" ? document.body.scrollHeight : v); }, y);
    await page.waitForTimeout(2500);
    await page.screenshot({ path: out(name + ".png") });
  }
  const m = await browser.newPage({ viewport: { width: 390, height: 844 }, deviceScaleFactor: 2, hasTouch: true, isMobile: true });
  m.on("pageerror", (e) => errors.push(String(e)));
  await m.goto(url);
  await m.waitForTimeout(3500);
  await m.screenshot({ path: out("mobile-01-hero.png") });
  console.log("errors:", errors, "network:", reqs);
  await browser.close();
})();
