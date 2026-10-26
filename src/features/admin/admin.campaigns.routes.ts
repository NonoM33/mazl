import { Hono } from "hono";
import type { Context } from "hono";
import { z } from "zod";
import type { AppVariables } from "../../shared/http/middleware";
import {
  getCampaigns,
  getCampaignById,
  createCampaign,
  updateCampaign as updateCampaignDb,
  deleteCampaign,
  getCampaignRecipients,
  claimCampaignForSending,
  addCampaignRecipients,
  markCampaignRecipientsSent,
  finishCampaignSending,
  getSegments,
  createSegment,
  type CampaignRecord,
} from "../../db";
import { sendCampaignEmail } from "../../email";
import type { PushTransport } from "../push/application/ports";
import { memberPushTransport } from "../push/member-push";
import { assertAdmin } from "./admin.auth";
import { parsePagination, parseRecordId } from "./admin.pagination";

// Admin campaigns + segments routes ("MODULE 3: CAMPAGNES EMAIL/PUSH"). The public
// tracking pixel (`/api/track/open`) and public unsubscribe page (`/api/unsubscribe`)
// are NOT admin and remain in src/index.ts.

const CAMPAIGN_TYPES = ["email", "push"] as const;
const CAMPAIGN_STATUSES = ["draft", "scheduled", "sending", "sent", "failed"] as const;
// The only statuses an admin may set by hand: sending/sent/failed belong to the send routine.
const SETTABLE_STATUSES = ["draft", "scheduled"] as const;

const dateString = z.string().refine((v) => !Number.isNaN(Date.parse(v)), "Invalid date");

const createCampaignSchema = z.object({
  type: z.enum(CAMPAIGN_TYPES),
  title: z.string().min(1).max(255),
  subject: z.string().max(255).nullish(),
  content: z.string().min(1),
  segmentId: z.number().int().positive().nullish(),
  scheduledAt: dateString.nullish(),
});

const updateCampaignSchema = z.object({
  title: z.string().min(1).max(255).optional(),
  subject: z.string().max(255).nullish(),
  content: z.string().min(1).optional(),
  segmentId: z.number().int().positive().nullish(),
  scheduledAt: dateString.nullish(),
  status: z.enum(SETTABLE_STATUSES).optional(),
});

const createSegmentSchema = z.object({
  name: z.string().min(1).max(100),
  description: z.string().max(2000).nullish(),
  filters: z.record(z.string(), z.unknown()),
});

const listFilterSchema = z.object({
  status: z.enum(CAMPAIGN_STATUSES).optional(),
  type: z.enum(CAMPAIGN_TYPES).optional(),
});

type AdminContext = Context<{ Variables: AppVariables }>;

async function readJson(c: AdminContext): Promise<unknown> {
  try {
    return await c.req.json();
  } catch {
    return null;
  }
}

interface SendOutcome {
  sent: number;
  errors: number;
  total: number;
}

async function deliverEmails(campaign: CampaignRecord, recipients: Array<{ id: number; email: string }>): Promise<SendOutcome> {
  let sent = 0;
  let errors = 0;
  for (const recipient of recipients) {
    try {
      const result = await sendCampaignEmail({
        to: recipient.email,
        subject: campaign.subject || campaign.title,
        content: campaign.content,
        campaignId: campaign.id,
        userId: recipient.id,
      });
      // sendCampaignEmail reports a provider failure by returning { success: false }, not by throwing.
      if (result.success) {
        sent++;
        await markCampaignRecipientsSent(campaign.id, [recipient.id]);
      } else {
        errors++;
        console.error(`Campaign ${campaign.id}: e-mail to member ${recipient.id} failed:`, result.error);
      }
    } catch (err) {
      errors++;
      console.error(`Campaign ${campaign.id}: e-mail to member ${recipient.id} failed:`, err);
    }
  }
  return { sent, errors, total: recipients.length };
}

const PUSH_CONCURRENCY = 10;

// One push per recipient (gorush addresses devices, not members); only the
// members reached are marked sent.
export async function deliverPushCampaign(
  transport: PushTransport,
  campaign: Pick<CampaignRecord, "id" | "title" | "content">,
  recipients: ReadonlyArray<{ id: number }>,
  markSent: (campaignId: number, userIds: number[]) => Promise<void>,
): Promise<SendOutcome> {
  const total = recipients.length;
  if (total === 0) return { sent: 0, errors: 0, total: 0 };
  if (!transport.isEnabled()) {
    console.error(`Campaign ${campaign.id}: push not configured`);
    return { sent: 0, errors: total, total };
  }
  let sent = 0;
  for (let start = 0; start < total; start += PUSH_CONCURRENCY) {
    const batch = recipients.slice(start, start + PUSH_CONCURRENCY);
    const results = await Promise.all(
      batch.map((recipient) =>
        transport
          .send({ recipientId: recipient.id, title: campaign.title, message: campaign.content, data: { type: "announcement", campaign_id: campaign.id } })
          .catch(() => ({ ok: false as const, reason: "failed" })),
      ),
    );
    const reached = batch.filter((_, index) => results[index]?.ok === true).map((recipient) => recipient.id);
    if (reached.length > 0) await markSent(campaign.id, reached);
    sent += reached.length;
  }
  if (sent < total) console.error(`Campaign ${campaign.id}: ${total - sent} push(es) not delivered`);
  return { sent, errors: total - sent, total };
}

const deliverPush = (campaign: CampaignRecord, recipients: Array<{ id: number }>): Promise<SendOutcome> =>
  deliverPushCampaign(memberPushTransport, campaign, recipients, markCampaignRecipientsSent);

export function registerAdminCampaignsRoutes(app: Hono<{ Variables: AppVariables }>): void {
  // Get campaigns (admin)
  app.get("/api/admin/campaigns", async (c) => {
    const auth = assertAdmin(c);
    if (!auth.ok) return c.json({ success: false, error: auth.error }, 401);

    const filters = listFilterSchema.safeParse({
      status: c.req.query("status") || undefined,
      type: c.req.query("type") || undefined,
    });
    if (!filters.success) return c.json({ success: false, error: "Invalid filter" }, 400);

    try {
      const { limit, offset } = parsePagination(c.req.query("limit"), c.req.query("offset"));
      const campaigns = await getCampaigns({ ...filters.data, limit, offset });
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
      const campaignId = parseRecordId(c.req.param("id"));
      const campaign = campaignId === null ? null : await getCampaignById(campaignId);

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

    const body = createCampaignSchema.safeParse(await readJson(c));
    if (!body.success) {
      return c.json({ success: false, error: "Valid type (email or push), title and content required" }, 400);
    }

    try {
      const campaign = await createCampaign({
        type: body.data.type,
        title: body.data.title,
        subject: body.data.subject ?? undefined,
        content: body.data.content,
        segmentId: body.data.segmentId ?? undefined,
        scheduledAt: body.data.scheduledAt ? new Date(body.data.scheduledAt) : undefined,
        createdBy: auth.email || "admin",
      });

      return c.json({ success: true, campaign });
    } catch (error: unknown) {
      console.error("Create campaign error:", error);
      return c.json({ success: false, error: "Failed to create campaign" }, 500);
    }
  });

  // Update campaign (admin). Only a draft or scheduled campaign can change.
  app.put("/api/admin/campaigns/:id", async (c) => {
    const auth = assertAdmin(c);
    if (!auth.ok) return c.json({ success: false, error: auth.error }, 401);

    const campaignId = parseRecordId(c.req.param("id"));
    if (campaignId === null) return c.json({ success: false, error: "Campaign not found" }, 404);

    const body = updateCampaignSchema.safeParse(await readJson(c));
    if (!body.success) return c.json({ success: false, error: "Invalid campaign update" }, 400);

    try {
      const campaign = await updateCampaignDb(campaignId, {
        title: body.data.title,
        subject: body.data.subject ?? undefined,
        content: body.data.content,
        segmentId: body.data.segmentId ?? undefined,
        scheduledAt: body.data.scheduledAt ? new Date(body.data.scheduledAt) : undefined,
        status: body.data.status,
      });

      if (!campaign) {
        const existing = await getCampaignById(campaignId);
        if (!existing) return c.json({ success: false, error: "Campaign not found" }, 404);
        return c.json({ success: false, error: "Campaign already sent or being sent: it can no longer be edited" }, 409);
      }

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
      const campaignId = parseRecordId(c.req.param("id"));
      if (campaignId === null) return c.json({ success: false, error: "Campaign not found" }, 404);
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

    const campaignId = parseRecordId(c.req.param("id"));
    if (campaignId === null) return c.json({ success: false, error: "Campaign not found" }, 404);

    try {
      const existing = await getCampaignById(campaignId);
      if (!existing) {
        return c.json({ success: false, error: "Campaign not found" }, 404);
      }

      if ((existing as CampaignRecord).segment_id !== null) {
        return c.json(
          {
            success: false,
            error: "Segment targeting is not available yet: detach the segment to send to every member",
          },
          409,
        );
      }

      // Atomic draft/scheduled -> sending: of N simultaneous sends, exactly one wins.
      const campaign = await claimCampaignForSending(campaignId);
      if (!campaign) {
        return c.json({ success: false, error: "Campaign already sent or being sent" }, 409);
      }

      let outcome: SendOutcome = { sent: 0, errors: 0, total: 0 };
      try {
        const recipients = await getCampaignRecipients(campaign.segment_id);
        await addCampaignRecipients(campaignId, recipients);
        outcome =
          campaign.type === "email" ? await deliverEmails(campaign, recipients) : await deliverPush(campaign, recipients);
      } catch (error: unknown) {
        // Never leave the campaign locked in 'sending'.
        await finishCampaignSending(campaignId, { sent: outcome.sent, total: outcome.total });
        throw error;
      }

      await finishCampaignSending(campaignId, { sent: outcome.sent, total: outcome.total });
      return c.json({ success: true, sent: outcome.sent, errors: outcome.errors, total: outcome.total });
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

    const body = createSegmentSchema.safeParse(await readJson(c));
    if (!body.success) return c.json({ success: false, error: "Name and filters required" }, 400);

    try {
      const segment = await createSegment({
        name: body.data.name,
        description: body.data.description ?? undefined,
        filters: body.data.filters,
        createdBy: auth.email || "admin",
      });

      return c.json({ success: true, segment });
    } catch (error: unknown) {
      console.error("Create segment error:", error);
      return c.json({ success: false, error: "Failed to create segment" }, 500);
    }
  });
}
