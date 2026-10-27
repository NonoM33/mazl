import { describe, expect, test } from "bun:test";
import { BASE_URL, auth, db, grantPlus, makeUser } from "./media-helpers";

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

interface ReceivedLikes {
  success: boolean;
  count: number;
  is_premium: unknown;
  likes: Record<string, unknown>[];
}

async function receivedBody(token: string): Promise<ReceivedLikes> {
  const res = await fetch(`${BASE_URL}/api/likes/received`, { headers: auth(token) });
  expect(res.status).toBe(200);
  return (await res.json()) as ReceivedLikes;
}

async function receivedLikes(token: string): Promise<Record<string, unknown>[]> {
  return (await receivedBody(token)).likes;
}

// V1-CONTRAT §3: the app shows the paywall from this flag, not by guessing from
// the shape of the likes.
describe("received likes: is_premium", () => {
  test("false with teasers for a free member, true with the whole profiles once mazl+", async () => {
    const liked = await makeUser("flag-liked");
    const liker = await makeUser("flag-liker");
    await completeProfile(liked.token, "female");
    await completeProfile(liker.token, "male");
    const swipe = await fetch(`${BASE_URL}/api/swipes`, {
      method: "POST",
      headers: { ...auth(liker.token), "Content-Type": "application/json" },
      body: JSON.stringify({ target_user_id: liked.id, action: "like" }),
    });
    expect(swipe.status).toBe(200);

    const free = await receivedBody(liked.token);
    expect(free.is_premium).toBe(false);
    expect(free.count).toBe(1);
    expect(Object.keys(free.likes[0] ?? {}).sort()).toEqual(["blurredPhotoUrl", "display_name", "is_super_like", "is_verified", "liked_at"]);

    await grantPlus(liked.id);
    const plus = await receivedBody(liked.token);
    expect(plus.is_premium).toBe(true);
    expect(plus.likes[0]).toMatchObject({ user_id: liker.id, display_name: "Jonas" });
    expect(Object.keys(plus.likes[0] ?? {})).toEqual(expect.arrayContaining(["user_id", "picture", "age", "is_verified", "liked_at", "is_super_like", "note"]));
  });

  test("a member with no like at all still gets the flag", async () => {
    const lonely = await makeUser("flag-lonely");
    expect(await receivedBody(lonely.token)).toMatchObject({ success: true, count: 0, is_premium: false, likes: [] });
    await grantPlus(lonely.id);
    expect((await receivedBody(lonely.token)).is_premium).toBe(true);
  });
});

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
    expect(Object.keys(teaser ?? {}).sort()).toEqual(["blurredPhotoUrl", "display_name", "is_super_like", "is_verified", "liked_at"]);

    await db`
      INSERT INTO subscriptions (user_id, plan_type, status, store, product_id, original_transaction_id, started_at, expires_at)
      VALUES (${liked.id}, 'monthly', 'active', 'apple', 'com.mazl.app.plus.1m', ${`visibility-${liked.id}`}, NOW() AT TIME ZONE 'UTC', (NOW() AT TIME ZONE 'UTC') + INTERVAL '30 days')`;
    const [full] = await receivedLikes(liked.token);
    expect(full?.user_id).toBe(liker.id);
  });
});
