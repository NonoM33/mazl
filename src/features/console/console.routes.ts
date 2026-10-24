import type { Hono } from "hono";
import { CONSOLE_MOUNT, type ConsoleAsset, type ConsoleBuild } from "./console.bundle";

export type ConsoleBuilder = () => Promise<ConsoleBuild>;

export interface ConsoleRoutesOptions {
  /** Produit le bundle. En production il est appelé une fois, en développement à chaque chargement de /console. */
  readonly build: ConsoleBuilder;
  readonly development: boolean;
}

const IMMUTABLE = "public, max-age=31536000, immutable";
const REVALIDATE = "public, max-age=3600";

function reply(asset: ConsoleAsset, cacheControl: string): Response {
  return new Response(asset.bytes, { headers: { "Content-Type": asset.type, "Cache-Control": cacheControl } });
}

/**
 * GET /console et /console/        → index.html (jamais mis en cache)
 * GET /console/assets/*            → fichiers du bundle (immuables quand leur nom porte une empreinte)
 * GET /console/fonts/*             → polices auto-hébergées
 * Tout le reste sous /console/     → 404.
 */
export function registerConsoleRoutes(app: Hono, options: ConsoleRoutesOptions): void {
  let current: Promise<ConsoleBuild> | null = null;

  const load = (fresh: boolean): Promise<ConsoleBuild> => {
    if (current === null || fresh) {
      const attempt = options.build();
      current = attempt;
      attempt.catch(() => {
        if (current === attempt) current = null;
      });
    }
    return current;
  };

  if (!options.development) void load(false).catch(() => undefined);

  const unavailable = (): Response => new Response("Console indisponible.", { status: 503, headers: { "Cache-Control": "no-store" } });
  const notFound = (): Response => new Response("Introuvable.", { status: 404, headers: { "Cache-Control": "no-store" } });

  const page = async (): Promise<Response> => {
    try {
      const build = await load(options.development);
      return reply(build.index, "no-store");
    } catch (error) {
      console.error("[console] build failed:", error);
      return unavailable();
    }
  };
  app.get(CONSOLE_MOUNT, () => page());
  app.get(`${CONSOLE_MOUNT}/`, () => page());

  const file = async (name: string): Promise<Response> => {
    let build: ConsoleBuild;
    try {
      build = await load(false);
    } catch (error) {
      console.error("[console] build failed:", error);
      return unavailable();
    }
    const asset = build.files.get(name);
    if (asset === undefined) return notFound();
    return reply(asset, asset.hashed ? IMMUTABLE : REVALIDATE);
  };
  app.get(`${CONSOLE_MOUNT}/assets/:name`, (c) => file(c.req.param("name")));
  app.get(`${CONSOLE_MOUNT}/fonts/:name`, (c) => file(`fonts/${c.req.param("name")}`));
  app.all(`${CONSOLE_MOUNT}/*`, () => notFound());
}
