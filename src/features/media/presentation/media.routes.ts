import type { Hono } from "hono";
import type { AppVariables } from "../../../shared/http/middleware";
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
      return new Response(bytes, {
        headers: {
          "Content-Type": "image/jpeg",
          "Cache-Control": "private, max-age=3600",
          "X-Content-Type-Options": "nosniff",
        },
      });
    } catch (error: unknown) {
      console.error("Serve photo error:", error instanceof Error ? error.name : "unknown");
      return c.json({ error: "Not found" }, 404);
    }
  });
}
