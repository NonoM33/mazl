import type { Hono } from "hono";
import { bodyLimit } from "hono/body-limit";
import { z } from "zod";
import {
  getProfilePhotos,
  reorderProfilePhotos,
  setProfilePhotoPrimary,
  MAX_PROFILE_PHOTOS,
  ProfilePhotoNotFoundError,
  ProfilePhotoSelectionError,
} from "../../../db";
import { requireAuth, type AppVariables } from "../../../shared/http/middleware";
import { idSchema, parseBody, parseId } from "../../../shared/http/validation";
import { createRateLimiter } from "../../../shared/http/rate-limit";
import { PhotoLimitError, PhotoRejectedError, PictureImportError } from "../domain/errors";
import { publicPhotoUrl } from "../application/photo-urls";
import type { PhotoService } from "../application/photo-service";

const MAX_UPLOAD_BYTES = 10 * 1024 * 1024;
const MULTIPART_OVERHEAD_BYTES = 1024 * 1024;

// JSON bodies can only ask for the OAuth picture import. Strict: a body that
// carries an arbitrary `url` is refused instead of being silently ignored.
const importBodySchema = z
  .object({
    import_oauth_picture: z.literal(true),
    is_primary: z.boolean().optional(),
  })
  .strict();

interface PhotoRow {
  readonly id: number;
  readonly url: string;
}

// Own-photo rows keep their shape, with the storage key replaced by a signed URL.
function present<T extends PhotoRow>(row: T): T | null {
  const url = publicPhotoUrl(row);
  return url === null ? null : { ...row, url };
}

function presentAll<T extends PhotoRow>(rows: readonly T[]): T[] {
  return rows.flatMap((row) => {
    const shown = present(row);
    return shown === null ? [] : [shown];
  });
}

const reorderBodySchema = z.object({
  photoIds: z
    .array(idSchema)
    .max(MAX_PROFILE_PHOTOS)
    .refine((ids) => new Set(ids).size === ids.length, { message: "photoIds must be distinct" }),
});

// 20 upload attempts an hour and member, refused ones included: a refused
// upload still costs an image decode.
const UPLOADS_PER_HOUR = 20;
const HOUR_MS = 60 * 60 * 1000;

interface Failure {
  readonly status: 400 | 409 | 500 | 502;
  readonly body: { success: false; error: string; reason?: string };
}

function describeFailure(error: unknown): Failure {
  if (error instanceof PhotoLimitError) {
    return { status: 409, body: { success: false, error: `Maximum of ${MAX_PROFILE_PHOTOS} photos reached` } };
  }
  if (error instanceof PhotoRejectedError) {
    return { status: 400, body: { success: false, error: "Invalid image", reason: error.reason } };
  }
  if (error instanceof PictureImportError) {
    const status = error.reason === "fetch_failed" ? 502 : 400;
    return { status, body: { success: false, error: "Cannot import picture", reason: error.reason } };
  }
  console.error("Upload photo error:", error instanceof Error ? error.name : "unknown");
  return { status: 500, body: { success: false, error: "Failed to upload photo" } };
}

// Declared before GET /api/profile/:userId, which would capture "photos".
export function registerPhotoRoutes(app: Hono<{ Variables: AppVariables }>, photos: PhotoService): void {
  const uploadLimiter = createRateLimiter({ max: UPLOADS_PER_HOUR, windowMs: HOUR_MS });

  app.get("/api/profile/photos", requireAuth, async (c) => {
    try {
      const rows = await getProfilePhotos(c.get("userId"));
      return c.json({ success: true, photos: presentAll(rows as unknown as PhotoRow[]) });
    } catch (error: unknown) {
      console.error("Get photos error:", error);
      return c.json({ success: false, error: "Failed to get photos" }, 500);
    }
  });

  app.post(
    "/api/profile/photos",
    requireAuth,
    uploadLimiter,
    bodyLimit({
      maxSize: MAX_UPLOAD_BYTES + MULTIPART_OVERHEAD_BYTES,
      onError: (c) => c.json({ success: false, error: "File too large (max 10MB)" }, 413),
    }),
    async (c) => {
      try {
        const userId = c.get("userId");
        const contentType = c.req.header("Content-Type") ?? "";

        if (contentType.includes("multipart/form-data")) {
          const form = await c.req.formData();
          const file = form.get("photo");
          if (!(file instanceof File)) {
            return c.json({ success: false, error: "No photo provided" }, 400);
          }
          if (file.size > MAX_UPLOAD_BYTES) {
            return c.json({ success: false, error: "File too large (max 10MB)" }, 400);
          }
          // Name and MIME type from the client are ignored on purpose.
          const bytes = new Uint8Array(await file.arrayBuffer());
          const photo = await photos.upload(userId, bytes, form.get("is_primary") === "true");
          return c.json({ success: true, photo: present(photo) });
        }

        if (contentType.includes("application/json")) {
          const parsed = await parseBody(importBodySchema, c);
          if (!parsed.ok) {
            return c.json({ success: false, error: parsed.error }, 400);
          }
          const photo = await photos.importOauthPicture(userId, parsed.data.is_primary ?? false);
          return c.json({ success: true, photo: present(photo) });
        }

        return c.json({ success: false, error: "Unsupported content type" }, 400);
      } catch (error: unknown) {
        const failure = describeFailure(error);
        return c.json(failure.body, failure.status);
      }
    },
  );

  app.delete("/api/profile/photos/:photoId", requireAuth, async (c) => {
    try {
      const photoId = parseId(c.req.param("photoId"));
      if (photoId === null) {
        return c.json({ success: false, error: "Invalid photo ID" }, 400);
      }
      await photos.remove(c.get("userId"), photoId);
      return c.json({ success: true });
    } catch (error: unknown) {
      if (error instanceof ProfilePhotoNotFoundError) {
        return c.json({ success: false, error: "Photo not found" }, 404);
      }
      console.error("Delete photo error:", error);
      return c.json({ success: false, error: "Failed to delete photo" }, 500);
    }
  });

  app.put("/api/profile/photos/reorder", requireAuth, async (c) => {
    try {
      const parsed = await parseBody(reorderBodySchema, c);
      if (!parsed.ok) {
        return c.json({ success: false, error: parsed.error }, 400);
      }
      const rows = await reorderProfilePhotos(c.get("userId"), parsed.data.photoIds);
      return c.json({ success: true, photos: presentAll(rows as unknown as PhotoRow[]) });
    } catch (error: unknown) {
      if (error instanceof ProfilePhotoSelectionError) {
        return c.json({ success: false, error: "Invalid photo ID" }, 400);
      }
      console.error("Reorder photos error:", error);
      return c.json({ success: false, error: "Failed to reorder photos" }, 500);
    }
  });

  app.put("/api/profile/photos/:photoId/primary", requireAuth, async (c) => {
    try {
      const photoId = parseId(c.req.param("photoId"));
      if (photoId === null) {
        return c.json({ success: false, error: "Invalid photo ID" }, 400);
      }
      const rows = await setProfilePhotoPrimary(photoId, c.get("userId"));
      return c.json({ success: true, photos: presentAll(rows as unknown as PhotoRow[]) });
    } catch (error: unknown) {
      if (error instanceof ProfilePhotoNotFoundError) {
        return c.json({ success: false, error: "Photo not found" }, 404);
      }
      console.error("Set primary photo error:", error);
      return c.json({ success: false, error: "Failed to set primary photo" }, 500);
    }
  });
}
