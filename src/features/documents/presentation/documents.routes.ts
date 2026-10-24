import type { Hono } from "hono";
import { bodyLimit } from "hono/body-limit";
import { z } from "zod";
import type { AppVariables } from "../../../shared/http/middleware";
import type { DocumentsModule } from "../composition";
import { DocumentUploadError, MAX_DOCUMENT_BYTES, MAX_UPLOAD_BODY_BYTES, type DocumentErrorCode } from "../domain/types";

const tokenSchema = z.string().min(1).max(256);
const submitBodySchema = z.object({ os: z.enum(["ios", "android"]).optional() });

// Messages the /verify page shows to the member (shape unchanged).
const UPLOAD_ERRORS: Record<DocumentErrorCode, string> = {
  invalid_type: "Type invalide",
  empty_file: "Fichier vide",
  file_too_large: "Fichier trop gros (max 10MB)",
  unsupported_format: "Format non supporté (JPG/PNG/PDF)",
  too_many_files: "Trop de fichiers envoyés",
};

const ALREADY_VERIFIED = "Profil déjà vérifié";

// Member-facing verification routes, addressed by the emailed token:
// GET /api/verify, POST /api/verify/upload, POST /api/verify/submit.
export function registerDocumentsRoutes(
  app: Hono<{ Variables: AppVariables }>,
  documents: DocumentsModule,
): void {
  app.get("/api/verify", async (c) => {
    const token = tokenSchema.safeParse(c.req.query("token") || "");
    if (!token.success) return c.json({ success: false, error: "Token manquant" }, 400);

    const result = await documents.verificationFlow.status(token.data);
    if (result.kind === "invalid_token") return c.json({ success: false, error: "Token invalide" }, 404);

    return c.json({
      success: true,
      email: result.email,
      verificationStatus: result.verificationStatus,
      requiredReady: result.requiredReady,
      missing: result.missing,
    });
  });

  // The body limit looks at Content-Length first: an oversized request is
  // refused before a byte of it is parsed.
  const uploadBodyLimit = bodyLimit({
    maxSize: MAX_UPLOAD_BODY_BYTES,
    onError: (c) => c.json({ success: false, error: "Requête trop volumineuse" }, 413),
  });

  app.post("/api/verify/upload", uploadBodyLimit, async (c) => {
    const token = tokenSchema.safeParse(c.req.query("token") || "");
    if (!token.success) return c.json({ success: false, error: "Token manquant" }, 400);

    const target = await documents.verificationFlow.uploadTarget(token.data);
    if (target.kind === "invalid_token") return c.json({ success: false, error: "Token invalide" }, 404);
    if (target.kind === "already_verified") return c.json({ success: false, error: ALREADY_VERIFIED }, 409);
    const waitlistId = target.waitlistId;

    const form = await c.req.formData().catch(() => null);
    const type = form?.get("type");
    const file = form?.get("file");
    if (typeof type !== "string" || type === "") return c.json({ success: false, error: "Type manquant" }, 400);
    if (!(file instanceof File)) return c.json({ success: false, error: "Fichier manquant" }, 400);
    // Cheap check before the bytes are read; the use case checks again.
    if (file.size > MAX_DOCUMENT_BYTES) {
      return c.json({ success: false, error: UPLOAD_ERRORS.file_too_large }, 400);
    }

    try {
      const bytes = new Uint8Array(await file.arrayBuffer());
      const { documentId, filename } = await documents.uploadDocument({ waitlistId, type, bytes });
      return c.json({ success: true, documentId, filename });
    } catch (error) {
      if (error instanceof DocumentUploadError) {
        return c.json({ success: false, error: UPLOAD_ERRORS[error.code] }, error.code === "too_many_files" ? 409 : 400);
      }
      console.error("document upload failed:", error instanceof Error ? error.name : "unknown error");
      return c.json({ success: false, error: "Erreur serveur" }, 500);
    }
  });

  app.post("/api/verify/submit", async (c) => {
    const token = tokenSchema.safeParse(c.req.query("token") || "");
    if (!token.success) return c.json({ success: false, error: "Token manquant" }, 400);

    const body = submitBodySchema.safeParse(await c.req.json().catch(() => ({})));
    const os = body.success ? body.data.os : undefined;

    const result = await documents.verificationFlow.submit(token.data, os);
    if (result.kind === "invalid_token") return c.json({ success: false, error: "Token invalide" }, 404);
    if (result.kind === "already_verified") return c.json({ success: false, error: ALREADY_VERIFIED }, 409);
    if (result.kind === "missing_documents") {
      return c.json(
        {
          success: false,
          error: `Documents manquants: ${result.missing.join(", ")}`,
          missing: result.missing,
        },
        400,
      );
    }
    return c.json({ success: true });
  });
}
