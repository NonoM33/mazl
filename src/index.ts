import { Hono } from "hono";
import { z } from "zod";
import { serveStatic } from "hono/bun";
import { cors } from "hono/cors";
import { mkdir } from "node:fs/promises";
import { join } from "node:path";
import {
  sql,
  createDocument,
  findWaitlistByVerificationToken,
  getTotalCount,
  initDb,
  markVerificationSubmitted,
  upsertWaitlistAndGetVerification,
  getLatestDocumentsByType,
  setWaitlistOS,
  findUserByEmail,
  getFullProfile,
  upsertProfile,
  // Boost
  activateBoost,
  getActiveBoost,
  getBoostsUsedToday,
  // Profile prompts
  PROMPT_CATALOG,
  getPromptText,
  getProfilePrompts,
  addProfilePrompt,
  updateProfilePrompt,
  deleteProfilePrompt,
  ProfilePromptLimitError,
  // Chat
  getConversations,
  getConversationById,
  getMessages,
  createMessage,
  markMessagesAsRead,
  // Events
  getEventById,
  // Subscriptions
  // Admin
  // Couple Mode
  createCouple,
  getCouple,
  createCoupleRequest,
  respondToCoupleRequest,
  cancelCoupleRequest,
  getCoupleRequestsForUser,
  getCoupleStatusWith,
  archiveConversationsExceptPartner,
  updateCoupleStatus,
  updateRelationshipStatus,
  deleteCouple,
  getDailyQuestion,
  answerDailyQuestion,
  getCoupleQuestionHistory,
  recordMilestone,
  getCoupleMilestones,
  checkAndRecordMilestones,
  // Admin utilities
  resetUserSwipes,
  // Module 1: Gestion Membres
  // Selfie verification (US-TS-03)
  startVerification,
  submitVerification,
  getVerificationStatus,
  // Profile Photos
  getProfilePhotos,
  addProfilePhoto,
  deleteProfilePhoto,
  reorderProfilePhotos,
  setProfilePhotoPrimary,
  // Module 2: Gestion Events
  getEventPhotos,
  // Module 3: Campagnes
  unsubscribeEmail,
  // Module 4: Modération
  createReport,
  blockUser,
  unblockUser,
  getBlockedUsers,
  isBlockedBetween,
  // Couple Mode - Activities & Events
  getCoupleActivities,
  getCoupleActivity,
  saveCoupleActivity,
  passCoupleActivity,
  getSavedActivities,
  removeSavedActivity,
  createCoupleBooking,
  getCoupleBookings,
  getCoupleEvents,
  getCoupleEvent,
  registerForCoupleEvent,
  cancelCoupleEventRegistration,
  getCoupleRegisteredEvents,
  // Couple Mode - Memories & Dates
  addCoupleMemory,
  getCoupleMemories,
  deleteCoupleMemory,
  addCoupleDate,
  getCoupleDates,
  updateCoupleDate,
  deleteCoupleDate,
  // Couple Mode - Bucket List & Stats
  addBucketListItem,
  getBucketList,
  completeBucketListItem,
  deleteBucketListItem,
  getCoupleStats,
  getCoupleAchievements,
  getCoupleByUserId,
} from "./db";
import { sendVerificationRequestEmail } from "./email";
import { generateJWT, verifyJWT } from "./auth";
import { sendPushToUsers, sendPushToAll } from "./onesignal";
import { requireAuth, type AppVariables } from "./shared/http/middleware";
import { parseBody, swipeBodySchema } from "./shared/http/validation";
import {
  sendToUser,
  emitNewMatch,
  addConnection,
  removeConnection,
} from "./shared/realtime/connections";
import { registerAuthRoutes } from "./features/auth/auth.routes";
import { registerEventsRoutes } from "./features/events/events.routes";
import { registerSubscriptionsRoutes } from "./features/subscriptions/subscriptions.routes";
import { registerMatchingRoutes } from "./features/matching/matching.routes";
import { registerCoupleRoutes } from "./features/couple/couple.routes";
import { registerAdminRoutes } from "./features/admin/admin.routes";

const app = new Hono<{ Variables: AppVariables }>();

// ============ INPUT VALIDATION (permissive safety net) ============
// These schemas only guard the TYPES of fields actually read by each handler
// and the presence of fields the handler logic already requires. They use
// `.passthrough()` so extra fields from the mobile app are never rejected, and
// keep optional anything the handler already treats as optional. On failure the
// caller returns the same `{ success: false, error }` 400 shape as the rest of
// the file — business logic and success responses are unchanged.

// `parseBody` and the shared `swipeBodySchema` now live in
// `src/shared/http/validation.ts` (imported above). The schemas below are
// used only by handlers in this file.

const reportUserBodySchema = z
  .object({
    category: z.string().optional(),
    comment: z.string().optional(),
    block_user: z.boolean().optional(),
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

const sendMessageBodySchema = z
  .object({
    content: z.string().min(1),
  })
  .passthrough();

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

const UPLOADS_DIR = process.env.UPLOADS_DIR || "uploads";

const IS_PRODUCTION = process.env.NODE_ENV === "production";

// CORS: explicit allowlist of origins (comma-separated CORS_ORIGINS env or defaults)
const DEFAULT_CORS_ORIGINS = [
  "http://localhost:3000",
  "http://localhost:5173",
  "http://localhost:8080",
  "capacitor://localhost",
  "ionic://localhost",
  "http://localhost",
];

const ALLOWED_ORIGINS: readonly string[] = (() => {
  const fromEnv = process.env.CORS_ORIGINS;
  if (fromEnv) {
    return fromEnv
      .split(",")
      .map((origin) => origin.trim())
      .filter((origin) => origin.length > 0);
  }
  return DEFAULT_CORS_ORIGINS;
})();

app.use(
  "/api/*",
  cors({
    origin: (origin) => (ALLOWED_ORIGINS.includes(origin) ? origin : null),
    allowMethods: ["GET", "POST", "PATCH", "PUT", "DELETE", "OPTIONS"],
    allowHeaders: ["Content-Type", "Authorization", "x-admin-password"],
    credentials: true,
  }),
);

// Pretty routes (must be before static)
app.get("/verify", async (c) => {
  const token = c.req.query("token") || "";
  return c.redirect(`/verify.html?token=${encodeURIComponent(token)}`);
});

app.get("/admin", async (c) => {
  return new Response(Bun.file("./public/admin-login.html"));
});

app.get("/admin/dashboard", async (c) => {
  return new Response(Bun.file("./public/admin.html"));
});

// Block direct access to uploads directory
app.use("/uploads/*", async (c) => {
  return c.json({ error: "Forbidden" }, 403);
});

// Static files
app.use("/*", serveStatic({ root: "./public" }));


function getFileExtension(file: File) {
  const byType: Record<string, string> = {
    "image/jpeg": "jpg",
    "image/png": "png",
    "application/pdf": "pdf",
    "image/webp": "webp",
  };

  if (file.type && byType[file.type]) return byType[file.type];
  const name = (file as any).name as string | undefined;
  if (!name) return "bin";
  const ext = name.split(".").pop();
  return ext ? ext.toLowerCase() : "bin";
}

function isAllowedUpload(file: File) {
  const allowed = new Set(["image/jpeg", "image/png", "application/pdf", "image/webp"]);
  if (file.type && allowed.has(file.type)) return true;

  // Fallback for browsers that do not set mime
  const name = (file as any).name as string | undefined;
  if (!name) return false;
  return /\.(jpe?g|png|pdf|webp)$/i.test(name);
}

// API Routes
app.post("/api/subscribe", async (c) => {
  try {
    const { email } = await c.req.json();

    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!email || !emailRegex.test(email)) {
      return c.json({ success: false, error: "Email invalide" }, 400);
    }

    const waitlist = await upsertWaitlistAndGetVerification(email);

    // Send verification request email (best-effort)
    try {
      const forwardedProto = c.req.header("x-forwarded-proto") || "https";
      const forwardedHost = c.req.header("x-forwarded-host") || c.req.header("host") || "";
      const requestOrigin = forwardedHost ? `${forwardedProto}://${forwardedHost}` : undefined;

      await sendVerificationRequestEmail({
        to: email,
        verificationToken: waitlist.verificationToken,
        baseUrl: requestOrigin,
      });
    } catch (err) {
      console.error("Email send failed:", err);
    }

    return c.json({
      success: true,
      message: "Inscription OK ! Regarde tes emails pour envoyer tes documents.",
    });
  } catch (error: any) {
    console.error("Subscribe error:", error);
    return c.json({ success: false, error: "Erreur serveur" }, 500);
  }
});

app.get("/api/count", async (c) => {
  try {
    const total = await getTotalCount();
    return c.json({ confirmed: total, total });
  } catch (error) {
    return c.json({ confirmed: 0, total: 0 });
  }
});

app.get("/api/verify", async (c) => {
  const token = c.req.query("token") || "";
  if (!token) return c.json({ success: false, error: "Token manquant" }, 400);

  const waitlist = await findWaitlistByVerificationToken(token);
  if (!waitlist) return c.json({ success: false, error: "Token invalide" }, 404);

  const latest = await getLatestDocumentsByType(waitlist.id);
  const required = ["selfie_id", "id_card_front", "id_card_back"];
  const missing = required.filter((t) => !latest[t] || latest[t].status === "rejected");

  return c.json({
    success: true,
    email: waitlist.email,
    verificationStatus: waitlist.verification_status,
    os: (waitlist as any).os,
    requiredReady: missing.length === 0,
    missing,
  });
});

app.post("/api/verify/upload", async (c) => {
  const token = c.req.query("token") || "";
  if (!token) return c.json({ success: false, error: "Token manquant" }, 400);

  const waitlist = await findWaitlistByVerificationToken(token);
  if (!waitlist) return c.json({ success: false, error: "Token invalide" }, 404);

  const form = await c.req.formData();
  const type = (form.get("type") || "") as string;
  const file = form.get("file");

  if (!type) return c.json({ success: false, error: "Type manquant" }, 400);
  if (!(file instanceof File)) return c.json({ success: false, error: "Fichier manquant" }, 400);

  if (!isAllowedUpload(file)) {
    return c.json({ success: false, error: "Format non supporté (JPG/PNG/PDF)" }, 400);
  }

  const maxBytes = 10 * 1024 * 1024;
  if (file.size > maxBytes) return c.json({ success: false, error: "Fichier trop gros (max 10MB)" }, 400);

  const ext = getFileExtension(file);
  const safeType = type.replace(/[^a-z0-9_-]/gi, "_").slice(0, 40);
  const filename = `${waitlist.id}-${safeType}-${crypto.randomUUID()}.${ext}`;
  const fullPath = join(UPLOADS_DIR, filename);

  await Bun.write(fullPath, file);

  const documentId = await createDocument({
    waitlistId: waitlist.id,
    type: safeType,
    filename,
    originalName: (file as any).name,
    mimeType: file.type,
  });

  return c.json({ success: true, documentId, filename });
});

app.post("/api/verify/submit", async (c) => {
  const token = c.req.query("token") || "";
  if (!token) return c.json({ success: false, error: "Token manquant" }, 400);

  const waitlist = await findWaitlistByVerificationToken(token);
  if (!waitlist) return c.json({ success: false, error: "Token invalide" }, 404);

  const { os } = await c.req.json().catch(() => ({}));
  if (os && ["ios", "android"].includes(os)) {
    await setWaitlistOS(waitlist.id, os);
  }

  const latest = await getLatestDocumentsByType(waitlist.id);
  const required = ["selfie_id", "id_card_front", "id_card_back"];
  const missing = required.filter((t) => !latest[t] || latest[t].status === "rejected");
  if (missing.length > 0) {
    return c.json(
      { success: false, error: `Documents manquants: ${missing.join(", ")}`, missing },
      400,
    );
  }

  await markVerificationSubmitted(waitlist.id);
  return c.json({ success: true });
});

// ============ ADMIN FEATURE ============
// All `/api/admin/*` endpoints live in src/features/admin/*. They are
// registered here — at their original location in the route table —
// preserving the exact relative declaration order of the admin routes.
// Admin auth (admin JWT + email whitelist via assertAdmin /
// assertAdminFileDownload) lives in src/features/admin/admin.auth.ts.
registerAdminRoutes(app, UPLOADS_DIR);

// ============ AUTH ENDPOINTS ============

// Auth feature routes (POST /api/auth/google, POST /api/auth/apple, GET /api/auth/me)
registerAuthRoutes(app);

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
  } catch (error: any) {
    console.error("Update profile error:", error);
    return c.json({ success: false, error: "Failed to update profile" }, 500);
  }
});

// ============ PROFILE PHOTOS ============

// Get profile photos
// ============ SELFIE VERIFICATION (US-TS-03) ============
// Distinct from the WEB email-token flow at /api/verify/* — do not conflate.
// These literal /api/verification/* routes are registered before any
// parameterized route that could otherwise capture them.

// Start a selfie verification: returns a random gesture to perform.
app.post("/api/verification/start", requireAuth, async (c) => {
  try {
    const userId = c.get("userId");

    const result = await startVerification(userId);
    if (!result.ok) {
      // Daily quota exhausted — enforced server-side.
      return c.json(
        {
          success: false,
          error: result.message ?? "Daily verification limit reached",
          next_attempt_time: result.nextAttemptTime,
        },
        429,
      );
    }

    return c.json({ success: true, gesture_id: result.gestureId });
  } catch (error: unknown) {
    console.error("Verification start error:", error);
    return c.json({ success: false, error: "Failed to start verification" }, 500);
  }
});

// Submit a selfie (base64) for the given gesture.
app.post("/api/verification/submit", requireAuth, async (c) => {
  try {
    const userId = c.get("userId");

    const body = await c.req.json().catch(() => null);
    const rawGesture =
      body && typeof body.gesture_id === "string" ? body.gesture_id : "";
    const selfie =
      body && typeof body.selfie === "string" ? body.selfie : "";
    // The base64 selfie is used transiently only; it is never persisted to
    // profile_photos / profiles.photos. We just check that one was provided.
    const imageProvided = selfie.length > 0;

    const result = await submitVerification(userId, rawGesture, imageProvided);
    if (result.nextAttemptTime && !result.verified && result.attemptsRemaining === 0) {
      // Quota was already exhausted before this call — refuse.
      return c.json(
        {
          success: false,
          error: result.message,
          next_attempt_time: result.nextAttemptTime,
        },
        429,
      );
    }

    return c.json({
      success: true,
      verified: result.verified,
      message: result.message,
      attempts_remaining: result.attemptsRemaining,
    });
  } catch (error: unknown) {
    console.error("Verification submit error:", error);
    return c.json({ success: false, error: "Failed to submit verification" }, 500);
  }
});

// Current verification status (verified flag + daily quota).
app.get("/api/verification/status", requireAuth, async (c) => {
  try {
    const userId = c.get("userId");

    const status = await getVerificationStatus(userId);
    return c.json({
      success: true,
      is_verified: status.isVerified,
      attempts_today: status.attemptsToday,
      next_attempt_time: status.nextAttemptTime ?? null,
    });
  } catch (error: unknown) {
    console.error("Verification status error:", error);
    return c.json({ success: false, error: "Failed to get verification status" }, 500);
  }
});

app.get("/api/profile/photos", requireAuth, async (c) => {
  try {
    const userId = c.get("userId");
    const photos = await getProfilePhotos(userId);

    return c.json({ success: true, photos });
  } catch (error: any) {
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
  } catch (error: any) {
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
  } catch (error: any) {
    console.error("Delete photo error:", error);
    return c.json({ success: false, error: error.message || "Failed to delete photo" }, 500);
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
  } catch (error: any) {
    console.error("Reorder photos error:", error);
    return c.json({ success: false, error: error.message || "Failed to reorder photos" }, 500);
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
  } catch (error: any) {
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

// Get user profile by ID (for viewing other users)
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

app.get("/api/profile/:userId", requireAuth, async (c) => {
  try {
    const userId = c.get("userId");

    const targetUserId = parseInt(c.req.param("userId"));
    if (isNaN(targetUserId)) {
      return c.json({ success: false, error: "Invalid user ID" }, 400);
    }

    const profile = await getFullProfile(targetUserId);
    if (!profile) {
      return c.json({ success: false, error: "Profile not found" }, 404);
    }

    return c.json({ success: true, profile });
  } catch (error: any) {
    console.error("Get profile error:", error);
    return c.json({ success: false, error: "Failed to get profile" }, 500);
  }
});

// ============ DISCOVER & MATCHING ============

// Core matching feature routes (GET /api/discover, GET /api/daily-picks,
// POST /api/swipes, GET /api/matches, GET /api/likes/received[/count]).
// Moved to src/features/matching/matching.routes.ts. `POST /api/swipes` still
// emits `match:new` via the exported `emitNewMatch` helper below.
registerMatchingRoutes(app);

// ============ BOOST ============

// Free-tier daily boost allowance. Premium (unlimited) enforcement lives
// on the client for now; the server just reports a sensible remaining count.
const FREE_DAILY_BOOSTS = 3;

async function buildBoostStatus(userId: number) {
  const [activeBoost, boostsUsedToday] = await Promise.all([
    getActiveBoost(userId),
    getBoostsUsedToday(userId),
  ]);

  const remainingBoosts = Math.max(0, FREE_DAILY_BOOSTS - boostsUsedToday);
  const expiresAt = activeBoost ? activeBoost.expires_at.toISOString() : null;

  // Keys are snake_case to match the mobile BoostStatus.fromJson parser.
  return {
    is_active: activeBoost !== null,
    expires_at: expiresAt,
    active_until: expiresAt,
    remaining_boosts: remainingBoosts,
    boosts_used_today: boostsUsedToday,
    views_during_boost: 0,
    likes_during_boost: 0,
  };
}

// Get current boost status
app.get("/api/boost/status", requireAuth, async (c) => {
  try {
    const userId = c.get("userId");
    const status = await buildBoostStatus(userId);

    return c.json({ success: true, ...status });
  } catch (error: any) {
    console.error("Boost status error:", error);
    return c.json({ success: false, error: "Failed to get boost status" }, 500);
  }
});

// Activate a boost (30 minutes)
app.post("/api/boost/activate", requireAuth, async (c) => {
  try {
    const userId = c.get("userId");
    const boost = await activateBoost(userId, 30);
    const status = await buildBoostStatus(userId);

    return c.json({ success: true, boost, status, ...status }, 201);
  } catch (error: any) {
    console.error("Boost activate error:", error);
    return c.json({ success: false, error: "Failed to activate boost" }, 500);
  }
});

// ============ CHAT ENDPOINTS ============

// Get user's conversations
app.get("/api/conversations", requireAuth, async (c) => {
  try {
    const userId = c.get("userId");
    const conversations = await getConversations(userId);

    return c.json({ success: true, conversations });
  } catch (error: any) {
    console.error("Conversations error:", error);
    return c.json({ success: false, error: "Failed to get conversations" }, 500);
  }
});

// Get conversation details
app.get("/api/conversations/:id", requireAuth, async (c) => {
  try {
    const userId = c.get("userId");
    const conversationId = parseInt(c.req.param("id"));

    const conversation = await getConversationById(conversationId);
    if (!conversation) {
      return c.json({ success: false, error: "Conversation not found" }, 404);
    }

    // Check user is part of conversation
    if ((conversation as any).user1_id !== userId && (conversation as any).user2_id !== userId) {
      return c.json({ success: false, error: "Access denied" }, 403);
    }

    return c.json({ success: true, conversation });
  } catch (error: any) {
    console.error("Conversation error:", error);
    return c.json({ success: false, error: "Failed to get conversation" }, 500);
  }
});

// Get messages for a conversation
app.get("/api/conversations/:id/messages", requireAuth, async (c) => {
  try {
    const userId = c.get("userId");
    const conversationId = parseInt(c.req.param("id"));
    const limit = parseInt(c.req.query("limit") || "50");
    const offset = parseInt(c.req.query("offset") || "0");

    const conversation = await getConversationById(conversationId);
    if (!conversation) {
      return c.json({ success: false, error: "Conversation not found" }, 404);
    }

    // Check user is part of conversation
    if ((conversation as any).user1_id !== userId && (conversation as any).user2_id !== userId) {
      return c.json({ success: false, error: "Access denied" }, 403);
    }

    const messages = await getMessages(conversationId, limit, offset);

    return c.json({ success: true, messages });
  } catch (error: any) {
    console.error("Messages error:", error);
    return c.json({ success: false, error: "Failed to get messages" }, 500);
  }
});

// Send a message
app.post("/api/conversations/:id/messages", requireAuth, async (c) => {
  try {
    const userId = c.get("userId");
    const conversationId = parseInt(c.req.param("id"));
    const parsed = await parseBody(sendMessageBodySchema, c);
    if (!parsed.ok) {
      return c.json({ success: false, error: parsed.error }, 400);
    }
    const content = parsed.data.content;

    if (!content || typeof content !== "string" || content.trim().length === 0) {
      return c.json({ success: false, error: "Message content required" }, 400);
    }

    const conversation = await getConversationById(conversationId);
    if (!conversation) {
      return c.json({ success: false, error: "Conversation not found" }, 404);
    }

    // Check user is part of conversation
    if ((conversation as any).user1_id !== userId && (conversation as any).user2_id !== userId) {
      return c.json({ success: false, error: "Access denied" }, 403);
    }

    const message = await createMessage(conversationId, userId, content.trim());

    // Broadcast via WebSocket to both users
    const conv = conversation as any;
    const otherUserId = conv.user1_id === userId ? conv.user2_id : conv.user1_id;
    const messageData = {
      type: "chat:message",
      payload: {
        conversationId,
        messageId: (message as any).id,
        senderId: userId,
        content: (message as any).content,
        createdAt: (message as any).created_at,
      },
    };
    sendToUser(userId, messageData);
    sendToUser(otherUserId, messageData);

    return c.json({ success: true, message });
  } catch (error: any) {
    console.error("Send message error:", error);
    return c.json({ success: false, error: "Failed to send message" }, 500);
  }
});

// Mark messages as read
app.put("/api/conversations/:id/read", requireAuth, async (c) => {
  try {
    const userId = c.get("userId");
    const conversationId = parseInt(c.req.param("id"));

    const conversation = await getConversationById(conversationId);
    if (!conversation) {
      return c.json({ success: false, error: "Conversation not found" }, 404);
    }

    // Check user is part of conversation
    if ((conversation as any).user1_id !== userId && (conversation as any).user2_id !== userId) {
      return c.json({ success: false, error: "Access denied" }, 403);
    }

    await markMessagesAsRead(conversationId, userId);

    // Broadcast via WebSocket to the other user
    const conv = conversation as any;
    const otherUserId = conv.user1_id === userId ? conv.user2_id : conv.user1_id;
    sendToUser(otherUserId, {
      type: "chat:read",
      payload: {
        conversationId,
        userId,
      },
    });

    return c.json({ success: true });
  } catch (error: any) {
    console.error("Mark read error:", error);
    return c.json({ success: false, error: "Failed to mark as read" }, 500);
  }
});

// ============ EVENTS ENDPOINTS ============

// Classic events feature routes (GET /api/events, GET /api/events/:id,
// POST /api/events/:id/rsvp, DELETE /api/events/:id/rsvp).
registerEventsRoutes(app);



// ============ SUBSCRIPTIONS ENDPOINTS ============

// User-facing subscription status + the RevenueCat webhook now live in the
// subscriptions feature. The former POST /api/subscription/sync route was
// REMOVED during the audit (it let any authenticated user declare themselves
// premium); premium status is driven client-side by RevenueCat entitlements
// and the server is informed only via the authenticated webhook below.
registerSubscriptionsRoutes(app);



// ============ DEV/DEBUG ENDPOINTS ============

// Create test user (dev only)
app.post("/api/dev/test-user", async (c) => {
  if (IS_PRODUCTION) return c.json({ error: "Not found" }, 404);
  try {
    const body = await c.req.json();
    const { email, password, name } = body;

    if (!email || !password) {
      return c.json({ success: false, error: "email and password required" }, 400);
    }

    // Check if user exists
    const existing = await sql`SELECT id, name FROM users WHERE email = ${email}`;
    if (existing.length > 0) {
      // User exists, return token
      const userId = (existing[0] as any).id;
      const userName = (existing[0] as any).name || 'Test User';
      const token = generateJWT({
        id: userId,
        email,
        name: userName,
        provider: 'google' as const, // Use google for compatibility
        providerId: email,
      });
      return c.json({ success: true, token, user: { id: userId, email } });
    }

    // Create new test user
    const result = await sql`
      INSERT INTO users (email, name, provider, provider_id, created_at)
      VALUES (${email}, ${name || 'Test User'}, 'test', ${email}, NOW())
      RETURNING id
    `;
    const userId = (result[0] as any).id;

    // Create profile
    await sql`
      INSERT INTO profiles (user_id, display_name, created_at)
      VALUES (${userId}, ${name || 'Test User'}, NOW())
    `;

    const token = generateJWT({
      id: userId,
      email,
      name: name || 'Test User',
      provider: 'google' as const, // Use google for compatibility
      providerId: email,
    });
    return c.json({ success: true, token, user: { id: userId, email } });
  } catch (error: any) {
    console.error("Create test user error:", error);
    return c.json({ success: false, error: error.message }, 500);
  }
});

// Login test user (dev only)
app.post("/api/dev/test-login", async (c) => {
  if (IS_PRODUCTION) return c.json({ error: "Not found" }, 404);
  try {
    const body = await c.req.json();
    const { email } = body;

    if (!email) {
      return c.json({ success: false, error: "email required" }, 400);
    }

    const result = await sql`SELECT id, email, name FROM users WHERE email = ${email}`;
    if (result.length === 0) {
      return c.json({ success: false, error: "User not found" }, 404);
    }

    const user = result[0] as any;
    const token = generateJWT({
      id: user.id,
      email: user.email,
      name: user.name || 'Test User',
      provider: 'google' as const,
      providerId: user.email,
    });
    return c.json({ success: true, token, user: { id: user.id, email: user.email, name: user.name } });
  } catch (error: any) {
    console.error("Test login error:", error);
    return c.json({ success: false, error: error.message }, 500);
  }
});

// Enable couple mode for testing (dev endpoint)
app.post("/api/dev/couple/enable", async (c) => {
  if (IS_PRODUCTION) return c.json({ error: "Not found" }, 404);
  try {
    const body = await c.req.json();
    const { userId, partnerId } = body;

    if (!userId) {
      return c.json({ success: false, error: "userId required" }, 400);
    }

    // Use partnerId if provided, otherwise find a seed profile
    let partnerUserId = partnerId;
    if (!partnerUserId) {
      const seedResult = await sql`
        SELECT id FROM users WHERE provider = 'seed' LIMIT 1
      `;
      if (seedResult.length === 0) {
        return c.json({ success: false, error: "No seed profiles available for partner" }, 404);
      }
      partnerUserId = (seedResult[0] as any).id;
    }

    // Check if couple already exists (any status)
    const existingCouple = await sql`
      SELECT id, status FROM couples
      WHERE (user1_id = ${userId} AND user2_id = ${partnerUserId})
         OR (user1_id = ${partnerUserId} AND user2_id = ${userId})
    `;

    let coupleId: number;

    if (existingCouple.length > 0) {
      const couple = existingCouple[0] as any;
      if (couple.status === 'active') {
        return c.json({
          success: true,
          message: "Couple already exists",
          coupleId: couple.id
        });
      }
      // Reactivate existing couple
      await sql`
        UPDATE couples SET status = 'active', updated_at = NOW()
        WHERE id = ${couple.id}
      `;
      coupleId = couple.id;
    } else {
      // Deactivate any other existing couples for these users
      await sql`
        UPDATE couples SET status = 'ended', updated_at = NOW()
        WHERE (user1_id = ${userId} OR user2_id = ${userId}
           OR user1_id = ${partnerUserId} OR user2_id = ${partnerUserId})
          AND status = 'active'
      `;

      // Create new couple
      const result = await sql`
        INSERT INTO couples (user1_id, user2_id, relationship_status, started_at, met_on_mazl_at, status)
        VALUES (${userId}, ${partnerUserId}, 'in_relationship', NOW(), NOW(), 'active')
        RETURNING id
      `;
      coupleId = (result[0] as any).id;
    }

    return c.json({
      success: true,
      message: `Couple mode enabled for user ${userId} with partner ${partnerUserId}`,
      coupleId
    });
  } catch (error: any) {
    console.error("Enable couple mode error:", error);
    return c.json({ success: false, error: `Failed: ${error.message}` }, 500);
  }
});

// Disable couple mode for testing (dev endpoint)
app.post("/api/dev/couple/disable", async (c) => {
  if (IS_PRODUCTION) return c.json({ error: "Not found" }, 404);
  try {
    const body = await c.req.json();
    const { userId } = body;

    if (!userId) {
      return c.json({ success: false, error: "userId required" }, 400);
    }

    // End all active couples for this user
    const result = await sql`
      UPDATE couples SET status = 'ended', updated_at = NOW()
      WHERE (user1_id = ${userId} OR user2_id = ${userId})
        AND status = 'active'
      RETURNING id
    `;

    return c.json({
      success: true,
      message: `Couple mode disabled for user ${userId}`,
      endedCouples: result.length
    });
  } catch (error: any) {
    console.error("Disable couple mode error:", error);
    return c.json({ success: false, error: `Failed: ${error.message}` }, 500);
  }
});

// Get couple status for debugging (dev endpoint)
app.get("/api/dev/couple/status/:userId", async (c) => {
  if (IS_PRODUCTION) return c.json({ error: "Not found" }, 404);
  try {
    const userId = parseInt(c.req.param("userId"));

    const couples = await sql`
      SELECT c.*,
        CASE WHEN c.user1_id = ${userId} THEN c.user2_id ELSE c.user1_id END as partner_id,
        CASE WHEN c.user1_id = ${userId} THEN p2.display_name ELSE p1.display_name END as partner_name
      FROM couples c
      LEFT JOIN profiles p1 ON p1.user_id = c.user1_id
      LEFT JOIN profiles p2 ON p2.user_id = c.user2_id
      WHERE c.user1_id = ${userId} OR c.user2_id = ${userId}
      ORDER BY c.created_at DESC
    `;

    return c.json({
      success: true,
      userId,
      activeCouple: couples.find((c: any) => c.status === 'active') || null,
      allCouples: couples
    });
  } catch (error: any) {
    console.error("Get couple status error:", error);
    return c.json({ success: false, error: `Failed: ${error.message}` }, 500);
  }
});

// Reset swipes by email (dev endpoint)
app.get("/api/dev/reset-swipes/:email", async (c) => {
  if (IS_PRODUCTION) return c.json({ error: "Not found" }, 404);
  const email = c.req.param("email");
  if (!email) {
    return c.json({ success: false, error: "email required" }, 400);
  }

  try {
    console.log("Looking for user with email:", email);
    const user = await findUserByEmail(email);
    console.log("Found user:", user);
    if (!user) {
      return c.json({ success: false, error: `User not found with email: ${email}` }, 404);
    }

    const result = await resetUserSwipes(user.id);
    return c.json({ success: true, message: `Swipes reset for ${email} (user ${user.id})`, ...result });
  } catch (error: any) {
    console.error("Reset swipes error:", error);
    return c.json({ success: false, error: `Failed to reset swipes: ${error.message}` }, 500);
  }
});


// ============ COUPLE MODE (feature) ============
// All `/api/couple/*` endpoints live in src/features/couple/*. They are
// registered here — at their original location in the route table — preserving
// the exact declaration order (literals before parameterised routes).
registerCoupleRoutes(app);




// Track email open (pixel tracking)
app.get("/api/track/open", async (c) => {
  const campaignId = parseInt(c.req.query("c") || "0");
  const userId = parseInt(c.req.query("u") || "0");

  if (campaignId && userId) {
    try {
      const { trackCampaignOpen } = await import("./db");
      await trackCampaignOpen(campaignId, userId);
    } catch (e) {
      // Ignore tracking errors
    }
  }

  // Return 1x1 transparent GIF
  const gif = Buffer.from("R0lGODlhAQABAIAAAAAAAP///yH5BAEAAAAALAAAAAABAAEAAAIBRAA7", "base64");
  return new Response(gif, {
    headers: {
      "Content-Type": "image/gif",
      "Cache-Control": "no-store, no-cache, must-revalidate",
    },
  });
});

// Unsubscribe endpoint (public)
app.get("/api/unsubscribe", async (c) => {
  const email = c.req.query("email");
  if (!email) {
    return c.html("<h1>Email manquant</h1>");
  }

  await unsubscribeEmail(email);
  return c.html(`
    <html>
      <head><title>Désinscription</title></head>
      <body style="font-family: sans-serif; text-align: center; padding: 50px;">
        <h1>✅ Désinscrit</h1>
        <p>Vous avez été désinscrit de nos emails marketing.</p>
      </body>
    </html>
  `);
});

// ============ MODULE 4: MODÉRATION & SIGNALEMENTS ============

// Block a user
app.post("/api/users/:id/block", requireAuth, async (c) => {
  try {
    const userId = c.get("userId");
    const blockedId = Number.parseInt(c.req.param("id"), 10);
    if (Number.isNaN(blockedId)) {
      return c.json({ success: false, error: "Invalid user id" }, 400);
    }
    if (blockedId === userId) {
      return c.json({ success: false, error: "Cannot block yourself" }, 400);
    }

    await blockUser(userId, blockedId);
    return c.json({ success: true });
  } catch (error) {
    console.error("Block user error:", error);
    return c.json({ success: false, error: "Failed to block user" }, 500);
  }
});

// Unblock a user
app.delete("/api/users/:id/block", requireAuth, async (c) => {
  try {
    const userId = c.get("userId");
    const blockedId = Number.parseInt(c.req.param("id"), 10);
    if (Number.isNaN(blockedId)) {
      return c.json({ success: false, error: "Invalid user id" }, 400);
    }

    await unblockUser(userId, blockedId);
    return c.json({ success: true });
  } catch (error) {
    console.error("Unblock user error:", error);
    return c.json({ success: false, error: "Failed to unblock user" }, 500);
  }
});

// List profiles blocked by the current user
app.get("/api/users/blocked", requireAuth, async (c) => {
  try {
    const userId = c.get("userId");
    const blocked = await getBlockedUsers(userId);
    return c.json({ success: true, blocked });
  } catch (error) {
    console.error("Get blocked users error:", error);
    return c.json({ success: false, error: "Failed to get blocked users" }, 500);
  }
});

// Report a user (mobile alias for POST /api/report, with optional block)
app.post("/api/users/:id/report", requireAuth, async (c) => {
  try {
    const userId = c.get("userId");
    const reportedUserId = Number.parseInt(c.req.param("id"), 10);
    if (Number.isNaN(reportedUserId)) {
      return c.json({ success: false, error: "Invalid user id" }, 400);
    }

    const parsed = await parseBody(reportUserBodySchema, c);
    if (!parsed.ok) {
      return c.json({ success: false, error: parsed.error }, 400);
    }
    const body = parsed.data;
    const category = body.category;
    const comment = body.comment;
    const blockUserFlag = body.block_user === true;

    if (!category) {
      return c.json({ success: false, error: "Category required" }, 400);
    }

    const report = await createReport({
      reporterId: userId,
      reportedUserId,
      reason: category,
      details: comment,
    });

    if (blockUserFlag && reportedUserId !== userId) {
      await blockUser(userId, reportedUserId);
    }

    return c.json({ success: true, report, blocked: blockUserFlag && reportedUserId !== userId });
  } catch (error) {
    console.error("Report user error:", error);
    return c.json({ success: false, error: "Failed to create report" }, 500);
  }
});

// Report user (from mobile app)
app.post("/api/report", requireAuth, async (c) => {
  try {
    const userId = c.get("userId");

    const { reportedUserId, reason, details } = await c.req.json();

    if (!reportedUserId || !reason) {
      return c.json({ success: false, error: "Reported user ID and reason required" }, 400);
    }

    const report = await createReport({
      reporterId: userId,
      reportedUserId,
      reason,
      details,
    });

    return c.json({ success: true, report });
  } catch (error: any) {
    console.error("Report error:", error);
    return c.json({ success: false, error: "Failed to create report" }, 500);
  }
});


// Health check
app.get("/api/health", (c) => c.json({ status: "ok" }));

// Initialize and start
const port = Number.parseInt(process.env.PORT || "3000", 10);

await mkdir(UPLOADS_DIR, { recursive: true });

await initDb();

console.log(`Server running on http://localhost:${port}`);

// ============ WEBSOCKET FOR REAL-TIME CHAT ============
// The connection registry (`sendToUser`, `addConnection`, `removeConnection`)
// and `emitNewMatch` now live in `src/shared/realtime/connections.ts` and are
// imported above. The `Bun.serve` websocket handlers below use those helpers.

// Bun.serve with WebSocket support
interface WebSocketData {
  userId: number;
}

const server = Bun.serve<WebSocketData>({
  port,
  fetch(req, server) {
    const url = new URL(req.url);

    // Handle WebSocket upgrade for /ws path
    if (url.pathname === "/ws") {
      const token = url.searchParams.get("token");
      if (!token) {
        return new Response("Token required", { status: 401 });
      }

      const payload = verifyJWT(token);
      if (!payload) {
        return new Response("Invalid token", { status: 401 });
      }

      const userId = parseInt(payload.sub);
      const upgraded = server.upgrade(req, {
        data: { userId },
      });

      if (upgraded) {
        return undefined;
      }
      return new Response("WebSocket upgrade failed", { status: 500 });
    }

    // Handle regular HTTP requests with Hono
    return app.fetch(req);
  },
  websocket: {
    open(ws) {
      const userId = (ws.data as any)?.userId as number;
      if (userId) {
        addConnection(userId, ws as unknown as WebSocket);
        console.log(`WebSocket connected: user ${userId}`);
      }
    },
    async message(ws, message) {
      const userId = (ws.data as any)?.userId as number;
      if (!userId) return;

      try {
        const data = JSON.parse(message.toString());

        switch (data.type) {
          case "chat:send": {
            // Send message via API and broadcast.
            // The mobile client wraps fields inside `payload` (see
            // mobile/lib/core/services/websocket_service.dart:247-255).
            const payload = data.payload;
            if (typeof payload !== "object" || payload === null) return;
            const conversationId = (payload as Record<string, unknown>).conversationId;
            const content = (payload as Record<string, unknown>).content;
            if (typeof conversationId !== "number" || typeof content !== "string") return;
            if (content.length === 0) return;

            const conversation = await getConversationById(conversationId);
            if (!conversation) return;

            // Verify user is in conversation
            const conv = conversation as any;
            if (conv.user1_id !== userId && conv.user2_id !== userId) return;

            // Determine other user
            const otherUserId = conv.user1_id === userId ? conv.user2_id : conv.user1_id;

            // Refuse silently if either party has blocked the other
            if (await isBlockedBetween(userId, otherUserId)) return;

            const msg = await createMessage(conversationId, userId, content);

            // Send to both users
            const messageData = {
              type: "chat:message",
              payload: {
                conversationId,
                messageId: (msg as any).id,
                senderId: userId,
                content: (msg as any).content,
                createdAt: (msg as any).created_at,
              },
            };
            sendToUser(userId, messageData);
            sendToUser(otherUserId, messageData);
            break;
          }

          case "chat:typing": {
            // Broadcast typing indicator.
            // Fields are nested under `payload` (see
            // mobile/lib/core/services/websocket_service.dart:258-265).
            const payload = data.payload;
            if (typeof payload !== "object" || payload === null) return;
            const conversationId = (payload as Record<string, unknown>).conversationId;
            const isTypingRaw = (payload as Record<string, unknown>).isTyping;
            if (typeof conversationId !== "number") return;
            const isTyping = typeof isTypingRaw === "boolean" ? isTypingRaw : true;

            const conversation = await getConversationById(conversationId);
            if (!conversation) return;

            const conv = conversation as any;
            if (conv.user1_id !== userId && conv.user2_id !== userId) return;

            const otherUserId = conv.user1_id === userId ? conv.user2_id : conv.user1_id;
            sendToUser(otherUserId, {
              type: "chat:typing",
              payload: {
                conversationId,
                userId,
                isTyping,
              },
            });
            break;
          }

          case "chat:read": {
            // Mark messages as read and notify.
            // Fields are nested under `payload` (see
            // mobile/lib/core/services/websocket_service.dart:269-275).
            const payload = data.payload;
            if (typeof payload !== "object" || payload === null) return;
            const conversationId = (payload as Record<string, unknown>).conversationId;
            if (typeof conversationId !== "number") return;

            const conversation = await getConversationById(conversationId);
            if (!conversation) return;

            const conv = conversation as any;
            if (conv.user1_id !== userId && conv.user2_id !== userId) return;

            await markMessagesAsRead(conversationId, userId);

            const otherUserId = conv.user1_id === userId ? conv.user2_id : conv.user1_id;
            sendToUser(otherUserId, {
              type: "chat:read",
              payload: {
                conversationId,
                userId,
              },
            });
            break;
          }

          case "ping": {
            (ws as any).send(JSON.stringify({ type: "pong" }));
            break;
          }
        }
      } catch (err) {
        console.error("WebSocket message error:", err);
      }
    },
    close(ws) {
      const userId = (ws.data as any)?.userId as number;
      if (userId) {
        removeConnection(userId, ws as unknown as WebSocket);
        console.log(`WebSocket disconnected: user ${userId}`);
      }
    },
  },
});

console.log(`Server with WebSocket running on http://localhost:${port}`);
