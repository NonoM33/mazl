import { Hono } from "hono";
import { serveStatic } from "hono/bun";
import { cors } from "hono/cors";
import { mkdir } from "node:fs/promises";
import { join } from "node:path";
import {
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
  upsertUser,
  findUserById,
  getUserProfile,
  upsertProfile,
  getDiscoverProfiles,
  recordSwipe,
  getMatches,
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
  createRsvp,
  deleteRsvp,
  getEventAttendees,
  getUserRsvp,
  // Subscriptions
  syncSubscription,
  getSubscription,
  getAllSubscriptions,
  // Admin
  getAdminStats,
  getAdminUsers,
  setUserActiveStatus,
} from "./db";
import { sendProfileApprovedEmail, sendReuploadRequestedEmail, sendVerificationRequestEmail } from "./email";
import { verifyGoogleIdToken, verifyAppleIdToken, generateJWT, verifyJWT, extractBearerToken } from "./auth";

const app = new Hono();

const UPLOADS_DIR = process.env.UPLOADS_DIR || "uploads";

// CORS
app.use("/api/*", cors());

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

function getAdminPassword(c: any) {
  return c.req.query("password") || c.req.header("x-admin-password") || "";
}

// Admin JWT secret (use a different secret than user JWT)
const ADMIN_JWT_SECRET = process.env.ADMIN_JWT_SECRET || process.env.JWT_SECRET || "admin-secret-key";

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

function assertAdmin(c: any) {
  // First try JWT token from Authorization header
  const authHeader = c.req.header("Authorization") || "";
  if (authHeader.startsWith("Bearer ")) {
    const token = authHeader.substring(7);
    const result = verifyAdminJWT(token);
    if (result.valid) {
      return { ok: true, email: result.email };
    }
  }

  // Try JWT token from query parameter (for file downloads)
  const tokenParam = c.req.query("token");
  if (tokenParam) {
    const result = verifyAdminJWT(tokenParam);
    if (result.valid) {
      return { ok: true, email: result.email };
    }
  }

  // Fallback to old password method (for backward compatibility)
  const required = process.env.ADMIN_PASSWORD;
  if (!required) return { ok: false, error: "ADMIN_PASSWORD not set" };
  if (getAdminPassword(c) !== required) return { ok: false, error: "Unauthorized" };
  return { ok: true };
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
  const auth = assertAdmin(c);
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

// Google OAuth - Verify ID token from mobile app
app.post("/api/auth/google", async (c) => {
  try {
    const { idToken, accessToken } = await c.req.json();

    if (!idToken) {
      return c.json({ success: false, error: "ID token required" }, 400);
    }

    // Verify the Google ID token
    const googleUser = await verifyGoogleIdToken(idToken);
    if (!googleUser) {
      return c.json({ success: false, error: "Invalid Google token" }, 401);
    }

    // Create or update user in database
    const { user, isNew } = await upsertUser({
      email: googleUser.email,
      name: googleUser.name,
      picture: googleUser.picture,
      provider: "google",
      providerId: googleUser.sub,
    });

    // Generate JWT token
    const token = generateJWT({
      id: user.id,
      email: user.email,
      name: user.name ?? undefined,
      picture: user.picture ?? undefined,
      provider: "google",
      providerId: googleUser.sub,
    });

    // Get user profile if exists
    const profile = await getUserProfile(user.id);

    return c.json({
      success: true,
      token,
      user: {
        id: user.id,
        email: user.email,
        name: user.name,
        picture: user.picture,
        provider: user.provider,
        isNew,
        hasProfile: !!profile?.is_complete,
      },
    });
  } catch (error: any) {
    console.error("Google auth error:", error);
    return c.json({ success: false, error: "Authentication failed" }, 500);
  }
});

// Apple OAuth - Verify identity token from mobile app
app.post("/api/auth/apple", async (c) => {
  try {
    const { identityToken, authorizationCode, email, fullName } = await c.req.json();

    if (!identityToken) {
      return c.json({ success: false, error: "Identity token required" }, 400);
    }

    // Verify the Apple identity token
    const appleUser = await verifyAppleIdToken(identityToken);
    if (!appleUser) {
      return c.json({ success: false, error: "Invalid Apple token" }, 401);
    }

    // Apple only sends email on first sign-in, use provided email or token email
    const userEmail = appleUser.email || email || `${appleUser.sub}@privaterelay.appleid.com`;

    // Create or update user in database
    const { user, isNew } = await upsertUser({
      email: userEmail,
      name: fullName,
      provider: "apple",
      providerId: appleUser.sub,
    });

    // Generate JWT token
    const token = generateJWT({
      id: user.id,
      email: user.email,
      name: user.name ?? undefined,
      provider: "apple",
      providerId: appleUser.sub,
    });

    // Get user profile if exists
    const profile = await getUserProfile(user.id);

    return c.json({
      success: true,
      token,
      user: {
        id: user.id,
        email: user.email,
        name: user.name,
        provider: user.provider,
        isNew,
        hasProfile: !!profile?.is_complete,
      },
    });
  } catch (error: any) {
    console.error("Apple auth error:", error);
    return c.json({ success: false, error: "Authentication failed" }, 500);
  }
});

// Get current user
app.get("/api/auth/me", async (c) => {
  try {
    const token = extractBearerToken(c.req.header("Authorization"));
    if (!token) {
      return c.json({ success: false, error: "No token provided" }, 401);
    }

    const payload = verifyJWT(token);
    if (!payload) {
      return c.json({ success: false, error: "Invalid token" }, 401);
    }

    const user = await findUserById(parseInt(payload.sub));
    if (!user) {
      return c.json({ success: false, error: "User not found" }, 404);
    }

    const profile = await getUserProfile(user.id);

    return c.json({
      success: true,
      user: {
        id: user.id,
        email: user.email,
        name: user.name,
        picture: user.picture,
        provider: user.provider,
        hasProfile: !!profile?.is_complete,
      },
      profile,
    });
  } catch (error: any) {
    console.error("Get user error:", error);
    return c.json({ success: false, error: "Failed to get user" }, 500);
  }
});

// Update user profile
app.put("/api/profile", async (c) => {
  try {
    const token = extractBearerToken(c.req.header("Authorization"));
    if (!token) {
      return c.json({ success: false, error: "No token provided" }, 401);
    }

    const payload = verifyJWT(token);
    if (!payload) {
      return c.json({ success: false, error: "Invalid token" }, 401);
    }

    const userId = parseInt(payload.sub);
    const body = await c.req.json();

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

// ============ DISCOVER & MATCHING ============

// Get profiles for discovery
app.get("/api/discover", async (c) => {
  try {
    const token = extractBearerToken(c.req.header("Authorization"));
    if (!token) {
      return c.json({ success: false, error: "No token provided" }, 401);
    }

    const payload = verifyJWT(token);
    if (!payload) {
      return c.json({ success: false, error: "Invalid token" }, 401);
    }

    const userId = parseInt(payload.sub);
    const limit = parseInt(c.req.query("limit") || "20");
    const offset = parseInt(c.req.query("offset") || "0");

    const profiles = await getDiscoverProfiles(userId, limit, offset);

    return c.json({ success: true, profiles });
  } catch (error: any) {
    console.error("Discover error:", error);
    return c.json({ success: false, error: "Failed to get profiles" }, 500);
  }
});

// Record swipe action
app.post("/api/swipes", async (c) => {
  try {
    const token = extractBearerToken(c.req.header("Authorization"));
    if (!token) {
      return c.json({ success: false, error: "No token provided" }, 401);
    }

    const payload = verifyJWT(token);
    if (!payload) {
      return c.json({ success: false, error: "Invalid token" }, 401);
    }

    const userId = parseInt(payload.sub);
    const { target_user_id, action } = await c.req.json();

    if (!target_user_id || !action) {
      return c.json({ success: false, error: "Missing target_user_id or action" }, 400);
    }

    if (!['like', 'pass', 'super_like'].includes(action)) {
      return c.json({ success: false, error: "Invalid action" }, 400);
    }

    const result = await recordSwipe(userId, target_user_id, action);

    return c.json({ success: true, ...result });
  } catch (error: any) {
    console.error("Swipe error:", error);
    return c.json({ success: false, error: "Failed to record swipe" }, 500);
  }
});

// Get user's matches
app.get("/api/matches", async (c) => {
  try {
    const token = extractBearerToken(c.req.header("Authorization"));
    if (!token) {
      return c.json({ success: false, error: "No token provided" }, 401);
    }

    const payload = verifyJWT(token);
    if (!payload) {
      return c.json({ success: false, error: "Invalid token" }, 401);
    }

    const userId = parseInt(payload.sub);
    const matches = await getMatches(userId);

    return c.json({ success: true, matches });
  } catch (error: any) {
    console.error("Matches error:", error);
    return c.json({ success: false, error: "Failed to get matches" }, 500);
  }
});

// ============ CHAT ENDPOINTS ============

// Get user's conversations
app.get("/api/conversations", async (c) => {
  try {
    const token = extractBearerToken(c.req.header("Authorization"));
    if (!token) {
      return c.json({ success: false, error: "No token provided" }, 401);
    }

    const payload = verifyJWT(token);
    if (!payload) {
      return c.json({ success: false, error: "Invalid token" }, 401);
    }

    const userId = parseInt(payload.sub);
    const conversations = await getConversations(userId);

    return c.json({ success: true, conversations });
  } catch (error: any) {
    console.error("Conversations error:", error);
    return c.json({ success: false, error: "Failed to get conversations" }, 500);
  }
});

// Get conversation details
app.get("/api/conversations/:id", async (c) => {
  try {
    const token = extractBearerToken(c.req.header("Authorization"));
    if (!token) {
      return c.json({ success: false, error: "No token provided" }, 401);
    }

    const payload = verifyJWT(token);
    if (!payload) {
      return c.json({ success: false, error: "Invalid token" }, 401);
    }

    const userId = parseInt(payload.sub);
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
app.get("/api/conversations/:id/messages", async (c) => {
  try {
    const token = extractBearerToken(c.req.header("Authorization"));
    if (!token) {
      return c.json({ success: false, error: "No token provided" }, 401);
    }

    const payload = verifyJWT(token);
    if (!payload) {
      return c.json({ success: false, error: "Invalid token" }, 401);
    }

    const userId = parseInt(payload.sub);
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
app.post("/api/conversations/:id/messages", async (c) => {
  try {
    const token = extractBearerToken(c.req.header("Authorization"));
    if (!token) {
      return c.json({ success: false, error: "No token provided" }, 401);
    }

    const payload = verifyJWT(token);
    if (!payload) {
      return c.json({ success: false, error: "Invalid token" }, 401);
    }

    const userId = parseInt(payload.sub);
    const conversationId = parseInt(c.req.param("id"));
    const { content } = await c.req.json();

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

    return c.json({ success: true, message });
  } catch (error: any) {
    console.error("Send message error:", error);
    return c.json({ success: false, error: "Failed to send message" }, 500);
  }
});

// Mark messages as read
app.put("/api/conversations/:id/read", async (c) => {
  try {
    const token = extractBearerToken(c.req.header("Authorization"));
    if (!token) {
      return c.json({ success: false, error: "No token provided" }, 401);
    }

    const payload = verifyJWT(token);
    if (!payload) {
      return c.json({ success: false, error: "Invalid token" }, 401);
    }

    const userId = parseInt(payload.sub);
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

    return c.json({ success: true });
  } catch (error: any) {
    console.error("Mark read error:", error);
    return c.json({ success: false, error: "Failed to mark as read" }, 500);
  }
});

// ============ EVENTS ENDPOINTS ============

// Get public events
app.get("/api/events", async (c) => {
  try {
    const type = c.req.query("type");
    const fromDate = c.req.query("from") || new Date().toISOString().split("T")[0];
    const limit = parseInt(c.req.query("limit") || "50");
    const offset = parseInt(c.req.query("offset") || "0");

    const events = await getEvents({
      type: type || undefined,
      fromDate,
      publishedOnly: true,
      limit,
      offset,
    });

    return c.json({ success: true, events });
  } catch (error: any) {
    console.error("Events error:", error);
    return c.json({ success: false, error: "Failed to get events" }, 500);
  }
});

// Get event by ID
app.get("/api/events/:id", async (c) => {
  try {
    const eventId = parseInt(c.req.param("id"));
    const event = await getEventById(eventId);

    if (!event) {
      return c.json({ success: false, error: "Event not found" }, 404);
    }

    // Check if user is logged in to get RSVP status
    let userRsvp = null;
    const token = extractBearerToken(c.req.header("Authorization"));
    if (token) {
      const payload = verifyJWT(token);
      if (payload) {
        const userId = parseInt(payload.sub);
        userRsvp = await getUserRsvp(eventId, userId);
      }
    }

    return c.json({ success: true, event, userRsvp });
  } catch (error: any) {
    console.error("Event error:", error);
    return c.json({ success: false, error: "Failed to get event" }, 500);
  }
});

// RSVP to event
app.post("/api/events/:id/rsvp", async (c) => {
  try {
    const token = extractBearerToken(c.req.header("Authorization"));
    if (!token) {
      return c.json({ success: false, error: "No token provided" }, 401);
    }

    const payload = verifyJWT(token);
    if (!payload) {
      return c.json({ success: false, error: "Invalid token" }, 401);
    }

    const userId = parseInt(payload.sub);
    const eventId = parseInt(c.req.param("id"));
    const { status } = await c.req.json().catch(() => ({ status: "going" }));

    const event = await getEventById(eventId);
    if (!event) {
      return c.json({ success: false, error: "Event not found" }, 404);
    }

    // Check max attendees
    if ((event as any).max_attendees && (event as any).attendee_count >= (event as any).max_attendees) {
      return c.json({ success: false, error: "Event is full" }, 400);
    }

    const rsvp = await createRsvp(eventId, userId, status || "going");

    return c.json({ success: true, rsvp });
  } catch (error: any) {
    console.error("RSVP error:", error);
    return c.json({ success: false, error: "Failed to RSVP" }, 500);
  }
});

// Cancel RSVP
app.delete("/api/events/:id/rsvp", async (c) => {
  try {
    const token = extractBearerToken(c.req.header("Authorization"));
    if (!token) {
      return c.json({ success: false, error: "No token provided" }, 401);
    }

    const payload = verifyJWT(token);
    if (!payload) {
      return c.json({ success: false, error: "Invalid token" }, 401);
    }

    const userId = parseInt(payload.sub);
    const eventId = parseInt(c.req.param("id"));

    await deleteRsvp(eventId, userId);

    return c.json({ success: true });
  } catch (error: any) {
    console.error("Cancel RSVP error:", error);
    return c.json({ success: false, error: "Failed to cancel RSVP" }, 500);
  }
});

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

// Get user subscription
app.get("/api/subscription", async (c) => {
  try {
    const token = extractBearerToken(c.req.header("Authorization"));
    if (!token) {
      return c.json({ success: false, error: "No token provided" }, 401);
    }

    const payload = verifyJWT(token);
    if (!payload) {
      return c.json({ success: false, error: "Invalid token" }, 401);
    }

    const userId = parseInt(payload.sub);
    const subscription = await getSubscription(userId);

    return c.json({ success: true, subscription });
  } catch (error: any) {
    console.error("Subscription error:", error);
    return c.json({ success: false, error: "Failed to get subscription" }, 500);
  }
});

// Sync subscription (from mobile app)
app.post("/api/subscription/sync", async (c) => {
  try {
    const token = extractBearerToken(c.req.header("Authorization"));
    if (!token) {
      return c.json({ success: false, error: "No token provided" }, 401);
    }

    const payload = verifyJWT(token);
    if (!payload) {
      return c.json({ success: false, error: "Invalid token" }, 401);
    }

    const userId = parseInt(payload.sub);
    const body = await c.req.json();

    const subscription = await syncSubscription(userId, {
      planType: body.planType,
      status: body.status,
      revenuecatId: body.revenuecatId,
      startsAt: body.startsAt,
      expiresAt: body.expiresAt,
    });

    return c.json({ success: true, subscription });
  } catch (error: any) {
    console.error("Sync subscription error:", error);
    return c.json({ success: false, error: "Failed to sync subscription" }, 500);
  }
});

// RevenueCat webhook
app.post("/api/subscriptions/webhook", async (c) => {
  try {
    const body = await c.req.json();

    // RevenueCat sends events with app_user_id
    const appUserId = body?.event?.app_user_id;
    if (!appUserId) {
      return c.json({ success: false, error: "No user ID" }, 400);
    }

    // Parse user ID (assuming format is "user_123")
    const userId = parseInt(appUserId.replace("user_", ""));
    if (isNaN(userId)) {
      return c.json({ success: false, error: "Invalid user ID format" }, 400);
    }

    const event = body?.event;
    const productId = event?.product_id || "";
    const expiresAt = event?.expiration_at_ms
      ? new Date(event.expiration_at_ms).toISOString()
      : null;

    // Determine plan type from product ID
    let planType = "unknown";
    if (productId.includes("monthly")) planType = "monthly";
    else if (productId.includes("yearly") || productId.includes("annual")) planType = "yearly";
    else if (productId.includes("lifetime")) planType = "lifetime";

    // Determine status from event type
    let status = "active";
    if (event?.type === "CANCELLATION" || event?.type === "EXPIRATION") {
      status = "cancelled";
    } else if (event?.type === "BILLING_ISSUE") {
      status = "billing_issue";
    }

    await syncSubscription(userId, {
      planType,
      status,
      revenuecatId: event?.id,
      expiresAt: expiresAt || undefined,
    });

    return c.json({ success: true });
  } catch (error: any) {
    console.error("Webhook error:", error);
    return c.json({ success: false, error: "Webhook processing failed" }, 500);
  }
});

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
      if (ws.readyState === WebSocket.OPEN) {
        ws.send(message);
      }
    }
  }
}

// Bun.serve with WebSocket support
const server = Bun.serve({
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
            // Send message via API and broadcast
            const { conversationId, content } = data;
            if (!conversationId || !content) return;

            const conversation = await getConversationById(conversationId);
            if (!conversation) return;

            // Verify user is in conversation
            const conv = conversation as any;
            if (conv.user1_id !== userId && conv.user2_id !== userId) return;

            const msg = await createMessage(conversationId, userId, content);

            // Determine other user
            const otherUserId = conv.user1_id === userId ? conv.user2_id : conv.user1_id;

            // Send to both users
            const messageData = {
              type: "chat:message",
              conversationId,
              message: msg,
            };
            sendToUser(userId, messageData);
            sendToUser(otherUserId, messageData);
            break;
          }

          case "chat:typing": {
            // Broadcast typing indicator
            const { conversationId } = data;
            if (!conversationId) return;

            const conversation = await getConversationById(conversationId);
            if (!conversation) return;

            const conv = conversation as any;
            if (conv.user1_id !== userId && conv.user2_id !== userId) return;

            const otherUserId = conv.user1_id === userId ? conv.user2_id : conv.user1_id;
            sendToUser(otherUserId, {
              type: "chat:typing",
              conversationId,
              userId,
            });
            break;
          }

          case "chat:read": {
            // Mark messages as read and notify
            const { conversationId } = data;
            if (!conversationId) return;

            const conversation = await getConversationById(conversationId);
            if (!conversation) return;

            const conv = conversation as any;
            if (conv.user1_id !== userId && conv.user2_id !== userId) return;

            await markMessagesAsRead(conversationId, userId);

            const otherUserId = conv.user1_id === userId ? conv.user2_id : conv.user1_id;
            sendToUser(otherUserId, {
              type: "chat:read",
              conversationId,
              userId,
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

// Export for Bun compatibility
export default server;
