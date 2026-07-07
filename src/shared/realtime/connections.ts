import { sql } from "../../db";

// ============ REAL-TIME WEBSOCKET CONNECTIONS ============
// Shared registry of active WebSocket connections keyed by user id, plus the
// helpers used to push real-time events (chat, match:new, ...) to connected
// users. Extracted from src/index.ts so features (matching, chat, couples, ...)
// can emit real-time events without importing the server entrypoint — which
// previously created a circular dependency.

// A JSON-serialisable outbound message. Every payload sent to a client is an
// object with a `type` discriminator; the concrete shape is validated by the
// mobile client. `unknown` values keep this strict (no `any`) while allowing
// the various event payloads.
export type OutboundMessage = {
  type: string;
  payload?: unknown;
};

// Store active WebSocket connections by user ID.
const wsConnections = new Map<number, Set<WebSocket>>();

// Register a freshly-opened connection for a user.
export function addConnection(userId: number, ws: WebSocket): void {
  let connections = wsConnections.get(userId);
  if (!connections) {
    connections = new Set<WebSocket>();
    wsConnections.set(userId, connections);
  }
  connections.add(ws);
}

// Remove a closed connection for a user, cleaning up the entry when empty.
export function removeConnection(userId: number, ws: WebSocket): void {
  const connections = wsConnections.get(userId);
  if (!connections) return;
  connections.delete(ws);
  if (connections.size === 0) {
    wsConnections.delete(userId);
  }
}

// Helper to send to all connections of a user.
export function sendToUser(userId: number, data: OutboundMessage): void {
  const connections = wsConnections.get(userId);
  if (connections) {
    const message = JSON.stringify(data);
    for (const ws of connections) {
      try {
        ws.send(message);
      } catch (err) {
        console.error(`WebSocket send error for user ${userId}:`, err);
      }
    }
  }
}

export interface MatchNewPayload {
  matchId: number;
  conversationId: number;
  userId: number;
  userName: string;
  userPicture: string | null;
}

// Emit a `match:new` event to both freshly-matched users (if connected).
// Each user receives the *other* person's identity, matching the shape the
// mobile client expects (see websocket_service.dart:193-203).
export async function emitNewMatch(userAId: number, userBId: number): Promise<void> {
  const rows = await sql`
    SELECT
      m.id as match_id,
      c.id as conversation_id,
      pa.display_name as user_a_name,
      ua.picture as user_a_picture,
      pb.display_name as user_b_name,
      ub.picture as user_b_picture
    FROM matches m
    LEFT JOIN conversations c ON c.match_id = m.id
    JOIN users ua ON ua.id = ${userAId}
    JOIN users ub ON ub.id = ${userBId}
    LEFT JOIN profiles pa ON pa.user_id = ${userAId}
    LEFT JOIN profiles pb ON pb.user_id = ${userBId}
    WHERE (m.user1_id = ${userAId} AND m.user2_id = ${userBId})
       OR (m.user1_id = ${userBId} AND m.user2_id = ${userAId})
    LIMIT 1
  `;

  const row = rows[0] as
    | {
        match_id: number;
        conversation_id: number | null;
        user_a_name: string | null;
        user_a_picture: string | null;
        user_b_name: string | null;
        user_b_picture: string | null;
      }
    | undefined;
  if (!row || row.conversation_id === null) return;

  const matchId = row.match_id;
  const conversationId = row.conversation_id;

  const toUserA: MatchNewPayload = {
    matchId,
    conversationId,
    userId: userBId,
    userName: row.user_b_name ?? "",
    userPicture: row.user_b_picture,
  };
  const toUserB: MatchNewPayload = {
    matchId,
    conversationId,
    userId: userAId,
    userName: row.user_a_name ?? "",
    userPicture: row.user_a_picture,
  };

  sendToUser(userAId, { type: "match:new", payload: toUserA });
  sendToUser(userBId, { type: "match:new", payload: toUserB });
}
