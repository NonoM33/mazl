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
  // Module 2: Gestion Events
  getEventPhotos,
  // Module 3: Campagnes
  unsubscribeEmail,
  // Module 4: Modération
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
import { registerProfileRoutes } from "./features/profile/profile.routes";
import { registerEngagementRoutes } from "./features/engagement/engagement.routes";

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

const sendMessageBodySchema = z
  .object({
    content: z.string().min(1),
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

// ============ PROFILE, PHOTOS & PROMPTS ============
// Profile feature routes (PUT /api/profile, photos upload/delete/reorder/
// set-primary, protected upload serving, GET /api/prompts, the caller's
// profile prompts, and GET /api/profile/:userId). Moved to
// src/features/profile/profile.routes.ts. The prompts routes are declared
// before /api/profile/:userId inside that file to preserve route ordering.
// Selfie verification (/api/verification/*) moved to the engagement feature.
registerProfileRoutes(app, UPLOADS_DIR);

// ============ DISCOVER & MATCHING ============

// Core matching feature routes (GET /api/discover, GET /api/daily-picks,
// POST /api/swipes, GET /api/matches, GET /api/likes/received[/count]).
// Moved to src/features/matching/matching.routes.ts. `POST /api/swipes` still
// emits `match:new` via the exported `emitNewMatch` helper below.
registerMatchingRoutes(app);

// ============ ENGAGEMENT (verification, boost, moderation) ============
// Engagement feature routes (selfie verification /api/verification/*, boost
// /api/boost/*, moderation /api/users/:id/block, /api/users/blocked,
// /api/users/:id/report, /api/report). Moved to
// src/features/engagement/engagement.routes.ts.
registerEngagementRoutes(app);

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
