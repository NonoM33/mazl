// Cache rules of the web client files. Shared by the API's web-app feature and
// by the website container (web/front), which renders its Caddy config from
// these very values (docs/web/adr/W01-hebergement.md, 2026-10-24 decoupling).

export const NO_STORE = "no-store";
export const IMMUTABLE = "public, max-age=31536000, immutable";

// A hashed build output (index-azgcf9mr.js): never changes under the same name.
// Written without lookbehind or flags so Go's RE2 (Caddy) reads it as well.
export const HASHED_ASSET = /-[a-z0-9]{8}\.(?:js|css|svg|png|woff2?)$/;
export const FONTS_DIRECTORY = "fonts/";

export function cacheControlFor(relativePath: string): string {
  return HASHED_ASSET.test(relativePath) || relativePath.startsWith(FONTS_DIRECTORY) ? IMMUTABLE : NO_STORE;
}
