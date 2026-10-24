import { describe, expect, test } from "bun:test";
import { BASE_URL, db, json, makeUser, type TestUser } from "./media-helpers";

// The app has a "relationship intention" (mobile/lib/core/models/
// relationship_intention.dart) that the matching engine weighs; the server
// used to drop it silently. Needs a running server (TEST_API_URL) and its
// database (TEST_DATABASE_URL).

const putProfile = (user: TestUser, body: unknown) =>
  fetch(`${BASE_URL}/api/profile`, { method: "PUT", headers: json(user.token), body: JSON.stringify(body) });

async function storedIntention(userId: number): Promise<string | null> {
  const rows = await db<{ relationship_intention: string | null }[]>`
    SELECT relationship_intention FROM profiles WHERE user_id = ${userId}
  `;
  return rows[0]?.relationship_intention ?? null;
}

describe("PUT /api/profile stores the relationship intention", () => {
  test("each intention of the app is stored and returned", async () => {
    const user = await makeUser("intention");
    for (const intention of ["marriage", "serious", "open", "friends_first"]) {
      const res = await putProfile(user, { relationshipIntention: intention });
      expect(res.status).toBe(200);
      const body = (await res.json()) as { profile: { relationship_intention: string | null } };
      expect(body.profile.relationship_intention).toBe(intention);
      expect(await storedIntention(user.id)).toBe(intention);
    }
  });

  test("an absent or null intention leaves the stored one alone", async () => {
    const user = await makeUser("intention-keep");
    await putProfile(user, { relationshipIntention: "marriage" });
    expect((await putProfile(user, { bio: "Bonjour" })).status).toBe(200);
    expect((await putProfile(user, { relationshipIntention: null })).status).toBe(200);
    expect(await storedIntention(user.id)).toBe("marriage");
  });

  test("an unknown intention is refused", async () => {
    const user = await makeUser("intention-bad");
    const res = await putProfile(user, { relationshipIntention: "casual_tonight" });
    expect(res.status).toBe(400);
    expect(await storedIntention(user.id)).toBeNull();
  });
});
