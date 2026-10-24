import { describe, expect, test } from "bun:test";
import { BASE_URL, auth, db, makeUser } from "./media-helpers";

// Against a running server: who liked me is a mazl+ benefit, and the response
// of a free member does not give it away (docs/web/adr/W11).

async function completeProfile(token: string, gender: "male" | "female"): Promise<void> {
  const res = await fetch(`${BASE_URL}/api/profile`, {
    method: "PUT",
    headers: { ...auth(token), "Content-Type": "application/json" },
    body: JSON.stringify({ displayName: "Jonas", birthdate: "1990-01-01", gender, lookingFor: gender === "male" ? "female" : "male" }),
  });
  expect(res.status).toBe(200);
}

async function receivedLikes(token: string): Promise<Record<string, unknown>[]> {
  const res = await fetch(`${BASE_URL}/api/likes/received`, { headers: auth(token) });
  expect(res.status).toBe(200);
  return ((await res.json()) as { likes: Record<string, unknown>[] }).likes;
}

describe("received likes and mazl+", () => {
  test("a free member sees a first name, never the photo, the id or the age; with mazl+ everything", async () => {
    const liked = await makeUser("liked");
    const liker = await makeUser("liker");
    await completeProfile(liked.token, "female");
    await completeProfile(liker.token, "male");
    const swipe = await fetch(`${BASE_URL}/api/swipes`, {
      method: "POST",
      headers: { ...auth(liker.token), "Content-Type": "application/json" },
      body: JSON.stringify({ target_user_id: liked.id, action: "like" }),
    });
    expect(swipe.status).toBe(200);

    const [teaser] = await receivedLikes(liked.token);
    expect(teaser).toBeDefined();
    expect(Object.keys(teaser ?? {}).sort()).toEqual(["display_name", "is_verified", "liked_at"]);

    await db`
      INSERT INTO subscriptions (user_id, plan_type, status, store, product_id, original_transaction_id, started_at, expires_at)
      VALUES (${liked.id}, 'monthly', 'active', 'apple', 'com.mazl.app.plus.1m', ${`visibility-${liked.id}`}, NOW() AT TIME ZONE 'UTC', (NOW() AT TIME ZONE 'UTC') + INTERVAL '30 days')`;
    const [full] = await receivedLikes(liked.token);
    expect(full?.user_id).toBe(liker.id);
  });
});
