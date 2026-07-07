import { Hono } from "hono";
import { z } from "zod";
import { mkdir } from "node:fs/promises";
import { join } from "node:path";
import {
  upsertProfile,
  getFullProfile,
  getProfilePhotos,
  addProfilePhoto,
  deleteProfilePhoto,
  reorderProfilePhotos,
  setProfilePhotoPrimary,
  PROMPT_CATALOG,
  getPromptText,
  getProfilePrompts,
  addProfilePrompt,
  updateProfilePrompt,
  deleteProfilePrompt,
  ProfilePromptLimitError,
} from "../../db";
import { requireAuth, type AppVariables } from "../../shared/http/middleware";
import { parseBody } from "../../shared/http/validation";

// Presentation layer for the PROFILE feature. These routes are moved verbatim
// from the monolith (src/index.ts): behaviour, payloads, status codes and
// relative ordering are identical to the original inline handlers.
//
// Covers: PUT /api/profile, the profile-photos routes (list/upload/delete/
// reorder/set-primary), the protected upload serving route, the public prompt
// catalog and the caller's profile prompts, and GET /api/profile/:userId.
//
// ORDERING NOTE: the /api/profile/prompts routes and GET /api/prompts MUST be
// declared BEFORE /api/profile/:userId, otherwise "prompts" is captured as
// :userId (parseInt("prompts") = NaN). They live in this same file so the
// ordering is guaranteed regardless of where registerProfileRoutes is called.

// PUT /api/profile: guard the numeric field TYPES (ageMin/ageMax/distanceMax,
// lat/long) and declare the string fields the handler reads so they stay
// well-typed. Everything is optional and `.passthrough()` keeps any other
// field the mobile app may send — nothing legitimate is rejected.
const updateProfileBodySchema = z
  .object({
    displayName: z.string().optional(),
    birthdate: z.string().optional(),
    gender: z.string().optional(),
    bio: z.string().optional(),
    location: z.string().optional(),
    latitude: z.number().optional(),
    longitude: z.number().optional(),
    denomination: z.string().optional(),
    kashrutLevel: z.string().optional(),
    shabbatObservance: z.string().optional(),
    lookingFor: z.string().optional(),
    ageMin: z.number().optional(),
    ageMax: z.number().optional(),
    distanceMax: z.number().optional(),
  })
  .passthrough();

const addPromptBodySchema = z
  .object({
    prompt_id: z.string(),
    answer: z.string(),
    position: z.number().optional(),
  })
  .passthrough();

const updatePromptBodySchema = z
  .object({
    answer: z.string(),
  })
  .passthrough();

export function registerProfileRoutes(
  app: Hono<{ Variables: AppVariables }>,
  UPLOADS_DIR: string,
): void {
  // Update user profile
  app.put("/api/profile", requireAuth, async (c) => {
    try {
      const userId = c.get("userId");
      const parsed = await parseBody(updateProfileBodySchema, c);
      if (!parsed.ok) {
        return c.json({ success: false, error: parsed.error }, 400);
      }
      const body = parsed.data;

      const profile = await upsertProfile(userId, {
        displayName: body.displayName,
        birthdate: body.birthdate,
        gender: body.gender,
        bio: body.bio,
        location: body.location,
        latitude: body.latitude,
        longitude: body.longitude,
        denomination: body.denomination,
        kashrutLevel: body.kashrutLevel,
        shabbatObservance: body.shabbatObservance,
        lookingFor: body.lookingFor,
        ageMin: body.ageMin,
        ageMax: body.ageMax,
        distanceMax: body.distanceMax,
      });

      return c.json({ success: true, profile });
    } catch (error: unknown) {
      console.error("Update profile error:", error);
      return c.json({ success: false, error: "Failed to update profile" }, 500);
    }
  });

  // ============ PROFILE PHOTOS ============

  app.get("/api/profile/photos", requireAuth, async (c) => {
    try {
      const userId = c.get("userId");
      const photos = await getProfilePhotos(userId);

      return c.json({ success: true, photos });
    } catch (error: unknown) {
      console.error("Get photos error:", error);
      return c.json({ success: false, error: "Failed to get photos" }, 500);
    }
  });

  // Upload profile photo
  app.post("/api/profile/photos", requireAuth, async (c) => {
    try {
      const userId = c.get("userId");

      // Check if multipart/form-data
      const contentType = c.req.header("Content-Type") || "";

      if (contentType.includes("multipart/form-data")) {
        // Handle file upload
        const formData = await c.req.formData();
        const file = formData.get("photo") as File;

        if (!file) {
          return c.json({ success: false, error: "No photo provided" }, 400);
        }

        // Validate file type
        if (!file.type.startsWith("image/")) {
          return c.json({ success: false, error: "Invalid file type" }, 400);
        }

        // Validate file size (max 10MB)
        if (file.size > 10 * 1024 * 1024) {
          return c.json({ success: false, error: "File too large (max 10MB)" }, 400);
        }

        // Create uploads directory if not exists
        const uploadDir = join(UPLOADS_DIR, "profiles", userId.toString());
        await mkdir(uploadDir, { recursive: true });

        // Generate unique filename
        const ext = file.name.split(".").pop() || "jpg";
        const filename = `${Date.now()}-${Math.random().toString(36).slice(2)}.${ext}`;
        const filepath = join(uploadDir, filename);

        // Save file
        const buffer = await file.arrayBuffer();
        await Bun.write(filepath, buffer);

        // Generate URL (relative path for serving)
        const url = `/uploads/profiles/${userId}/${filename}`;

        // Add to database
        const photo = await addProfilePhoto({
          userId,
          url,
          isPrimary: formData.get("is_primary") === "true",
        });

        return c.json({ success: true, photo });
      } else {
        // Handle JSON with URL (for external URLs like Google profile pictures)
        const body = await c.req.json();
        if (!body.url) {
          return c.json({ success: false, error: "No URL provided" }, 400);
        }

        const photo = await addProfilePhoto({
          userId,
          url: body.url,
          isPrimary: body.is_primary || false,
        });

        return c.json({ success: true, photo });
      }
    } catch (error: unknown) {
      console.error("Upload photo error:", error);
      return c.json({ success: false, error: "Failed to upload photo" }, 500);
    }
  });

  // Delete profile photo
  app.delete("/api/profile/photos/:photoId", requireAuth, async (c) => {
    try {
      const userId = c.get("userId");
      const photoId = parseInt(c.req.param("photoId"));

      if (isNaN(photoId)) {
        return c.json({ success: false, error: "Invalid photo ID" }, 400);
      }

      await deleteProfilePhoto(photoId, userId);

      return c.json({ success: true });
    } catch (error: unknown) {
      console.error("Delete photo error:", error);
      const message = error instanceof Error ? error.message : undefined;
      return c.json({ success: false, error: message || "Failed to delete photo" }, 500);
    }
  });

  // Reorder profile photos
  app.put("/api/profile/photos/reorder", requireAuth, async (c) => {
    try {
      const userId = c.get("userId");
      const body = await c.req.json();

      if (!Array.isArray(body.photoIds)) {
        return c.json({ success: false, error: "photoIds must be an array" }, 400);
      }

      const photos = await reorderProfilePhotos(userId, body.photoIds);

      return c.json({ success: true, photos });
    } catch (error: unknown) {
      console.error("Reorder photos error:", error);
      const message = error instanceof Error ? error.message : undefined;
      return c.json({ success: false, error: message || "Failed to reorder photos" }, 500);
    }
  });

  // Set photo as primary
  app.put("/api/profile/photos/:photoId/primary", requireAuth, async (c) => {
    try {
      const userId = c.get("userId");
      const photoId = parseInt(c.req.param("photoId"));

      if (isNaN(photoId)) {
        return c.json({ success: false, error: "Invalid photo ID" }, 400);
      }

      const photos = await setProfilePhotoPrimary(photoId, userId);

      return c.json({ success: true, photos });
    } catch (error: unknown) {
      console.error("Set primary photo error:", error);
      return c.json({ success: false, error: "Failed to set primary photo" }, 500);
    }
  });

  // Serve profile photos (protected)
  app.get("/uploads/profiles/:userId/:filename", async (c) => {
    try {
      const requestedUserId = c.req.param("userId");
      const filename = c.req.param("filename");
      const filepath = join(UPLOADS_DIR, "profiles", requestedUserId, filename);

      const file = Bun.file(filepath);
      if (!await file.exists()) {
        return c.json({ error: "File not found" }, 404);
      }

      return new Response(file, {
        headers: {
          "Content-Type": file.type || "image/jpeg",
          "Cache-Control": "public, max-age=31536000",
        },
      });
    } catch (error) {
      return c.json({ error: "File not found" }, 404);
    }
  });

  // ============ PROFILE PROMPTS ============
  // NOTE: these /api/profile/prompts routes MUST be declared BEFORE
  // /api/profile/:userId, otherwise "prompts" is captured as :userId
  // (parseInt("prompts") = NaN) and returns 400 instead of the prompts.

  // Public prompt catalog (available questions). Shape aligns with PromptTemplate.
  app.get("/api/prompts", (c) => {
    return c.json({ success: true, prompts: PROMPT_CATALOG });
  });

  // Get the caller's own prompts
  app.get("/api/profile/prompts", requireAuth, async (c) => {
    try {
      const userId = c.get("userId");
      const rows = await getProfilePrompts(userId);
      const prompts = rows.map((r) => ({
        id: r.id,
        prompt_id: r.prompt_id,
        prompt_text: getPromptText(r.prompt_id),
        answer: r.answer,
        position: r.position,
      }));
      return c.json({ success: true, prompts });
    } catch (error: unknown) {
      console.error("Get prompts error:", error);
      return c.json({ success: false, error: "Failed to get prompts" }, 500);
    }
  });

  // Add a prompt to the caller's profile (max 3)
  app.post("/api/profile/prompts", requireAuth, async (c) => {
    try {
      const userId = c.get("userId");
      const parsed = await parseBody(addPromptBodySchema, c);
      if (!parsed.ok) {
        return c.json({ success: false, error: parsed.error }, 400);
      }
      const body = parsed.data;
      const promptId = body.prompt_id;
      const answer = body.answer;
      if (!promptId || !answer || !answer.trim()) {
        return c.json({ success: false, error: "Missing prompt_id or answer" }, 400);
      }
      const position = typeof body.position === "number" ? body.position : 0;

      const row = await addProfilePrompt(userId, promptId, answer, position);
      return c.json({
        success: true,
        prompt: {
          id: row.id,
          prompt_id: row.prompt_id,
          prompt_text: getPromptText(row.prompt_id),
          answer: row.answer,
          position: row.position,
        },
      }, 201);
    } catch (error: unknown) {
      if (error instanceof ProfilePromptLimitError) {
        return c.json({ success: false, error: error.message }, 400);
      }
      console.error("Add prompt error:", error);
      return c.json({ success: false, error: "Failed to add prompt" }, 500);
    }
  });

  // Update one of the caller's prompts
  app.put("/api/profile/prompts/:id", requireAuth, async (c) => {
    try {
      const userId = c.get("userId");
      const promptId = parseInt(c.req.param("id"));
      if (isNaN(promptId)) {
        return c.json({ success: false, error: "Invalid prompt ID" }, 400);
      }
      const parsed = await parseBody(updatePromptBodySchema, c);
      if (!parsed.ok) {
        return c.json({ success: false, error: parsed.error }, 400);
      }
      const answer = parsed.data.answer;
      if (!answer || !answer.trim()) {
        return c.json({ success: false, error: "Missing answer" }, 400);
      }

      const row = await updateProfilePrompt(userId, promptId, answer);
      if (!row) {
        return c.json({ success: false, error: "Prompt not found" }, 404);
      }
      return c.json({
        success: true,
        prompt: {
          id: row.id,
          prompt_id: row.prompt_id,
          prompt_text: getPromptText(row.prompt_id),
          answer: row.answer,
          position: row.position,
        },
      });
    } catch (error: unknown) {
      console.error("Update prompt error:", error);
      return c.json({ success: false, error: "Failed to update prompt" }, 500);
    }
  });

  // Delete one of the caller's prompts
  app.delete("/api/profile/prompts/:id", requireAuth, async (c) => {
    try {
      const userId = c.get("userId");
      const promptId = parseInt(c.req.param("id"));
      if (isNaN(promptId)) {
        return c.json({ success: false, error: "Invalid prompt ID" }, 400);
      }

      const deleted = await deleteProfilePrompt(userId, promptId);
      if (!deleted) {
        return c.json({ success: false, error: "Prompt not found" }, 404);
      }
      return c.json({ success: true });
    } catch (error: unknown) {
      console.error("Delete prompt error:", error);
      return c.json({ success: false, error: "Failed to delete prompt" }, 500);
    }
  });

  // Get user profile by ID (for viewing other users)
  app.get("/api/profile/:userId", requireAuth, async (c) => {
    try {
      const targetUserId = parseInt(c.req.param("userId"));
      if (isNaN(targetUserId)) {
        return c.json({ success: false, error: "Invalid user ID" }, 400);
      }

      const profile = await getFullProfile(targetUserId);
      if (!profile) {
        return c.json({ success: false, error: "Profile not found" }, 404);
      }

      return c.json({ success: true, profile });
    } catch (error: unknown) {
      console.error("Get profile error:", error);
      return c.json({ success: false, error: "Failed to get profile" }, 500);
    }
  });
}
