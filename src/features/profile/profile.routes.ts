import { Hono } from "hono";
import { z } from "zod";
import {
  upsertProfile,
  getFullProfile,
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
import { createRateLimiter } from "../../shared/http/rate-limit";
import { clampDistanceMax } from "../media/domain/geo-fuzz";
import type { MediaModule } from "../media";
import { registerPhotoRoutes } from "../media/presentation/photo.routes";

// Presentation layer for the PROFILE feature: PUT /api/profile, the public
// prompt catalog, the caller's profile prompts and GET /api/profile/:userId.
// The profile-photos routes live in the media feature (registered here so that
// they stay ahead of /api/profile/:userId); photos and positions are handled
// by the media module passed in `deps`.
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
    latitude: z.number().min(-90).max(90).optional(),
    longitude: z.number().min(-180).max(180).optional(),
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

export interface ProfileRouteDeps {
  readonly media: MediaModule;
}

// CONTRAT.md §2.3: at most 120 other-member profile views per hour and user.
const PROFILE_VIEWS_PER_HOUR = 120;
const HOUR_MS = 60 * 60 * 1000;

export function registerProfileRoutes(
  app: Hono<{ Variables: AppVariables }>,
  deps: ProfileRouteDeps,
): void {
  const profileViewLimiter = createRateLimiter({ max: PROFILE_VIEWS_PER_HOUR, windowMs: HOUR_MS });

  // Update user profile
  app.put("/api/profile", requireAuth, async (c) => {
    try {
      const userId = c.get("userId");
      const parsed = await parseBody(updateProfileBodySchema, c);
      if (!parsed.ok) {
        return c.json({ success: false, error: parsed.error }, 400);
      }
      const body = parsed.data;

      // Exact coordinates are never stored (CONTRAT.md §2.2).
      const position = await deps.media.location.resolve(userId, body.latitude, body.longitude);

      const profile = await upsertProfile(userId, {
        displayName: body.displayName,
        birthdate: body.birthdate,
        gender: body.gender,
        bio: body.bio,
        location: body.location,
        latitude: position?.latitude,
        longitude: position?.longitude,
        denomination: body.denomination,
        kashrutLevel: body.kashrutLevel,
        shabbatObservance: body.shabbatObservance,
        lookingFor: body.lookingFor,
        ageMin: body.ageMin,
        ageMax: body.ageMax,
        distanceMax: body.distanceMax === undefined ? undefined : clampDistanceMax(body.distanceMax),
      });

      return c.json({ success: true, profile });
    } catch (error: unknown) {
      console.error("Update profile error:", error);
      return c.json({ success: false, error: "Failed to update profile" }, 500);
    }
  });

  registerPhotoRoutes(app, deps.media.photos);

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
  app.get("/api/profile/:userId", requireAuth, profileViewLimiter, async (c) => {
    try {
      const targetUserId = parseInt(c.req.param("userId"));
      if (isNaN(targetUserId)) {
        return c.json({ success: false, error: "Invalid user ID" }, 400);
      }

      // Email and account name only for the caller's own profile.
      const profile = await getFullProfile(targetUserId, targetUserId === c.get("userId"));
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
