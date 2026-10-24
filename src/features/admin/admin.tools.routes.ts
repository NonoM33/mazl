import { Hono } from "hono";
import type { AppVariables } from "../../shared/http/middleware";
import { sql, seedFakeProfiles, resetUserSwipes, resetAllSwipes } from "../../db";
import { sendToUser } from "../../shared/realtime/connections";
import { assertAdmin } from "./admin.auth";

// Admin developer/testing tools, moved verbatim from the monolith (src/index.ts).
// Two original blocks are preserved in order: test-match / seed-profiles /
// reset-swipes, then (after the couple feature) the test-message route.
// Same paths, behaviour, payloads and status codes.

export function registerAdminTestingRoutes(app: Hono<{ Variables: AppVariables }>): void {
  // Create test match (admin)
  app.post("/api/admin/test-match", async (c) => {
    const auth = assertAdmin(c);
    if (!auth.ok) return c.json({ success: false, error: auth.error }, 401);

    try {
      const body = await c.req.json();
      const { userEmail, seedProfileIndex = 0 } = body;

      // Find user by email
      const userResult = (await sql`SELECT id FROM users WHERE email = ${userEmail}`) as Array<{ id: number }>;
      if (userResult.length === 0) {
        return c.json({ success: false, error: "User not found" }, 404);
      }
      const userId = userResult[0]!.id;

      // Find a seed profile to match with
      const seedResult = (await sql`
        SELECT id FROM users WHERE provider = 'seed'
        ORDER BY id
        LIMIT 1 OFFSET ${seedProfileIndex}
      `) as Array<{ id: number }>;
      if (seedResult.length === 0) {
        return c.json({ success: false, error: "No seed profiles available" }, 404);
      }
      const seedUserId = seedResult[0]!.id;

      // Check if match already exists
      const existingMatch = (await sql`
        SELECT id FROM matches
        WHERE (user1_id = ${userId} AND user2_id = ${seedUserId})
           OR (user1_id = ${seedUserId} AND user2_id = ${userId})
      `) as Array<{ id: number }>;
      if (existingMatch.length > 0) {
        return c.json({ success: true, message: "Match already exists", matchId: existingMatch[0]!.id });
      }

      // Create the match
      const matchResult = (await sql`
        INSERT INTO matches (user1_id, user2_id)
        VALUES (${userId}, ${seedUserId})
        RETURNING id
      `) as Array<{ id: number }>;
      const matchId = matchResult[0]!.id;

      // Also create a conversation for this match
      const convResult = (await sql`
        INSERT INTO conversations (match_id, user1_id, user2_id)
        VALUES (${matchId}, ${userId}, ${seedUserId})
        RETURNING id
      `) as Array<{ id: number }>;

      return c.json({
        success: true,
        matchId,
        conversationId: convResult.length > 0 ? convResult[0]!.id : null,
        message: "Test match created"
      });
    } catch (error: unknown) {
      console.error("Create test match error:", error);
      return c.json({ success: false, error: "Failed to create test match" }, 500);
    }
  });

  // Seed fake profiles (admin)
  app.post("/api/admin/seed-profiles", async (c) => {
    const auth = assertAdmin(c);
    if (!auth.ok) return c.json({ success: false, error: auth.error }, 401);

    try {
      await seedFakeProfiles(true);
      return c.json({ success: true, message: "Seed profiles created" });
    } catch (error: unknown) {
      console.error("Seed profiles error:", error);
      return c.json({ success: false, error: "Failed to seed profiles" }, 500);
    }
  });

  // Reset swipes for a user (admin)
  app.post("/api/admin/reset-swipes", async (c) => {
    const auth = assertAdmin(c);
    if (!auth.ok) return c.json({ success: false, error: auth.error }, 401);

    try {
      const body = await c.req.json();
      const { userId, all } = body;

      if (all === true) {
        const result = await resetAllSwipes();
        return c.json({ success: true, message: `All swipes reset`, ...result });
      }

      if (!userId) {
        return c.json({ success: false, error: "userId required" }, 400);
      }

      const result = await resetUserSwipes(userId);
      return c.json({ success: true, message: `Swipes reset for user ${userId}`, ...result });
    } catch (error: unknown) {
      console.error("Reset swipes error:", error);
      return c.json({ success: false, error: "Failed to reset swipes" }, 500);
    }
  });
}

export function registerAdminTestMessageRoute(app: Hono<{ Variables: AppVariables }>): void {
  // Send test message from seed profile (admin)
  app.post("/api/admin/test-message", async (c) => {
    const auth = assertAdmin(c);
    if (!auth.ok) return c.json({ success: false, error: auth.error }, 401);

    try {
      const body = await c.req.json();
      const { conversationId, message } = body;

      if (!conversationId || !message) {
        return c.json({ success: false, error: "conversationId and message required" }, 400);
      }

      // Get the conversation to find the seed user
      const convResult = (await sql`
        SELECT user1_id, user2_id FROM conversations WHERE id = ${conversationId}
      `) as Array<{ user1_id: number; user2_id: number }>;
      if (convResult.length === 0) {
        return c.json({ success: false, error: "Conversation not found" }, 404);
      }

      const conv = convResult[0]!;

      // Find which user is the seed profile
      const seedUserResult = (await sql`
        SELECT id FROM users
        WHERE (id = ${conv.user1_id} OR id = ${conv.user2_id})
          AND provider = 'seed'
        LIMIT 1
      `) as Array<{ id: number }>;

      if (seedUserResult.length === 0) {
        return c.json({ success: false, error: "No seed user in this conversation" }, 400);
      }

      const seedUserId = seedUserResult[0]!.id;
      const otherUserId = conv.user1_id === seedUserId ? conv.user2_id : conv.user1_id;

      // Create message from seed user
      const msgResult = (await sql`
        INSERT INTO messages (conversation_id, sender_id, content)
        VALUES (${conversationId}, ${seedUserId}, ${message})
        RETURNING *
      `) as Array<{ id: number; created_at: string }>;
      const msg = msgResult[0]!;

      // Update last_message_at
      await sql`
        UPDATE conversations SET last_message_at = NOW() WHERE id = ${conversationId}
      `;

      // Broadcast via WebSocket to the other user
      const messageData = {
        type: "chat:message",
        payload: {
          conversationId,
          messageId: msg.id,
          senderId: seedUserId,
          content: message,
          createdAt: msg.created_at,
        },
      };
      sendToUser(otherUserId, messageData);

      return c.json({ success: true, message: msg });
    } catch (error: unknown) {
      console.error("Send test message error:", error);
      return c.json({ success: false, error: "Failed to send test message" }, 500);
    }
  });
}
