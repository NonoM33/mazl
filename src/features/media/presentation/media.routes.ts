import type { Hono } from "hono";
import type { AppVariables } from "../../../shared/http/middleware";
import { verifyBlurSignature, verifyPhotoSignature } from "../application/photo-signer";
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

  // GET /media/photos/:photoId/blur?exp=&sig=: the 48 px blurred variant shown to a
  // member without mazl+ in place of the photo of someone who liked them. Same
  // rules as the sharp photo: the signature is the credential, every refusal is 404.
  app.get("/media/photos/:photoId/blur", async (c) => {
    const rawId = c.req.param("photoId");
    const photoId = /^\d{1,9}$/.test(rawId) ? Number(rawId) : null;
    if (photoId === null || !verifyBlurSignature(photoId, c.req.query("exp"), c.req.query("sig"))) {
      return c.json({ error: "Not found" }, 404);
    }
    try {
      const bytes = await photos.serveBlurred(photoId);
      if (bytes === null) return c.json({ error: "Not found" }, 404);
      return new Response(bytes, {
        headers: {
          "Content-Type": "image/jpeg",
          "Cache-Control": "private, max-age=3600",
          "X-Content-Type-Options": "nosniff",
        },
      });
    } catch (error: unknown) {
      console.error("Serve blurred photo error:", error instanceof Error ? error.name : "unknown");
      return c.json({ error: "Not found" }, 404);
    }
  });
}
