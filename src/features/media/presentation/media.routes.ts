import type { Hono } from "hono";
import type { AppVariables } from "../../../shared/http/middleware";
import { createHash } from "node:crypto";
import { maxAgeFor, parseExpiry } from "../domain/signed-url";
import { verifyPhotoSignature } from "../application/photo-signer";
import type { PhotoService } from "../application/photo-service";

// GET /media/photos/:photoId?exp=&sig= (CONTRAT.md §2.1). No session needed: the
// signature is the credential. Every refusal looks the same (404) so that a
// caller cannot tell a bad signature from a missing photo.
export function registerMediaRoutes(app: Hono<{ Variables: AppVariables }>, photos: PhotoService): void {
  app.get("/media/photos/:photoId", async (c) => {
    const rawId = c.req.param("photoId");
    const photoId = /^\d{1,9}$/.test(rawId) ? Number(rawId) : null;
    if (photoId === null || !verifyPhotoSignature(photoId, c.req.query("exp"), c.req.query("sig"))) {
      return c.json({ error: "Not found" }, 404);
    }
    try {
      const bytes = await photos.serve(photoId);
      if (bytes === null) return c.json({ error: "Not found" }, 404);
      const etag = `"${createHash("sha256").update(bytes).digest("hex").slice(0, 32)}"`;
      // A photo id never changes content (a replacement is a new id), so the bytes
      // stay valid for as long as the signed URL does.
      const maxAge = maxAgeFor(parseExpiry(c.req.query("exp")) ?? 0, Date.now());
      const headers = {
        "Cache-Control": `private, max-age=${maxAge}, immutable`,
        ETag: etag,
        "X-Content-Type-Options": "nosniff",
      };
      if (c.req.header("if-none-match") === etag) return new Response(null, { status: 304, headers });
      return new Response(bytes, { headers: { ...headers, "Content-Type": "image/jpeg" } });
    } catch (error: unknown) {
      console.error("Serve photo error:", error instanceof Error ? error.name : "unknown");
      return c.json({ error: "Not found" }, 404);
    }
  });
}
