import { Hono } from "hono";
import type { AppVariables } from "../../shared/http/middleware";
import {
  getReports,
  getReportStats,
  handleReport,
  getPendingPhotos,
  approvePhoto,
  rejectPhoto,
  getModerationLogs,
} from "../../db";
import { assertAdmin } from "./admin.auth";

// Admin moderation routes ("MODULE 4: MODÉRATION & SIGNALEMENTS", admin subset),
// moved verbatim from the monolith (src/index.ts). Same paths, behaviour,
// payloads and status codes. The public block/report endpoints (`/api/users/:id/
// block`, `/api/users/blocked`, `/api/users/:id/report`, `/api/report`) that
// interleave with this block are NOT admin and remain in src/index.ts.
export function registerAdminModerationRoutes(app: Hono<{ Variables: AppVariables }>): void {
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
    } catch (error: unknown) {
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
    } catch (error: unknown) {
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
        handledBy: auth.email || "admin",
        actionTaken: body.actionTaken,
        status: body.status,
      });

      return c.json({ success: true, report });
    } catch (error: unknown) {
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
    } catch (error: unknown) {
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
      await approvePhoto(photoId, auth.email || "admin");
      return c.json({ success: true });
    } catch (error: unknown) {
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

      await rejectPhoto(photoId, auth.email || "admin", reason);
      return c.json({ success: true });
    } catch (error: unknown) {
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
    } catch (error: unknown) {
      console.error("Get moderation logs error:", error);
      return c.json({ success: false, error: "Failed to get logs" }, 500);
    }
  });
}
