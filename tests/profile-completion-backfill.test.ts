import { describe, expect, test } from "bun:test";
import { backfillProfileCompleteness } from "../src/db";
import { db, makeUser } from "./media-helpers";

// Profiles are only shown to others once complete (GET /api/profile/:id,
// discover). Nothing used to set is_complete, so members who filled in their
// profile before that rule must be completed once, at boot, not hidden.
// Needs the test database (DATABASE_URL = TEST_DATABASE_URL).

describe("completion backfill", () => {
  test("a profile with name, adult birthdate, gender and looking-for becomes complete; one missing any of them does not", async () => {
    const finished = await makeUser("backfill-ok");
    const unfinished = await makeUser("backfill-ko");
    await db`UPDATE profiles SET display_name = 'Jeanne', birthdate = '1990-05-01', gender = 'female', looking_for = 'male', is_complete = false WHERE user_id = ${finished.id}`;
    await db`UPDATE profiles SET display_name = 'Paul', birthdate = NULL, gender = 'male', looking_for = 'female', is_complete = false WHERE user_id = ${unfinished.id}`;

    await backfillProfileCompleteness();

    const rows = await db<{ user_id: number; is_complete: boolean }[]>`
      SELECT user_id, is_complete FROM profiles WHERE user_id IN (${finished.id}, ${unfinished.id})
    `;
    const complete = new Map(rows.map((r) => [r.user_id, r.is_complete]));
    expect(complete.get(finished.id)).toBe(true);
    expect(complete.get(unfinished.id)).toBe(false);
  });
});
