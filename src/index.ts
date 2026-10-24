import { Hono } from "hono";
import { serveStatic } from "hono/bun";
import { cors } from "hono/cors";
import { secureHeaders } from "hono/secure-headers";
import { z } from "zod";
import { mkdir } from "node:fs/promises";
import {
  sql,
  getTotalCount,
  initDb,
  completeFinishedProfiles,
  upsertWaitlistAndGetVerification,
  findUserByEmail,
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
import { isValidUnsubscribeToken, sendVerificationRequestEmail } from "./email";
import { generateJWT, verifyJWT } from "./auth";
import { sendPushToUsers, sendPushToAll } from "./onesignal";
import { requireAuth, type AppVariables } from "./shared/http/middleware";
import { isAccountActive } from "./shared/http/account-state";
import { createIpRateLimiter, createKeyedLimiter } from "./shared/http/rate-limit";
import { parseBody, swipeBodySchema } from "./shared/http/validation";
import {
  emitNewMatch,
  addConnection,
  removeConnection,
  closeUserConnections,
  ACCOUNT_DISABLED_CLOSE,
} from "./shared/realtime/connections";
import { registerAuthRoutes } from "./features/auth/auth.routes";
import { registerEventsRoutes } from "./features/events/events.routes";
import { createTransactionVerifier, registerSubscriptions } from "./features/subscriptions/subscriptions.module";
import { createCreditsService, registerCredits } from "./features/credits/credits.module";
import { createWebSessionModule, ensureWebSessionSchema, registerWebSession } from "./features/web-session";
import { createWebApp } from "./features/web-app";
import { registerMatchingRoutes } from "./features/matching/matching.routes";
import { registerCoupleRoutes } from "./features/couple/couple.routes";
import { registerAdminRoutes } from "./features/admin/admin.routes";
import { registerProfileRoutes } from "./features/profile/profile.routes";
import { createMediaModule, ensureMediaSchema, fuzzExistingLocations } from "./features/media";
import { ensureAccountSchema, registerAccountRoutes } from "./features/account/account.routes";
import { createBillingWeb, ensureBillingWebSchema, registerBillingWeb, withStripeCancellation } from "./features/billing-web/billing-web.module";
import { registerMediaRoutes } from "./features/media/presentation/media.routes";
import { registerEngagementRoutes } from "./features/engagement/engagement.routes";
import { createChatModule, ensureChatSchema, registerChat, startChatMaintenance } from "./features/chat";
import { assertKeysConfigured } from "./shared/crypto/keys";
import {
  createDocumentsModule,
  ensureDocumentsSchema,
  registerDocumentsDevRoutes,
  registerDocumentsRoutes,
  startPurgeScheduler,
} from "./features/documents";
import {
  createVerificationModule,
  ensureVerificationSchema,
  registerVerification,
} from "./features/verification/verification.module";

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

const UPLOADS_DIR = process.env.UPLOADS_DIR || "uploads";

// Member verification (selfie): models load lazily, configuration is read now
// so that a malformed threshold stops the boot.
const verification = createVerificationModule({ sql, uploadsDir: UPLOADS_DIR });

// Development routes (/api/dev/*: sign in as anyone, reset swipes...) exist
// only when NODE_ENV says development or test. Any other value, unset
// included, closes them: a staging server without NODE_ENV must not hand out
// tokens for any e-mail.
const DEV_ROUTES_ENABLED = process.env.NODE_ENV === "development" || process.env.NODE_ENV === "test";
if (DEV_ROUTES_ENABLED) console.warn(`Development routes are ENABLED (NODE_ENV=${process.env.NODE_ENV})`);

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

// Security headers on every response. The CSP is written for the console and
// the landing pages (inline scripts and handlers, Google Sign-In, Google
// Fonts); it mainly stops framing and keeps scripts and connections to the
// listed origins.
app.use(
  "*",
  secureHeaders({
    crossOriginResourcePolicy: "same-site",
    crossOriginOpenerPolicy: "same-origin-allow-popups",
    referrerPolicy: "strict-origin-when-cross-origin",
    contentSecurityPolicy: {
      defaultSrc: ["'self'"],
      scriptSrc: ["'self'", "'unsafe-inline'", "https://accounts.google.com/gsi/client"],
      styleSrc: ["'self'", "'unsafe-inline'", "https://fonts.googleapis.com", "https://accounts.google.com/gsi/style"],
      fontSrc: ["'self'", "https://fonts.gstatic.com"],
      imgSrc: ["'self'", "data:", "blob:", "https:"],
      connectSrc: ["'self'", "https://accounts.google.com/gsi/"],
      frameSrc: ["https://accounts.google.com/gsi/"],
      frameAncestors: ["'none'"],
      objectSrc: ["'none'"],
      baseUri: ["'none'"],
      formAction: ["'self'"],
    },
  }),
);

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

// Legal pages. The app's Premium screen links to /terms and /privacy.
for (const page of ["cgu", "cgv", "confidentialite"] as const) {
  app.get(`/${page}`, (c) => c.html(Bun.file(`./public/${page}.html`).text()));
}
app.get("/terms", (c) => c.redirect("/cgu", 301));
app.get("/privacy", (c) => c.redirect("/confidentialite", 301));

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


// API Routes
// Waitlist sign-up is public: limited per client address and per e-mail, so
// that nobody can flood a stranger's inbox with MAZL e-mails. The answer is
// the same whatever happens, so it tells nothing about who is registered.
const subscribeLimiter = createIpRateLimiter({ max: 5, windowMs: 60 * 60_000 });
const subscribeEmailsPerAddress = createKeyedLimiter({ max: 3, windowMs: 24 * 60 * 60_000 });
const subscribeBodySchema = z.object({ email: z.email().max(254) });
const SUBSCRIBED = { success: true, message: "Inscription OK ! Regarde tes emails pour envoyer tes documents." } as const;

app.post("/api/subscribe", subscribeLimiter, async (c) => {
  const parsed = subscribeBodySchema.safeParse(await c.req.json().catch(() => null));
  if (!parsed.success) {
    return c.json({ success: false, error: "Email invalide" }, 400);
  }
  const email = parsed.data.email.trim();
  const emailKey = email.toLowerCase();
  if (subscribeEmailsPerAddress.retryAfter(emailKey) !== null) return c.json(SUBSCRIBED);
  subscribeEmailsPerAddress.hit(emailKey);

  try {
    const waitlist = await upsertWaitlistAndGetVerification(email);
    // A verified or submitted member is left alone: no new link, no e-mail.
    if (waitlist.alreadyHandled) return c.json(SUBSCRIBED);

    // The link always points at APP_URL (src/email.ts), never at a header.
    try {
      await sendVerificationRequestEmail({ to: email, verificationToken: waitlist.verificationToken });
    } catch (err) {
      console.error("Email send failed:", err instanceof Error ? err.name : "unknown error");
    }

    return c.json(SUBSCRIBED);
  } catch (error) {
    console.error("Subscribe error:", error instanceof Error ? error.name : "unknown error");
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

// Member document flow (GET /api/verify, POST /api/verify/upload, POST
// /api/verify/submit): src/features/documents. Files are encrypted at rest and
// purged after the admin decision.
const chat = createChatModule({ uploadsDir: UPLOADS_DIR });
const documents = createDocumentsModule(UPLOADS_DIR);
registerDocumentsRoutes(app, documents);

// ============ ADMIN FEATURE ============
// All `/api/admin/*` endpoints live in src/features/admin/*. They are
// registered here — at their original location in the route table —
// preserving the exact relative declaration order of the admin routes.
// Admin auth (admin JWT + email whitelist via assertAdmin)
// lives in src/features/admin/admin.auth.ts.
const media = createMediaModule({ uploadsDir: UPLOADS_DIR, faceChecker: verification.photoFaceChecker });
// GDPR erasure of a member: rows first (inside `deletion`), then their profile
// photo files, then their chat files. A failed deletion touches no file.
// Once erased, the member's open sockets are closed.
const userErasure = {
  around: async <T,>(userId: number, deletion: () => Promise<T>): Promise<T> => {
    const erased = await chat.media.eraseUserMedia(userId, () => media.photos.eraseUserPhotos(userId, deletion));
    closeUserConnections(userId, ACCOUNT_DISABLED_CLOSE, "account_disabled");
    return erased;
  },
};
// Web payments: a member's Stripe subscription is cancelled before their erasure.
const billingWeb = createBillingWeb({ sql, authenticate: requireAuth });
const erasureWithBilling = withStripeCancellation(userErasure, billingWeb);
registerAdminRoutes(app, UPLOADS_DIR, erasureWithBilling);
registerAccountRoutes(app, sql, erasureWithBilling);
registerBillingWeb(app, billingWeb);

// ============ AUTH ENDPOINTS ============

// Auth feature routes (POST /api/auth/google, POST /api/auth/apple, GET /api/auth/me)
registerAuthRoutes(app);

// Web sign-in (QR, Google, Apple), revocable web sessions and the cookie bridge.
const webSession = createWebSessionModule({ sql });
registerWebSession(app, webSession);
// The built web client under /app, with its own headers (docs/web/adr/W01).
const webApp = createWebApp({ distDir: process.env.WEB_DIST_DIR || "web/dist", webOrigin: process.env.WEB_ORIGIN || null });

// ============ PROFILE, PHOTOS & PROMPTS ============
// Profile feature routes (PUT /api/profile, photos upload/delete/reorder/
// set-primary, protected upload serving, GET /api/prompts, the caller's
// profile prompts, and GET /api/profile/:userId). Moved to
// src/features/profile/profile.routes.ts. The prompts routes are declared
// before /api/profile/:userId inside that file to preserve route ordering.
// Selfie verification (/api/verification/*) lives in src/features/verification.
// Photos added after verification are compared with the member's face reference.
registerMediaRoutes(app, media.photos);
registerProfileRoutes(app, { media });

// ============ CREDITS (boosts and super likes held by the server) ============
// Allowances, purchased consumables, debits and refunds: src/features/credits
// (docs/premium/CREDITS.md). The Apple verifier is shared with the
// subscriptions below; the swipe and boost routes receive the service.
const appleTransactions = createTransactionVerifier(process.env);
const credits = createCreditsService({ sql, transactions: appleTransactions });
registerCredits(app, credits, requireAuth);

// ============ DISCOVER & MATCHING ============

// Core matching feature routes (GET /api/discover, GET /api/daily-picks,
// POST /api/swipes, GET /api/matches, GET /api/likes/received[/count]).
// Moved to src/features/matching/matching.routes.ts. `POST /api/swipes` still
// emits `match:new` via the exported `emitNewMatch` helper below.
registerMatchingRoutes(app, { credits });

// ============ ENGAGEMENT (verification, boost, moderation) ============
// Engagement feature routes (selfie verification /api/verification/*, boost
// /api/boost/*, moderation /api/users/:id/block, /api/users/blocked,
// /api/users/:id/report, /api/report). Moved to
// src/features/engagement/engagement.routes.ts.
registerEngagementRoutes(app, { credits });

// ============ MEMBER VERIFICATION (level 1: live selfie) ============
// /api/verification/* (face session + submit, reference deletion, status and
// the legacy start/submit). Registered next to the engagement routes it was
// split from. The module is built above, next to UPLOADS_DIR, so that
// `verification.photoFaceChecker` can be handed to the profile feature.
registerVerification(app, verification);

// ============ CHAT ENDPOINTS ============

// Conversations, messages (text, photos, voice), reactions, unsend, read
// receipts, reports and signed chat media: src/features/chat (docs/chat/CONTRAT.md).
registerChat(app, chat);

// ============ EVENTS ENDPOINTS ============

// Classic events feature routes (GET /api/events, GET /api/events/:id,
// POST /api/events/:id/rsvp, DELETE /api/events/:id/rsvp).
registerEventsRoutes(app);



// ============ SUBSCRIPTIONS ENDPOINTS ============

// User-facing subscription status, native Apple purchase verification
// (StoreKit 2 signed transactions) and App Store Server Notifications V2 live in
// the subscriptions feature. The former POST /api/subscription/sync route was
// REMOVED during the audit (it let any authenticated user declare themselves
// premium): the server now trusts only Apple-signed payloads.
registerSubscriptions(app, { sql, authenticate: requireAuth, transactions: appleTransactions, consumables: credits });



// ============ DEV/DEBUG ENDPOINTS ============

registerDocumentsDevRoutes(app, documents, !DEV_ROUTES_ENABLED);

// Create test user (dev only)
app.post("/api/dev/test-user", async (c) => {
  if (!DEV_ROUTES_ENABLED) return c.json({ error: "Not found" }, 404);
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
  if (!DEV_ROUTES_ENABLED) return c.json({ error: "Not found" }, 404);
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
  if (!DEV_ROUTES_ENABLED) return c.json({ error: "Not found" }, 404);
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
      // Reactivate existing couple, after ending any other active couple of
      // either member (the database allows one active couple per member).
      await sql`
        UPDATE couples SET status = 'ended', updated_at = NOW()
        WHERE id <> ${couple.id} AND status = 'active'
          AND (user1_id IN (${userId}, ${partnerUserId}) OR user2_id IN (${userId}, ${partnerUserId}))
      `;
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
  if (!DEV_ROUTES_ENABLED) return c.json({ error: "Not found" }, 404);
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
  if (!DEV_ROUTES_ENABLED) return c.json({ error: "Not found" }, 404);
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
  if (!DEV_ROUTES_ENABLED) return c.json({ error: "Not found" }, 404);
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
  const token = c.req.query("t");
  if (!email || !token || !isValidUnsubscribeToken(email, token)) {
    return c.html("<h1>Lien de désinscription invalide</h1><p>Utilise le lien présent dans le dernier e-mail reçu.</p>", 400);
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

// Fail fast in production when a data-protection key is missing.
assertKeysConfigured();

await initDb();
const completedAtBoot = await completeFinishedProfiles();
if (completedAtBoot > 0) console.log(`Completed ${completedAtBoot} finished profiles`);
await ensureDocumentsSchema();
startPurgeScheduler(() => documents.purger.sweep());
await ensureMediaSchema();
await ensureChatSchema();
await ensureAccountSchema(sql);
await ensureBillingWebSchema(sql);
startChatMaintenance(chat);
const fuzzedAtBoot = await fuzzExistingLocations();
if (fuzzedAtBoot > 0) console.log(`Fuzzed ${fuzzedAtBoot} stored positions`);
await ensureVerificationSchema(sql);
await ensureWebSessionSchema(sql);

console.log(`Server running on http://localhost:${port}`);

// ============ WEBSOCKET FOR REAL-TIME CHAT ============
// The connection registry (`sendToUser`, `addConnection`, `removeConnection`)
// and `emitNewMatch` now live in `src/shared/realtime/connections.ts` and are
// imported above. The `Bun.serve` websocket handlers below use those helpers.

// Bun.serve with WebSocket support
interface WebSocketData {
  userId: number;
  // Seconds since the epoch: the socket lives no longer than its token.
  expiresAt: number;
  // Set when the token is a web socket ticket: the web session it belongs to.
  webSessionId?: string;
}

// The token rides in the query string (browsers cannot set headers on a
// WebSocket); the account is checked like on every HTTP request.
async function upgradeToSocket(req: Request, url: URL, server: Bun.Server<WebSocketData>): Promise<Response | undefined> {
  const token = url.searchParams.get("token");
  if (!token) {
    return new Response("Token required", { status: 401 });
  }

  const payload = verifyJWT(token);
  if (!payload) {
    return new Response("Invalid token", { status: 401 });
  }

  const userId = Number(payload.sub);
  if (!(await isAccountActive(userId))) {
    return new Response("Account disabled", { status: 401 });
  }

  if (server.upgrade(req, { data: { userId, expiresAt: payload.exp, webSessionId: webSession.socketSession(token) } })) {
    return undefined;
  }
  return new Response("WebSocket upgrade failed", { status: 500 });
}

const server = Bun.serve<WebSocketData>({
  port,
  async fetch(req, server) {
    await webSession.bridge(req);
    const page = await webApp.handle(req);
    if (page) return page;
    const url = new URL(req.url);
    if (url.pathname === "/ws") return upgradeToSocket(req, url, server);

    // Regular HTTP requests go to Hono, which reads the client address from
    // the Bun server (src/shared/http/client-ip.ts).
    return app.fetch(req, { server });
  },
  websocket: {
    // A chat frame is at most a few kilobytes; anything bigger is refused
    // before it is buffered and parsed.
    maxPayloadLength: 64 * 1024,
    open(ws) {
      const userId = (ws.data as any)?.userId as number;
      if (userId) {
        addConnection(userId, ws as unknown as WebSocket);
        if (ws.data.webSessionId) webSession.socketOpened(ws.data.webSessionId, ws);
        console.log(`WebSocket connected: user ${userId}`);
      }
    },
    async message(ws, message) {
      const userId = (ws.data as any)?.userId as number;
      if (!userId) return;
      if (ws.data.expiresAt <= Math.floor(Date.now() / 1000)) {
        ws.close(4001, "token_expired");
        return;
      }

      try {
        const data = JSON.parse(message.toString());

        switch (data.type) {
          // The chat:* frames are handled by the chat feature (membership,
          // blocking, idempotency and fan-out all live there). The mobile
          // client wraps its fields inside `payload`.
          case "chat:send":
            await chat.sockets.send(userId, data.payload);
            break;

          case "chat:typing":
            await chat.sockets.typing(userId, data.payload);
            break;

          case "chat:read":
            await chat.sockets.read(userId, data.payload);
            break;

          case "ping": {
            (ws as any).send(JSON.stringify({ type: "pong" }));
            break;
          }
        }
      } catch (err) {
        // Never log the frame itself (docs/chat/CONTRAT.md §0.3).
        console.error("WebSocket message error:", err instanceof Error ? err.name : "unknown error");
      }
    },
    close(ws) {
      const userId = (ws.data as any)?.userId as number;
      if (userId) {
        removeConnection(userId, ws as unknown as WebSocket);
        if (ws.data.webSessionId) webSession.socketClosed(ws.data.webSessionId, ws);
        console.log(`WebSocket disconnected: user ${userId}`);
      }
    },
  },
});

console.log(`Server with WebSocket running on http://localhost:${port}`);
