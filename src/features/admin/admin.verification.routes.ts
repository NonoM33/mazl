import { Hono } from "hono";
import type { AppVariables } from "../../shared/http/middleware";
import {
  listPendingSubmissions,
  listVerifiedProfiles,
  setWaitlistVerificationStatus,
  getWaitlistEmailById,
  requestReuploadAndRotateToken,
} from "../../db";
import { createDocumentsModule, findMissingRequired } from "../documents";
import { sendProfileApprovedEmail, sendReuploadRequestedEmail } from "../../email";
import type { Context } from "hono";
import { z } from "zod";
import { createGoogleVerifier } from "../auth/google-token";
import { clientIp } from "../../shared/http/client-ip";
import { createIpRateLimiter, tooManyRequests } from "../../shared/http/rate-limit";
import {
  adminPasswordAttempts,
  assertAdmin,
  assertAdminFileDownload,
  generateAdminJWT,
  isAdminEmail,
  normalizeEmail,
  secretsMatch,
} from "./admin.auth";

// The console signs in with the WEB client only (never the iOS one).
const adminGoogle = createGoogleVerifier({ audiences: [process.env.GOOGLE_CLIENT_ID ?? ""] });

const adminPasswordLoginSchema = z.object({
  email: z.string().min(1).max(320),
  password: z.string().min(1).max(512),
});

const adminGoogleLoginSchema = z
  .object({
    idToken: z.string().min(1).max(8192).optional(),
    accessToken: z.string().min(1).max(8192).optional(),
  })
  .refine((body) => Boolean(body.idToken) !== Boolean(body.accessToken), "exactly one Google token");

async function readJson(c: Context): Promise<unknown> {
  try {
    return await c.req.json();
  } catch {
    return null;
  }
}

// Admin authentication + verification/document moderation routes, moved verbatim
// from the monolith (src/index.ts). Same paths, behaviour, payloads and status
// codes. Declaration order is preserved: login, google-login, verify, pending,
// verified, document/profile review actions, then the file-download endpoint.
export function registerAdminVerificationRoutes(
  app: Hono<{ Variables: AppVariables }>,
  uploadsDir: string,
): void {
  // Every decision goes through documents.review, which also purges the files
  // it decides (CONTRAT §2.4); the file endpoint decrypts on the fly.
  const documents = createDocumentsModule(uploadsDir);

  // Admin sign-in. Both routes are limited per client address; a wrong
  // password counts towards the lockout shared with the x-admin-password
  // header (admin.auth.ts).
  const googleSignInLimiter = createIpRateLimiter({ max: 20, windowMs: 15 * 60_000 });

  app.post("/api/admin/login", async (c) => {
    const parsed = adminPasswordLoginSchema.safeParse(await readJson(c));
    if (!parsed.success) return c.json({ success: false, error: "Requete invalide" }, 400);

    const adminEmail = process.env.ADMIN_EMAIL;
    const adminPassword = process.env.ADMIN_PASSWORD;
    if (!adminEmail || !adminPassword) {
      console.error("ADMIN_EMAIL or ADMIN_PASSWORD not configured");
      return c.json({ success: false, error: "Configuration serveur manquante" }, 500);
    }

    const address = clientIp(c);
    const lockedFor = adminPasswordAttempts.lockedFor(address);
    if (lockedFor !== null) return tooManyRequests(c, lockedFor);

    const { email, password } = parsed.data;
    const emailMatches = secretsMatch(normalizeEmail(email), normalizeEmail(adminEmail));
    const passwordMatches = secretsMatch(password, adminPassword);
    if (!emailMatches || !passwordMatches) {
      adminPasswordAttempts.recordFailure(address);
      return c.json({ success: false, error: "Email ou mot de passe incorrect" }, 401);
    }

    adminPasswordAttempts.forget(address);
    return c.json({ success: true, token: generateAdminJWT(adminEmail), email: normalizeEmail(adminEmail) });
  });

  // Google sign-in of the console. The identity comes from Google only: an ID
  // token (One Tap) or an access token (pop-up), both checked against our web
  // client id with a verified email. An email in the body is never trusted.
  app.post("/api/admin/google-login", googleSignInLimiter, async (c) => {
    const parsed = adminGoogleLoginSchema.safeParse(await readJson(c));
    if (!parsed.success) return c.json({ success: false, error: "Preuve Google requise" }, 400);

    const { idToken, accessToken } = parsed.data;
    const identity = idToken
      ? await adminGoogle.verifyIdToken(idToken)
      : await adminGoogle.verifyAccessToken(accessToken ?? "");
    if (!identity) return c.json({ success: false, error: "Token Google invalide" }, 401);

    if (!isAdminEmail(identity.email)) {
      console.warn("Admin Google sign-in refused for a non-whitelisted account");
      return c.json({ success: false, error: "Cet email n'est pas autorise" }, 403);
    }

    console.log("Admin signed in via Google");
    return c.json({ success: true, token: generateAdminJWT(identity.email), email: normalizeEmail(identity.email) });
  });

  app.get("/api/admin/verify", async (c) => {
    const auth = assertAdmin(c);
    if (!auth.ok) return c.json({ success: false, error: auth.error }, 401);

    return c.json({
      success: true,
      email: auth.email,
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
    await documents.review.approveDocument(documentId);
    return c.json({ success: true });
  });

  app.post("/api/admin/profiles/:id/approve", async (c) => {
    const auth = assertAdmin(c);
    if (!auth.ok) return c.json({ success: false, error: auth.error }, 401);

    const waitlistId = Number.parseInt(c.req.param("id"), 10);
    const latest = await documents.repo.latestByType(waitlistId);
    const missing = findMissingRequired(latest);

    if (missing.length > 0) {
      return c.json({ success: false, error: `Docs manquants: ${missing.join(", ")}` }, 400);
    }

    await documents.review.approveAllForWaitlist(waitlistId);

    const hasCommunity = latest["community_doc"]?.status === "approved";
    const level = hasCommunity ? "verified_plus" : "verified";
    await setWaitlistVerificationStatus(waitlistId, level);

    // Email (best-effort)
    try {
      const email = await getWaitlistEmailById(waitlistId);
      if (email) {
        await sendProfileApprovedEmail({ to: email, level });
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

    await documents.review.rejectAllForWaitlist(waitlistId, notes || "reupload requested");

    // Rotate token so previous links become invalid
    const rotated = await requestReuploadAndRotateToken(waitlistId);

    // Send email with reason (best-effort)
    try {

      await sendReuploadRequestedEmail({
        to: rotated.email,
        verificationToken: rotated.verificationToken,
        reason: notes,
        rejectedTypes: ["selfie_id", "id_card_front", "id_card_back"],
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
      ? body.approveDocumentIds
          .map((n: unknown) => Number.parseInt(String(n), 10))
          .filter((n: number) => Number.isFinite(n))
      : [];

    const rejectDocumentIds = Array.isArray(body?.rejectDocumentIds)
      ? body.rejectDocumentIds
          .map((n: unknown) => Number.parseInt(String(n), 10))
          .filter((n: number) => Number.isFinite(n))
      : [];

    const approveProfile = Boolean(body?.approveProfile);
    const reason = (body?.reason || body?.notes || "").toString().trim();

    if (rejectDocumentIds.length > 0 && !reason) {
      return c.json({ success: false, error: "Motif requis" }, 400);
    }

    // Apply doc reviews
    await documents.review.reviewBulk({ waitlistId, documentIds: approveDocumentIds, status: "approved" });
    await documents.review.reviewBulk({ waitlistId, documentIds: rejectDocumentIds, status: "rejected", notes: reason });

    // If any rejected => reset to pending + rotate token + email
    if (rejectDocumentIds.length > 0) {
      const rejectedTypes = await documents.repo.typesByIds(waitlistId, rejectDocumentIds);
      const rotated = await requestReuploadAndRotateToken(waitlistId);

      try {

        await sendReuploadRequestedEmail({
          to: rotated.email,
          verificationToken: rotated.verificationToken,
          reason,
          rejectedTypes,
        });
      } catch (err) {
        console.error("Reupload email failed:", err);
      }

      return c.json({ success: true, status: "pending" });
    }

    // Optional: validate profile
    if (approveProfile) {
      const latest = await documents.repo.latestByType(waitlistId);
      const missing = findMissingRequired(latest);
      if (missing.length > 0) {
        return c.json({ success: false, error: `Docs manquants: ${missing.join(", ")}` }, 400);
      }

      await documents.review.approveAllForWaitlist(waitlistId);

      const hasCommunity = latest["community_doc"]?.status === "approved";
      const level = hasCommunity ? "verified_plus" : "verified";
      await setWaitlistVerificationStatus(waitlistId, level);

      try {
        const email = await getWaitlistEmailById(waitlistId);
        if (email) {
          await sendProfileApprovedEmail({ to: email, level });
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
    const notes = typeof body?.notes === "string" ? body.notes : null;
    await documents.review.rejectDocument(documentId, notes);
    return c.json({ success: true });
  });

  app.get("/api/admin/documents/:id/file", async (c) => {
    const auth = assertAdminFileDownload(c);
    if (!auth.ok) return c.json({ success: false, error: auth.error }, 401);

    const documentId = Number.parseInt(c.req.param("id"), 10);
    if (!Number.isInteger(documentId)) return c.json({ success: false, error: "Not found" }, 404);

    try {
      const result = await documents.readDocument(documentId);
      switch (result.kind) {
        case "not_found":
          return c.json({ success: false, error: "Not found" }, 404);
        case "purged":
          return c.json({ success: false, error: "Document purgé" }, 410);
        case "file_missing":
          return c.json({ success: false, error: "Missing file" }, 404);
        case "ok":
          return new Response(result.bytes, {
            headers: {
              "content-type": result.mimeType || "application/octet-stream",
              "cache-control": "no-store",
              "x-content-type-options": "nosniff",
            },
          });
      }
    } catch (error) {
      console.error(`document ${documentId} unreadable:`, error instanceof Error ? error.name : "unknown error");
      return c.json({ success: false, error: "Document illisible" }, 500);
    }
  });
}
