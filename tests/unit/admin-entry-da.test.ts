import { describe, expect, test } from "bun:test";
import { Hono } from "hono";
import { registerAdminEntryRoutes } from "../../src/features/admin/admin.entry-routes";

const app = new Hono();
registerAdminEntryRoutes(app);

const PAGES: string[] = ["public/admin.html", "public/admin-login.html"];

describe("/admin entry", () => {
  test("/admin redirects to the staff console", async () => {
    const res = await app.request("/admin");
    expect(res.status).toBe(302);
    expect(res.headers.get("location")).toBe("/console");
  });

  test("/admin/ redirects to the staff console too", async () => {
    const res = await app.request("/admin/");
    expect(res.headers.get("location")).toBe("/console");
  });

  test("the old console sign-in stays reachable at /admin/connexion", async () => {
    const res = await app.request("/admin/connexion");
    expect(res.status).toBe(200);
    expect(res.headers.get("content-type")).toContain("text/html");
    expect(await res.text()).toContain('id="login-form"');
  });

  test("the old dashboard sends signed-out visitors to /admin/connexion, not back to /admin", async () => {
    const html = await Bun.file("public/admin.html").text();
    expect(html).toContain("window.location.href = '/admin/connexion'");
    expect(html).not.toContain("window.location.href = '/admin';");
  });
});

describe.each(PAGES)("%s uses the Encre & Tekhelet design", (file) => {
  const read = () => Bun.file(file).text();

  test("no trace of the old violet/pink palette", async () => {
    const html = (await read()).toLowerCase();
    for (const old of ["6c5ce7", "fd79a8", "5849c2", "a29bfe", "667eea", "764ba2", "f093fb", "108, 92, 231", "253, 121, 168", "1a1a2e", "2d3436", "f8f9fe", "00b894", "ff6b6b"]) {
      expect(html).not.toContain(old);
    }
    expect(html).not.toContain("gradient");
  });

  test("Geist is self-hosted, no Inter, no serif, no external font", async () => {
    const html = await read();
    expect(html).toContain("/console/fonts/Geist-400.ttf");
    expect(html).not.toMatch(/fonts\.googleapis|fonts\.gstatic|Inter\b|Playfair/);
    expect(html.replaceAll("sans-serif", "")).not.toMatch(/\bserif\b/);
    expect(html).not.toMatch(/font-family:\s*['"]?(Inter|Playfair)/);
    expect(html).toContain("#2747F5");
  });
});
