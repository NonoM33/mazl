import { describe, expect, test } from "bun:test";
import { resetUnprovenPhotoBadges } from "../src/features/verification/infra/schema";
import { db, makeUser } from "./media-helpers";

// Regression: the pre-level-1 flow set verification_level = 'photo' for any
// base64 string. Those badges must disappear; real ones and manual reviews stay.
async function profileWith(label: string, level: string, photoVerified: boolean): Promise<number> {
  const u = await makeUser(label);
  await db`
    INSERT INTO profiles (user_id, display_name) VALUES (${u.id}, ${label})
    ON CONFLICT (user_id) DO NOTHING
  `;
  await db`
    UPDATE profiles SET is_verified = ${level !== "none"}, verification_level = ${level},
      photo_verified_at = ${photoVerified ? new Date() : null}
    WHERE user_id = ${u.id}
  `;
  return u.id;
}

const badge = async (userId: number) =>
  (await db<{ is_verified: boolean; verification_level: string }[]>`
    SELECT is_verified, verification_level FROM profiles WHERE user_id = ${userId}
  `)[0];

describe("resetUnprovenPhotoBadges", () => {
  test("removes badges granted by the old fake flow, keeps proven and manual ones", async () => {
    const fake = await profileWith("badge-fake", "photo", false);
    const real = await profileWith("badge-real", "photo", true);
    const manual = await profileWith("badge-manual", "verified_plus", false);

    expect(await resetUnprovenPhotoBadges(db)).toBeGreaterThanOrEqual(1);
    expect(await badge(fake)).toEqual({ is_verified: false, verification_level: "none" });
    expect(await badge(real)).toEqual({ is_verified: true, verification_level: "photo" });
    expect(await badge(manual)).toEqual({ is_verified: true, verification_level: "verified_plus" });
    expect(await resetUnprovenPhotoBadges(db)).toBe(0);
  });
});
