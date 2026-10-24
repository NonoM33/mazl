// Simple Bun server for the landing page
// Run with: bun run landing-server.ts

import { join, extname } from "node:path";

const PUBLIC_DIR = join(import.meta.dir, "public");

const MIME_TYPES: Record<string, string> = {
  ".html": "text/html",
  ".css": "text/css",
  ".js": "application/javascript",
  ".json": "application/json",
  ".svg": "image/svg+xml",
  ".png": "image/png",
  ".jpg": "image/jpeg",
  ".jpeg": "image/jpeg",
  ".webp": "image/webp",
  ".woff": "font/woff",
  ".woff2": "font/woff2",
  ".ico": "image/x-icon",
};

// Old addresses (linked from the app's premium screen) that moved to the French-named pages.
const PERMANENT_REDIRECTS: Readonly<Record<string, string>> = {
  "/terms": "/cgu",
  "/privacy": "/confidentialite",
};

export async function handleLandingRequest(req: Request): Promise<Response> {
  const url = new URL(req.url);
  let path = url.pathname;

  const redirectTarget = Object.hasOwn(PERMANENT_REDIRECTS, path) ? PERMANENT_REDIRECTS[path] : undefined;
  if (redirectTarget !== undefined) {
    return new Response(null, { status: 301, headers: { Location: redirectTarget } });
  }

  // Default to index.html
  if (path === "/" || path === "") {
    path = "/index.html";
  }

  const filePath = join(PUBLIC_DIR, path);

  try {
    const file = Bun.file(filePath);
    const exists = await file.exists();

    if (!exists) {
      // Try adding .html extension
      const htmlFile = Bun.file(filePath + ".html");
      if (await htmlFile.exists()) {
        const ext = ".html";
        return new Response(htmlFile, {
          headers: {
            "Content-Type": MIME_TYPES[ext] || "application/octet-stream",
          },
        });
      }

      // 404
      return new Response("Not Found", { status: 404 });
    }

    const ext = extname(path).toLowerCase();
    return new Response(file, {
      headers: {
        "Content-Type": MIME_TYPES[ext] || "application/octet-stream",
        "Cache-Control": ext === ".html" ? "no-cache" : "public, max-age=31536000",
      },
    });
  } catch (error) {
    return new Response("Server Error", { status: 500 });
  }
}

if (import.meta.main) {
  const server = Bun.serve({
    port: 3000,
    fetch: handleLandingRequest,
  });

  console.log(`
🚀 MAZL Landing Page Server
   ─────────────────────────
   Local:   http://localhost:${server.port}

   Press Ctrl+C to stop
`);
}
