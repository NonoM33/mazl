import type { Hono } from "hono";
import { bodyLimit } from "hono/body-limit";
import { requireAuth, type AppVariables } from "../../../shared/http/middleware";
import { createRateLimiter } from "../../../shared/http/rate-limit";
import { MAX_PHOTO_BYTES, type ChatMediaService } from "../application/chat-media-service";
import { verifyChatMediaSignature } from "../application/media-signer";
import { parseByteRange } from "../domain/byte-range";
import { notFoundResponse, respondToFailure } from "./http-errors";
import { parseId } from "./schemas";

const MULTIPART_OVERHEAD_BYTES = 1024 * 1024;
const uploadLimiter = createRateLimiter({ max: 30, windowMs: 60_000 });

const SERVE_HEADERS = {
  "Cache-Control": "private, max-age=3600",
  "X-Content-Type-Options": "nosniff",
  "Accept-Ranges": "bytes",
} as const;

function textField(form: FormData, name: string): string {
  const value = form.get(name);
  return typeof value === "string" ? value : "";
}

// POST /api/conversations/:id/media (upload) and GET /media/chat/:mediaId (signed read).
export function registerChatMediaRoutes(app: Hono<{ Variables: AppVariables }>, media: ChatMediaService): void {
  app.post(
    "/api/conversations/:id/media",
    requireAuth,
    uploadLimiter,
    bodyLimit({
      maxSize: MAX_PHOTO_BYTES + MULTIPART_OVERHEAD_BYTES,
      onError: (c) => c.json({ success: false, error: "File too large" }, 413),
    }),
    async (c) => {
      try {
        const conversationId = parseId(c.req.param("id"));
        if (conversationId === null) return notFoundResponse(c);
        if (!(c.req.header("Content-Type") ?? "").includes("multipart/form-data")) {
          return c.json({ success: false, error: "multipart/form-data expected" }, 400);
        }
        const form = await c.req.formData().catch(() => null);
        const file = form?.get("file");
        if (form === null || !(file instanceof File)) return c.json({ success: false, error: "No file provided" }, 400);
        const kind = textField(form, "kind");
        // The client's file name and MIME type are ignored on purpose: bytes decide.
        const bytes = new Uint8Array(await file.arrayBuffer());
        const userId = c.get("userId");

        if (kind === "photo") {
          return c.json({ success: true, media: await media.uploadPhoto(userId, conversationId, bytes) });
        }
        if (kind === "voice") {
          const uploaded = await media.uploadVoice(userId, conversationId, {
            bytes,
            durationMs: Number(textField(form, "duration_ms")),
            waveform: textField(form, "waveform"),
          });
          return c.json({ success: true, media: uploaded });
        }
        return c.json({ success: false, error: "kind must be photo or voice" }, 400);
      } catch (error: unknown) {
        return respondToFailure(c, error);
      }
    },
  );

  // No session: the signature is the credential. Every refusal looks the same.
  app.get("/media/chat/:mediaId", async (c) => {
    const mediaId = parseId(c.req.param("mediaId"));
    if (mediaId === null || !verifyChatMediaSignature(mediaId, c.req.query("exp"), c.req.query("sig"))) {
      return c.json({ error: "Not found" }, 404);
    }
    try {
      const served = await media.serve(mediaId);
      if (served === null) return c.json({ error: "Not found" }, 404);
      const size = served.bytes.byteLength;
      const range = parseByteRange(c.req.header("Range"), size);
      if (range === "unsatisfiable") {
        return new Response(null, { status: 416, headers: { ...SERVE_HEADERS, "Content-Range": `bytes */${size}` } });
      }
      if (range === null) {
        return new Response(served.bytes, { headers: { ...SERVE_HEADERS, "Content-Type": served.contentType, "Content-Length": String(size) } });
      }
      const part = served.bytes.subarray(range.start, range.end + 1);
      return new Response(part, {
        status: 206,
        headers: {
          ...SERVE_HEADERS,
          "Content-Type": served.contentType,
          "Content-Length": String(part.byteLength),
          "Content-Range": `bytes ${range.start}-${range.end}/${size}`,
        },
      });
    } catch (error: unknown) {
      console.error("Serve chat media error:", error instanceof Error ? error.name : "unknown");
      return c.json({ error: "Not found" }, 404);
    }
  });
}
