// A reciprocal like, as the `match:new` socket frame carries it (the other
// member's identity) or as built from our own swipe.

export interface MatchEvent {
  readonly userId: number;
  readonly name: string;
  readonly picture: string | null;
  readonly conversationId: number | null;
}

export function parseMatchEvent(payload: unknown): MatchEvent | null {
  if (typeof payload !== "object" || payload === null) return null;
  const { userId, userName, userPicture, conversationId } = payload as Record<string, unknown>;
  if (typeof userId !== "number") return null;
  return {
    userId,
    name: typeof userName === "string" ? userName : "",
    picture: typeof userPicture === "string" ? userPicture : null,
    conversationId: typeof conversationId === "number" ? conversationId : null,
  };
}
