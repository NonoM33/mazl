import type { Context } from "hono";
import { ChatError } from "../domain/errors";

// One mapping from typed errors to HTTP answers. A non-member and a missing
// resource get the very same 404 (CONTRAT.md §0.1).
export function respondToFailure(c: Context, error: unknown): Response {
  if (error instanceof ChatError) {
    switch (error.kind) {
      case "not_found":
        return c.json({ success: false, error: "Not found" }, 404);
      case "blocked":
        return c.json({ success: false, error: "blocked" }, 403);
      case "not_author":
        return c.json({ success: false, error: "not_author" }, 403);
      case "too_late":
        return c.json({ success: false, error: "too_late" }, 409);
      case "too_large":
        return c.json({ success: false, error: "File too large", detail: error.detail }, 413);
      case "too_many_pending":
        return c.json({ success: false, error: "too_many_pending" }, 429);
      case "invalid":
        return c.json({ success: false, error: error.detail }, 400);
    }
  }
  console.error("Chat error:", error instanceof Error ? error.name : "unknown");
  return c.json({ success: false, error: "Chat request failed" }, 500);
}

export const notFoundResponse = (c: Context): Response => c.json({ success: false, error: "Not found" }, 404);
