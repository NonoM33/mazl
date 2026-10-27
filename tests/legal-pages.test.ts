import { describe, expect, test } from "bun:test";
import { BASE_URL } from "./media-helpers";

// mazl.app is served by src/index.ts in production. The Premium screen of the
// app links to /terms and /privacy, which answered 404: the legal pages must be
// reachable there, not only through the local landing server.

const get = (path: string): Promise<Response> => fetch(`${BASE_URL}${path}`, { redirect: "manual" });

describe("legal pages served by the API server", () => {
  for (const [path, title] of [
    ["/cgu", "Conditions générales d'utilisation"],
    ["/cgv", "Conditions générales de vente"],
    ["/confidentialite", "Politique de confidentialité"],
    ["/mentions-legales", "Mentions légales"],
    ["/cookies", "Politique de cookies et de traceurs"],
  ] as const) {
    test(`${path} answers the page`, async () => {
      const res = await get(path);
      expect(res.status).toBe(200);
      expect(res.headers.get("content-type") ?? "").toContain("text/html");
      expect(await res.text()).toContain(title);
    });
  }

  test("/terms, linked from the Premium screen, moves permanently to /cgu", async () => {
    const res = await get("/terms");
    expect(res.status).toBe(301);
    expect(res.headers.get("location")).toBe("/cgu");
  });

  test("/privacy, linked from the Premium screen, moves permanently to /confidentialite", async () => {
    const res = await get("/privacy");
    expect(res.status).toBe(301);
    expect(res.headers.get("location")).toBe("/confidentialite");
  });
});
