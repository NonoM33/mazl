import { Hono } from "hono";
import { join } from "node:path";
import type { AppVariables } from "../../shared/http/middleware";
import {
  listPendingSubmissions,
  listVerifiedProfiles,
  setDocumentReview,
  getLatestDocumentsByType,
  approveAllDocumentsForWaitlist,
  setWaitlistVerificationStatus,
  getWaitlistEmailById,
  rejectAllDocumentsForWaitlist,
  requestReuploadAndRotateToken,
  setDocumentsReviewBulk,
  getDocumentTypesByIds,
  getDocumentById,
} from "../../db";
import { sendProfileApprovedEmail, sendReuploadRequestedEmail } from "../../email";
import { verifyGoogleIdToken } from "../../auth";
import {
  assertAdmin,
  assertAdminFileDownload,
  generateAdminJWT,
  ADMIN_EMAILS,
} from "./admin.auth";

// Admin authentication + verification/document moderation routes, moved verbatim
// from the monolith (src/index.ts). Same paths, behaviour, payloads and status
// codes. Declaration order is preserved: login, google-login, verify, pending,
// verified, document/profile review actions, then the file-download endpoint.
export function registerAdminVerificationRoutes(
  app: Hono<{ Variables: AppVariables }>,
  uploadsDir: string,
): void {
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

    const path = join(uploadsDir, doc.filename);
    const file = Bun.file(path);
    if (!(await file.exists())) return c.json({ success: false, error: "Missing file" }, 404);

    return new Response(file, {
      headers: {
        "content-type": doc.mime_type || "application/octet-stream",
        "cache-control": "no-store",
      },
    });
  });
}
