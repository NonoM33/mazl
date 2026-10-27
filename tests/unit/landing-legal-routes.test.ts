import { describe, expect, test } from "bun:test";
import { handleLandingRequest } from "../../landing-server";

const get = (path: string): Promise<Response> =>
  handleLandingRequest(new Request(`http://localhost:3000${path}`));

describe("landing: legal pages", () => {
  for (const path of ["/cgu", "/cgv", "/confidentialite", "/mentions-legales", "/cookies"]) {
    test(`${path} answers 200 with an HTML page`, async () => {
      const response = await get(path);
      expect(response.status).toBe(200);
      expect(response.headers.get("Content-Type")).toContain("text/html");
      expect(await response.text()).toContain("<html");
    });
  }

  test("/terms redirects permanently to /cgu", async () => {
    const response = await get("/terms");
    expect(response.status).toBe(301);
    expect(response.headers.get("Location")).toBe("/cgu");
  });

  test("/privacy redirects permanently to /confidentialite", async () => {
    const response = await get("/privacy");
    expect(response.status).toBe(301);
    expect(response.headers.get("Location")).toBe("/confidentialite");
  });

  test("the pages are also reachable under their .html name", async () => {
    for (const path of ["/cgu.html", "/cgv.html", "/confidentialite.html", "/mentions-legales.html", "/cookies.html"]) {
      expect((await get(path)).status).toBe(200);
    }
  });

  test("the legal pages link to each other and back to the home page", async () => {
    for (const path of ["/cgu", "/cgv", "/confidentialite", "/mentions-legales", "/cookies"]) {
      const html = await (await get(path)).text();
      for (const target of ["/cgu", "/cgv", "/confidentialite", "/mentions-legales", "/cookies", "/"]) expect(html).toContain(`href="${target}"`);
    }
  });

  test("the legal pages load their stylesheet and icon from the site root", async () => {
    expect((await get("/legal.css")).status).toBe(200);
    expect((await get("/legal.css")).headers.get("Content-Type")).toContain("text/css");
    expect((await get("/favicon.svg")).status).toBe(200);
  });

  test("the home page footer links to the five legal pages", async () => {
    const html = await (await get("/")).text();
    for (const target of ["/cgu", "/cgv", "/confidentialite", "/mentions-legales", "/cookies"]) expect(html).toContain(`href="${target}"`);
  });

  test("an unknown path stays a 404", async () => {
    expect((await get("/does-not-exist")).status).toBe(404);
  });

  test("the home page still answers 200", async () => {
    expect((await get("/")).status).toBe(200);
  });
});
