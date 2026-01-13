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
  upsertWaitlistAndGetVerification,
  getLatestDocumentsByType,
  setWaitlistVerificationStatus,
  rejectAllDocumentsForWaitlist,
  approveAllDocumentsForWaitlist,
  requestReuploadAndRotateToken,
} from "./db";
import { sendReuploadRequestedEmail, sendVerificationRequestEmail } from "./email";

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
  const password = c.req.query("password") || "";
  return c.redirect(`/admin.html?password=${encodeURIComponent(password)}`);
});

// Static files
app.use("/*", serveStatic({ root: "./public" }));

function getAdminPassword(c: any) {
  return c.req.query("password") || c.req.header("x-admin-password") || "";
}

function assertAdmin(c: any) {
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

// Admin
app.get("/api/admin/pending", async (c) => {
  const auth = assertAdmin(c);
  if (!auth.ok) return c.json({ success: false, error: auth.error }, 401);

  const items = await listPendingSubmissions();
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

  const hasCommunity = Boolean(latest["community_doc"] && latest["community_doc"].status !== "rejected");
  await setWaitlistVerificationStatus(waitlistId, hasCommunity ? "verified_plus" : "verified");

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
      baseUrl: requestOrigin,
    });
  } catch (err) {
    console.error("Reupload email failed:", err);
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

// Health check
app.get("/api/health", (c) => c.json({ status: "ok" }));

// Initialize and start
const port = Number.parseInt(process.env.PORT || "3000", 10);

await mkdir(UPLOADS_DIR, { recursive: true });

await initDb();

console.log(`Server running on http://localhost:${port}`);

export default {
  port,
  fetch: app.fetch,
};
