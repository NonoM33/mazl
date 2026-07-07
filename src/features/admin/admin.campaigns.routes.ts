import { Hono } from "hono";
import type { AppVariables } from "../../shared/http/middleware";
import {
  getCampaigns,
  getCampaignById,
  createCampaign,
  updateCampaign as updateCampaignDb,
  deleteCampaign,
  sendCampaign,
  getSegments,
  createSegment,
} from "../../db";
import { sendCampaignEmail } from "../../email";
import { sendPushToUsers } from "../../onesignal";
import { assertAdmin } from "./admin.auth";

// Admin campaigns + segments routes ("MODULE 3: CAMPAGNES EMAIL/PUSH"), moved
// verbatim from the monolith (src/index.ts). Same paths, behaviour, payloads and
// status codes. The public tracking pixel (`/api/track/open`) and public
// unsubscribe page (`/api/unsubscribe`) that originally followed these routes are
// NOT admin and remain in src/index.ts.
export function registerAdminCampaignsRoutes(app: Hono<{ Variables: AppVariables }>): void {
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
    } catch (error: unknown) {
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
    } catch (error: unknown) {
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
        createdBy: auth.email || "admin",
      });

      return c.json({ success: true, campaign });
    } catch (error: unknown) {
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
    } catch (error: unknown) {
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
    } catch (error: unknown) {
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

      const camp = campaign as {
        type?: string;
        title: string;
        subject?: string;
        content: string;
      };

      // Mark campaign as sending and get recipients
      const result = await sendCampaign(campaignId);
      const recipients = result.recipients as Array<{ id: number; email: string }>;

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
    } catch (error: unknown) {
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
    } catch (error: unknown) {
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
        createdBy: auth.email || "admin",
      });

      return c.json({ success: true, segment });
    } catch (error: unknown) {
      console.error("Create segment error:", error);
      return c.json({ success: false, error: "Failed to create segment" }, 500);
    }
  });
}
