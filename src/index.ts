import { Hono } from "hono";
import type { Context } from "hono";
import { z } from "zod";
import { serveStatic } from "hono/bun";
import { cors } from "hono/cors";
import { mkdir } from "node:fs/promises";
import { join } from "node:path";
import {
  sql,
  createDocument,
  findWaitlistByVerificationToken,
  getDocumentById,
  getTotalCount,
  initDb,
  listPendingSubmissions,
  markVerificationSubmitted,
  setDocumentReview,
  setDocumentsReviewBulk,
  getDocumentTypesByIds,
  getWaitlistEmailById,
  upsertWaitlistAndGetVerification,
  getLatestDocumentsByType,
  setWaitlistVerificationStatus,
  setWaitlistOS,
  rejectAllDocumentsForWaitlist,
  approveAllDocumentsForWaitlist,
  requestReuploadAndRotateToken,
  listVerifiedProfiles,
  findUserByEmail,
  getFullProfile,
  upsertProfile,
  getDiscoverProfiles,
  // Boost
  activateBoost,
  getActiveBoost,
  getBoostsUsedToday,
  recordSwipe,
  getMatches,
  // Received likes
  getReceivedLikes,
  getReceivedLikesCount,
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
  createEvent,
  updateEvent,
  deleteEvent,
  getEvents,
  getEventById,
  getEventAttendees,
  // Subscriptions
  getAllSubscriptions,
  // Admin
  getAdminStats,
  getAdminUsers,
  setUserActiveStatus,
  seedFakeProfiles,
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
  resetAllSwipes,
  // Module 1: Gestion Membres
  getAdminUserDetail,
  banUser,
  unbanUser,
  addAdminNote,
  getUserActivity,
  deleteUserCompletely,
  setUserVerificationLevel,
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
  addEventPhoto,
  getEventPhotos,
  deleteEventPhoto,
  checkInAttendee,
  getEventFullDetails,
  exportEventAttendees,
  duplicateEvent,
  // Module 3: Campagnes
  createCampaign,
  updateCampaign as updateCampaignDb,
  getCampaigns,
  getCampaignById,
  deleteCampaign,
  sendCampaign,
  createSegment,
  getSegments,
  unsubscribeEmail,
  // Module 4: Modération
  createReport,
  blockUser,
  unblockUser,
  getBlockedUsers,
  isBlockedBetween,
  getReports,
  handleReport,
  getPendingPhotos,
  approvePhoto,
  rejectPhoto,
  getModerationLogs,
  getReportStats,
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
import { sendProfileApprovedEmail, sendReuploadRequestedEmail, sendVerificationRequestEmail, sendCampaignEmail } from "./email";
import { verifyGoogleIdToken, generateJWT, verifyJWT } from "./auth";
import { sendPushToUsers, sendPushToAll } from "./onesignal";
import { requireAuth, type AppVariables } from "./shared/http/middleware";
import { registerAuthRoutes } from "./features/auth/auth.routes";
import { registerEventsRoutes } from "./features/events/events.routes";
import { registerSubscriptionsRoutes } from "./features/subscriptions/subscriptions.routes";

const app = new Hono<{ Variables: AppVariables }>();

// ============ INPUT VALIDATION (permissive safety net) ============
// These schemas only guard the TYPES of fields actually read by each handler
// and the presence of fields the handler logic already requires. They use
// `.passthrough()` so extra fields from the mobile app are never rejected, and
// keep optional anything the handler already treats as optional. On failure the
// caller returns the same `{ success: false, error }` 400 shape as the rest of
// the file — business logic and success responses are unchanged.

type BodyParseResult<T> =
  | { ok: true; data: T }
  | { ok: false; error: string };

async function parseBody<T>(
  schema: z.ZodType<T>,
  c: Context<{ Variables: AppVariables }>,
): Promise<BodyParseResult<T>> {
  let raw: unknown;
  try {
    raw = await c.req.json();
  } catch {
    return { ok: false, error: "Invalid JSON body" };
  }
  const parsed = schema.safeParse(raw);
  if (!parsed.success) {
    const first = parsed.error.issues[0];
    const path = first?.path.join(".");
    const message = first
      ? path
        ? `${path}: ${first.message}`
        : first.message
      : "Invalid request body";
    return { ok: false, error: message };
  }
  return { ok: true, data: parsed.data };
}

const swipeBodySchema = z
  .object({
    target_user_id: z.number(),
    action: z.enum(["like", "pass", "super_like"]),
  })
  .passthrough();

const reportUserBodySchema = z
  .object({
    category: z.string().optional(),
    comment: z.string().optional(),
    block_user: z.boolean().optional(),
  })
  .passthrough();

const coupleRequestBodySchema = z
  .object({
    target_user_id: z.number(),
  })
  .passthrough();

const coupleRespondBodySchema = z
  .object({
    action: z.enum(["accept", "reject"]),
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

function getAdminPassword(c: Context): string {
  // Only accept the admin password via header, never via query string
  // (query strings leak into logs, browser history and Referer headers).
  return c.req.header("x-admin-password") || "";
}

// Admin JWT secret (use a different secret than user JWT).
// Fail fast at boot rather than silently falling back to a hard-coded secret.
const ADMIN_JWT_SECRET: string = (() => {
  const secret = process.env.ADMIN_JWT_SECRET || process.env.JWT_SECRET;
  if (!secret) {
    throw new Error(
      "ADMIN_JWT_SECRET (or JWT_SECRET) must be set; refusing to start with a hard-coded admin secret",
    );
  }
  return secret;
})();

// Generate admin JWT token
function generateAdminJWT(email: string): string {
  const header = { alg: "HS256", typ: "JWT" };
  const payload = {
    email,
    role: "admin",
    iat: Math.floor(Date.now() / 1000),
    exp: Math.floor(Date.now() / 1000) + 86400 * 7, // 7 days
  };

  const base64Header = btoa(JSON.stringify(header)).replace(/=/g, "");
  const base64Payload = btoa(JSON.stringify(payload)).replace(/=/g, "");
  const data = `${base64Header}.${base64Payload}`;

  const encoder = new TextEncoder();
  const keyData = encoder.encode(ADMIN_JWT_SECRET);
  const messageData = encoder.encode(data);

  // Simple HMAC-SHA256 using Web Crypto (sync version for Bun)
  const crypto = require("crypto");
  const hmac = crypto.createHmac("sha256", ADMIN_JWT_SECRET);
  hmac.update(data);
  const signature = hmac.digest("base64url");

  return `${data}.${signature}`;
}

// Verify admin JWT token
function verifyAdminJWT(token: string): { valid: boolean; email?: string; error?: string } {
  try {
    const parts = token.split(".");
    if (parts.length !== 3) return { valid: false, error: "Invalid token format" };

    const [header, payload, signature] = parts;
    if (!header || !payload || !signature) return { valid: false, error: "Invalid token format" };
    const data = `${header}.${payload}`;

    // Verify signature
    const crypto = require("crypto");
    const hmac = crypto.createHmac("sha256", ADMIN_JWT_SECRET);
    hmac.update(data);
    const expectedSig = hmac.digest("base64url");

    if (signature !== expectedSig) return { valid: false, error: "Invalid signature" };

    // Decode payload
    const decodedPayload = JSON.parse(atob(payload));

    // Check expiration
    if (decodedPayload.exp && decodedPayload.exp < Math.floor(Date.now() / 1000)) {
      return { valid: false, error: "Token expired" };
    }

    // Check role
    if (decodedPayload.role !== "admin") {
      return { valid: false, error: "Not an admin token" };
    }

    return { valid: true, email: decodedPayload.email };
  } catch (e) {
    return { valid: false, error: "Token verification failed" };
  }
}

type AdminAuthResult = { ok: true; email?: string } | { ok: false; error: string };

function assertAdmin(c: Context): AdminAuthResult {
  // Admin JWT token from the Authorization header only (no query-string tokens:
  // they leak into logs, history and Referer headers).
  const authHeader = c.req.header("Authorization") || "";
  if (authHeader.startsWith("Bearer ")) {
    const token = authHeader.substring(7);
    const result = verifyAdminJWT(token);
    if (result.valid) {
      return { ok: true, email: result.email };
    }
  }

  // Fallback to password method via header only (for backward compatibility).
  const required = process.env.ADMIN_PASSWORD;
  if (!required) return { ok: false, error: "ADMIN_PASSWORD not set" };
  if (getAdminPassword(c) !== required) return { ok: false, error: "Unauthorized" };
  return { ok: true };
}

// Admin auth for browser file downloads only. An <a href> navigation cannot set
// an Authorization header, so this single read-only endpoint additionally accepts
// a signed admin JWT via the `token` query param. No password is ever accepted here.
function assertAdminFileDownload(c: Context): AdminAuthResult {
  const headerResult = assertAdmin(c);
  if (headerResult.ok) return headerResult;

  const tokenParam = c.req.query("token");
  if (tokenParam) {
    const result = verifyAdminJWT(tokenParam);
    if (result.valid) {
      return { ok: true, email: result.email };
    }
  }

  return { ok: false, error: "Unauthorized" };
}

// IDOR guard: confirm the authenticated user is a member of the target couple.
// getCouple(userId) returns only the caller's own active couple (with its id),
// so a matching id proves membership.
async function assertCoupleMembership(
  userId: number,
  coupleId: number,
): Promise<boolean> {
  if (Number.isNaN(coupleId)) return false;
  const couple = await getCouple(userId);
  if (!couple) return false;
  const ownedId = Number((couple as { id: number }).id);
  return ownedId === coupleId;
}

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

// Admin Authentication
app.post("/api/admin/login", async (c) => {
  try {
    const { email, password } = await c.req.json();

    // Get admin credentials from environment
    const adminEmail = process.env.ADMIN_EMAIL;
    const adminPassword = process.env.ADMIN_PASSWORD;

    if (!adminEmail || !adminPassword) {
      console.error("ADMIN_EMAIL or ADMIN_PASSWORD not configured");
      return c.json({ success: false, error: "Configuration serveur manquante" }, 500);
    }

    // Validate credentials
    if (email !== adminEmail || password !== adminPassword) {
      return c.json({ success: false, error: "Email ou mot de passe incorrect" }, 401);
    }

    // Generate JWT token
    const token = generateAdminJWT(email);

    return c.json({
      success: true,
      token,
      email,
    });
  } catch (e) {
    console.error("Admin login error:", e);
    return c.json({ success: false, error: "Erreur serveur" }, 500);
  }
});

// Admin whitelist for Google login
const ADMIN_EMAILS = [
  "renaudlemagicien@gmail.com",
  process.env.ADMIN_EMAIL,
].filter(Boolean);

// Google login for admin
app.post("/api/admin/google-login", async (c) => {
  try {
    const { idToken, email: directEmail } = await c.req.json();

    let email: string | null = null;

    // If we have an ID token, verify it
    if (idToken) {
      const payload = await verifyGoogleIdToken(idToken);
      if (!payload || !payload.email) {
        return c.json({ success: false, error: "Token Google invalide" }, 401);
      }
      email = payload.email;
    } else if (directEmail) {
      // Direct email (from OAuth2 access token flow)
      email = directEmail;
    }

    if (!email) {
      return c.json({ success: false, error: "Email non fourni" }, 400);
    }

    // Check if email is in admin whitelist
    if (!ADMIN_EMAILS.includes(email)) {
      console.log(`Admin login attempt rejected for: ${email}`);
      return c.json({ success: false, error: "Cet email n'est pas autorise" }, 403);
    }

    // Generate admin JWT
    const token = generateAdminJWT(email);

    console.log(`Admin logged in via Google: ${email}`);

    return c.json({
      success: true,
      token,
      email,
    });
  } catch (e) {
    console.error("Admin Google login error:", e);
    return c.json({ success: false, error: "Erreur serveur" }, 500);
  }
});

app.get("/api/admin/verify", async (c) => {
  const auth = assertAdmin(c);
  if (!auth.ok) return c.json({ success: false, error: auth.error }, 401);

  return c.json({
    success: true,
    email: (auth as any).email,
  });
});

// Admin
app.get("/api/admin/pending", async (c) => {
  const auth = assertAdmin(c);
  if (!auth.ok) return c.json({ success: false, error: auth.error }, 401);

  const items = await listPendingSubmissions();
  return c.json({ success: true, items });
});

app.get("/api/admin/verified", async (c) => {
  const auth = assertAdmin(c);
  if (!auth.ok) return c.json({ success: false, error: auth.error }, 401);

  const items = await listVerifiedProfiles();
  return c.json({ success: true, items });
});

app.post("/api/admin/documents/:id/approve", async (c) => {
  const auth = assertAdmin(c);
  if (!auth.ok) return c.json({ success: false, error: auth.error }, 401);

  const documentId = Number.parseInt(c.req.param("id"), 10);
  await setDocumentReview({ documentId, status: "approved" });
  return c.json({ success: true });
});

app.post("/api/admin/profiles/:id/approve", async (c) => {
  const auth = assertAdmin(c);
  if (!auth.ok) return c.json({ success: false, error: auth.error }, 401);

  const waitlistId = Number.parseInt(c.req.param("id"), 10);
  const latest = await getLatestDocumentsByType(waitlistId);
  const required = ["selfie_id", "id_card_front", "id_card_back"];
  const missing = required.filter((t) => !latest[t] || latest[t].status === "rejected");

  if (missing.length > 0) {
    return c.json({ success: false, error: `Docs manquants: ${missing.join(", ")}` }, 400);
  }

  await approveAllDocumentsForWaitlist(waitlistId);

  const hasCommunity = Boolean(latest["community_doc"] && latest["community_doc"].status === "approved");
  const level = hasCommunity ? "verified_plus" : "verified";
  await setWaitlistVerificationStatus(waitlistId, level);

  // Email (best-effort)
  try {
    const forwardedProto = c.req.header("x-forwarded-proto") || "https";
    const forwardedHost = c.req.header("x-forwarded-host") || c.req.header("host") || "";
    const requestOrigin = forwardedHost ? `${forwardedProto}://${forwardedHost}` : undefined;
    const email = await getWaitlistEmailById(waitlistId);
    if (email) {
      await sendProfileApprovedEmail({ to: email, baseUrl: requestOrigin, level });
    }
  } catch (err) {
    console.error("Approved email failed:", err);
  }

  return c.json({ success: true });
});

app.post("/api/admin/profiles/:id/request-reupload", async (c) => {
  const auth = assertAdmin(c);
  if (!auth.ok) return c.json({ success: false, error: auth.error }, 401);

  const waitlistId = Number.parseInt(c.req.param("id"), 10);
  const body = await c.req.json().catch(() => ({}));
  const notes = (body?.notes || "").toString();

  await rejectAllDocumentsForWaitlist(waitlistId, notes || "reupload requested");

  // Rotate token so previous links become invalid
  const rotated = await requestReuploadAndRotateToken(waitlistId);

  // Send email with reason (best-effort)
  try {
    const forwardedProto = c.req.header("x-forwarded-proto") || "https";
    const forwardedHost = c.req.header("x-forwarded-host") || c.req.header("host") || "";
    const requestOrigin = forwardedHost ? `${forwardedProto}://${forwardedHost}` : undefined;

    await sendReuploadRequestedEmail({
      to: rotated.email,
      verificationToken: rotated.verificationToken,
      reason: notes,
      rejectedTypes: ["selfie_id", "id_card_front", "id_card_back"],
      baseUrl: requestOrigin,
    });
  } catch (err) {
    console.error("Reupload email failed:", err);
  }

  return c.json({ success: true });
});

app.post("/api/admin/profiles/:id/review", async (c) => {
  const auth = assertAdmin(c);
  if (!auth.ok) return c.json({ success: false, error: auth.error }, 401);

  const waitlistId = Number.parseInt(c.req.param("id"), 10);
  const body = await c.req.json().catch(() => ({}));

  const approveDocumentIds = Array.isArray(body?.approveDocumentIds)
    ? body.approveDocumentIds.map((n: any) => Number.parseInt(String(n), 10)).filter((n: number) => Number.isFinite(n))
    : [];

  const rejectDocumentIds = Array.isArray(body?.rejectDocumentIds)
    ? body.rejectDocumentIds.map((n: any) => Number.parseInt(String(n), 10)).filter((n: number) => Number.isFinite(n))
    : [];

  const approveProfile = Boolean(body?.approveProfile);
  const reason = (body?.reason || body?.notes || "").toString().trim();

  if (rejectDocumentIds.length > 0 && !reason) {
    return c.json({ success: false, error: "Motif requis" }, 400);
  }

  // Apply doc reviews
  await setDocumentsReviewBulk({ waitlistId, documentIds: approveDocumentIds, status: "approved" });
  await setDocumentsReviewBulk({ waitlistId, documentIds: rejectDocumentIds, status: "rejected", notes: reason });

  // If any rejected => reset to pending + rotate token + email
  if (rejectDocumentIds.length > 0) {
    const rejectedTypes = await getDocumentTypesByIds({ waitlistId, documentIds: rejectDocumentIds });
    const rotated = await requestReuploadAndRotateToken(waitlistId);

    try {
      const forwardedProto = c.req.header("x-forwarded-proto") || "https";
      const forwardedHost = c.req.header("x-forwarded-host") || c.req.header("host") || "";
      const requestOrigin = forwardedHost ? `${forwardedProto}://${forwardedHost}` : undefined;

      await sendReuploadRequestedEmail({
        to: rotated.email,
        verificationToken: rotated.verificationToken,
        reason,
        rejectedTypes,
        baseUrl: requestOrigin,
      });
    } catch (err) {
      console.error("Reupload email failed:", err);
    }

    return c.json({ success: true, status: "pending" });
  }

  // Optional: validate profile
  if (approveProfile) {
    const latest = await getLatestDocumentsByType(waitlistId);
    const required = ["selfie_id", "id_card_front", "id_card_back"];
    const missing = required.filter((t) => !latest[t] || latest[t].status === "rejected");
    if (missing.length > 0) {
      return c.json({ success: false, error: `Docs manquants: ${missing.join(", ")}` }, 400);
    }

    await approveAllDocumentsForWaitlist(waitlistId);

    const hasCommunity = Boolean(latest["community_doc"] && latest["community_doc"].status === "approved");
    const level = hasCommunity ? "verified_plus" : "verified";
    await setWaitlistVerificationStatus(waitlistId, level);

    try {
      const forwardedProto = c.req.header("x-forwarded-proto") || "https";
      const forwardedHost = c.req.header("x-forwarded-host") || c.req.header("host") || "";
      const requestOrigin = forwardedHost ? `${forwardedProto}://${forwardedHost}` : undefined;
      const email = await getWaitlistEmailById(waitlistId);
      if (email) {
        await sendProfileApprovedEmail({ to: email, baseUrl: requestOrigin, level });
      }
    } catch (err) {
      console.error("Approved email failed:", err);
    }

    return c.json({ success: true, status: "verified" });
  }

  return c.json({ success: true });
});

app.post("/api/admin/documents/:id/reject", async (c) => {
  const auth = assertAdmin(c);
  if (!auth.ok) return c.json({ success: false, error: auth.error }, 401);

  const documentId = Number.parseInt(c.req.param("id"), 10);
  const body = await c.req.json().catch(() => ({}));
  await setDocumentReview({ documentId, status: "rejected", notes: body?.notes });
  return c.json({ success: true });
});

app.get("/api/admin/documents/:id/file", async (c) => {
  const auth = assertAdminFileDownload(c);
  if (!auth.ok) return c.json({ success: false, error: auth.error }, 401);

  const documentId = Number.parseInt(c.req.param("id"), 10);
  const doc = await getDocumentById(documentId);
  if (!doc) return c.json({ success: false, error: "Not found" }, 404);

  const path = join(UPLOADS_DIR, doc.filename);
  const file = Bun.file(path);
  if (!(await file.exists())) return c.json({ success: false, error: "Missing file" }, 404);

  return new Response(file, {
    headers: {
      "content-type": doc.mime_type || "application/octet-stream",
      "cache-control": "no-store",
    },
  });
});

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

// Get profiles for discovery
app.get("/api/discover", requireAuth, async (c) => {
  try {
    const userId = c.get("userId");
    const limit = parseInt(c.req.query("limit") || "20");
    const offset = parseInt(c.req.query("offset") || "0");

    const profiles = await getDiscoverProfiles(userId, limit, offset);

    return c.json({ success: true, profiles });
  } catch (error: any) {
    console.error("Discover error:", error);
    return c.json({ success: false, error: "Failed to get profiles" }, 500);
  }
});

// Get daily picks (curated selection of profiles)
app.get("/api/daily-picks", requireAuth, async (c) => {
  try {
    const userId = c.get("userId");

    // Get profiles and return top 5 as daily picks
    const profiles = await getDiscoverProfiles(userId, 5, 0);

    // Add "picked today" timestamp
    const today = new Date().toISOString().split('T')[0];

    return c.json({
      success: true,
      picks: profiles,
      date: today,
      refreshesAt: new Date(new Date().setHours(24, 0, 0, 0)).toISOString()
    });
  } catch (error: any) {
    console.error("Daily picks error:", error);
    return c.json({ success: false, error: "Failed to get daily picks" }, 500);
  }
});

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

// Record swipe action
app.post("/api/swipes", requireAuth, async (c) => {
  try {
    const userId = c.get("userId");
    const parsed = await parseBody(swipeBodySchema, c);
    if (!parsed.ok) {
      return c.json({ success: false, error: parsed.error }, 400);
    }
    const { target_user_id, action } = parsed.data;

    const result = await recordSwipe(userId, target_user_id, action);

    // On a reciprocal match, notify both users over WebSocket if connected.
    if (result.match) {
      await emitNewMatch(userId, target_user_id);
    }

    return c.json({ success: true, ...result });
  } catch (error: any) {
    console.error("Swipe error:", error);
    return c.json({ success: false, error: "Failed to record swipe" }, 500);
  }
});

// Get user's matches
app.get("/api/matches", requireAuth, async (c) => {
  try {
    const userId = c.get("userId");
    const matches = await getMatches(userId);

    return c.json({ success: true, matches });
  } catch (error: any) {
    console.error("Matches error:", error);
    return c.json({ success: false, error: "Failed to get matches" }, 500);
  }
});

// ============ RECEIVED LIKES ============

// Profiles of users who liked me but with whom I have not matched yet.
app.get("/api/likes/received", requireAuth, async (c) => {
  try {
    const userId = c.get("userId");

    const rows = await getReceivedLikes(userId);
    const likes = rows.map((r) => ({
      user_id: r.user_id,
      display_name: r.display_name,
      picture: r.picture,
      age: r.age !== null ? Math.trunc(r.age) : null,
      is_verified: r.is_verified === true,
      liked_at: r.liked_at,
    }));

    return c.json({ success: true, count: likes.length, likes });
  } catch (error: unknown) {
    console.error("Received likes error:", error);
    return c.json({ success: false, error: "Failed to get received likes" }, 500);
  }
});

// Count of received likes.
app.get("/api/likes/received/count", requireAuth, async (c) => {
  try {
    const userId = c.get("userId");

    const count = await getReceivedLikesCount(userId);
    return c.json({ success: true, count });
  } catch (error: unknown) {
    console.error("Received likes count error:", error);
    return c.json({ success: false, error: "Failed to get likes count" }, 500);
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

// ============ ADMIN EVENTS ENDPOINTS ============

// Get all events (admin)
app.get("/api/admin/events", async (c) => {
  const auth = assertAdmin(c);
  if (!auth.ok) return c.json({ success: false, error: auth.error }, 401);

  try {
    const limit = parseInt(c.req.query("limit") || "50");
    const offset = parseInt(c.req.query("offset") || "0");

    const events = await getEvents({
      publishedOnly: false,
      limit,
      offset,
    });

    return c.json({ success: true, events });
  } catch (error: any) {
    console.error("Admin events error:", error);
    return c.json({ success: false, error: "Failed to get events" }, 500);
  }
});

// Create event (admin)
app.post("/api/admin/events", async (c) => {
  const auth = assertAdmin(c);
  if (!auth.ok) return c.json({ success: false, error: auth.error }, 401);

  try {
    const body = await c.req.json();

    if (!body.title || !body.date) {
      return c.json({ success: false, error: "Title and date required" }, 400);
    }

    const event = await createEvent({
      title: body.title,
      description: body.description,
      eventType: body.eventType,
      location: body.location,
      address: body.address,
      latitude: body.latitude,
      longitude: body.longitude,
      date: body.date,
      time: body.time,
      endTime: body.endTime,
      price: body.price,
      currency: body.currency,
      maxAttendees: body.maxAttendees,
      imageUrl: body.imageUrl,
      isPublished: body.isPublished ?? false,
    });

    return c.json({ success: true, event });
  } catch (error: any) {
    console.error("Create event error:", error);
    return c.json({ success: false, error: "Failed to create event" }, 500);
  }
});

// Update event (admin)
app.put("/api/admin/events/:id", async (c) => {
  const auth = assertAdmin(c);
  if (!auth.ok) return c.json({ success: false, error: auth.error }, 401);

  try {
    const eventId = parseInt(c.req.param("id"));
    const body = await c.req.json();

    const event = await updateEvent(eventId, {
      title: body.title,
      description: body.description,
      eventType: body.eventType,
      location: body.location,
      address: body.address,
      latitude: body.latitude,
      longitude: body.longitude,
      date: body.date,
      time: body.time,
      endTime: body.endTime,
      price: body.price,
      currency: body.currency,
      maxAttendees: body.maxAttendees,
      imageUrl: body.imageUrl,
      isPublished: body.isPublished,
    });

    return c.json({ success: true, event });
  } catch (error: any) {
    console.error("Update event error:", error);
    return c.json({ success: false, error: "Failed to update event" }, 500);
  }
});

// Delete event (admin)
app.delete("/api/admin/events/:id", async (c) => {
  const auth = assertAdmin(c);
  if (!auth.ok) return c.json({ success: false, error: auth.error }, 401);

  try {
    const eventId = parseInt(c.req.param("id"));
    await deleteEvent(eventId);
    return c.json({ success: true });
  } catch (error: any) {
    console.error("Delete event error:", error);
    return c.json({ success: false, error: "Failed to delete event" }, 500);
  }
});

// Get event attendees (admin)
app.get("/api/admin/events/:id/attendees", async (c) => {
  const auth = assertAdmin(c);
  if (!auth.ok) return c.json({ success: false, error: auth.error }, 401);

  try {
    const eventId = parseInt(c.req.param("id"));
    const attendees = await getEventAttendees(eventId);
    return c.json({ success: true, attendees });
  } catch (error: any) {
    console.error("Event attendees error:", error);
    return c.json({ success: false, error: "Failed to get attendees" }, 500);
  }
});

// ============ ADMIN USERS ENDPOINTS ============

// Get admin stats
app.get("/api/admin/stats", async (c) => {
  const auth = assertAdmin(c);
  if (!auth.ok) return c.json({ success: false, error: auth.error }, 401);

  try {
    const stats = await getAdminStats();
    return c.json({ success: true, stats });
  } catch (error: any) {
    console.error("Admin stats error:", error);
    return c.json({ success: false, error: "Failed to get stats" }, 500);
  }
});

// Get users (admin)
app.get("/api/admin/users", async (c) => {
  const auth = assertAdmin(c);
  if (!auth.ok) return c.json({ success: false, error: auth.error }, 401);

  try {
    const search = c.req.query("search");
    const limit = parseInt(c.req.query("limit") || "50");
    const offset = parseInt(c.req.query("offset") || "0");

    const users = await getAdminUsers({
      search: search || undefined,
      limit,
      offset,
    });

    return c.json({ success: true, users });
  } catch (error: any) {
    console.error("Admin users error:", error);
    return c.json({ success: false, error: "Failed to get users" }, 500);
  }
});

// Update user status (admin)
app.put("/api/admin/users/:id/status", async (c) => {
  const auth = assertAdmin(c);
  if (!auth.ok) return c.json({ success: false, error: auth.error }, 401);

  try {
    const userId = parseInt(c.req.param("id"));
    const { isActive } = await c.req.json();

    if (typeof isActive !== "boolean") {
      return c.json({ success: false, error: "isActive boolean required" }, 400);
    }

    await setUserActiveStatus(userId, isActive);
    return c.json({ success: true });
  } catch (error: any) {
    console.error("Update user status error:", error);
    return c.json({ success: false, error: "Failed to update user status" }, 500);
  }
});

// ============ SUBSCRIPTIONS ENDPOINTS ============

// User-facing subscription status + the RevenueCat webhook now live in the
// subscriptions feature. The former POST /api/subscription/sync route was
// REMOVED during the audit (it let any authenticated user declare themselves
// premium); premium status is driven client-side by RevenueCat entitlements
// and the server is informed only via the authenticated webhook below.
registerSubscriptionsRoutes(app);

// Get all subscriptions (admin)
app.get("/api/admin/subscriptions", async (c) => {
  const auth = assertAdmin(c);
  if (!auth.ok) return c.json({ success: false, error: auth.error }, 401);

  try {
    const status = c.req.query("status");
    const limit = parseInt(c.req.query("limit") || "100");
    const offset = parseInt(c.req.query("offset") || "0");

    const subscriptions = await getAllSubscriptions({
      status: status || undefined,
      limit,
      offset,
    });

    return c.json({ success: true, subscriptions });
  } catch (error: any) {
    console.error("Admin subscriptions error:", error);
    return c.json({ success: false, error: "Failed to get subscriptions" }, 500);
  }
});

// Create test match (admin)
app.post("/api/admin/test-match", async (c) => {
  const auth = assertAdmin(c);
  if (!auth.ok) return c.json({ success: false, error: auth.error }, 401);

  try {
    const body = await c.req.json();
    const { userEmail, seedProfileIndex = 0 } = body;

    // Find user by email
    const userResult = await sql`SELECT id FROM users WHERE email = ${userEmail}`;
    if (userResult.length === 0) {
      return c.json({ success: false, error: "User not found" }, 404);
    }
    const userId = (userResult[0] as any).id;

    // Find a seed profile to match with
    const seedResult = await sql`
      SELECT id FROM users WHERE provider = 'seed'
      ORDER BY id
      LIMIT 1 OFFSET ${seedProfileIndex}
    `;
    if (seedResult.length === 0) {
      return c.json({ success: false, error: "No seed profiles available" }, 404);
    }
    const seedUserId = (seedResult[0] as any).id;

    // Check if match already exists
    const existingMatch = await sql`
      SELECT id FROM matches
      WHERE (user1_id = ${userId} AND user2_id = ${seedUserId})
         OR (user1_id = ${seedUserId} AND user2_id = ${userId})
    `;
    if (existingMatch.length > 0) {
      return c.json({ success: true, message: "Match already exists", matchId: (existingMatch[0] as any).id });
    }

    // Create the match
    const matchResult = await sql`
      INSERT INTO matches (user1_id, user2_id)
      VALUES (${userId}, ${seedUserId})
      RETURNING id
    `;
    const matchId = (matchResult[0] as any).id;

    // Also create a conversation for this match
    const convResult = await sql`
      INSERT INTO conversations (match_id, user1_id, user2_id)
      VALUES (${matchId}, ${userId}, ${seedUserId})
      RETURNING id
    `;

    return c.json({
      success: true,
      matchId,
      conversationId: convResult.length > 0 ? (convResult[0] as any).id : null,
      message: "Test match created"
    });
  } catch (error: any) {
    console.error("Create test match error:", error);
    return c.json({ success: false, error: "Failed to create test match" }, 500);
  }
});

// Seed fake profiles (admin)
app.post("/api/admin/seed-profiles", async (c) => {
  const auth = assertAdmin(c);
  if (!auth.ok) return c.json({ success: false, error: auth.error }, 401);

  try {
    await seedFakeProfiles(true);
    return c.json({ success: true, message: "Seed profiles created" });
  } catch (error: any) {
    console.error("Seed profiles error:", error);
    return c.json({ success: false, error: "Failed to seed profiles" }, 500);
  }
});

// Reset swipes for a user (admin)
app.post("/api/admin/reset-swipes", async (c) => {
  const auth = assertAdmin(c);
  if (!auth.ok) return c.json({ success: false, error: auth.error }, 401);

  try {
    const body = await c.req.json();
    const { userId, all } = body;

    if (all === true) {
      const result = await resetAllSwipes();
      return c.json({ success: true, message: `All swipes reset`, ...result });
    }

    if (!userId) {
      return c.json({ success: false, error: "userId required" }, 400);
    }

    const result = await resetUserSwipes(userId);
    return c.json({ success: true, message: `Swipes reset for user ${userId}`, ...result });
  } catch (error: any) {
    console.error("Reset swipes error:", error);
    return c.json({ success: false, error: "Failed to reset swipes" }, 500);
  }
});

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

// Send test message from seed profile (admin)
app.post("/api/admin/test-message", async (c) => {
  const auth = assertAdmin(c);
  if (!auth.ok) return c.json({ success: false, error: auth.error }, 401);

  try {
    const body = await c.req.json();
    const { conversationId, message } = body;

    if (!conversationId || !message) {
      return c.json({ success: false, error: "conversationId and message required" }, 400);
    }

    // Get the conversation to find the seed user
    const convResult = await sql`
      SELECT user1_id, user2_id FROM conversations WHERE id = ${conversationId}
    `;
    if (convResult.length === 0) {
      return c.json({ success: false, error: "Conversation not found" }, 404);
    }

    const conv = convResult[0] as any;

    // Find which user is the seed profile
    const seedUserResult = await sql`
      SELECT id FROM users
      WHERE (id = ${conv.user1_id} OR id = ${conv.user2_id})
        AND provider = 'seed'
      LIMIT 1
    `;

    if (seedUserResult.length === 0) {
      return c.json({ success: false, error: "No seed user in this conversation" }, 400);
    }

    const seedUserId = (seedUserResult[0] as any).id;
    const otherUserId = conv.user1_id === seedUserId ? conv.user2_id : conv.user1_id;

    // Create message from seed user
    const msgResult = await sql`
      INSERT INTO messages (conversation_id, sender_id, content)
      VALUES (${conversationId}, ${seedUserId}, ${message})
      RETURNING *
    `;
    const msg = msgResult[0] as any;

    // Update last_message_at
    await sql`
      UPDATE conversations SET last_message_at = NOW() WHERE id = ${conversationId}
    `;

    // Broadcast via WebSocket to the other user
    const messageData = {
      type: "chat:message",
      payload: {
        conversationId,
        messageId: msg.id,
        senderId: seedUserId,
        content: message,
        createdAt: msg.created_at,
      },
    };
    sendToUser(otherUserId, messageData);

    return c.json({ success: true, message: msg });
  } catch (error: any) {
    console.error("Send test message error:", error);
    return c.json({ success: false, error: "Failed to send test message" }, 500);
  }
});

// ============ COUPLE MODE ENDPOINTS ============

// Create or activate couple mode
app.post("/api/couple", requireAuth, async (c) => {
  try {
    const userId = c.get("userId");
    const body = await c.req.json();
    const { partnerId, relationshipStatus, startedAt } = body;

    if (!partnerId) {
      return c.json({ success: false, error: "Partner ID required" }, 400);
    }

    const couple = await createCouple(
      userId,
      partnerId,
      relationshipStatus || 'dating',
      startedAt ? new Date(startedAt) : undefined
    );

    return c.json({ success: true, couple });
  } catch (error: any) {
    console.error("Create couple error:", error);
    return c.json({ success: false, error: error.message }, 500);
  }
});

// Get current user's couple
app.get("/api/couple", requireAuth, async (c) => {
  try {
    const userId = c.get("userId");

    const couple = await getCouple(userId);

    if (!couple) {
      return c.json({ success: true, couple: null });
    }

    // Calculate days together
    const startedAt = (couple as any).started_at;
    const daysTogether = startedAt
      ? Math.floor((Date.now() - new Date(startedAt).getTime()) / (1000 * 60 * 60 * 24))
      : 0;

    // Check and record milestones
    await checkAndRecordMilestones((couple as any).id, daysTogether);

    // Get milestones
    const milestones = await getCoupleMilestones((couple as any).id);

    return c.json({
      success: true,
      couple: {
        ...(couple as any),
        daysTogether,
        milestones,
      },
    });
  } catch (error: any) {
    console.error("Get couple error:", error);
    return c.json({ success: false, error: error.message }, 500);
  }
});

// ============ COUPLE REQUESTS (demande / acceptation de couple) ============
// NOTE: registered before /api/couple/:coupleId so literal "request(s)"/"check"
// segments are not captured by the :coupleId param.

// Send a couple request
app.post("/api/couple/request", requireAuth, async (c) => {
  try {
    const userId = c.get("userId");
    const parsed = await parseBody(coupleRequestBodySchema, c);
    if (!parsed.ok) {
      return c.json({ success: false, error: parsed.error }, 400);
    }
    const targetUserId = Number(parsed.data.target_user_id);

    if (!Number.isInteger(targetUserId) || targetUserId <= 0) {
      return c.json({ success: false, error: "target_user_id required" }, 400);
    }

    const result = await createCoupleRequest(userId, targetUserId);
    if (!result.ok) {
      return c.json({ success: false, error: result.error }, 400);
    }

    return c.json({ success: true, request: result.request });
  } catch (error) {
    console.error("Create couple request error:", error);
    return c.json({ success: false, error: (error as Error).message }, 500);
  }
});

// Respond to a couple request (accept / reject) — only the target may respond
app.put("/api/couple/request/:id", requireAuth, async (c) => {
  try {
    const userId = c.get("userId");
    const requestId = parseInt(c.req.param("id"));
    if (!Number.isInteger(requestId)) {
      return c.json({ success: false, error: "Invalid request id" }, 400);
    }

    const parsed = await parseBody(coupleRespondBodySchema, c);
    if (!parsed.ok) {
      return c.json({ success: false, error: parsed.error }, 400);
    }
    const action = parsed.data.action;

    const result = await respondToCoupleRequest(requestId, userId, action);
    if (!result.ok) {
      return c.json({ success: false, error: result.error }, result.status as 403 | 404 | 409);
    }

    if (result.action === "accepted") {
      return c.json({ success: true, action: "accepted", couple: result.couple });
    }
    return c.json({ success: true, action: "rejected" });
  } catch (error) {
    console.error("Respond couple request error:", error);
    return c.json({ success: false, error: (error as Error).message }, 500);
  }
});

// Cancel a sent couple request — only the requester may cancel
app.delete("/api/couple/request/:id", requireAuth, async (c) => {
  try {
    const userId = c.get("userId");
    const requestId = parseInt(c.req.param("id"));
    if (!Number.isInteger(requestId)) {
      return c.json({ success: false, error: "Invalid request id" }, 400);
    }

    const result = await cancelCoupleRequest(requestId, userId);
    if (!result.ok) {
      return c.json({ success: false, error: result.error }, result.status as 403 | 404 | 409);
    }

    return c.json({ success: true });
  } catch (error) {
    console.error("Cancel couple request error:", error);
    return c.json({ success: false, error: (error as Error).message }, 500);
  }
});

// List pending couple requests (sent + received)
app.get("/api/couple/requests", requireAuth, async (c) => {
  try {
    const userId = c.get("userId");
    const { sent, received } = await getCoupleRequestsForUser(userId);

    return c.json({ success: true, sent, received });
  } catch (error) {
    console.error("Get couple requests error:", error);
    return c.json({ success: false, error: (error as Error).message }, 500);
  }
});

// Check couple/request status with a specific user
app.get("/api/couple/check/:userId", requireAuth, async (c) => {
  try {
    const userId = c.get("userId");
    const otherUserId = parseInt(c.req.param("userId"));
    if (!Number.isInteger(otherUserId)) {
      return c.json({ success: false, error: "Invalid user id" }, 400);
    }

    const status = await getCoupleStatusWith(userId, otherUserId);

    return c.json({
      success: true,
      status,
      in_couple_mode: status === "coupled",
    });
  } catch (error) {
    console.error("Check couple status error:", error);
    return c.json({ success: false, error: (error as Error).message }, 500);
  }
});

// Archive the user's conversations except with the partner
app.post("/api/couple/archive-conversations", requireAuth, async (c) => {
  try {
    const userId = c.get("userId");
    const body = await c.req.json().catch(() => ({}));
    const rawPartner = (body as { partner_user_id?: unknown }).partner_user_id;
    const partnerUserId =
      rawPartner === undefined || rawPartner === null
        ? null
        : Number(rawPartner);
    if (partnerUserId !== null && !Number.isInteger(partnerUserId)) {
      return c.json({ success: false, error: "Invalid partner_user_id" }, 400);
    }
    const rawMessage = (body as { message?: unknown }).message;
    const message = typeof rawMessage === "string" ? rawMessage : undefined;

    const { archived } = await archiveConversationsExceptPartner(
      userId,
      partnerUserId,
      message
    );

    return c.json({ success: true, archived });
  } catch (error) {
    console.error("Archive conversations error:", error);
    return c.json({ success: false, error: (error as Error).message }, 500);
  }
});

// Update relationship status
app.patch("/api/couple/:coupleId/status", requireAuth, async (c) => {
  try {
    const userId = c.get("userId");

    const coupleId = parseInt(c.req.param("coupleId"));
    if (!(await assertCoupleMembership(userId, coupleId))) {
      return c.json({ error: "Forbidden" }, 403);
    }
    const { relationshipStatus } = await c.req.json();

    await updateRelationshipStatus(coupleId, relationshipStatus);

    return c.json({ success: true });
  } catch (error: any) {
    console.error("Update couple status error:", error);
    return c.json({ success: false, error: error.message }, 500);
  }
});

// End couple mode (soft delete)
app.delete("/api/couple/:coupleId", requireAuth, async (c) => {
  try {
    const userId = c.get("userId");

    const coupleId = parseInt(c.req.param("coupleId"));
    if (!(await assertCoupleMembership(userId, coupleId))) {
      return c.json({ error: "Forbidden" }, 403);
    }
    await deleteCouple(coupleId);

    return c.json({ success: true });
  } catch (error: any) {
    console.error("Delete couple error:", error);
    return c.json({ success: false, error: error.message }, 500);
  }
});

// Get daily question
app.get("/api/couple/:coupleId/question", requireAuth, async (c) => {
  try {
    const userId = c.get("userId");

    const coupleId = parseInt(c.req.param("coupleId"));
    if (!(await assertCoupleMembership(userId, coupleId))) {
      return c.json({ error: "Forbidden" }, 403);
    }
    const question = await getDailyQuestion(coupleId);

    return c.json({ success: true, question });
  } catch (error: any) {
    console.error("Get daily question error:", error);
    return c.json({ success: false, error: error.message }, 500);
  }
});

// Answer daily question
app.post("/api/couple/:coupleId/question/:questionId/answer", requireAuth, async (c) => {
  try {
    const userId = c.get("userId");

    const coupleId = parseInt(c.req.param("coupleId"));
    if (!(await assertCoupleMembership(userId, coupleId))) {
      return c.json({ error: "Forbidden" }, 403);
    }
    const questionId = parseInt(c.req.param("questionId"));
    const { answer } = await c.req.json();

    await answerDailyQuestion(coupleId, questionId, userId, answer);

    return c.json({ success: true });
  } catch (error: any) {
    console.error("Answer question error:", error);
    return c.json({ success: false, error: error.message }, 500);
  }
});

// Get question history
app.get("/api/couple/:coupleId/questions", requireAuth, async (c) => {
  try {
    const userId = c.get("userId");

    const coupleId = parseInt(c.req.param("coupleId"));
    if (!(await assertCoupleMembership(userId, coupleId))) {
      return c.json({ error: "Forbidden" }, 403);
    }
    const questions = await getCoupleQuestionHistory(coupleId);

    return c.json({ success: true, questions });
  } catch (error: any) {
    console.error("Get questions error:", error);
    return c.json({ success: false, error: error.message }, 500);
  }
});

// Get milestones
app.get("/api/couple/:coupleId/milestones", requireAuth, async (c) => {
  try {
    const userId = c.get("userId");

    const coupleId = parseInt(c.req.param("coupleId"));
    if (!(await assertCoupleMembership(userId, coupleId))) {
      return c.json({ error: "Forbidden" }, 403);
    }
    const milestones = await getCoupleMilestones(coupleId);

    return c.json({ success: true, milestones });
  } catch (error: any) {
    console.error("Get milestones error:", error);
    return c.json({ success: false, error: error.message }, 500);
  }
});

// ============ COUPLE MODE - ACTIVITIES FEED ============

// Get couple activities feed
app.get("/api/couple/activities", requireAuth, async (c) => {
  try {
    const userId = c.get("userId");
    const couple = await getCoupleByUserId(userId);
    if (!couple) return c.json({ success: false, error: "Not in a couple" }, 400);

    const limit = parseInt(c.req.query("limit") || "20");
    const offset = parseInt(c.req.query("offset") || "0");
    const category = c.req.query("category");

    const activities = await getCoupleActivities((couple as any).id, limit, offset, category || undefined);

    return c.json({ success: true, activities });
  } catch (error: any) {
    console.error("Get couple activities error:", error);
    return c.json({ success: false, error: error.message }, 500);
  }
});

// Get single activity detail
app.get("/api/couple/activities/:id", requireAuth, async (c) => {
  try {
    const userId = c.get("userId");

    const activityId = parseInt(c.req.param("id"));
    const activity = await getCoupleActivity(activityId);

    if (!activity) return c.json({ success: false, error: "Activity not found" }, 404);

    return c.json({ success: true, activity });
  } catch (error: any) {
    console.error("Get activity error:", error);
    return c.json({ success: false, error: error.message }, 500);
  }
});

// Save activity (swipe up / bookmark)
app.post("/api/couple/activities/:id/save", requireAuth, async (c) => {
  try {
    const userId = c.get("userId");
    const couple = await getCoupleByUserId(userId);
    if (!couple) return c.json({ success: false, error: "Not in a couple" }, 400);

    const activityId = parseInt(c.req.param("id"));
    const body = await c.req.json().catch(() => ({}));

    await saveCoupleActivity((couple as any).id, activityId, body.notes);

    return c.json({ success: true });
  } catch (error: any) {
    console.error("Save activity error:", error);
    return c.json({ success: false, error: error.message }, 500);
  }
});

// Pass activity (swipe left)
app.post("/api/couple/activities/:id/pass", requireAuth, async (c) => {
  try {
    const userId = c.get("userId");
    const couple = await getCoupleByUserId(userId);
    if (!couple) return c.json({ success: false, error: "Not in a couple" }, 400);

    const activityId = parseInt(c.req.param("id"));
    await passCoupleActivity((couple as any).id, activityId);

    return c.json({ success: true });
  } catch (error: any) {
    console.error("Pass activity error:", error);
    return c.json({ success: false, error: error.message }, 500);
  }
});

// Get saved activities
app.get("/api/couple/saved", requireAuth, async (c) => {
  try {
    const userId = c.get("userId");
    const couple = await getCoupleByUserId(userId);
    if (!couple) return c.json({ success: false, error: "Not in a couple" }, 400);

    const activities = await getSavedActivities((couple as any).id);

    return c.json({ success: true, activities });
  } catch (error: any) {
    console.error("Get saved activities error:", error);
    return c.json({ success: false, error: error.message }, 500);
  }
});

// Remove saved activity
app.delete("/api/couple/saved/:id", requireAuth, async (c) => {
  try {
    const userId = c.get("userId");
    const couple = await getCoupleByUserId(userId);
    if (!couple) return c.json({ success: false, error: "Not in a couple" }, 400);

    const activityId = parseInt(c.req.param("id"));
    await removeSavedActivity((couple as any).id, activityId);

    return c.json({ success: true });
  } catch (error: any) {
    console.error("Remove saved activity error:", error);
    return c.json({ success: false, error: error.message }, 500);
  }
});

// Create booking
app.post("/api/couple/bookings", requireAuth, async (c) => {
  try {
    const userId = c.get("userId");
    const couple = await getCoupleByUserId(userId);
    if (!couple) return c.json({ success: false, error: "Not in a couple" }, 400);

    const body = await c.req.json();
    const booking = await createCoupleBooking({
      coupleId: (couple as any).id,
      activityId: body.activityId,
      eventId: body.eventId,
      bookingDate: body.bookingDate,
      bookingTime: body.bookingTime,
      notes: body.notes,
    });

    return c.json({ success: true, booking });
  } catch (error: any) {
    console.error("Create booking error:", error);
    return c.json({ success: false, error: error.message }, 500);
  }
});

// Get bookings
app.get("/api/couple/bookings", requireAuth, async (c) => {
  try {
    const userId = c.get("userId");
    const couple = await getCoupleByUserId(userId);
    if (!couple) return c.json({ success: false, error: "Not in a couple" }, 400);

    const bookings = await getCoupleBookings((couple as any).id);

    return c.json({ success: true, bookings });
  } catch (error: any) {
    console.error("Get bookings error:", error);
    return c.json({ success: false, error: error.message }, 500);
  }
});

// ============ COUPLE MODE - EVENTS ============

// Get couple events
app.get("/api/couple/events", requireAuth, async (c) => {
  try {
    const userId = c.get("userId");

    const limit = parseInt(c.req.query("limit") || "20");
    const offset = parseInt(c.req.query("offset") || "0");
    const category = c.req.query("category");

    const events = await getCoupleEvents(limit, offset, category || undefined);

    return c.json({ success: true, events });
  } catch (error: any) {
    console.error("Get couple events error:", error);
    return c.json({ success: false, error: error.message }, 500);
  }
});

// Get registered events (must be before :id route)
app.get("/api/couple/events/registered", requireAuth, async (c) => {
  try {
    const userId = c.get("userId");
    const couple = await getCoupleByUserId(userId);
    if (!couple) return c.json({ success: false, error: "Not in a couple" }, 400);

    const events = await getCoupleRegisteredEvents((couple as any).id);

    return c.json({ success: true, events });
  } catch (error: any) {
    console.error("Get registered events error:", error);
    return c.json({ success: false, error: error.message }, 500);
  }
});

// Get single event
app.get("/api/couple/events/:id", requireAuth, async (c) => {
  try {
    const userId = c.get("userId");

    const eventId = parseInt(c.req.param("id"));
    const event = await getCoupleEvent(eventId);

    if (!event) return c.json({ success: false, error: "Event not found" }, 404);

    return c.json({ success: true, event });
  } catch (error: any) {
    console.error("Get event error:", error);
    return c.json({ success: false, error: error.message }, 500);
  }
});

// Register for event
app.post("/api/couple/events/:id/register", requireAuth, async (c) => {
  try {
    const userId = c.get("userId");
    const couple = await getCoupleByUserId(userId);
    if (!couple) return c.json({ success: false, error: "Not in a couple" }, 400);

    const eventId = parseInt(c.req.param("id"));
    const registration = await registerForCoupleEvent((couple as any).id, eventId);

    return c.json({ success: true, registration });
  } catch (error: any) {
    console.error("Register for event error:", error);
    return c.json({ success: false, error: error.message }, 500);
  }
});

// Cancel registration
app.delete("/api/couple/events/:id/register", requireAuth, async (c) => {
  try {
    const userId = c.get("userId");
    const couple = await getCoupleByUserId(userId);
    if (!couple) return c.json({ success: false, error: "Not in a couple" }, 400);

    const eventId = parseInt(c.req.param("id"));
    await cancelCoupleEventRegistration((couple as any).id, eventId);

    return c.json({ success: true });
  } catch (error: any) {
    console.error("Cancel registration error:", error);
    return c.json({ success: false, error: error.message }, 500);
  }
});
// ============ COUPLE MODE - MEMORIES ============

// Get memories
app.get("/api/couple/memories", requireAuth, async (c) => {
  try {
    const userId = c.get("userId");
    const couple = await getCoupleByUserId(userId);
    if (!couple) return c.json({ success: false, error: "Not in a couple" }, 400);

    const memories = await getCoupleMemories((couple as any).id);

    return c.json({ success: true, memories });
  } catch (error: any) {
    console.error("Get memories error:", error);
    return c.json({ success: false, error: error.message }, 500);
  }
});

// Add memory
app.post("/api/couple/memories", requireAuth, async (c) => {
  try {
    const userId = c.get("userId");
    const couple = await getCoupleByUserId(userId);
    if (!couple) return c.json({ success: false, error: "Not in a couple" }, 400);

    const body = await c.req.json();
    const memory = await addCoupleMemory({
      coupleId: (couple as any).id,
      type: body.type,
      title: body.title,
      content: body.content,
      imageUrl: body.imageUrl,
      memoryDate: body.memoryDate,
      location: body.location,
      createdBy: userId,
    });

    return c.json({ success: true, memory });
  } catch (error: any) {
    console.error("Add memory error:", error);
    return c.json({ success: false, error: error.message }, 500);
  }
});

// Delete memory
app.delete("/api/couple/memories/:id", requireAuth, async (c) => {
  try {
    const userId = c.get("userId");
    const couple = await getCoupleByUserId(userId);
    if (!couple) return c.json({ success: false, error: "Not in a couple" }, 400);

    const memoryId = parseInt(c.req.param("id"));
    await deleteCoupleMemory((couple as any).id, memoryId);

    return c.json({ success: true });
  } catch (error: any) {
    console.error("Delete memory error:", error);
    return c.json({ success: false, error: error.message }, 500);
  }
});

// ============ COUPLE MODE - DATES ============

// Get dates
app.get("/api/couple/dates", requireAuth, async (c) => {
  try {
    const userId = c.get("userId");
    const couple = await getCoupleByUserId(userId);
    if (!couple) return c.json({ success: false, error: "Not in a couple" }, 400);

    const dates = await getCoupleDates((couple as any).id);

    return c.json({ success: true, dates });
  } catch (error: any) {
    console.error("Get dates error:", error);
    return c.json({ success: false, error: error.message }, 500);
  }
});

// Add date
app.post("/api/couple/dates", requireAuth, async (c) => {
  try {
    const userId = c.get("userId");
    const couple = await getCoupleByUserId(userId);
    if (!couple) return c.json({ success: false, error: "Not in a couple" }, 400);

    const body = await c.req.json();
    const date = await addCoupleDate({
      coupleId: (couple as any).id,
      title: body.title,
      date: body.date,
      type: body.type,
      isRecurring: body.isRecurring,
      remindDaysBefore: body.remindDaysBefore,
      notes: body.notes,
    });

    return c.json({ success: true, date });
  } catch (error: any) {
    console.error("Add date error:", error);
    return c.json({ success: false, error: error.message }, 500);
  }
});

// Update date
app.put("/api/couple/dates/:id", requireAuth, async (c) => {
  try {
    const userId = c.get("userId");
    const couple = await getCoupleByUserId(userId);
    if (!couple) return c.json({ success: false, error: "Not in a couple" }, 400);

    const dateId = parseInt(c.req.param("id"));
    const body = await c.req.json();

    const date = await updateCoupleDate((couple as any).id, dateId, body);

    return c.json({ success: true, date });
  } catch (error: any) {
    console.error("Update date error:", error);
    return c.json({ success: false, error: error.message }, 500);
  }
});

// Delete date
app.delete("/api/couple/dates/:id", requireAuth, async (c) => {
  try {
    const userId = c.get("userId");
    const couple = await getCoupleByUserId(userId);
    if (!couple) return c.json({ success: false, error: "Not in a couple" }, 400);

    const dateId = parseInt(c.req.param("id"));
    await deleteCoupleDate((couple as any).id, dateId);

    return c.json({ success: true });
  } catch (error: any) {
    console.error("Delete date error:", error);
    return c.json({ success: false, error: error.message }, 500);
  }
});

// ============ COUPLE MODE - BUCKET LIST ============

// Get bucket list
app.get("/api/couple/bucket-list", requireAuth, async (c) => {
  try {
    const userId = c.get("userId");
    const couple = await getCoupleByUserId(userId);
    if (!couple) return c.json({ success: false, error: "Not in a couple" }, 400);

    const items = await getBucketList((couple as any).id);

    return c.json({ success: true, items });
  } catch (error: any) {
    console.error("Get bucket list error:", error);
    return c.json({ success: false, error: error.message }, 500);
  }
});

// Add bucket list item
app.post("/api/couple/bucket-list", requireAuth, async (c) => {
  try {
    const userId = c.get("userId");
    const couple = await getCoupleByUserId(userId);
    if (!couple) return c.json({ success: false, error: "Not in a couple" }, 400);

    const body = await c.req.json();
    const item = await addBucketListItem({
      coupleId: (couple as any).id,
      title: body.title,
      description: body.description,
      category: body.category,
      targetDate: body.targetDate,
    });

    return c.json({ success: true, item });
  } catch (error: any) {
    console.error("Add bucket list item error:", error);
    return c.json({ success: false, error: error.message }, 500);
  }
});

// Complete bucket list item
app.post("/api/couple/bucket-list/:id/complete", requireAuth, async (c) => {
  try {
    const userId = c.get("userId");
    const couple = await getCoupleByUserId(userId);
    if (!couple) return c.json({ success: false, error: "Not in a couple" }, 400);

    const itemId = parseInt(c.req.param("id"));
    const item = await completeBucketListItem((couple as any).id, itemId);

    return c.json({ success: true, item });
  } catch (error: any) {
    console.error("Complete bucket list item error:", error);
    return c.json({ success: false, error: error.message }, 500);
  }
});

// Delete bucket list item
app.delete("/api/couple/bucket-list/:id", requireAuth, async (c) => {
  try {
    const userId = c.get("userId");
    const couple = await getCoupleByUserId(userId);
    if (!couple) return c.json({ success: false, error: "Not in a couple" }, 400);

    const itemId = parseInt(c.req.param("id"));
    await deleteBucketListItem((couple as any).id, itemId);

    return c.json({ success: true });
  } catch (error: any) {
    console.error("Delete bucket list item error:", error);
    return c.json({ success: false, error: error.message }, 500);
  }
});

// ============ COUPLE MODE - STATS & ACHIEVEMENTS ============

// Get couple stats
app.get("/api/couple/stats", requireAuth, async (c) => {
  try {
    const userId = c.get("userId");
    const couple = await getCoupleByUserId(userId);
    if (!couple) return c.json({ success: false, error: "Not in a couple" }, 400);

    const stats = await getCoupleStats((couple as any).id);
    const achievements = await getCoupleAchievements((couple as any).id);

    return c.json({ success: true, stats, achievements });
  } catch (error: any) {
    console.error("Get couple stats error:", error);
    return c.json({ success: false, error: error.message }, 500);
  }
});

// ============ MODULE 1: GESTION MEMBRES COMPLÈTE ============

// Get user detail (admin)
app.get("/api/admin/users/:id", async (c) => {
  const auth = assertAdmin(c);
  if (!auth.ok) return c.json({ success: false, error: auth.error }, 401);

  try {
    const userId = parseInt(c.req.param("id"));
    const user = await getAdminUserDetail(userId);

    if (!user) {
      return c.json({ success: false, error: "User not found" }, 404);
    }

    return c.json({ success: true, user });
  } catch (error: any) {
    console.error("Get user detail error:", error);
    return c.json({ success: false, error: "Failed to get user" }, 500);
  }
});

// Ban user (admin)
app.post("/api/admin/users/:id/ban", async (c) => {
  const auth = assertAdmin(c);
  if (!auth.ok) return c.json({ success: false, error: auth.error }, 401);

  try {
    const userId = parseInt(c.req.param("id"));
    const body = await c.req.json();

    if (!body.reason) {
      return c.json({ success: false, error: "Reason required" }, 400);
    }

    const ban = await banUser({
      userId,
      reason: body.reason,
      bannedBy: (auth as any).email || "admin",
      expiresAt: body.expiresAt ? new Date(body.expiresAt) : undefined,
      isPermanent: body.isPermanent ?? false,
    });

    return c.json({ success: true, ban });
  } catch (error: any) {
    console.error("Ban user error:", error);
    return c.json({ success: false, error: "Failed to ban user" }, 500);
  }
});

// Unban user (admin)
app.post("/api/admin/users/:id/unban", async (c) => {
  const auth = assertAdmin(c);
  if (!auth.ok) return c.json({ success: false, error: auth.error }, 401);

  try {
    const userId = parseInt(c.req.param("id"));
    await unbanUser(userId, (auth as any).email || "admin");
    return c.json({ success: true });
  } catch (error: any) {
    console.error("Unban user error:", error);
    return c.json({ success: false, error: "Failed to unban user" }, 500);
  }
});

// Add note to user (admin)
app.post("/api/admin/users/:id/notes", async (c) => {
  const auth = assertAdmin(c);
  if (!auth.ok) return c.json({ success: false, error: auth.error }, 401);

  try {
    const userId = parseInt(c.req.param("id"));
    const { note } = await c.req.json();

    if (!note) {
      return c.json({ success: false, error: "Note required" }, 400);
    }

    const result = await addAdminNote({
      userId,
      adminEmail: (auth as any).email || "admin",
      note,
    });

    return c.json({ success: true, note: result });
  } catch (error: any) {
    console.error("Add note error:", error);
    return c.json({ success: false, error: "Failed to add note" }, 500);
  }
});

// Get user activity (admin)
app.get("/api/admin/users/:id/activity", async (c) => {
  const auth = assertAdmin(c);
  if (!auth.ok) return c.json({ success: false, error: auth.error }, 401);

  try {
    const userId = parseInt(c.req.param("id"));
    const activity = await getUserActivity(userId);
    return c.json({ success: true, activity });
  } catch (error: any) {
    console.error("Get activity error:", error);
    return c.json({ success: false, error: "Failed to get activity" }, 500);
  }
});

// Delete user (admin)
app.delete("/api/admin/users/:id", async (c) => {
  const auth = assertAdmin(c);
  if (!auth.ok) return c.json({ success: false, error: auth.error }, 401);

  try {
    const userId = parseInt(c.req.param("id"));
    await deleteUserCompletely(userId, (auth as any).email || "admin");
    return c.json({ success: true });
  } catch (error: any) {
    console.error("Delete user error:", error);
    return c.json({ success: false, error: "Failed to delete user" }, 500);
  }
});

// Update user verification (admin)
app.put("/api/admin/users/:id/verification", async (c) => {
  const auth = assertAdmin(c);
  if (!auth.ok) return c.json({ success: false, error: auth.error }, 401);

  try {
    const userId = parseInt(c.req.param("id"));
    const { level } = await c.req.json();

    if (!level) {
      return c.json({ success: false, error: "Level required" }, 400);
    }

    await setUserVerificationLevel(userId, level);
    return c.json({ success: true });
  } catch (error: any) {
    console.error("Set verification error:", error);
    return c.json({ success: false, error: "Failed to set verification" }, 500);
  }
});

// ============ MODULE 2: GESTION EVENTS COMPLÈTE ============

// Get event full details (admin)
app.get("/api/admin/events/:id/details", async (c) => {
  const auth = assertAdmin(c);
  if (!auth.ok) return c.json({ success: false, error: auth.error }, 401);

  try {
    const eventId = parseInt(c.req.param("id"));
    const event = await getEventFullDetails(eventId);

    if (!event) {
      return c.json({ success: false, error: "Event not found" }, 404);
    }

    return c.json({ success: true, event });
  } catch (error: any) {
    console.error("Get event details error:", error);
    return c.json({ success: false, error: "Failed to get event" }, 500);
  }
});

// Upload event photo (admin)
app.post("/api/admin/events/:id/photos", async (c) => {
  const auth = assertAdmin(c);
  if (!auth.ok) return c.json({ success: false, error: auth.error }, 401);

  try {
    const eventId = parseInt(c.req.param("id"));
    const body = await c.req.json();

    if (!body.url) {
      return c.json({ success: false, error: "URL required" }, 400);
    }

    const photo = await addEventPhoto({
      eventId,
      url: body.url,
      position: body.position,
      isCover: body.isCover,
    });

    return c.json({ success: true, photo });
  } catch (error: any) {
    console.error("Add photo error:", error);
    return c.json({ success: false, error: "Failed to add photo" }, 500);
  }
});

// Delete event photo (admin)
app.delete("/api/admin/events/:id/photos/:photoId", async (c) => {
  const auth = assertAdmin(c);
  if (!auth.ok) return c.json({ success: false, error: auth.error }, 401);

  try {
    const photoId = parseInt(c.req.param("photoId"));
    await deleteEventPhoto(photoId);
    return c.json({ success: true });
  } catch (error: any) {
    console.error("Delete photo error:", error);
    return c.json({ success: false, error: "Failed to delete photo" }, 500);
  }
});

// Check-in attendee (admin)
app.post("/api/admin/events/:id/checkin", async (c) => {
  const auth = assertAdmin(c);
  if (!auth.ok) return c.json({ success: false, error: auth.error }, 401);

  try {
    const eventId = parseInt(c.req.param("id"));
    const { userId } = await c.req.json();

    if (!userId) {
      return c.json({ success: false, error: "User ID required" }, 400);
    }

    const checkin = await checkInAttendee({
      eventId,
      userId,
      checkedInBy: (auth as any).email || "admin",
    });

    return c.json({ success: true, checkin });
  } catch (error: any) {
    console.error("Check-in error:", error);
    return c.json({ success: false, error: "Failed to check in" }, 500);
  }
});

// Export attendees CSV (admin)
app.get("/api/admin/events/:id/export", async (c) => {
  const auth = assertAdmin(c);
  if (!auth.ok) return c.json({ success: false, error: auth.error }, 401);

  try {
    const eventId = parseInt(c.req.param("id"));
    const attendees = await exportEventAttendees(eventId);

    // Generate CSV
    const headers = ["email", "name", "display_name", "status", "paid", "rsvp_at", "checked_in_at"];
    const csv = [
      headers.join(","),
      ...(attendees as any[]).map((a) =>
        headers.map((h) => `"${(a[h] ?? "").toString().replace(/"/g, '""')}"`).join(",")
      ),
    ].join("\n");

    return new Response(csv, {
      headers: {
        "Content-Type": "text/csv",
        "Content-Disposition": `attachment; filename="event-${eventId}-attendees.csv"`,
      },
    });
  } catch (error: any) {
    console.error("Export error:", error);
    return c.json({ success: false, error: "Failed to export" }, 500);
  }
});

// Duplicate event (admin)
app.post("/api/admin/events/:id/duplicate", async (c) => {
  const auth = assertAdmin(c);
  if (!auth.ok) return c.json({ success: false, error: auth.error }, 401);

  try {
    const eventId = parseInt(c.req.param("id"));
    const newEvent = await duplicateEvent(eventId);

    if (!newEvent) {
      return c.json({ success: false, error: "Event not found" }, 404);
    }

    return c.json({ success: true, event: newEvent });
  } catch (error: any) {
    console.error("Duplicate error:", error);
    return c.json({ success: false, error: "Failed to duplicate" }, 500);
  }
});

// ============ MODULE 3: CAMPAGNES EMAIL/PUSH ============

// Get campaigns (admin)
app.get("/api/admin/campaigns", async (c) => {
  const auth = assertAdmin(c);
  if (!auth.ok) return c.json({ success: false, error: auth.error }, 401);

  try {
    const status = c.req.query("status");
    const type = c.req.query("type");
    const limit = parseInt(c.req.query("limit") || "50");
    const offset = parseInt(c.req.query("offset") || "0");

    const campaigns = await getCampaigns({
      status: status || undefined,
      type: type || undefined,
      limit,
      offset,
    });

    return c.json({ success: true, campaigns });
  } catch (error: any) {
    console.error("Get campaigns error:", error);
    return c.json({ success: false, error: "Failed to get campaigns" }, 500);
  }
});

// Get campaign by ID (admin)
app.get("/api/admin/campaigns/:id", async (c) => {
  const auth = assertAdmin(c);
  if (!auth.ok) return c.json({ success: false, error: auth.error }, 401);

  try {
    const campaignId = parseInt(c.req.param("id"));
    const campaign = await getCampaignById(campaignId);

    if (!campaign) {
      return c.json({ success: false, error: "Campaign not found" }, 404);
    }

    return c.json({ success: true, campaign });
  } catch (error: any) {
    console.error("Get campaign error:", error);
    return c.json({ success: false, error: "Failed to get campaign" }, 500);
  }
});

// Create campaign (admin)
app.post("/api/admin/campaigns", async (c) => {
  const auth = assertAdmin(c);
  if (!auth.ok) return c.json({ success: false, error: auth.error }, 401);

  try {
    const body = await c.req.json();

    if (!body.type || !body.title || !body.content) {
      return c.json({ success: false, error: "Type, title and content required" }, 400);
    }

    const campaign = await createCampaign({
      type: body.type,
      title: body.title,
      subject: body.subject,
      content: body.content,
      segmentId: body.segmentId,
      scheduledAt: body.scheduledAt ? new Date(body.scheduledAt) : undefined,
      createdBy: (auth as any).email || "admin",
    });

    return c.json({ success: true, campaign });
  } catch (error: any) {
    console.error("Create campaign error:", error);
    return c.json({ success: false, error: "Failed to create campaign" }, 500);
  }
});

// Update campaign (admin)
app.put("/api/admin/campaigns/:id", async (c) => {
  const auth = assertAdmin(c);
  if (!auth.ok) return c.json({ success: false, error: auth.error }, 401);

  try {
    const campaignId = parseInt(c.req.param("id"));
    const body = await c.req.json();

    const campaign = await updateCampaignDb(campaignId, {
      title: body.title,
      subject: body.subject,
      content: body.content,
      segmentId: body.segmentId,
      scheduledAt: body.scheduledAt ? new Date(body.scheduledAt) : undefined,
      status: body.status,
    });

    return c.json({ success: true, campaign });
  } catch (error: any) {
    console.error("Update campaign error:", error);
    return c.json({ success: false, error: "Failed to update campaign" }, 500);
  }
});

// Delete campaign (admin)
app.delete("/api/admin/campaigns/:id", async (c) => {
  const auth = assertAdmin(c);
  if (!auth.ok) return c.json({ success: false, error: auth.error }, 401);

  try {
    const campaignId = parseInt(c.req.param("id"));
    await deleteCampaign(campaignId);
    return c.json({ success: true });
  } catch (error: any) {
    console.error("Delete campaign error:", error);
    return c.json({ success: false, error: "Failed to delete campaign" }, 500);
  }
});

// Send campaign (admin)
app.post("/api/admin/campaigns/:id/send", async (c) => {
  const auth = assertAdmin(c);
  if (!auth.ok) return c.json({ success: false, error: auth.error }, 401);

  try {
    const campaignId = parseInt(c.req.param("id"));
    const campaign = await getCampaignById(campaignId);

    if (!campaign) {
      return c.json({ success: false, error: "Campaign not found" }, 404);
    }

    const camp = campaign as any;

    // Mark campaign as sending and get recipients
    const result = await sendCampaign(campaignId);
    const recipients = result.recipients as any[];

    let sentCount = 0;
    let errorCount = 0;

    if (camp.type === "email") {
      // Send emails via Resend
      for (const recipient of recipients) {
        try {
          await sendCampaignEmail({
            to: recipient.email,
            subject: camp.subject || camp.title,
            content: camp.content,
            campaignId,
            userId: recipient.id,
          });
          sentCount++;
        } catch (err) {
          console.error(`Failed to send email to ${recipient.email}:`, err);
          errorCount++;
        }
      }
    } else if (camp.type === "push") {
      // Send push via OneSignal
      const userIds = recipients.map((r) => r.id);

      if (userIds.length > 0) {
        const pushResult = await sendPushToUsers(userIds, camp.title, camp.content, {
          campaignId,
        });

        if (pushResult.success) {
          sentCount = pushResult.recipients || userIds.length;
        } else {
          errorCount = userIds.length;
          console.error("Push notification failed:", pushResult.error);
        }
      }
    }

    return c.json({
      success: true,
      sent: sentCount,
      errors: errorCount,
      total: recipients.length,
    });
  } catch (error: any) {
    console.error("Send campaign error:", error);
    return c.json({ success: false, error: "Failed to send campaign" }, 500);
  }
});

// Get segments (admin)
app.get("/api/admin/segments", async (c) => {
  const auth = assertAdmin(c);
  if (!auth.ok) return c.json({ success: false, error: auth.error }, 401);

  try {
    const segments = await getSegments();
    return c.json({ success: true, segments });
  } catch (error: any) {
    console.error("Get segments error:", error);
    return c.json({ success: false, error: "Failed to get segments" }, 500);
  }
});

// Create segment (admin)
app.post("/api/admin/segments", async (c) => {
  const auth = assertAdmin(c);
  if (!auth.ok) return c.json({ success: false, error: auth.error }, 401);

  try {
    const body = await c.req.json();

    if (!body.name || !body.filters) {
      return c.json({ success: false, error: "Name and filters required" }, 400);
    }

    const segment = await createSegment({
      name: body.name,
      description: body.description,
      filters: body.filters,
      createdBy: (auth as any).email || "admin",
    });

    return c.json({ success: true, segment });
  } catch (error: any) {
    console.error("Create segment error:", error);
    return c.json({ success: false, error: "Failed to create segment" }, 500);
  }
});

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

// Get reports (admin)
app.get("/api/admin/reports", async (c) => {
  const auth = assertAdmin(c);
  if (!auth.ok) return c.json({ success: false, error: auth.error }, 401);

  try {
    const status = c.req.query("status");
    const limit = parseInt(c.req.query("limit") || "50");
    const offset = parseInt(c.req.query("offset") || "0");

    const reports = await getReports({
      status: status || undefined,
      limit,
      offset,
    });

    return c.json({ success: true, reports });
  } catch (error: any) {
    console.error("Get reports error:", error);
    return c.json({ success: false, error: "Failed to get reports" }, 500);
  }
});

// Get report stats (admin)
app.get("/api/admin/reports/stats", async (c) => {
  const auth = assertAdmin(c);
  if (!auth.ok) return c.json({ success: false, error: auth.error }, 401);

  try {
    const stats = await getReportStats();
    return c.json({ success: true, stats });
  } catch (error: any) {
    console.error("Get report stats error:", error);
    return c.json({ success: false, error: "Failed to get stats" }, 500);
  }
});

// Handle report (admin)
app.put("/api/admin/reports/:id", async (c) => {
  const auth = assertAdmin(c);
  if (!auth.ok) return c.json({ success: false, error: auth.error }, 401);

  try {
    const reportId = parseInt(c.req.param("id"));
    const body = await c.req.json();

    if (!body.actionTaken) {
      return c.json({ success: false, error: "Action taken required" }, 400);
    }

    const report = await handleReport({
      reportId,
      handledBy: (auth as any).email || "admin",
      actionTaken: body.actionTaken,
      status: body.status,
    });

    return c.json({ success: true, report });
  } catch (error: any) {
    console.error("Handle report error:", error);
    return c.json({ success: false, error: "Failed to handle report" }, 500);
  }
});

// Get pending photos (admin)
app.get("/api/admin/photos/pending", async (c) => {
  const auth = assertAdmin(c);
  if (!auth.ok) return c.json({ success: false, error: auth.error }, 401);

  try {
    const limit = parseInt(c.req.query("limit") || "50");
    const photos = await getPendingPhotos(limit);
    return c.json({ success: true, photos });
  } catch (error: any) {
    console.error("Get pending photos error:", error);
    return c.json({ success: false, error: "Failed to get photos" }, 500);
  }
});

// Approve photo (admin)
app.put("/api/admin/photos/:id/approve", async (c) => {
  const auth = assertAdmin(c);
  if (!auth.ok) return c.json({ success: false, error: auth.error }, 401);

  try {
    const photoId = parseInt(c.req.param("id"));
    await approvePhoto(photoId, (auth as any).email || "admin");
    return c.json({ success: true });
  } catch (error: any) {
    console.error("Approve photo error:", error);
    return c.json({ success: false, error: "Failed to approve photo" }, 500);
  }
});

// Reject photo (admin)
app.put("/api/admin/photos/:id/reject", async (c) => {
  const auth = assertAdmin(c);
  if (!auth.ok) return c.json({ success: false, error: auth.error }, 401);

  try {
    const photoId = parseInt(c.req.param("id"));
    const { reason } = await c.req.json();

    if (!reason) {
      return c.json({ success: false, error: "Reason required" }, 400);
    }

    await rejectPhoto(photoId, (auth as any).email || "admin", reason);
    return c.json({ success: true });
  } catch (error: any) {
    console.error("Reject photo error:", error);
    return c.json({ success: false, error: "Failed to reject photo" }, 500);
  }
});

// Get moderation logs (admin)
app.get("/api/admin/moderation/logs", async (c) => {
  const auth = assertAdmin(c);
  if (!auth.ok) return c.json({ success: false, error: auth.error }, 401);

  try {
    const adminEmail = c.req.query("admin");
    const targetType = c.req.query("type");
    const limit = parseInt(c.req.query("limit") || "100");
    const offset = parseInt(c.req.query("offset") || "0");

    const logs = await getModerationLogs({
      adminEmail: adminEmail || undefined,
      targetType: targetType || undefined,
      limit,
      offset,
    });

    return c.json({ success: true, logs });
  } catch (error: any) {
    console.error("Get moderation logs error:", error);
    return c.json({ success: false, error: "Failed to get logs" }, 500);
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

// Store active WebSocket connections by user ID
const wsConnections = new Map<number, Set<WebSocket>>();

// Helper to send to all connections of a user
function sendToUser(userId: number, data: any) {
  const connections = wsConnections.get(userId);
  if (connections) {
    const message = JSON.stringify(data);
    for (const ws of connections) {
      try {
        (ws as any).send(message);
      } catch (err) {
        console.error(`WebSocket send error for user ${userId}:`, err);
      }
    }
  }
}

interface MatchNewPayload {
  matchId: number;
  conversationId: number;
  userId: number;
  userName: string;
  userPicture: string | null;
}

// Emit a `match:new` event to both freshly-matched users (if connected).
// Each user receives the *other* person's identity, matching the shape the
// mobile client expects (see websocket_service.dart:193-203).
async function emitNewMatch(userAId: number, userBId: number): Promise<void> {
  const rows = await sql`
    SELECT
      m.id as match_id,
      c.id as conversation_id,
      pa.display_name as user_a_name,
      ua.picture as user_a_picture,
      pb.display_name as user_b_name,
      ub.picture as user_b_picture
    FROM matches m
    LEFT JOIN conversations c ON c.match_id = m.id
    JOIN users ua ON ua.id = ${userAId}
    JOIN users ub ON ub.id = ${userBId}
    LEFT JOIN profiles pa ON pa.user_id = ${userAId}
    LEFT JOIN profiles pb ON pb.user_id = ${userBId}
    WHERE (m.user1_id = ${userAId} AND m.user2_id = ${userBId})
       OR (m.user1_id = ${userBId} AND m.user2_id = ${userAId})
    LIMIT 1
  `;

  const row = rows[0] as
    | {
        match_id: number;
        conversation_id: number | null;
        user_a_name: string | null;
        user_a_picture: string | null;
        user_b_name: string | null;
        user_b_picture: string | null;
      }
    | undefined;
  if (!row || row.conversation_id === null) return;

  const matchId = row.match_id;
  const conversationId = row.conversation_id;

  const toUserA: MatchNewPayload = {
    matchId,
    conversationId,
    userId: userBId,
    userName: row.user_b_name ?? "",
    userPicture: row.user_b_picture,
  };
  const toUserB: MatchNewPayload = {
    matchId,
    conversationId,
    userId: userAId,
    userName: row.user_a_name ?? "",
    userPicture: row.user_a_picture,
  };

  sendToUser(userAId, { type: "match:new", payload: toUserA });
  sendToUser(userBId, { type: "match:new", payload: toUserB });
}

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
        if (!wsConnections.has(userId)) {
          wsConnections.set(userId, new Set());
        }
        wsConnections.get(userId)!.add(ws as any);
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
        const connections = wsConnections.get(userId);
        if (connections) {
          connections.delete(ws as any);
          if (connections.size === 0) {
            wsConnections.delete(userId);
          }
        }
        console.log(`WebSocket disconnected: user ${userId}`);
      }
    },
  },
});

console.log(`Server with WebSocket running on http://localhost:${port}`);
